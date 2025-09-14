import SwiftUI
import Foundation

struct ThemeSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.xl) {
                // 预览区域
                themePreviewSection

                // 主题选择
                themeSelectionSection

                Spacer()
            }
            .padding(Spacing.pagePadding)
            .background(Color.brandSecondary50)
            .navigationTitle("外观模式")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - 主题预览
    private var themePreviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("预览")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)
                .padding(.leading, Spacing.sm)

            // 预览卡片
            Card(shadow: true) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Circle()
                            .fill(Color.brandPrimary500)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "car.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("安全驾驶助手")
                                .font(.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundColor(.brandSecondary900)

                            Text("当前外观：\(themeManager.currentTheme.displayName)")
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary500)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.bodySmall)
                            .foregroundColor(.brandSecondary300)
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("安全评分")
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary600)
                            Text("92分")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.brandPrimary500)
                        }

                        Spacer()

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("连续天数")
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary600)
                            Text("15天")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.brandInfo500)
                        }

                        Spacer()

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("今日完成")
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary600)
                            Text("67%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.brandWarning500)
                        }
                    }
                }
                .padding(Spacing.lg)
            }
        }
    }

    // MARK: - 主题选择
    private var themeSelectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("选择外观")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)
                .padding(.leading, Spacing.sm)

            Card(shadow: true) {
                VStack(spacing: 0) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Button(action: {
                            themeManager.setTheme(theme)
                        }) {
                            themeOptionRow(theme: theme)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if theme != AppTheme.allCases.last {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - 主题选项行
    private func themeOptionRow(theme: AppTheme) -> some View {
        HStack(spacing: Spacing.md) {
            // 主题图标
            Image(systemName: themeIcon(for: theme))
                .font(.title3)
                .foregroundColor(themeColor(for: theme))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(theme.displayName)
                    .font(.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.brandSecondary900)

                Text(themeDescription(for: theme))
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary500)
            }

            Spacer()

            // 选中状态
            Image(systemName: themeManager.currentTheme == theme ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(themeManager.currentTheme == theme ? .brandPrimary500 : .brandSecondary300)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - 辅助方法
    private func themeIcon(for theme: AppTheme) -> String {
        switch theme {
        case .system: return "gear"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }

    private func themeColor(for theme: AppTheme) -> Color {
        switch theme {
        case .system: return .brandSecondary600
        case .light: return .brandWarning500
        case .dark: return .brandInfo500
        }
    }

    private func themeDescription(for theme: AppTheme) -> String {
        switch theme {
        case .system: return "自动根据系统设置切换浅色和深色模式"
        case .light: return "始终使用浅色背景和深色文字"
        case .dark: return "始终使用深色背景和浅色文字"
        }
    }
}

#Preview {
    ThemeSelectorView()
        .environmentObject(ThemeManager.shared)
}