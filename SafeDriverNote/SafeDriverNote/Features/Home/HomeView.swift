import SwiftUI

struct HomeView: View {
	@StateObject private var vm = HomeViewModel()
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 16) {
					headerGreeting
					statsRow
					quickActions
					recentSection
					todayPunchSection
				}
				.padding()
			}
			.navigationTitle("")
			.toolbarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .principal) {
					Text("首页")
						.font(.system(size: 24, weight: .semibold))
						.foregroundStyle(Color.brandSecondary900)
				}
			}
			.onAppear { vm.reload() }
		}
	}
	
	private var headerGreeting: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(vm.greeting)
				.font(.title3)
				.foregroundStyle(.secondary)
			Text("安全驾驶，从记录开始！")
				.font(.headline)
				.foregroundStyle(Color.brandSecondary700)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.top, 2)
	}
	
	private var statsRow: some View {
		HStack(spacing: 12) {
			statCard(title: "本月日志", value: "\(vm.monthTotal)", color: .brandInfo500)
			statCard(title: "本月失误", value: "\(vm.monthMistakes)", color: .brandDanger500)
			statCard(title: "改进率", value: vm.improvementRateText, color: .brandPrimary500)
		}
	}
	
	private var quickActions: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("快速操作").font(.headline)
			HStack(spacing: 12) {
				NavigationLink(destination: LogListView()) {
					actionButton(title: "记失误", systemImage: "exclamationmark.triangle.fill", color: .brandDanger500)
				}
				NavigationLink(destination: LogListView()) {
					actionButton(title: "记成功", systemImage: "checkmark.seal.fill", color: .brandPrimary500)
				}
				NavigationLink(destination: ChecklistView()) {
					actionButton(title: "开始打卡", systemImage: "checklist", color: .brandInfo500)
				}
			}
		}
	}
	
	private var todayPunchSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("今日打卡").font(.headline)
			HStack(spacing: 12) {
				NavigationLink(destination: ChecklistView()) {
					statCard(title: "行前", value: "\(vm.todayPreCount)次", color: .brandInfo500)
				}
				NavigationLink(destination: ChecklistView()) {
					statCard(title: "行后", value: "\(vm.todayPostCount)次", color: .brandPrimary500)
				}
			}
		}
	}
	
	private var recentSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("最近记录").font(.headline)
			if vm.recentLogs.isEmpty {
				Text("暂无记录，去日志页添加一条吧～").font(.subheadline).foregroundStyle(.secondary)
			} else {
				ForEach(vm.recentLogs, id: \.id) { log in
					HStack {
						Text(vm.formatDate(log.createdAt)).font(.caption).foregroundStyle(.secondary)
						Text(log.type == .mistake ? "失误" : "成功").font(.caption2)
							.padding(.horizontal, 6).padding(.vertical, 2)
							.background(log.type == .mistake ? Color.brandDanger100 : Color.brandPrimary100)
							.foregroundColor(log.type == .mistake ? .brandDanger600 : .brandPrimary700)
							.clipShape(Capsule())
						Spacer()
						Text(vm.title(for: log))
					}
					.padding(12)
					.background(Color.brandSecondary100)
					.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
				}
			}
		}
	}
	
	@ViewBuilder
	private func statCard(title: String, value: String, color: Color) -> some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(title).font(.caption).foregroundStyle(.secondary)
			Text(value).font(.headline)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(12)
		.background(color.opacity(0.08))
		.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
	}
	
	private func actionButton(title: String, systemImage: String, color: Color) -> some View {
		HStack(spacing: 8) {
			Image(systemName: systemImage)
			Text(title)
		}
		.font(.subheadline)
		.padding(.horizontal, 12)
		.padding(.vertical, 10)
		.background(color.opacity(0.12))
		.foregroundColor(color)
		.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
	}
}

@MainActor
final class HomeViewModel: ObservableObject {
	@Published private(set) var allLogs: [LogEntry] = []
	@Published private(set) var recentLogs: [LogEntry] = []
	@Published private(set) var todayPreCount: Int = 0
	@Published private(set) var todayPostCount: Int = 0
		
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