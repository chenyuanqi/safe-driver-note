import SwiftUI
import Foundation
import StoreKit

struct SettingsView: View {
    @State private var showingUserProfile = false
    @State private var showingHelpGuide = false
    @State private var showingAbout = false
    @State private var showingDataExport = false
    @State private var showingDataImport = false
    @State private var showingThemeSelector = false
    @State private var showingLocationPermission = false
    @State private var showingiCloudSync = false
    @State private var showingClearCacheAlert = false
    @State private var showingCacheCleared = false
    @State private var showingFeedbackOptions = false
    @State private var showingRestoreDefaults = false
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var di: AppDI

    @State private var userProfile: UserProfile?
    @State private var userStats: UserStats?
    @State private var isLoading = true
    @State private var avatarImage: Image?

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
        .sheet(isPresented: $showingDataImport) {
            DataImportView()
        }
        .sheet(isPresented: $showingThemeSelector) {
            ThemeSelectorView()
        }
        .sheet(isPresented: $showingLocationPermission) {
            LocationPermissionView()
                .environmentObject(di)
        }
        .sheet(isPresented: $showingiCloudSync) {
            iCloudSyncView()
                .environmentObject(di)
        }
        .sheet(isPresented: $showingRestoreDefaults) {
            RestoreDefaultsView()
                .environmentObject(di)
        }
        .alert("清除缓存", isPresented: $showingClearCacheAlert) {
            Button("取消", role: .cancel) { }
            Button("确定", role: .destructive) {
                clearCache()
            }
        } message: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("这将清理应用的临时文件和缓存数据，确定要继续吗？")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .alert("清理完成", isPresented: $showingCacheCleared) {
            Button("确定") { }
        } message: {
            Text("临时文件已成功清理")
        }
        .actionSheet(isPresented: $showingFeedbackOptions) {
            ActionSheet(
                title: Text("意见反馈"),
                message: Text("选择反馈方式"),
                buttons: [
                    .default(Text("📧 发送邮件")) {
                        sendFeedbackEmail()
                    },
                    .default(Text("⭐ 应用评分")) {
                        openAppStoreRating()
                    },
                    .cancel(Text("取消"))
                ]
            )
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
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimary100)
                            .frame(width: 60, height: 60)

                        if let avatarImage = avatarImage {
                            avatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundColor(.brandPrimary500)
                        }
                    }

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

                Button(action: {
                    showingLocationPermission = true
                }) {
                    settingsRow(
                        icon: "location",
                        title: "位置权限",
                        subtitle: "用于记录驾驶路线",
                        color: .brandInfo500
                    )
                }
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

                Button(action: {
                    showingDataImport = true
                }) {
                    settingsRow(
                        icon: "square.and.arrow.down",
                        title: "导入数据",
                        subtitle: "从备份恢复应用数据",
                        color: .brandInfo500
                    )
                }

                // iCloud 同步功能暂时隐藏，避免崩溃问题
                // Divider().padding(.leading, 52)
                // Button(action: {
                //     showingiCloudSync = true
                // }) {
                //     settingsRow(
                //         icon: "icloud",
                //         title: "iCloud 同步",
                //         subtitle: "同步数据到 iCloud",
                //         color: .brandSecondary600
                //     )
                // }

                Divider().padding(.leading, 52)

                Button(action: {
                    showingRestoreDefaults = true
                }) {
                    settingsRow(
                        icon: "arrow.counterclockwise.circle",
                        title: "恢复默认数据",
                        subtitle: "恢复系统默认的清单和守则",
                        color: .brandDanger500
                    )
                }

                Divider().padding(.leading, 52)

                Button(action: {
                    showingClearCacheAlert = true
                }) {
                    settingsRow(
                        icon: "trash",
                        title: "清除缓存",
                        subtitle: "清理临时文件",
                        color: .brandWarning500
                    )
                }
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

                Button(action: {
                    showingFeedbackOptions = true
                }) {
                    settingsRow(
                        icon: "envelope",
                        title: "意见反馈",
                        subtitle: "告诉我们您的想法和建议",
                        color: .brandSecondary600
                    )
                }

                Divider().padding(.leading, 52)

                Button(action: {
                    openAppStoreRating()
                }) {
                    settingsRow(
                        icon: "star",
                        title: "为我们评分",
                        subtitle: "在App Store上给我们评分",
                        color: .brandWarning500
                    )
                }
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
        color: Color
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

            Image(systemName: "chevron.right")
                .font(.bodySmall)
                .foregroundColor(.brandSecondary300)
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
                    self.loadAvatarImage(from: profile.avatarImagePath)
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

    private func loadAvatarImage(from path: String?) {
        guard let path = path else {
            avatarImage = nil
            return
        }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsPath.appendingPathComponent(path)

        if let data = try? Data(contentsOf: fileURL),
           let uiImage = UIImage(data: data) {
            self.avatarImage = Image(uiImage: uiImage)
        }
    }

    // MARK: - App Store Rating

    private func openAppStoreRating() {
        // 方法1: 直接跳转到App Store评分页面
        // 注意：应用必须已经在App Store上架，否则链接会无效
        let appID = "6753129152"
        if let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") {
            UIApplication.shared.open(url)
        }

        // 方法2: 使用 SKStoreReviewController（Apple官方API，作为备选）
        // 这个方法在应用上架后会显示评分弹窗，在开发阶段不会做任何事
        // 如果上面的直接跳转失败，可以尝试使用这个方法
        /*
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
        */
    }

    // MARK: - Feedback Management

    private func sendFeedbackEmail() {
        let email = "chenyuanqi@outlook.com"
        let subject = "安全驾驶助手 - 用户反馈"
        let body = """
        您好，

        我在使用安全驾驶助手过程中有以下反馈：

        [请在此处描述您的问题或建议]

        设备信息：
        - 应用版本：1.0.0 (2025.001)
        - 系统版本：iOS \(UIDevice.current.systemVersion)
        - 设备型号：\(UIDevice.current.model)

        谢谢！
        """

        if let emailURL = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            if UIApplication.shared.canOpenURL(emailURL) {
                UIApplication.shared.open(emailURL)
            } else {
                // 如果无法打开邮件应用，将邮箱地址复制到剪贴板
                UIPasteboard.general.string = email
            }
        }
    }

    // MARK: - Cache Management

    private func clearCache() {
        Task {
            do {
                // 清理临时目录
                let tempDirectory = FileManager.default.temporaryDirectory
                if FileManager.default.fileExists(atPath: tempDirectory.path) {
                    let tempContents = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
                    for url in tempContents {
                        try FileManager.default.removeItem(at: url)
                    }
                }

                // 清理缓存目录
                if let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                    let cacheContents = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
                    for url in cacheContents {
                        // 只删除非系统缓存文件
                        if !url.lastPathComponent.hasPrefix("com.apple") {
                            try FileManager.default.removeItem(at: url)
                        }
                    }
                }

                // 清理图片缓存等应用特定缓存
                UserDefaults.standard.removeObject(forKey: "ImageCache")
                UserDefaults.standard.removeObject(forKey: "TempData")

                await MainActor.run {
                    self.showingCacheCleared = true
                }

            } catch {
                await MainActor.run {
                    print("Failed to clear cache: \(error)")
                    // 即使出错也显示完成，因为部分清理可能成功了
                    self.showingCacheCleared = true
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
