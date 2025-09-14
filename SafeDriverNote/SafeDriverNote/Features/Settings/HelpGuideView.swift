import SwiftUI
import Foundation

struct HelpGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: GuideSection = .quickStart

    enum GuideSection: String, CaseIterable {
        case quickStart = "快速开始"
        case drivingLog = "驾驶日志"
        case checklist = "检查清单"
        case knowledge = "安全知识"
        case settings = "设置管理"
        case tips = "使用技巧"

        var icon: String {
            switch self {
            case .quickStart: return "play.circle"
            case .drivingLog: return "list.bullet"
            case .checklist: return "checklist"
            case .knowledge: return "book"
            case .settings: return "gear"
            case .tips: return "lightbulb"
            }
        }
    }

    var body: some View {
        NavigationView {
            HStack(spacing: 0) {
                // 左侧导航
                sidebarNavigation

                Divider()

                // 右侧内容
                contentView
            }
            .navigationTitle("使用指南")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - 侧边栏导航
    private var sidebarNavigation: some View {
        VStack(spacing: Spacing.xs) {
            // 添加顶部间距
            Spacer()
                .frame(height: Spacing.md)

            ForEach(GuideSection.allCases, id: \.self) { section in
                Button(action: {
                    selectedSection = section
                }) {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: section.icon)
                            .font(.title3)
                            .foregroundColor(selectedSection == section ? .brandPrimary500 : .brandSecondary500)

                        Text(section.rawValue)
                            .font(.caption)
                            .fontWeight(selectedSection == section ? .semibold : .medium)
                            .foregroundColor(selectedSection == section ? .brandPrimary500 : .brandSecondary700)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.md)
                    .background(
                        selectedSection == section ?
                        Color.brandPrimary50 : Color.clear
                    )
                    .cornerRadius(CornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()
        }
        .frame(width: 140)
        .background(Color.brandSecondary50)
        .padding(.horizontal, Spacing.sm)
    }

    // MARK: - 内容视图
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                switch selectedSection {
                case .quickStart:
                    quickStartContent
                case .drivingLog:
                    drivingLogContent
                case .checklist:
                    checklistContent
                case .knowledge:
                    knowledgeContent
                case .settings:
                    settingsContent
                case .tips:
                    tipsContent
                }
            }
            .padding(Spacing.lg)
        }
        .background(Color.cardBackground)
    }

    // MARK: - 各部分内容
    private var quickStartContent: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sectionHeader("快速开始", "开始使用安全驾驶助手")

            guideStep(
                number: "1",
                title: "完成首次设置",
                content: "允许位置权限和通知权限，这样可以记录您的驾驶路线并接收安全提醒。"
            )

            guideStep(
                number: "2",
                title: "开始您的第一次驾驶",
                content: "点击首页的\"开始驾驶\"按钮，系统会自动记录您的路线和时间。"
            )

            guideStep(
                number: "3",
                title: "完成检查清单",
                content: "驾驶前后使用检查清单功能，养成良好的安全驾驶习惯。"
            )

            guideStep(
                number: "4",
                title: "学习安全知识",
                content: "每天阅读安全驾驶知识，提升您的驾驶技能和安全意识。"
            )
        }
    }

    private var drivingLogContent: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sectionHeader("驾驶日志", "记录和管理您的驾驶经历")

            guideItem(
                title: "添加驾驶记录",
                content: "点击"+"按钮或使用语音功能快速添加驾驶日志，记录路况、心得或需要改进的地方。"
            )

            guideItem(
                title: "分类管理",
                content: "日志分为\"成功经验\"和\"失误记录\"两类，帮助您更好地总结和改进驾驶技巧。"
            )

            guideItem(
                title: "添加照片",
                content: "为日志添加相关照片，如路况、停车位置等，让记录更加生动具体。"
            )

            guideItem(
                title: "查看统计",
                content: "在首页查看您的安全评分、连续天数等统计信息，追踪进步情况。"
            )
        }
    }

    private var checklistContent: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sectionHeader("检查清单", "培养系统化的安全检查习惯")

            guideItem(
                title: "行前检查",
                content: "每次驾驶前使用行前检查清单，检查车辆状态、调整座椅镜子等基本安全事项。"
            )

            guideItem(
                title: "行后检查",
                content: "驾驶结束后进行行后检查，总结本次驾驶情况，记录需要改进的地方。"
            )

            guideItem(
                title: "自定义清单",
                content: "根据个人需要添加或修改检查项目，让清单更适合您的驾驶习惯。"
            )

            guideItem(
                title: "打卡记录",
                content: "完成检查后系统自动记录，连续完成可获得成就奖励。"
            )
        }
    }

    private var knowledgeContent: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sectionHeader("安全知识", "每天学习，提升安全驾驶意识")

            guideItem(
                title: "每日推荐",
                content: "首页每天推荐3张安全知识卡片，涵盖交通规则、驾驶技巧、紧急处理等内容。"
            )

            guideItem(
                title: "知识卡片",
                content: "每张卡片包含知识点的\"是什么\"、\"为什么\"、\"怎么做\"三个方面的详细说明。"
            )

            guideItem(
                title: "学习记录",
                content: "点击\"已学习\"标记您已掌握的知识点，系统会记录您的学习进度。"
            )

            guideItem(
                title: "知识搜索",
                content: "在知识页面搜索特定内容，快速找到您需要的安全驾驶知识。"
            )
        }
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sectionHeader("设置管理", "个性化您的应用体验")

            guideItem(
                title: "通知设置",
                content: "设置每日安全提醒的时间，选择是否接收知识推送等通知。"
            )

            guideItem(
                title: "个人资料",
                content: "完善个人信息，包括驾龄、车型等，获得更个性化的安全建议。"
            )

            guideItem(
                title: "数据管理",
                content: "导出您的驾驶记录，开启iCloud同步，或清理应用缓存。"
            )

            guideItem(
                title: "隐私安全",
                content: "管理位置权限、通知权限等，保护您的个人隐私。"
            )
        }
    }

    private var tipsContent: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sectionHeader("使用技巧", "让您更高效地使用应用")

            guideItem(
                title: "快速记录",
                content: "使用语音功能快速添加驾驶日志，无需手动输入文字。"
            )

            guideItem(
                title: "下拉刷新",
                content: "在首页下拉可刷新数据，获取最新的统计信息和推荐内容。"
            )

            guideItem(
                title: "快捷操作",
                content: "长按驾驶日志可快速编辑或删除，提高操作效率。"
            )

            guideItem(
                title: "批量操作",
                content: "在日志列表页面可以批量选择和管理多条记录。"
            )

            tipBox(
                title: "💡 专业建议",
                content: "坚持每天使用应用记录和学习，21天可以形成良好的安全驾驶习惯！"
            )
        }
    }

    // MARK: - 辅助方法
    private func sectionHeader(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.brandSecondary900)

            Text(subtitle)
                .font(.bodyMedium)
                .foregroundColor(.brandSecondary600)
        }
    }

    private func guideStep(number: String, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Circle()
                .fill(Color.brandPrimary500)
                .frame(width: 24, height: 24)
                .overlay(
                    Text(number)
                        .font(.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)

                Text(content)
                    .font(.body)
                    .foregroundColor(.brandSecondary700)
                    .lineLimit(nil)
            }

            Spacer()
        }
    }

    private func guideItem(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)

            Text(content)
                .font(.body)
                .foregroundColor(.brandSecondary700)
                .lineLimit(nil)
        }
        .padding(.vertical, Spacing.sm)
    }

    private func tipBox(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(.brandPrimary600)

            Text(content)
                .font(.body)
                .foregroundColor(.brandPrimary700)
        }
        .padding(Spacing.md)
        .background(Color.brandPrimary50)
        .cornerRadius(CornerRadius.md)
    }
}

#Preview {
    HelpGuideView()
}