import SwiftUI
import CoreLocation

struct EnhancedChecklistView: View {
    @StateObject private var vm = ChecklistViewModel(repository: AppDI.shared.checklistRepository)
    @State private var showingQuickCheck = false
    @State private var showingHistory = false
    @State private var showingTips = false
    @State private var weatherCondition: WeatherCondition = .clear
    @State private var timeOfDay: TimeOfDay = .morning
    @State private var selectedCategory: CheckCategory = .all

    enum WeatherCondition: String, CaseIterable {
        case clear = "晴天"
        case rain = "雨天"
        case fog = "雾天"
        case night = "夜间"

        var icon: String {
            switch self {
            case .clear: return "sun.max"
            case .rain: return "cloud.rain"
            case .fog: return "cloud.fog"
            case .night: return "moon.stars"
            }
        }

        var importantChecks: [String] {
            switch self {
            case .rain: return ["雨刮器", "车灯", "轮胎花纹", "刹车"]
            case .fog: return ["雾灯", "前后车灯", "喇叭", "除雾"]
            case .night: return ["所有车灯", "反光镜", "仪表盘照明"]
            case .clear: return ["轮胎气压", "机油", "冷却液"]
            }
        }
    }

    enum TimeOfDay {
        case morning, afternoon, evening, night

        var greeting: String {
            switch self {
            case .morning: return "早安，开始新的一天"
            case .afternoon: return "下午好，注意休息"
            case .evening: return "傍晚时分，谨慎驾驶"
            case .night: return "夜深了，安全第一"
            }
        }
    }

    enum CheckCategory: String, CaseIterable {
        case all = "全部"
        case essential = "必查项"
        case safety = "安全项"
        case maintenance = "保养项"
        case weather = "天气相关"

        var icon: String {
            switch self {
            case .all: return "checklist"
            case .essential: return "exclamationmark.triangle"
            case .safety: return "shield.checkered"
            case .maintenance: return "wrench.and.screwdriver"
            case .weather: return "cloud.sun"
            }
        }

        var color: Color {
            switch self {
            case .all: return .brandSecondary600
            case .essential: return .brandDanger500
            case .safety: return .brandPrimary500
            case .maintenance: return .brandWarning500
            case .weather: return .brandInfo500
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 导航栏
            StandardNavigationBar(
                title: "检查清单",
                showBackButton: false,
                trailingButtons: [
                    StandardNavigationBar.NavBarButton(icon: "clock.arrow.circlepath") {
                        showingHistory = true
                    },
                    StandardNavigationBar.NavBarButton(icon: "lightbulb") {
                        showingTips = true
                    }
                ]
            )

            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // 智能提醒卡片
                    smartReminderCard

                    // 快速检查入口
                    quickCheckSection

                    // 分类筛选
                    categoryFilterSection

                    // 检查清单分组
                    checklistGroupSection

                    // 打卡统计
                    statisticsSection
                }
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.vertical, Spacing.lg)
            }
            .background(Color.brandSecondary50)
        }
        .onAppear {
            updateTimeAndWeather()
        }
        .sheet(isPresented: $showingHistory) {
            ChecklistHistoryView()
                .environmentObject(AppDI.shared)
        }
        .sheet(isPresented: $showingTips) {
            DrivingTipsView(weather: weatherCondition)
        }
        .sheet(isPresented: $showingQuickCheck) {
            QuickCheckView(
                mode: vm.mode,
                weatherCondition: weatherCondition,
                onComplete: { checkedItems in
                    // 处理快速检查结果
                    handleQuickCheckComplete(checkedItems)
                }
            )
        }
    }

    // MARK: - 智能提醒卡片
    private var smartReminderCard: some View {
        Card(backgroundColor: Color.brandPrimary100, shadow: true) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: weatherCondition.icon)
                        .font(.title2)
                        .foregroundColor(.brandPrimary600)

                    VStack(alignment: .leading) {
                        Text(timeOfDay.greeting)
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)

                        Text("今日\(weatherCondition.rawValue)，建议重点检查")
                            .font(.body)
                            .foregroundColor(.brandSecondary600)
                    }

                    Spacer()
                }

                // 重点检查项
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(weatherCondition.importantChecks, id: \.self) { item in
                            Text(item)
                                .font(.caption)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.white)
                                .foregroundColor(.brandPrimary600)
                                .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 快速检查入口
    private var quickCheckSection: some View {
        HStack(spacing: Spacing.md) {
            // 一键快速检查
            Button(action: {
                showingQuickCheck = true
            }) {
                Card(backgroundColor: Color.brandPrimary500, shadow: true) {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "bolt.fill")
                            .font(.title)
                            .foregroundColor(.white)

                        Text("快速检查")
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text("30秒完成")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // 标准检查
            NavigationLink(destination: ChecklistView()) {
                Card(backgroundColor: Color.cardBackground, shadow: true) {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.title)
                            .foregroundColor(.brandSecondary700)

                        Text("标准检查")
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)

                        Text("详细记录")
                            .font(.caption)
                            .foregroundColor(.brandSecondary500)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - 分类筛选
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(CheckCategory.allCases, id: \.self) { category in
                    Button(action: {
                        withAnimation {
                            selectedCategory = category
                        }
                    }) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: category.icon)
                                .font(.caption)
                            Text(category.rawValue)
                                .font(.body)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .foregroundColor(selectedCategory == category ? .white : category.color)
                        .background(
                            selectedCategory == category ? category.color : category.color.opacity(0.1)
                        )
                        .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - 检查清单分组
    private var checklistGroupSection: some View {
        VStack(spacing: Spacing.lg) {
            // 行前检查组
            checklistGroup(
                title: "行前检查",
                icon: "car",
                items: filteredItems(for: .pre),
                completedCount: completedCount(for: .pre),
                color: .brandInfo500
            )

            // 行后检查组
            checklistGroup(
                title: "行后检查",
                icon: "parkingsign",
                items: filteredItems(for: .post),
                completedCount: completedCount(for: .post),
                color: .brandWarning500
            )
        }
    }

    private func checklistGroup(
        title: String,
        icon: String,
        items: [ChecklistItem],
        completedCount: Int,
        color: Color
    ) -> some View {
        Card(shadow: false) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // 头部
                HStack {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: icon)
                            .font(.body)
                            .foregroundColor(color)

                        Text(title)
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)
                    }

                    Spacer()

                    // 进度环
                    CircularProgressView(
                        progress: Double(completedCount) / Double(max(items.count, 1)),
                        color: color,
                        lineWidth: 3,
                        size: 30
                    )
                    .overlay(
                        Text("\(completedCount)/\(items.count)")
                            .font(.caption2)
                            .foregroundColor(.brandSecondary600)
                    )
                }

                // 展开的检查项列表（可折叠）
                if !items.isEmpty {
                    VStack(spacing: Spacing.sm) {
                        ForEach(items.prefix(3), id: \.id) { item in
                            checklistItemRow(item)
                        }

                        if items.count > 3 {
                            Button(action: {
                                // 展开更多
                            }) {
                                Text("查看全部 \(items.count) 项")
                                    .font(.body)
                                    .foregroundColor(color)
                            }
                        }
                    }
                }
            }
        }
    }

    private func checklistItemRow(_ item: ChecklistItem) -> some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .font(.body)
                .foregroundColor(.brandSecondary400)

            Text(item.title)
                .font(.body)
                .foregroundColor(.brandSecondary700)

            Spacer()

            if item.isPinned ?? false {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundColor(.brandWarning500)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    // MARK: - 统计区域
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("本周打卡统计")
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)

            HStack(spacing: Spacing.md) {
                StatCard(
                    title: "连续打卡",
                    value: "7天",
                    icon: "flame.fill",
                    color: .brandDanger500
                )

                StatCard(
                    title: "完成率",
                    value: "95%",
                    icon: "percent",
                    color: .brandPrimary500
                )

                StatCard(
                    title: "最常忘记",
                    value: "转向灯",
                    icon: "exclamationmark.triangle",
                    color: .brandWarning500
                )
            }
        }
    }

    // MARK: - Helper Views
    struct CircularProgressView: View {
        let progress: Double
        let color: Color
        let lineWidth: CGFloat
        let size: CGFloat

        var body: some View {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, lineWidth: lineWidth)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: progress)
            }
            .frame(width: size, height: size)
        }
    }

    struct StatCard: View {
        let title: String
        let value: String
        let icon: String
        let color: Color

        var body: some View {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)

                    Text(title)
                        .font(.caption)
                        .foregroundColor(.brandSecondary500)
                }

                Text(value)
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(color.opacity(0.1))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Helper Methods
    private func updateTimeAndWeather() {
        // 更新时间
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            timeOfDay = .morning
        case 12..<17:
            timeOfDay = .afternoon
        case 17..<20:
            timeOfDay = .evening
        default:
            timeOfDay = .night
        }

        // 这里可以接入天气API
        // 暂时使用模拟数据
        weatherCondition = .clear
    }

    private func filteredItems(for mode: ChecklistViewModel.Mode) -> [ChecklistItem] {
        let items = mode == .pre ? vm.itemsPre : vm.itemsPost

        switch selectedCategory {
        case .all:
            return items
        case .essential:
            return items.filter { $0.isPinned ?? false }
        case .safety:
            // 根据标题关键词过滤
            return items.filter { item in
                ["刹车", "灯", "安全带", "后视镜"].contains { item.title.contains($0) }
            }
        case .maintenance:
            return items.filter { item in
                ["机油", "水", "轮胎", "电瓶"].contains { item.title.contains($0) }
            }
        case .weather:
            return items.filter { item in
                weatherCondition.importantChecks.contains { item.title.contains($0) }
            }
        }
    }

    private func completedCount(for mode: ChecklistViewModel.Mode) -> Int {
        // 获取今日已完成的项数
        let punches = mode == .pre ? vm.punchesTodayPre : vm.punchesTodayPost
        return punches.first?.checkedItemIds.count ?? 0
    }

    private func handleQuickCheckComplete(_ checkedItems: Set<UUID>) {
        // 处理快速检查完成
        print("快速检查完成，选中了 \(checkedItems.count) 项")
    }
}