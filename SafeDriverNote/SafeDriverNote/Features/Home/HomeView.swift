import SwiftUI
import CoreLocation
import Foundation
import UserNotifications
import SwiftData

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
    
    // 添加状态说明弹框相关属性
    @State private var showingStatusExplanation = false
    @State private var statusExplanationTitle = ""
    @State private var statusExplanationContent = ""
    
    // 添加知识页导航相关属性
    @State private var showingKnowledgeView = false
    @State private var selectedKnowledgeCardTitle: String? = nil
    
    // 添加自动轮播定时器
    @State private var carouselTimer: Timer?
    
    // 添加通知权限弹框相关属性
    @State private var showingNotificationPermissionAlert = false
    @State private var notificationPermissionGranted: Bool? = nil

    // 添加通知详情相关属性
    @State private var showingNotificationDetail = false
    @State private var notificationDetailTitle = ""
    @State private var notificationDetailContent = ""

    // 添加调试信息弹框
    @State private var showingDebugInfo = false
    @State private var debugInfoText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
            // Custom Navigation Bar
            StandardNavigationBar(
                title: "安全驾驶",
                showBackButton: false
            )
            
            ScrollView {
                VStack(spacing: Spacing.xxxl) {
                    // Status Panel
                    statusPanel

                    // Quick Actions
                    quickActionsSection

                    // Today Learning
                    todayLearningSection

                    // Smart Recommendations (暂时隐藏)
                    // smartRecommendationsSection

                    // Recent Activity
                    recentActivitySection
                }
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.vertical, Spacing.lg)
            }
            .refreshable {
                await refreshHomeData()
            }
            .background(Color.brandSecondary50)
            } // 关闭VStack
        } // 关闭NavigationStack
        .onAppear { 
            vm.reload() 
            // 先请求位置权限，避免交互中触发系统弹窗导致等待
            LocationService.shared.requestLocationPermission()
            Task {
                await vm.loadRecentRoutes()
                // 获取当前位置（一次性，不并发重复调用）
                await updateCurrentLocation()
                
                // 检查通知权限状态
                await checkNotificationPermission()
            }
            
            // 添加通知监听
            setupNotificationObservers()
            
            // 清除通知红点
            Task {
                await clearNotificationBadges()
            }
        }
        .onDisappear {
            // 移除通知观察者
            removeNotificationObservers()
            // 停止自动轮播定时器
            stopAutoCarousel()
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
        .sheet(isPresented: $showingDriveConfirmation) {
            StartDrivingConfirmationView(
                onCancel: {
                    showingDriveConfirmation = false
                },
                onConfirm: {
                    showingDriveConfirmation = false
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
            )
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.visible)
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
        .alert("通知权限", isPresented: $showingNotificationPermissionAlert) {
            Button("暂不开启") { 
                showingNotificationPermissionAlert = false
            }
            Button("去开启") { 
                requestNotificationPermission()
            }
        } message: {
            Text("开启通知权限，您将每天收到安全驾驶提醒，祝您今天开车安全第一！")
        }
        .alert(notificationDetailTitle, isPresented: $showingNotificationDetail) {
            Button("知道了") { }
        } message: {
            Text(notificationDetailContent)
        }
        .sheet(isPresented: $showingKnowledgeView) {
            KnowledgeTodayView(initialCardTitle: selectedKnowledgeCardTitle)
                .presentationDetents([.large, .fraction(0.85)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
        .alert("驾驶调试信息", isPresented: $showingDebugInfo) {
            Button("复制") {
                UIPasteboard.general.string = debugInfoText
            }
            Button("关闭", role: .cancel) { }
        } message: {
            Text(debugInfoText)
        }
    }
    
    // 添加通知监听
    private func setupNotificationObservers() {
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
        
        // 监听知识卡片标记通知
        NotificationCenter.default.addObserver(
            forName: .knowledgeCardMarked,
            object: nil,
            queue: .main
        ) { _ in
            // 重新加载今日学习卡片
            vm.loadTodayKnowledgeCards()
        }
    }
    
    // 移除通知监听
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self)
    }
	
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
				) {
					// 安全评分说明
					statusExplanationTitle = "安全评分"
					statusExplanationContent = "基于您本月的驾驶记录计算得出。满分100分，每有一次失误记录会扣减相应分数。持续保持良好的驾驶习惯可以提高安全评分。"
					showingStatusExplanation = true
				}
				
				StatusCard(
					title: "连续天数",
					value: "\(vm.consecutiveDays)天",
					color: .brandInfo500,
					icon: "calendar"
				) {
					// 连续天数说明
					statusExplanationTitle = "连续天数"
					statusExplanationContent = "连续记录驾驶日志的天数。只要当天有创建驾驶日志或完成检查清单，就算作有效记录。连续记录有助于培养良好的驾驶习惯。"
					showingStatusExplanation = true
				}
				
				StatusCard(
					title: "今日完成",
					value: vm.todayCompletionRate,
					color: .brandPrimary500,
					icon: "checkmark.circle"
				) {
					// 今日完成说明
					statusExplanationTitle = "今日完成"
					statusExplanationContent = "今日任务完成度，包括行前检查、行后检查和知识学习。完成所有三项任务可获得100%的完成度。每天坚持完成任务有助于提升驾驶技能。"
					showingStatusExplanation = true
				}
			}
		}
		.sheet(isPresented: $showingStatusExplanation) {
			NavigationStack {
				VStack(alignment: .leading, spacing: Spacing.lg) {
					Text(statusExplanationTitle)
						.font(.title2)
						.fontWeight(.semibold)
						.foregroundColor(.brandSecondary900)

					Text(statusExplanationContent)
						.font(.body)
						.foregroundColor(.brandSecondary700)
						.multilineTextAlignment(.leading)

					Spacer()
				}
				.padding()
				.toolbar {
					ToolbarItem(placement: .confirmationAction) {
						Button("知道了") {
							showingStatusExplanation = false
						}
					}
				}
			}
			.presentationDetents([.medium])
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
						// 获取调试信息
						debugInfoText = driveService.getDebugInfo()

						// 使用带重试和超时的结束流程
						await driveService.endDrivingWithRetries(maxAttempts: 3, perAttemptTimeout: 5)
						await vm.loadRecentRoutes()

						// 显示调试信息弹框
						showingDebugInfo = true
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
								Text("已驾驶 \(driveService.currentDrivingTime) · 记录\(driveService.currentWaypointCount)个点")
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
	            
	            Text("\(vm.todayLearnedCount)/3")
	                .font(.bodySmall)
	                .foregroundColor(.brandSecondary500)
	        }
	        
	        // 使用ZStack和手动控制页面切换，避免手势冲突
	        ZStack {
	            ForEach(0..<vm.todayKnowledgeCards.count, id: \.self) { index in
	                let card = vm.todayKnowledgeCards[index]
	                knowledgeCardView(card, index: index)
	                    .opacity(index == selectedKnowledgeIndex ? 1.0 : 0.0)
	                    .zIndex(index == selectedKnowledgeIndex ? 1.0 : 0.0)
	            }
	        }
	        .frame(height: 200)
	        .onAppear {
	            // 启动自动轮播定时器
	            startAutoCarousel()
	        }
	        .onDisappear {
	            // 视图消失时停止定时器
	            stopAutoCarousel()
	        }
	        
	        // 手动添加页面指示器并居中显示
	        HStack(spacing: 8) {
	            ForEach(0..<vm.todayKnowledgeCards.count, id: \.self) { index in
	                Circle()
	                    .fill(index == selectedKnowledgeIndex ? Color.brandPrimary500 : Color.brandSecondary300)
	                    .frame(width: 8, height: 8)
	                    .onTapGesture {
	                        withAnimation {
	                            selectedKnowledgeIndex = index
	                            // 用户手动切换时重置定时器
	                            resetAutoCarousel()
	                        }
	                    }
	            }
	        }
	        .frame(maxWidth: .infinity)
	        .padding(.top, Spacing.md)
	    }
	}

	// MARK: - Knowledge Card View
	private func knowledgeCardView(_ card: KnowledgeCardData, index: Int) -> some View {
	    Card(shadow: true) {
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
	                    HStack(spacing: Spacing.xs) {
	                        Text("点击学习")
	                            .font(.bodySmall)
	                            .foregroundColor(.brandPrimary500)
	                        Image(systemName: "chevron.right")
	                            .font(.caption)
	                            .foregroundColor(.brandPrimary500)
	                    }
	                }
	            }
	        }
	    }
	    .gesture(
	        DragGesture(minimumDistance: 50)
	            .onEnded { value in
	                if value.translation.width > 50 {
	                    // 右滑，切换到上一张卡片
	                    withAnimation {
	                        selectedKnowledgeIndex = max(0, selectedKnowledgeIndex - 1)
	                        // 用户手动切换时重置定时器
	                        resetAutoCarousel()
	                    }
	                } else if value.translation.width < -50 {
	                    // 左滑，切换到下一张卡片
	                    withAnimation {
	                        selectedKnowledgeIndex = min(vm.todayKnowledgeCards.count - 1, selectedKnowledgeIndex + 1)
	                        // 用户手动切换时重置定时器
	                        resetAutoCarousel()
	                    }
	                }
	            }
	    )
	    .onTapGesture {
	        // 点击卡片时跳转到知识页面，并传递当前卡片标题
	        selectedKnowledgeCardTitle = card.title
	        showingKnowledgeView = true
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

			if vm.recentActivities.isEmpty {
				// 空状态显示
				Card(backgroundColor: Color.brandSecondary100.opacity(0.3), shadow: false) {
					HStack {
						Image(systemName: "calendar.badge.exclamationmark")
							.font(.title2)
							.foregroundColor(.brandSecondary400)

						VStack(alignment: .leading, spacing: Spacing.xs) {
							Text("暂无活动记录")
								.font(.body)
								.fontWeight(.medium)
								.foregroundColor(.brandSecondary600)

							Text("开始驾驶或创建日志后将显示在这里")
								.font(.bodySmall)
								.foregroundColor(.brandSecondary500)
						}

						Spacer()
					}
					.padding(.vertical, Spacing.md)
				}
			} else {
				VStack(spacing: Spacing.md) {
					ForEach(vm.recentActivities.prefix(3), id: \.id) { activity in
						recentActivityItem(activity)
					}

					if vm.recentActivities.count > 3 {
						NavigationLink(destination: LogListView(defaultTab: .driveRoute).environmentObject(AppDI.shared)) {
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
	
	// MARK: - Auto Carousel Methods
    private func startAutoCarousel() {
        // 每5秒自动切换到下一张卡片
        carouselTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation {
                    selectedKnowledgeIndex = (selectedKnowledgeIndex + 1) % vm.todayKnowledgeCards.count
                }
            }
        }
    }
    
    private func stopAutoCarousel() {
        carouselTimer?.invalidate()
        carouselTimer = nil
    }
    
    private func resetAutoCarousel() {
        // 重置定时器：先停止再重新启动
        stopAutoCarousel()
        startAutoCarousel()
    }
    
    /// 检查通知权限状态并在未授予权限时显示弹框
    private func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationPermissionGranted = settings.alertSetting == .enabled
            
            // 如果通知权限未授予，显示权限请求弹框
            if notificationPermissionGranted != true {
                showingNotificationPermissionAlert = true
            }
        }
    }
    
    /// 请求通知权限
    private func requestNotificationPermission() {
        Task {
            let granted = await NotificationService.shared.requestPermission()
            await MainActor.run {
                notificationPermissionGranted = granted
                showingNotificationPermissionAlert = false
                
                // 如果权限被授予，设置每日提醒
                if granted {
                    Task {
                        await NotificationService.shared.scheduleDailyKnowledgeReminder()
                    }
                }
            }
        }
    }
    
    /// 清除通知红点
    private func clearNotificationBadges() async {
        await NotificationService.shared.clearBadges()
    }


    /// 处理系统通知点击事件
    private func handleNotificationTap() {
        notificationDetailTitle = "今日安全驾驶提醒"
        notificationDetailContent = "祝您今天开车安全第一！您可以在首页查看今日的安全驾驶知识，学习新的驾驶技巧。记住：道路千万条，安全第一条！"
        showingNotificationDetail = true
    }

    // MARK: - Pull to Refresh
    private func refreshHomeData() async {
        // 重新加载主页数据
        vm.reload()

        // 重新加载路线数据
        await vm.loadRecentRoutes()

        // 更新当前位置
        await updateCurrentLocation()

        // 检查通知权限状态
        await checkNotificationPermission()

        // 添加轻微延迟以提供更好的用户体验
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
    }
}

// MARK: - Knowledge Card Data
struct KnowledgeCardData: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let isLearned: Bool
}

// 修改为使用KnowledgeCard模型
extension KnowledgeCardData {
    init(from knowledgeCard: KnowledgeCard) {
        self.init(
            title: knowledgeCard.title,
            content: knowledgeCard.what,
            isLearned: false
        )
    }
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
    @Published private(set) var todayKnowledgeCompleted: Bool = false
    @Published private(set) var todayLearnedCount: Int = 0  // 今天已学习的卡片数量
        
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
    
    func loadTodayKnowledgeCards() {
        // 从知识库获取今日学习卡片数据
        let knowledgeRepo = AppDI.shared.knowledgeRepository
        if let knowledgeCards = try? knowledgeRepo.todayCards(limit: 3) {
            // 获取今日的学习进度
            let ctx = try? GlobalModelContext.context
            let progresses = (try? ctx?.fetch(FetchDescriptor<KnowledgeProgress>())) ?? []
            
            // 获取今天的日期（用于检查是否已学习）
            let today = Calendar.current.startOfDay(for: Date())
            
            // 计算今天已标记学习的卡片数量
            let todayLearnedCount = progresses.reduce(0) { count, progress in
                let hasLearnedToday = progress.markedDates.contains { date in
                    Calendar.current.isDate(date, inSameDayAs: today)
                }
                return count + (hasLearnedToday ? 1 : 0)
            }

            // 保存今天已学习的卡片数量
            self.todayLearnedCount = todayLearnedCount

            // 如果今天已经标记学习了3个或以上卡片，则认为今日知识学习已完成
            self.todayKnowledgeCompleted = todayLearnedCount >= 3

            self.todayKnowledgeCards = knowledgeCards.map { card in
                // 检查该卡片今天是否已学习
                let isLearned = progresses.contains { progress in
                    progress.cardId == card.id &&
                    progress.markedDates.contains { date in
                        Calendar.current.isDate(date, inSameDayAs: today)
                    }
                }

                return KnowledgeCardData(
                    title: card.title,
                    content: card.what,
                    isLearned: isLearned
                )
            }
        } else {
            // 如果获取失败，使用模拟数据
            self.todayKnowledgeCompleted = false
            todayKnowledgeCards = [
                KnowledgeCardData(
                    title: "安全跟车距离",
                    content: "保持3秒车距原则，在高速公路上应保持更长的跟车距离，确保有足够的反应时间。",
                    isLearned: false
                ),
                KnowledgeCardData(
                    title: "雨天驾驶技巧",
                    content: "雨天路面湿滑，要降低车速，保持更大的跟车距离，避免急刹车和急转弯。",
                    isLearned: false
                ),
                KnowledgeCardData(
                    title: "停车技巧",
                    content: "倒车入库时要多观察后视镜，利用参照物判断车位，耐心慢速操作。",
                    isLearned: false
                )
            ]
        }
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
		let completed = min(1, todayPreCount) + min(1, todayPostCount) + (todayKnowledgeCompleted ? 1 : 0)
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