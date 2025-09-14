import SwiftUI
import SwiftData
import UserNotifications

// 创建并共享一个 SwiftData ModelContainer（MVP 简化处理）
let sharedModelContainer: ModelContainer = {
    let schema = Schema([LogEntry.self, ChecklistRecord.self, KnowledgeCard.self, KnowledgeProgress.self, KnowledgeRecentlyShown.self, ChecklistItem.self, ChecklistPunch.self, DriveRoute.self])
    let config = ModelConfiguration()
    do {
        return try ModelContainer(for: schema, configurations: [config])
    } catch {
        // 迁移失败时，清理旧的默认存储并重试（仅限本地开发/模拟器）
        if let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let storeURL = supportURL.appendingPathComponent("default.store")
            try? FileManager.default.removeItem(at: storeURL)
            // 再尝试一次
            if let retried = try? ModelContainer(for: schema, configurations: [config]) {
                return retried
            }
        }
        fatalError("⚠️ Failed to create ModelContainer (after cleanup): \(error)")
    }
}()

@main
struct SafeDriverNoteApp: App {
    @StateObject private var notificationDelegate = NotificationDelegate()
    @StateObject private var themeManager = ThemeManager.shared

    init() {
        GlobalModelContext.container = sharedModelContainer
        // 首次启动播种知识卡
        DataSeeder.seedIfNeeded(context: sharedModelContainer.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(AppDI.shared)
                .environmentObject(notificationDelegate)
                .environmentObject(themeManager)
                .onAppear {
                    // 设置通知代理
                    UNUserNotificationCenter.current().delegate = notificationDelegate

                    // 应用启动时设置通知
                    Task {
                        await setupNotifications()
                    }
                    // 应用启动时清除通知红点
                    Task {
                        await clearNotificationBadges()
                    }

                    // 检查是否需要显示延时提醒
                    checkForDelayedAlert()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    /// 设置通知权限和每日提醒
    private func setupNotifications() async {
        let permissionGranted = await NotificationService.shared.requestPermission()
        if permissionGranted {
            await NotificationService.shared.scheduleDailyKnowledgeReminder()
        }
    }
    
    /// 清除通知红点
    private func clearNotificationBadges() async {
        await NotificationService.shared.clearBadges()
    }

    /// 检查是否需要显示延时提醒
    private func checkForDelayedAlert() {
        let defaults = UserDefaults.standard

        // 检查上次通知发送时间
        if let lastNotificationDate = defaults.object(forKey: "lastNotificationDate") as? Date {
            let now = Date()
            let hoursSinceNotification = now.timeIntervalSince(lastNotificationDate) / 3600

            // 如果距离上次通知超过1小时且小于24小时，显示强提醒
            if hoursSinceNotification >= 1 && hoursSinceNotification < 24 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    notificationDelegate.showDelayedAlert = true
                }
            }
        }
    }
}

struct RootTabView: View {
    @EnvironmentObject private var notificationDelegate: NotificationDelegate
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("首页", systemImage: "house") }

            NavigationStack {
                LogListView()
            }
            .tabItem { Label("日志", systemImage: "list.bullet") }

            NavigationStack {
                ChecklistView()
            }
            .tabItem { Label("清单", systemImage: "checklist") }

            NavigationStack {
                KnowledgeTodayView()
            }
            .tabItem { Label("知识", systemImage: "book") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("设置", systemImage: "gearshape") }

            // 测试页 (暂时隐藏)
            /*
            #if DEBUG
            NavigationStack {
                WeakNetworkTestView()
            }
            .tabItem { Label("测试", systemImage: "testtube.2") }
            #endif
            */
        }
        .alert(notificationDelegate.notificationDetailTitle, isPresented: $notificationDelegate.showNotificationDetail) {
            Button("知道了") {
                notificationDelegate.showNotificationDetail = false
            }
        } message: {
            Text(notificationDelegate.notificationDetailContent)
        }
        .alert("安全驾驶提醒", isPresented: $notificationDelegate.showDelayedAlert) {
            Button("知道了") {
                notificationDelegate.showDelayedAlert = false
            }
        } message: {
            Text("您好像有一段时间没有查看安全驾驶知识了。道路千万条，安全第一条！记得每天学习新的驾驶技巧哦~")
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
}

// MARK: - Notification Delegate
@MainActor
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    @Published var showNotificationDetail = false
    @Published var notificationDetailTitle = ""
    @Published var notificationDetailContent = ""
    @Published var showDelayedAlert = false

    /// 当应用在前台时收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 在前台显示通知
        completionHandler([.banner, .sound, .badge])
    }

    /// 当用户点击通知时
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 处理通知点击
        handleNotificationTap(response.notification)
        completionHandler()
    }

    private func handleNotificationTap(_ notification: UNNotification) {
        // 根据通知标识符设置详情内容
        switch notification.request.identifier {
        case "daily_knowledge_reminder":
            notificationDetailTitle = "今日安全驾驶提醒"
            notificationDetailContent = "祝您今天开车安全第一！您可以在首页查看今日的安全驾驶知识，学习新的驾驶技巧。记住：道路千万条，安全第一条！"
        default:
            notificationDetailTitle = "通知提醒"
            notificationDetailContent = "感谢您使用安全驾驶助手。请查看首页了解更多安全驾驶知识。"
        }

        showNotificationDetail = true
    }
}
