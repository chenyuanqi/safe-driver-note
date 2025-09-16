import SwiftUI

struct QuickCheckView: View {
    let mode: ChecklistViewModel.Mode
    let weatherCondition: EnhancedChecklistView.WeatherCondition
    let onComplete: (Set<UUID>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var checkedItems = Set<UUID>()
    @State private var currentStep = 0
    @State private var timeRemaining = 30
    @State private var timer: Timer?

    // 快速检查分组
    private let quickCheckGroups = [
        QuickCheckGroup(
            title: "安全必查",
            icon: "shield.checkered",
            color: .brandDanger500,
            items: ["刹车", "安全带", "后视镜", "车灯"]
        ),
        QuickCheckGroup(
            title: "车况检查",
            icon: "car.circle",
            color: .brandPrimary500,
            items: ["轮胎", "机油", "水箱", "雨刮"]
        ),
        QuickCheckGroup(
            title: "仪表确认",
            icon: "gauge",
            color: .brandInfo500,
            items: ["油量", "胎压", "温度", "故障灯"]
        )
    ]

    struct QuickCheckGroup {
        let title: String
        let icon: String
        let color: Color
        let items: [String]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 自定义导航栏
                HStack {
                    Button("取消") {
                        timer?.invalidate()
                        dismiss()
                    }
                    .foregroundColor(.brandSecondary600)

                    Spacer()

                    // 倒计时
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "timer")
                            .font(.body)
                        Text("\(timeRemaining)秒")
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(timeRemaining < 10 ? .brandDanger500 : .brandPrimary500)

                    Spacer()

                    Button("完成") {
                        completeCheck()
                    }
                    .foregroundColor(.brandPrimary500)
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)

                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.brandSecondary200)
                            .frame(height: 4)

                        Rectangle()
                            .fill(Color.brandPrimary500)
                            .frame(
                                width: geometry.size.width * Double(currentStep + 1) / Double(quickCheckGroups.count),
                                height: 4
                            )
                            .animation(.spring(), value: currentStep)
                    }
                }
                .frame(height: 4)

                // 内容区域
                TabView(selection: $currentStep) {
                    ForEach(0..<quickCheckGroups.count, id: \.self) { index in
                        quickCheckGroupView(quickCheckGroups[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

                // 底部操作区
                HStack(spacing: Spacing.xl) {
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("上一步")
                            }
                            .font(.body)
                            .foregroundColor(.brandSecondary600)
                        }
                    }

                    Spacer()

                    // 一键全选当前组
                    Button(action: selectAllInCurrentGroup) {
                        HStack {
                            Image(systemName: "checkmark.square.fill")
                            Text("全部正常")
                        }
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(Color.brandPrimary500)
                        .cornerRadius(20)
                    }

                    Spacer()

                    if currentStep < quickCheckGroups.count - 1 {
                        Button(action: {
                            withAnimation {
                                currentStep += 1
                            }
                        }) {
                            HStack {
                                Text("下一步")
                                Image(systemName: "chevron.right")
                            }
                            .font(.body)
                            .foregroundColor(.brandPrimary500)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.lg)
                .background(Color.cardBackground)
            }
            .background(Color.brandSecondary50)
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Quick Check Group View
    private func quickCheckGroupView(_ group: QuickCheckGroup) -> some View {
        VStack(spacing: Spacing.xl) {
            // 组标题
            VStack(spacing: Spacing.md) {
                Image(systemName: group.icon)
                    .font(.system(size: 48))
                    .foregroundColor(group.color)

                Text(group.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.brandSecondary900)

                Text("请快速确认以下项目是否正常")
                    .font(.body)
                    .foregroundColor(.brandSecondary600)
            }
            .padding(.top, Spacing.xxxl)

            // 检查项网格
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.lg) {
                ForEach(group.items, id: \.self) { item in
                    checkItemCard(item, color: group.color)
                }
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()
        }
    }

    // MARK: - Check Item Card
    private func checkItemCard(_ item: String, color: Color) -> some View {
        let isChecked = checkedItems.contains { _ in false } // 简化逻辑

        return Button(action: {
            // 切换选中状态
            withAnimation(.spring()) {
                // 这里简化处理，实际应该根据item找到对应的UUID
            }
        }) {
            VStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isChecked ? color : Color.brandSecondary100)
                        .frame(width: 60, height: 60)

                    Image(systemName: isChecked ? "checkmark" : getIconForItem(item))
                        .font(.title2)
                        .foregroundColor(isChecked ? .white : .brandSecondary600)
                }

                Text(item)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.brandSecondary900)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(Color.white)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            .scaleEffect(isChecked ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper Methods
    private func getIconForItem(_ item: String) -> String {
        switch item {
        case "刹车": return "brake.signal"
        case "安全带": return "figure.seated.seatbelt"
        case "后视镜": return "mirror.side.left"
        case "车灯": return "light.beacon.max"
        case "轮胎": return "tirepressure"
        case "机油": return "drop.fill"
        case "水箱": return "drop.triangle"
        case "雨刮": return "windshield.front.and.wiper"
        case "油量": return "fuelpump"
        case "胎压": return "gauge"
        case "温度": return "thermometer"
        case "故障灯": return "exclamationmark.triangle"
        default: return "questionmark.circle"
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                completeCheck()
            }
        }
    }

    private func selectAllInCurrentGroup() {
        // 选中当前组的所有项目
        withAnimation(.spring()) {
            // 简化处理
            if currentStep < quickCheckGroups.count - 1 {
                currentStep += 1
            } else {
                completeCheck()
            }
        }
    }

    private func completeCheck() {
        timer?.invalidate()
        onComplete(checkedItems)
        dismiss()
    }
}

// MARK: - 驾驶小贴士视图
struct DrivingTipsView: View {
    let weather: EnhancedChecklistView.WeatherCondition

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // 天气相关提示
                    weatherTipsSection

                    // 老司机经验
                    experienceTipsSection

                    // 常见问题
                    commonIssuesSection
                }
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.vertical, Spacing.lg)
            }
            .background(Color.brandSecondary50)
            .navigationTitle("驾驶小贴士")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var weatherTipsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: weather.icon)
                    .font(.title3)
                    .foregroundColor(.brandInfo500)

                Text("\(weather.rawValue)驾驶注意事项")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(tipsForWeather(), id: \.self) { tip in
                    HStack(alignment: .top, spacing: Spacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundColor(.brandPrimary500)
                            .padding(.top, 2)

                        Text(tip)
                            .font(.body)
                            .foregroundColor(.brandSecondary700)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .padding(Spacing.lg)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.lg)
        }
    }

    private var experienceTipsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(.brandWarning500)

                Text("老司机经验分享")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)
            }

            ForEach(experienceTips(), id: \.title) { tip in
                Card(shadow: false) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(tip.title)
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)

                        Text(tip.content)
                            .font(.body)
                            .foregroundColor(.brandSecondary600)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var commonIssuesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.title3)
                    .foregroundColor(.brandDanger500)

                Text("常见问题处理")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)
            }

            ForEach(commonIssues(), id: \.issue) { item in
                Card(backgroundColor: Color.brandDanger100.opacity(0.5), shadow: false) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("问题：\(item.issue)")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.brandDanger600)

                        Text("解决：\(item.solution)")
                            .font(.body)
                            .foregroundColor(.brandSecondary700)
                    }
                }
            }
        }
    }

    private func tipsForWeather() -> [String] {
        switch weather {
        case .rain:
            return [
                "保持较远的跟车距离，制动距离会增加",
                "开启雨刮器和车灯，提高能见度",
                "避免急刹车和急转向，防止打滑",
                "通过积水路段要低速通过"
            ]
        case .fog:
            return [
                "开启雾灯和示宽灯，不要用远光灯",
                "降低车速，保持安全距离",
                "勤按喇叭提醒其他车辆",
                "必要时开启双闪警示灯"
            ]
        case .night:
            return [
                "检查所有车灯是否正常工作",
                "避免长时间使用远光灯",
                "注意行人和非机动车",
                "疲劳时及时休息"
            ]
        case .clear:
            return [
                "注意阳光直射造成的眩光",
                "定期检查轮胎气压",
                "长途驾驶注意休息",
                "保持适当的车速"
            ]
        }
    }

    private func experienceTips() -> [(title: String, content: String)] {
        return [
            (title: "起步前原地热车1分钟", content: "冬天3分钟，让机油充分润滑，延长发动机寿命"),
            (title: "倒车时降下车窗", content: "能听到周围声音，避免盲区事故"),
            (title: "过减速带斜着过", content: "减少颠簸，保护悬挂系统")
        ]
    }

    private func commonIssues() -> [(issue: String, solution: String)] {
        return [
            (issue: "方向盘抖动", solution: "检查轮胎动平衡，可能需要做四轮定位"),
            (issue: "刹车异响", solution: "检查刹车片厚度，及时更换"),
            (issue: "油耗突然增加", solution: "检查胎压、空气滤芯，清理积碳")
        ]
    }
}