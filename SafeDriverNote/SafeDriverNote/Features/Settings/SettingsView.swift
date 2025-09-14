import SwiftUI
import Foundation

struct SettingsView: View {
    @State private var showingUserProfile = false
    @State private var showingHelpGuide = false
    @State private var showingAbout = false
    @State private var showingDataExport = false
    @State private var showingThemeSelector = false
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var di: AppDI

    @State private var userProfile: UserProfile?
    @State private var userStats: UserStats?
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // 个人信息卡片
                userProfileSection

                // 应用设置
                appSettingsSection

                // 数据管理
                dataManagementSection

                // 帮助与支持
                helpSupportSection

                // 关于应用
                aboutSection
            }
            .padding(Spacing.pagePadding)
        }
        .background(Color.brandSecondary50)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUserData()
        }
        .sheet(isPresented: $showingUserProfile) {
            UserProfileView()
                .environmentObject(di)
                .onDisappear {
                    // 当个人资料页面关闭时重新加载数据
                    loadUserData()
                }
        }
        .sheet(isPresented: $showingHelpGuide) {
            HelpGuideView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView()
        }
        .sheet(isPresented: $showingThemeSelector) {
            ThemeSelectorView()
        }
    }

    // MARK: - 个人信息区域
    private var userProfileSection: some View {
        Button(action: {
            showingUserProfile = true
        }) {
            Card(shadow: true) {
                HStack(spacing: Spacing.md) {
                    // 头像
                    Circle()
                        .fill(Color.brandPrimary100)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundColor(.brandPrimary500)
                        )

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(userProfile?.userName ?? "安全驾驶人")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)

                        if let profile = userProfile, let stats = userStats {
                            Text("驾龄 \(profile.drivingYears) 年 · 安全评分 \(stats.safetyScore)分")
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary500)

                            Text("连续打卡 \(stats.currentStreakDays)天")
                                .font(.caption)
                                .foregroundColor(.brandPrimary500)
                        } else if isLoading {
                            Text("加载中...")
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary500)

                            Text("数据统计中...")
                                .font(.caption)
                                .foregroundColor(.brandSecondary400)
                        } else {
                            Text("驾龄 0 年 · 安全评分 --分")
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary500)

                            Text("连续打卡 0天")
                                .font(.caption)
                                .foregroundColor(.brandPrimary500)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary300)
                }
                .padding(Spacing.lg)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 应用设置
    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("应用设置")

            VStack(spacing: 0) {
                NavigationLink(destination: NotificationSettingsView()) {
                    settingsRow(
                        icon: "bell",
                        title: "通知设置",
                        subtitle: "管理每日安全驾驶提醒",
                        color: .brandPrimary500
                    )
                }

                Divider().padding(.leading, 52)

                Button(action: {
                    showingThemeSelector = true
                }) {
                    settingsRow(
                        icon: "moon",
                        title: "外观模式",
                        subtitle: themeManager.currentTheme.displayName,
                        color: .brandSecondary600
                    )
                }

                Divider().padding(.leading, 52)

                settingsRow(
                    icon: "location",
                    title: "位置权限",
                    subtitle: "用于记录驾驶路线",
                    color: .brandInfo500
                )
            }
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.md)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }

    // MARK: - 数据管理
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("数据管理")

            VStack(spacing: 0) {
                Button(action: {
                    showingDataExport = true
                }) {
                    settingsRow(
                        icon: "square.and.arrow.up",
                        title: "导出数据",
                        subtitle: "导出您的驾驶记录和日志",
                        color: .brandInfo500
                    )
                }

                Divider().padding(.leading, 52)

                settingsRow(
                    icon: "icloud",
                    title: "iCloud 同步",
                    subtitle: "同步数据到 iCloud",
                    color: .brandSecondary600,
                    isToggle: true
                )

                Divider().padding(.leading, 52)

                settingsRow(
                    icon: "trash",
                    title: "清除缓存",
                    subtitle: "清理临时文件",
                    color: .brandWarning500
                )
            }
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.md)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }

    // MARK: - 帮助与支持
    private var helpSupportSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("帮助与支持")

            VStack(spacing: 0) {
                Button(action: {
                    showingHelpGuide = true
                }) {
                    settingsRow(
                        icon: "questionmark.circle",
                        title: "使用指南",
                        subtitle: "了解如何使用各项功能",
                        color: .brandPrimary500
                    )
                }

                Divider().padding(.leading, 52)

                settingsRow(
                    icon: "envelope",
                    title: "意见反馈",
                    subtitle: "告诉我们您的想法",
                    color: .brandSecondary600
                )

                Divider().padding(.leading, 52)

                settingsRow(
                    icon: "star",
                    title: "为我们评分",
                    subtitle: "在 App Store 中评分",
                    color: .brandWarning500
                )
            }
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.md)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }

    // MARK: - 关于应用
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("关于")

            Button(action: {
                showingAbout = true
            }) {
                Card(shadow: true) {
                    settingsRow(
                        icon: "info.circle",
                        title: "关于安全驾驶助手",
                        subtitle: "版本 1.0.0",
                        color: .brandSecondary600
                    )
                }
            }
        }
    }

    // MARK: - 辅助方法
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(.brandSecondary900)
            .padding(.leading, Spacing.sm)
    }

    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        isToggle: Bool = false
    ) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.bodyLarge)
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.brandSecondary900)

                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary500)
            }

            Spacer()

            if isToggle {
                Toggle("", isOn: .constant(false))
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "chevron.right")
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary300)
            }
        }
        .padding(Spacing.md)
    }

    // MARK: - Data Loading

    private func loadUserData() {
        Task {
            do {
                let profile = try di.userProfileRepository.fetchUserProfile()
                let stats = try di.userProfileRepository.calculateUserStats()

                await MainActor.run {
                    self.userProfile = profile
                    self.userStats = stats
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Failed to load user data: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppDI.shared)
    }
}