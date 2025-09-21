import SwiftUI
import Foundation

struct HelpGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSection: GuideSection = .quickStart
    @State private var isSidebarCollapsed = false

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
                if isSidebarCollapsed {
                    collapsedSidebar
                } else {
                    sidebarNavigation
                }

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
        .background(Color.pageBackground.ignoresSafeArea())
    }

    // MARK: - 侧边栏导航
    private var sidebarNavigation: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(Animation.standard) {
                        isSidebarCollapsed = true
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.brandSecondary600)
                        .padding(Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                .fill(sidebarControlBackground)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("收起导航")
            }

            ForEach(GuideSection.allCases, id: \.self) { section in
                sidebarButton(for: section, showLabel: true)
            }

            Spacer(minLength: Spacing.xl)
        }
        .frame(width: 128)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xl)
        .background(sidebarBackground)
    }

    private var collapsedSidebar: some View {
        VStack(spacing: Spacing.lg) {
            Button(action: {
                withAnimation(Animation.standard) {
                    isSidebarCollapsed = false
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundColor(.brandSecondary600)
                    .padding(Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                            .fill(sidebarControlBackground)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("展开导航")

            ForEach(GuideSection.allCases, id: \.self) { section in
                sidebarButton(for: section, showLabel: false)
            }

            Spacer(minLength: Spacing.xxxl)
        }
        .frame(width: 64)
        .padding(.vertical, Spacing.xl)
        .background(sidebarBackground)
    }

    // MARK: - 内容视图
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
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
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxxl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.clear)
    }

    // MARK: - 各部分内容
    private var quickStartContent: some View {
        guideSectionContainer {
            sectionHeader("快速开始", "使用安全驾驶助手的核心流程")

            guideStep(
                number: "1",
                title: "完成首次设置",
                content: "允许位置、运动与通知权限，并在\"设置\"中选择同步方式，让行程记录与提醒功能即时生效。"
            )

            guideStep(
                number: "2",
                title: "开始第一趟驾驶",
                content: "在首页点击\"开始驾驶\"或使用捷径进入驾驶模式，系统会记录路线、时间与安全评分并生成日志草稿。"
            )

            guideStep(
                number: "3",
                title: "完成行前/行后检查",
                content: "打开快捷操作中的\"行前检查\"与\"语音记录\"，逐项确认车辆状态，语音转文字帮助您快速补充备注。"
            )

            guideStep(
                number: "4",
                title: "复盘并学习",
                content: "在驾驶结束后查看自动生成的驾驶日志，补充心得并学习推荐的安全知识，形成良性循环。"
            )
        }
    }

    private var drivingLogContent: some View {
        guideSectionContainer {
            sectionHeader("驾驶日志", "记录、标记并复盘每一次出行")

            guideItem(
                icon: "plus.square.on.square",
                title: "一键添加",
                content: "在驾驶日志页点击“+”或使用语音转写，快速保存天气、路况与心情等关键信息。"
            )

            guideItem(
                icon: "tag",
                title: "标签与分类",
                content: "使用\"成功经验\"与\"需要改进\"分类，并为日志添加自定义标签，后续检索更轻松。"
            )

            guideItem(
                icon: "photo.on.rectangle",
                title: "图文结合",
                content: "支持添加现场照片或附件，帮助还原当时路况、停车位置或异常情况。"
            )

            guideItem(
                icon: "calendar.badge.clock",
                title: "智能回顾",
                content: "通过时间轴与统计面板，查看安全评分、连续驾驶天数与风险事件，形成可视化复盘。"
            )
        }
    }

    private var checklistContent: some View {
        guideSectionContainer {
            sectionHeader("检查清单", "让安全步骤变成肌肉记忆")

            guideItem(
                icon: "checkmark.rectangle",
                title: "行前/行后流程",
                content: "按照默认的行前与行后清单逐项确认，包括车辆状态、情绪管理与驾驶总结。"
            )

            guideItem(
                icon: "slider.horizontal.3",
                title: "自定义项目",
                content: "通过管理面板增删项目、调整顺序或分组，更贴合您的车辆配置与日常路线。"
            )

            guideItem(
                icon: "sparkles",
                title: "成就激励",
                content: "完成清单会自动打卡并累计 streak，连续完成可解锁勋章与安全积分。"
            )

            guideItem(
                icon: "square.and.pencil",
                title: "复盘笔记",
                content: "在检查过程中即可补充备注或语音记录，帮助后续驾驶日志的整理。"
            )
        }
    }

    private var knowledgeContent: some View {
        guideSectionContainer {
            sectionHeader("安全知识", "输入新知识，输出好习惯")

            guideItem(
                icon: "square.grid.3x3.fill",
                title: "每日精选",
                content: "首页自动推送 3 条主题知识卡，覆盖法规、驾驶技巧和应急处理等核心内容。"
            )

            guideItem(
                icon: "doc.text.magnifyingglass",
                title: "结构化学习",
                content: "每张卡片拆解“是什么”“为什么”“怎么做”，辅以情景示例，方便快速吸收。"
            )

            guideItem(
                icon: "checkmark.seal",
                title: "学习进度",
                content: "点击“已掌握”即可记录学习状态，系统会根据掌握情况推荐新的知识点。"
            )

            guideItem(
                icon: "magnifyingglass",
                title: "关键词检索",
                content: "使用搜索功能快速定位想要复习的知识，支持按标签与场景筛选。"
            )
        }
    }

    private var settingsContent: some View {
        guideSectionContainer {
            sectionHeader("设置管理", "根据需求定制安全驾驶体验")

            guideItem(
                icon: "bell.badge",
                title: "通知与提醒",
                content: "在\"通知设置\"中安排每日安全提醒、知识推送与行程提醒的时间与频率。"
            )

            guideItem(
                icon: "paintbrush",
                title: "主题外观",
                content: "打开\"主题与外观\"选择浅色、深色或跟随系统，配合首页卡片样式获得最舒适的视觉体验。"
            )

            guideItem(
                icon: "person.crop.circle",
                title: "个人资料",
                content: "完善驾龄、车辆与驾驶习惯，系统会给出更贴合您的安全建议与统计对比。"
            )

            guideItem(
                icon: "icloud.and.arrow.up",
                title: "数据与同步",
                content: "在\"数据管理\"中导出驾驶数据、开启 iCloud 同步或清理缓存，确保数据安全又轻便。"
            )

            guideItem(
                icon: "lock.shield",
                title: "权限与隐私",
                content: "通过\"权限管理\"快速检查位置、运动与麦克风等授权情况，及时调整隐私策略。"
            )
        }
    }

    private var tipsContent: some View {
        guideSectionContainer {
            sectionHeader("使用技巧", "这些小窍门让效率再提升")

            guideItem(
                icon: "mic.circle",
                title: "语音速记",
                content: "开启语音记录边开边说，系统会自动转文字并生成待补充的驾驶日志。"
            )

            guideItem(
                icon: "arrow.down.circle",
                title: "首页刷新",
                content: "下拉首页即可刷新安全评分、知识推荐与快捷入口，保持数据实时同步。"
            )

            guideItem(
                icon: "square.on.square.dashed",
                title: "批量管理",
                content: "在驾驶日志和检查清单中长按进入批量选择模式，更快归档或删除多条记录。"
            )

            guideItem(
                icon: "paperplane",
                title: "快捷分享",
                content: "从日志详情中一键导出 PDF 或分享摘要，方便与家人、教练同步驾驶情况。"
            )

            tipBox(
                title: "💡 专业建议",
                content: "坚持 21 天建立\"记录-复盘-学习\"循环，安全评分与驾驶习惯都会稳步提升。"
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

    private func guideItem(icon: String? = nil, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            if let icon = icon {
                Circle()
                    .fill(Color.brandPrimary500.opacity(0.18))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: icon)
                            .font(.body)
                            .foregroundColor(.brandPrimary600)
                    )
            }

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

            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.sm)
    }

    private func tipBox(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(.brandPrimary600)

            Text(content)
                .font(.body)
                .foregroundColor(.brandPrimary700)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(Color.brandPrimary50.opacity(colorScheme == .dark ? 0.25 : 1))
        )
    }

    private func guideSectionContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            content()
        }
        .padding(Spacing.xl)
        .frame(maxWidth: 540, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(sectionSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                        .stroke(sectionBorderColor, lineWidth: 1)
                )
        )
        .shadow(color: Shadow.md.color.opacity(colorScheme == .dark ? 0.45 : 0.25), radius: Shadow.md.radius, x: Shadow.md.x, y: Shadow.md.y)
    }

    private var sidebarBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: colorScheme == .dark ? [Color.black.opacity(0.85), Color.black.opacity(0.65)] : [Color.brandSecondary100, Color.white]),
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(colorScheme == .dark ? 0.05 : 0.15), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var navigationHighlight: Color {
        colorScheme == .dark ? Color.brandPrimary500.opacity(0.2) : Color.brandPrimary50
    }

    private var navigationHighlightBorder: Color {
        colorScheme == .dark ? Color.brandPrimary500.opacity(0.35) : Color.brandPrimary100
    }

    private var sectionSurfaceColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.white
    }

    private var sectionBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.brandSecondary200
    }

    private var sidebarControlBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.65)
    }

    private func sidebarButton(for section: GuideSection, showLabel: Bool) -> some View {
        Button(action: {
            withAnimation(Animation.standard) {
                selectedSection = section
            }
        }) {
            VStack(spacing: showLabel ? Spacing.xs : Spacing.sm) {
                Image(systemName: section.icon)
                    .font(showLabel ? .title3 : .bodyLarge)
                    .foregroundColor(selectedSection == section ? .brandPrimary500 : .brandSecondary500)

                if showLabel {
                    Text(section.rawValue)
                        .font(.caption)
                        .fontWeight(selectedSection == section ? .semibold : .medium)
                        .foregroundColor(selectedSection == section ? .brandPrimary500 : .brandSecondary600)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, showLabel ? Spacing.lg : Spacing.md)
            .padding(.horizontal, showLabel ? Spacing.sm : 0)
            .background(
                RoundedRectangle(cornerRadius: showLabel ? CornerRadius.md : CornerRadius.sm, style: .continuous)
                    .fill(selectedSection == section ? navigationHighlight : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: showLabel ? CornerRadius.md : CornerRadius.sm, style: .continuous)
                            .stroke(selectedSection == section ? navigationHighlightBorder : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HelpGuideView()
}
