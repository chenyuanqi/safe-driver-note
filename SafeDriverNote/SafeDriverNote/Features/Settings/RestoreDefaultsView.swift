import SwiftUI

struct RestoreDefaultsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var di: AppDI
    @State private var showingRestoreAlert = false
    @State private var restoreType: RestoreType?
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""

    enum RestoreType {
        case preChecklist
        case postChecklist
        case drivingRules

        var title: String {
            switch self {
            case .preChecklist: return "行前检查清单"
            case .postChecklist: return "行后检查清单"
            case .drivingRules: return "开车守则"
            }
        }

        var confirmMessage: String {
            switch self {
            case .preChecklist: return "这将删除所有自定义的行前检查项，并恢复为系统默认的7项检查。此操作无法撤销，确定要继续吗？"
            case .postChecklist: return "这将删除所有自定义的行后检查项，并恢复为系统默认的6项检查。此操作无法撤销，确定要继续吗？"
            case .drivingRules: return "这将删除所有自定义的开车守则，并恢复为系统默认的24条守则。此操作无法撤销，确定要继续吗？"
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xxxl) {
                    // 说明文字
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.brandDanger500)

                        Text("恢复默认数据")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.brandSecondary900)

                        Text("选择要恢复的数据类型，恢复后将删除所有自定义内容并还原为系统默认")
                            .font(.bodyMedium)
                            .foregroundColor(.brandSecondary600)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.xl)
                    }
                    .padding(.top, Spacing.xxxl)

                    // 恢复选项
                    VStack(spacing: Spacing.lg) {
                        restoreOptionCard(
                            icon: "car.fill",
                            title: "行前检查清单",
                            description: "恢复系统默认的7项行前检查",
                            color: .brandInfo500,
                            type: .preChecklist
                        )

                        restoreOptionCard(
                            icon: "parkingsign.circle.fill",
                            title: "行后检查清单",
                            description: "恢复系统默认的6项行后检查",
                            color: .brandSuccess500,
                            type: .postChecklist
                        )

                        restoreOptionCard(
                            icon: "book.fill",
                            title: "开车守则",
                            description: "恢复系统默认的24条开车守则",
                            color: .brandWarning500,
                            type: .drivingRules
                        )
                    }
                    .padding(.horizontal, Spacing.xl)
                }
                .padding(.vertical, Spacing.lg)
            }
            .background(Color.brandSecondary50)
            .navigationTitle("恢复默认数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .alert(restoreType?.title ?? "确认恢复", isPresented: $showingRestoreAlert) {
            Button("取消", role: .cancel) { }
            Button("恢复", role: .destructive) {
                performRestore()
            }
        } message: {
            Text(restoreType?.confirmMessage ?? "")
        }
        .alert("恢复成功", isPresented: $showingSuccessAlert) {
            Button("确定") { }
        } message: {
            Text(successMessage)
        }
    }

    private func restoreOptionCard(
        icon: String,
        title: String,
        description: String,
        color: Color,
        type: RestoreType
    ) -> some View {
        Button(action: {
            restoreType = type
            showingRestoreAlert = true
        }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandSecondary900)

                    Text(description)
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary600)
                }

                Spacer()

                Image(systemName: "arrow.counterclockwise")
                    .font(.body)
                    .foregroundColor(.brandSecondary400)
            }
            .padding(Spacing.lg)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func performRestore() {
        guard let type = restoreType else { return }

        Task {
            do {
                switch type {
                case .preChecklist:
                    try await restorePreChecklist()
                    successMessage = "已成功恢复行前检查清单为系统默认"
                case .postChecklist:
                    try await restorePostChecklist()
                    successMessage = "已成功恢复行后检查清单为系统默认"
                case .drivingRules:
                    try await restoreDrivingRules()
                    successMessage = "已成功恢复开车守则为系统默认"
                }

                await MainActor.run {
                    showingSuccessAlert = true
                    // 发送通知，让清单页面刷新数据
                    NotificationCenter.default.post(name: .checklistDataRestored, object: nil)
                }
            } catch {
                print("恢复失败: \(error)")
            }
        }
    }

    // MARK: - Restore Methods

    private func restorePreChecklist() async throws {
        let repository = di.checklistRepository

        // 删除所有行前检查项
        let existingItems = try repository.fetchItems(mode: .pre)
        for item in existingItems {
            try repository.deleteItem(item)
        }

        // 添加默认行前检查项
        let defaultTitles = [
            "检查周围环境是否安全（车底，周边行人、小孩等）",
            "检查车子是否正常（胎压、仪表盘显示）",
            "调整好方向盘、座椅，以及内后视镜和外后视镜",
            "如果下雨天，提前做准备（雨刷检查、空调对两边吹、后视镜加热，去油膜处理）",
            "如果在停车场，提前缴费再开车出去",
            "规划好行车路线",
            "阅读「开车守则」，遵守交通规则，安全抵达目的地！"
        ]

        for (index, title) in defaultTitles.enumerated() {
            let item = ChecklistItem(
                title: title,
                mode: .pre,
                sortOrder: index,
                isCustom: false
            )
            try repository.addItem(item)
        }
    }

    private func restorePostChecklist() async throws {
        let repository = di.checklistRepository

        // 删除所有行后检查项
        let existingItems = try repository.fetchItems(mode: .post)
        for item in existingItems {
            try repository.deleteItem(item)
        }

        // 添加默认行后检查项
        let defaultTitles = [
            "检查车子的位置是否有问题",
            "关窗、锁门、熄火、防盗，确认停车🅿正常",
            "打开车子厂商的 app 再次确认车子情况",
            "如果陌生停车场，停车拍照 + 设置定位 + 手动记位置",
            "将本次\"失误–反思–改进\"条目补录到行车日记中",
            "记账 - 充电、加油、停车等费用"
        ]

        for (index, title) in defaultTitles.enumerated() {
            let item = ChecklistItem(
                title: title,
                mode: .post,
                sortOrder: index,
                isCustom: false
            )
            try repository.addItem(item)
        }
    }

    private func restoreDrivingRules() async throws {
        let repository = di.drivingRuleRepository

        // 删除所有开车守则
        let existingRules = try repository.fetchAll()
        for rule in existingRules {
            try repository.delete(rule)
        }

        // 添加默认开车守则
        let defaultRules = [
            "慢出稳，练出精，思出透！敬畏生命，安全驾驶！",
            "开车前绕车一周，检查自己车况（车牌、车身和周围有没有问题？）+自身精神情况（穿着舒适，视野清晰）",
            "保持车距，专注前方，快速扫描周围环境(2s)",
            "三逢（盲区+道路+自身）四要（减速+备刹+眼神+精神），逢变化必减速注意",
            "不加速，脚一定放在刹车上",
            "眼不到手不动！",
            "让速不让道！",
            "转弯，左右摆头查看盲区是否有交通参与者",
            "变道（前方和目标车道车速判断+后视镜确认后打灯3s+再看后视镜&内后视镜&b柱盲区确认安全+快速完成）",
            "会车防车尾（防剐蹭+其他交通参与者窜出），超车防车头（防追尾+预判前车的移动方向）",
            "错过的路口就让它错过，不要紧急打方向盘变道",
            "急刹，前方有状况，开启双闪提醒后方",
            "远离大车（尤其是左右两侧和前方盲区）",
            "假设别人会犯错，提前给自己预留处理空间",
            "看不清的前方，鸣笛告知和回应对方",
            "入弯道，控制速度避免车子被甩",
            "限速路段，不跑快车",
            "左转之后尽量先保持在原车道，确认没问题再换到其他车道",
            "高速行驶不要猛打方向盘(慢打)，不要急刹车(点刹)",
            "永远给自己留一条后路，防止急刹后被追尾",
            "下车前，提醒乘客查看前后是否有交通参与者",
            "打转向灯、鸣笛，是为了告知其他交通参与者",
            "特殊环境提前做好准备，比如雨天提前清理油膜",
            "打哈欠、眼皮沉重、走神+情绪不好，必须靠边休息恢复"
        ]

        for (index, content) in defaultRules.enumerated() {
            let rule = DrivingRule(
                content: content,
                sortOrder: index,
                isCustom: false
            )
            try repository.add(rule)
        }
    }
}

#Preview {
    RestoreDefaultsView()
        .environmentObject(AppDI.shared)
}
