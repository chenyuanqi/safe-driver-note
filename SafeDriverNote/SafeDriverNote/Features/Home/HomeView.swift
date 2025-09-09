import SwiftUI
import CoreLocation

struct HomeView: View {
	@StateObject private var vm = HomeViewModel()
	@StateObject private var driveService = AppDI.shared.driveService
	@State private var selectedKnowledgeIndex = 0
	@State private var showingLogEditor = false
	@State private var showingSafetyAlert = false
	@State private var showingVoiceRecordingAlert = false
	@State private var showingDriveConfirmation = false
	@State private var currentLocationDescription = "获取位置中..."
	@State private var isLocationUpdating = false
	@State private var showingDriveError = false
	@State private var driveErrorMessage = ""
	@State private var manualLocationTries = 0
	@State private var manualEndTries = 0
	@State private var showingManualLocationSheet = false
	@State private var showingPermissionGuide = false
	@State private var manualAddress: String = ""
	@State private var manualStartOrEnd: String = "start" // "start" or "end"
	
	var body: some View {
		NavigationStack {
		VStack(spacing: 0) {
			// Custom Navigation Bar
			StandardNavigationBar(
					title: "安全驾驶",
				showBackButton: false,
				trailingButtons: [
					StandardNavigationBar.NavBarButton(icon: "bell") {
						// Handle notifications
					}
				]
			)
			
			ScrollView {
				VStack(spacing: Spacing.xxxl) {
					// Status Panel
					statusPanel
					
					// Quick Actions
					quickActionsSection
					
					// Today Learning
					todayLearningSection
					
					// Smart Recommendations
					smartRecommendationsSection
					
					// Recent Activity
					recentActivitySection
				}
				.padding(.horizontal, Spacing.pagePadding)
				.padding(.vertical, Spacing.lg)
			}
			.background(Color.brandSecondary50)
		}
		}
		.onAppear { 
			vm.reload() 
			// 先请求位置权限，避免交互中触发系统弹窗导致等待
			LocationService.shared.requestLocationPermission()
			Task {
				await vm.loadRecentRoutes()
				// 获取当前位置（一次性，不并发重复调用）
				await updateCurrentLocation()
			}
			
			// 监听驾驶服务错误通知
			NotificationCenter.default.addObserver(
				forName: .driveServiceError,
				object: nil,
				queue: .main
			) { notification in
				if let errorMessage = notification.object as? String {
					driveErrorMessage = errorMessage
					showingDriveError = true
				}
			}
		}
		.onDisappear {
			// 移除通知观察者
			NotificationCenter.default.removeObserver(self)
		}
		.sheet(isPresented: $showingLogEditor) {
			LogEditorView(entry: nil) { type, detail, location, scene, cause, improvement, tags, photos, audioFileName, transcript in
				// 创建新的驾驶日志
				let newEntry = LogEntry(
					type: type,
					locationNote: location,
					scene: scene,
					detail: detail,
					cause: cause,
					improvement: improvement,
					tags: tags.isEmpty ? [] : tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
					photoLocalIds: photos,
					audioFileName: audioFileName,
					transcript: transcript
				)
				try? AppDI.shared.logRepository.add(newEntry)
				// 重新加载数据
				vm.reload()
			}
		}
		.alert("安全提醒", isPresented: $showingSafetyAlert) {
			Button("知道了") { }
		} message: {
			Text("道路千万条，安全第一条！平安抵达目的地才是唯一目的！")
		}
		.alert("功能开发中", isPresented: $showingVoiceRecordingAlert) {
			Button("知道了") { }
		} message: {
			Text("语音记录功能正在开发中，敬请期待！")
		}
		.alert("开始驾驶", isPresented: $showingDriveConfirmation) {
			Button("取消", role: .cancel) { }
			Button("开始") {
				Task {
					// 尝试定位，失败累计计数
					let locationService = LocationService.shared
					do {
						try _ = await locationService.getCurrentLocation(timeout: 5.0)
						await driveService.startDriving()
						await vm.loadRecentRoutes()
						manualLocationTries = 0
					} catch {
						manualLocationTries += 1
						if manualLocationTries >= 3 {
							manualStartOrEnd = "start"
							showingManualLocationSheet = true
						} else {
							// 仍然允许开始驾驶，但无起点
							await driveService.startDriving()
							await vm.loadRecentRoutes()
						}
					}
				}
			}
		} message: {
			Text("将记录您的驾驶路线和时间，帮助您更好地管理驾驶行为。道路千万条，安全第一条！")
		}
		.alert("驾驶服务错误", isPresented: $showingDriveError) {
			Button("知道了") { }
		} message: {
			Text(driveErrorMessage)
		}
		.sheet(isPresented: $showingManualLocationSheet) {
			NavigationStack {
				VStack(alignment: .leading, spacing: Spacing.lg) {
					Text(manualStartOrEnd == "start" ? "输入起点位置" : "输入终点位置")
						.font(.title3)
						.fontWeight(.semibold)
					TextField("如：上海市人民广场或经纬度 31.23,121.47", text: $manualAddress)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled(true)
					Spacer()
				}
				.padding()
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						Button("取消") { showingManualLocationSheet = false }
					}
					ToolbarItem(placement: .confirmationAction) {
						Button("保存") {
							Task { @MainActor in
								let ls = LocationService.shared
								// 支持“lat,lon”直接输入
								let trimmed = manualAddress.trimmingCharacters(in: .whitespacesAndNewlines)
								var location: CLLocation?
								if let comma = trimmed.firstIndex(of: ",") {
									let latStr = String(trimmed[..<comma]).trimmingCharacters(in: .whitespaces)
									let lonStr = String(trimmed[trimmed.index(after: comma)...]).trimmingCharacters(in: .whitespaces)
									if let lat = Double(latStr), let lon = Double(lonStr) {
										location = CLLocation(latitude: lat, longitude: lon)
									}
								}
								if location == nil {
									do { location = try await ls.geocodeAddress(trimmed) } catch { location = nil }
								}
								if let loc = location {
									let address = await ls.getLocationDescription(from: loc)
									let routeLoc = RouteLocation(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, address: address)
									if manualStartOrEnd == "start" {
										await driveService.startDriving(with: routeLoc)
										await vm.loadRecentRoutes()
									} else {
										await driveService.endDriving(with: routeLoc)
										manualEndTries = 0
										await vm.loadRecentRoutes()
									}
								}
								manualAddress = ""
								showingManualLocationSheet = false
							}
						}
						.disabled(manualAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
					}
				}
			}
		}
		.sheet(isPresented: $showingPermissionGuide) {
			LocationPermissionGuideView()
		}
	}
	/* duplicate manualLocation sheet removed */
	
	// MARK: - Status Panel
	private var statusPanel: some View {
		VStack(alignment: .leading, spacing: Spacing.lg) {
			// Greeting
			VStack(alignment: .leading, spacing: Spacing.sm) {
				Text(vm.greeting)
					.font(.bodyLarge)
					.foregroundColor(.brandSecondary500)
				Text("安全驾驶，从记录开始！")
					.font(.title2)
					.foregroundColor(.brandSecondary900)
			}
			
			// Status Cards
			HStack(spacing: Spacing.lg) {
				StatusCard(
					title: "安全评分",
					value: vm.safetyScore,
					color: .brandPrimary500,
					icon: "shield.checkered"
				)
				
				StatusCard(
					title: "连续天数",
					value: "\(vm.consecutiveDays)天",
					color: .brandInfo500,
					icon: "calendar"
				)
				
				StatusCard(
					title: "今日完成",
					value: vm.todayCompletionRate,
					color: .brandPrimary500,
					icon: "checkmark.circle"
				)
			}
		}
	}
	
	// MARK: - Quick Actions Section
	private var quickActionsSection: some View {
		VStack(alignment: .leading, spacing: Spacing.lg) {
			Text("快速操作")
				.font(.title3)
				.fontWeight(.semibold)
				.foregroundColor(.brandSecondary900)
			
			// Primary Action - Start/End Driving
			Button(action: {
				if driveService.isDriving {
					// 结束驾驶（带三次失败后手动输入）
					Task {
						// 使用带重试和超时的结束流程
						await driveService.endDrivingWithRetries(maxAttempts: 3, perAttemptTimeout: 5)
						await vm.loadRecentRoutes()
					}
				} else {
					// 权限引导：如果仅使用期间或被拒绝，先弹权限引导页
					let status = LocationService.shared.authorizationStatus
					if status == .denied || status == .restricted || status == .notDetermined || status == .authorizedWhenInUse {
						showingPermissionGuide = true
					} else {
						// 开始驾驶前显示确认对话框
						showingDriveConfirmation = true
					}
				}
			}) {
				Card(backgroundColor: driveService.isDriving ? .brandDanger500 : .brandPrimary500, shadow: true) {
					HStack(spacing: Spacing.lg) {
						if driveService.isStartingDrive || driveService.isEndingDrive {
							ProgressView()
								.progressViewStyle(CircularProgressViewStyle(tint: .white))
								.scaleEffect(0.8)
						} else {
							Image(systemName: driveService.isDriving ? "stop.circle" : "car")
							.font(.title2)
							.foregroundColor(.white)
						}
						
						VStack(alignment: .leading, spacing: Spacing.xs) {
							Text(driveService.isDriving ? "结束驾驶" : "开始驾驶")
							.font(.bodyLarge)
							.fontWeight(.semibold)
							.foregroundColor(.white)
								
							if driveService.isDriving, let route = driveService.currentRoute {
								Text("已驾驶 \(driveService.currentDrivingTime)")
									.font(.bodySmall)
									.foregroundColor(.white.opacity(0.8))
								
								// 显示当前位置
								Text(currentLocationDescription)
									.font(.bodySmall)
									.foregroundColor(.white.opacity(0.8))
							} else if !driveService.isDriving {
								// 显示当前位置
								Text(currentLocationDescription)
									.font(.bodySmall)
									.foregroundColor(.white.opacity(0.8))
							}
						}
						
						Spacer()
						
						Image(systemName: "chevron.right")
							.font(.body)
							.foregroundColor(.white.opacity(0.8))
					}
				}
			}
			.buttonStyle(PlainButtonStyle())
			.disabled(driveService.isStartingDrive || driveService.isEndingDrive)
			// 移除额外的 onTapGesture，避免并发位置请求
			
			// Secondary Actions
			HStack(spacing: Spacing.lg) {
				NavigationLink(destination: ChecklistView(initialMode: .pre)) {
					Card(backgroundColor: Color.brandInfo500.opacity(0.12), shadow: false) {
						HStack(spacing: Spacing.md) {
							Image(systemName: "checkmark.seal")
								.font(.title3)
								.foregroundColor(.brandInfo500)
							
							Text("行前检查")
								.font(.bodyLarge)
								.foregroundColor(.brandInfo500)
								.fontWeight(.medium)
							
							Spacer()
						}
					}
				}
				.buttonStyle(PlainButtonStyle())
				
				NavigationLink(destination: VoiceNoteView()) {
					Card(backgroundColor: Color.brandWarning500.opacity(0.12), shadow: false) {
						HStack(spacing: Spacing.md) {
							Image(systemName: "mic")
								.font(.title3)
								.foregroundColor(.brandWarning500)
							
							Text("语音记录")
								.font(.bodyLarge)
								.foregroundColor(.brandWarning500)
								.fontWeight(.medium)
							
							Spacer()
						}
					}
				}
				.buttonStyle(PlainButtonStyle())
			}
		}
	}
	
	// MARK: - Update Current Location
	private func updateCurrentLocation() async {
		// 如果正在更新位置，则直接返回
		guard !isLocationUpdating else { return }
		
		isLocationUpdating = true
		defer { isLocationUpdating = false }
		
		// 更新位置显示为加载状态
		currentLocationDescription = "获取位置中..."
		
		do {
			// 获取位置服务实例
			let locationService = LocationService.shared
			let locationDescription = await locationService.getCurrentLocationDescription()
			await MainActor.run {
				self.currentLocationDescription = locationDescription
			}
		} catch {
			await MainActor.run {
				self.currentLocationDescription = "未知位置"
			}
		}
	}
	
	// MARK: - Today Learning Section
	private var todayLearningSection: some View {
		VStack(alignment: .leading, spacing: Spacing.lg) {
			HStack {
				Label("今日学习", systemImage: "book")
					.font(.title3)
					.fontWeight(.semibold)
					.foregroundColor(.brandSecondary900)
				
				Spacer()
				
				Text("2/3")
					.font(.bodySmall)
					.foregroundColor(.brandSecondary500)
			}
			
			// Knowledge Cards Carousel
			TabView(selection: $selectedKnowledgeIndex) {
				ForEach(0..<vm.todayKnowledgeCards.count, id: \.self) { index in
					let card = vm.todayKnowledgeCards[index]
					knowledgeCardView(card)
						.tag(index)
				}
			}
			.tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
			.frame(height: 200)
			.indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
		}
	}
	
	// MARK: - Smart Recommendations Section
	private var smartRecommendationsSection: some View {
		VStack(alignment: .leading, spacing: Spacing.lg) {
			Label("为你推荐", systemImage: "lightbulb")
				.font(.title3)
				.fontWeight(.semibold)
				.foregroundColor(.brandSecondary900)
			
			VStack(spacing: Spacing.lg) {
				// FAQ Recommendation
				ListItemCard(
					leadingIcon: "questionmark.circle",
					leadingColor: .brandInfo500,
					trailingContent: {
						AnyView(
							Image(systemName: "chevron.right")
								.font(.bodySmall)
								.foregroundColor(.brandSecondary300)
						)
					}
				) {
					VStack(alignment: .leading, spacing: Spacing.xs) {
						Text("高速爆胎怎么办？")
							.font(.body)
							.fontWeight(.medium)
							.foregroundColor(.brandSecondary900)
						Text("紧急情况处理指南")
							.font(.bodySmall)
							.foregroundColor(.brandSecondary500)
					}
				}
				
				// Product Recommendation
				ListItemCard(
					leadingIcon: "cart",
					leadingColor: .brandPrimary500,
					trailingContent: {
						AnyView(
							Image(systemName: "chevron.right")
								.font(.bodySmall)
								.foregroundColor(.brandSecondary300)
						)
					}
				) {
					VStack(alignment: .leading, spacing: Spacing.xs) {
						Text("小圆镜")
							.font(.body)
							.fontWeight(.medium)
							.foregroundColor(.brandSecondary900)
						Text("消除盲区必备")
							.font(.bodySmall)
							.foregroundColor(.brandSecondary500)
					}
				}
			}
		}
	}
	
	// MARK: - Recent Activity Section
	private var recentActivitySection: some View {
		VStack(alignment: .leading, spacing: Spacing.lg) {
			Label("最近活动", systemImage: "calendar")
				.font(.title3)
				.fontWeight(.semibold)
				.foregroundColor(.brandSecondary900)
			
			VStack(spacing: Spacing.md) {
				ForEach(vm.recentActivities.prefix(3), id: \.id) { activity in
					recentActivityItem(activity)
				}
				
				if vm.recentActivities.count > 3 {
					NavigationLink(destination: LogListView().environmentObject(AppDI.shared)) {
						HStack {
							Text("查看更多")
								.font(.bodySmall)
							.foregroundColor(.brandSecondary500)
						
							Spacer()
							
							Image(systemName: "chevron.right")
								.font(.bodySmall)
								.foregroundColor(.brandSecondary300)
						}
						.padding(.vertical, Spacing.sm)
					}
				}
			}
		}
	}
	
	// MARK: - Knowledge Card View
	private func knowledgeCardView(_ card: KnowledgeCardData) -> some View {
		Card(backgroundColor: .white, shadow: true) {
			VStack(alignment: .leading, spacing: Spacing.lg) {
				Text(card.title)
					.font(.bodyLarge)
					.fontWeight(.semibold)
					.foregroundColor(.brandSecondary900)
					.multilineTextAlignment(.leading)
				
				Text(card.content)
					.font(.body)
					.foregroundColor(.brandSecondary700)
					.lineLimit(3)
					.multilineTextAlignment(.leading)
				
				Spacer()
				
				HStack {
					Spacer()
					
					if card.isLearned {
						Text("已学习")
							.tagStyle(.success)
					} else {
						Button("开始学习") {
							// Handle learning action
						}
						.compactStyle(color: .brandPrimary500)
					}
				}
			}
		}
	}
	
	private func recentActivityItem(_ activity: RecentActivity) -> some View {
		Group {
			if activity.activityType == .logEntry, let logId = activity.relatedId {
				// 日志记录点击跳转到日志列表
				NavigationLink(destination: LogListView()) {
					activityItemContent(activity)
				}
				.buttonStyle(PlainButtonStyle())
			} else if activity.activityType == .driveRoute, let routeId = activity.relatedId {
				// 驾驶记录点击跳转到详情页
				if let route = vm.recentRoutes.first(where: { $0.id == routeId }) {
					NavigationLink(destination: DriveRouteDetailView(route: route).environmentObject(AppDI.shared)) {
						activityItemContent(activity)
					}
					.buttonStyle(PlainButtonStyle())
				} else {
					activityItemContent(activity)
				}
			} else {
				activityItemContent(activity)
			}
		}
	}
	
	private func activityItemContent(_ activity: RecentActivity) -> some View {
		ListItemCard(
			leadingIcon: activity.icon,
			leadingColor: activity.color
		) {
			VStack(alignment: .leading, spacing: Spacing.xs) {
				HStack {
					Text(vm.formatDate(activity.date))
						.font(.caption)
						.foregroundColor(.brandSecondary500)
					
					Spacer()
					
					Text(activity.type)
						.tagStyle(activity.tagStyle)
				}
				
				Text(activity.title)
					.font(.body)
					.fontWeight(.medium)
					.foregroundColor(.brandSecondary900)
					.lineLimit(2)
				
				if let subtitle = activity.subtitle {
					Text(subtitle)
						.font(.caption)
						.foregroundColor(.brandSecondary500)
						.lineLimit(1)
				}
			}
		}
	}
	

}

// MARK: - Knowledge Card Data
struct KnowledgeCardData: Identifiable {
	let id = UUID()
	let title: String
	let content: String
	let isLearned: Bool
}

// MARK: - Recent Activity Data
struct RecentActivity: Identifiable {
	let id = UUID()
	let date: Date
	let type: String
	let title: String
	let subtitle: String?
	let icon: String
	let color: Color
	let tagStyle: TagStyle.TagType
	let activityType: ActivityType
	let relatedId: UUID?
	
	enum ActivityType {
		case logEntry
		case driveRoute
	}
}

@MainActor
final class HomeViewModel: ObservableObject {
	@Published private(set) var allLogs: [LogEntry] = []
	@Published private(set) var recentLogs: [LogEntry] = []
	@Published private(set) var recentRoutes: [DriveRoute] = []
	@Published private(set) var recentActivities: [RecentActivity] = []
	@Published private(set) var todayPreCount: Int = 0
	@Published private(set) var todayPostCount: Int = 0
	@Published private(set) var todayKnowledgeCards: [KnowledgeCardData] = []
		
	init() { reload() }
	
	func reload() {
		if let list = try? AppDI.shared.logRepository.fetchAll() {
			let sorted = list.sorted { $0.createdAt > $1.createdAt }
			self.allLogs = sorted
			self.recentLogs = Array(sorted.prefix(3))
		}
		// Checklist today
		let today = Date()
		let repo = AppDI.shared.checklistRepository
		let pre = (try? repo.fetchPunches(on: today, mode: .pre)) ?? []
		let post = (try? repo.fetchPunches(on: today, mode: .post)) ?? []
		self.todayPreCount = pre.count
		self.todayPostCount = post.count
		
		// Load today's knowledge cards
		loadTodayKnowledgeCards()
		
		// Load recent activities (combine logs and routes)
		updateRecentActivities()
	}
	
	func loadRecentRoutes() async {
		let routeService = AppDI.shared.driveService
		self.recentRoutes = routeService.getRecentRoutes(limit: 5)
		updateRecentActivities()
	}
	
	private func updateRecentActivities() {
		var activities: [RecentActivity] = []
		
		// Add log entries
		for log in recentLogs {
			let activity = RecentActivity(
				date: log.createdAt,
				type: log.type == .mistake ? "失误" : "成功",
				title: title(for: log),
				subtitle: log.locationNote.isEmpty ? nil : log.locationNote,
				icon: log.type == .mistake ? "exclamationmark.triangle.fill" : "checkmark.circle.fill",
				color: log.type == .mistake ? .brandDanger500 : .brandPrimary500,
				tagStyle: log.type == .mistake ? .error : .success,
				activityType: .logEntry,
				relatedId: log.id
			)
			activities.append(activity)
		}
		
		// Add drive routes
		for route in recentRoutes {
			let duration = AppDI.shared.driveService.formatDuration(route.duration)
			let distance = AppDI.shared.driveService.formatDistance(route.distance)
			
			let subtitle: String
			if let dur = route.duration, let dist = route.distance {
				subtitle = "\(duration) · \(distance)"
			} else if route.duration != nil {
				subtitle = duration
			} else if route.distance != nil {
				subtitle = distance
			} else {
				subtitle = "驾驶记录"
			}
			
			let activity = RecentActivity(
				date: route.endTime ?? route.startTime,
				type: "驾驶",
				title: formatRouteTitle(route),
				subtitle: subtitle,
				icon: "car.fill",
				color: .brandPrimary500,
				tagStyle: .primary,
				activityType: .driveRoute,
				relatedId: route.id
			)
			activities.append(activity)
		}
		
		// Sort by date and take recent ones
		self.recentActivities = activities
			.sorted { $0.date > $1.date }
			.prefix(5)
			.map { $0 }
	}
	
	private func formatRouteTitle(_ route: DriveRoute) -> String {
		if let start = route.startLocation?.address, let end = route.endLocation?.address {
			return "\(start) → \(end)"
		} else if let start = route.startLocation?.address {
			return "从 \(start) 出发"
		} else if let end = route.endLocation?.address {
			return "抵达 \(end)"
		} else {
			return "驾驶记录"
		}
	}
	
	func formatDrivingTime(from startTime: Date) -> String {
		let elapsed = Date().timeIntervalSince(startTime)
		let hours = Int(elapsed) / 3600
		let minutes = (Int(elapsed) % 3600) / 60
		
		if hours > 0 {
			return "\(hours)小时\(minutes)分钟"
		} else {
			return "\(minutes)分钟"
		}
	}
	
	private func loadTodayKnowledgeCards() {
		// Mock knowledge cards for today
		todayKnowledgeCards = [
			KnowledgeCardData(
				title: "安全跟车距离",
				content: "保持3秒车距原则，在高速公路上应保持更长的跟车距离，确保有足够的反应时间。",
				isLearned: false
			),
			KnowledgeCardData(
				title: "雨天驾驶技巧",
				content: "雨天路面湿滑，要降低车速，保持更大的跟车距离，避免急刹车和急转弯。",
				isLearned: true
			),
			KnowledgeCardData(
				title: "停车技巧",
				content: "倒车入库时要多观察后视镜，利用参照物判断车位，耐心慢速操作。",
				isLearned: false
			)
		]
	}
	
	var monthLogs: [LogEntry] {
		let cal = Calendar(identifier: .gregorian)
		let start = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
		return allLogs.filter { $0.createdAt >= start }
	}
	var monthTotal: Int { monthLogs.count }
	var monthMistakes: Int { monthLogs.filter { $0.type == .mistake }.count }
	var monthSuccess: Int { monthLogs.filter { $0.type == .success }.count }
	var improvementRateText: String {
		guard monthTotal > 0 else { return "--%" }
		return String(format: "%.0f%%", Double(monthSuccess) / Double(monthTotal) * 100)
	}
	
	// MARK: - New Properties for Redesign
	var safetyScore: String {
		guard monthTotal > 0 else { return "--" }
		let score = max(60, min(100, 100 - (monthMistakes * 10)))
		return "\(score)分"
	}
	
	var consecutiveDays: Int {
		// Calculate consecutive days with records
		let calendar = Calendar.current
		let today = Date()
		var days = 0
		
		for i in 0..<30 { // Check last 30 days
			guard let checkDate = calendar.date(byAdding: .day, value: -i, to: today) else { break }
			let dayStart = calendar.startOfDay(for: checkDate)
			let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
			
			let hasRecord = allLogs.contains { log in
				log.createdAt >= dayStart && log.createdAt < dayEnd
			}
			
			if hasRecord {
				days += 1
			} else if i > 0 {
				break // Stop counting if we find a day without records (except today)
			}
		}
		
		return days
	}
	
	var todayCompletionRate: String {
		let totalTasks = 3 // Assume 3 daily tasks (checklist pre, post, learning)
		let completed = min(1, todayPreCount) + min(1, todayPostCount) + (todayKnowledgeCards.filter(\.isLearned).count > 0 ? 1 : 0)
		let rate = totalTasks > 0 ? (Double(completed) / Double(totalTasks) * 100) : 0
		return String(format: "%.0f%%", rate)
	}
	
	var greeting: String {
		let h = Calendar.current.component(.hour, from: Date())
		switch h {
		case 5..<12: return "早上好"
		case 12..<18: return "下午好"
		default: return "晚上好"
		}
	}
	
	func title(for log: LogEntry) -> String {
		if !log.scene.isEmpty { return log.scene }
		if !log.locationNote.isEmpty { return log.locationNote }
		if !log.detail.isEmpty { return String(log.detail.prefix(18)) }
		return "记录"
	}
	
	func formatDate(_ date: Date) -> String {
		let f = DateFormatter()
		f.locale = Locale(identifier: "zh_CN")
		f.calendar = Calendar(identifier: .gregorian)
		f.dateFormat = "M月d日 HH:mm"
		return f.string(from: date)
	}
}

#Preview { HomeView() }