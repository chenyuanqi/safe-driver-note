import SwiftUI
import SwiftData
import UserNotifications

// 创建并共享一个 SwiftData ModelContainer（MVP 简化处理）
let sharedModelContainer: ModelContainer = {
    let schema = Schema([LogEntry.self, ChecklistRecord.self, KnowledgeCard.self, KnowledgeProgress.self, KnowledgeRecentlyShown.self, ChecklistItem.self, ChecklistPunch.self, DriveRoute.self, UserProfile.self])
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
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var notificationDelegate = NotificationDelegate()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var quickActionManager: QuickActionManager
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let quickActionManager = QuickActionManager()
        self._quickActionManager = StateObject(wrappedValue: quickActionManager)
        GlobalModelContext.container = sharedModelContainer
        // 首次启动播种知识卡
        DataSeeder.seedIfNeeded(context: sharedModelContainer.mainContext)
        // 修复有问题的音频文件名
        AudioStorageService.shared.fixProblematicAudioFiles()
        appDelegate.registerQuickActionManager(quickActionManager)
        SceneDelegate.quickActionManager = quickActionManager
    }

    // 快速操作相关的处理方法
    private func handleURL(_ url: URL) {
        print("🔗 Handling URL: \(url)")
        if let actionType = QuickActionType.allCases.first(where: { url.absoluteString.contains($0.rawValue) }) {
            print("🔗 Found matching action type: \(actionType)")
            quickActionManager.trigger(actionType)
        }
    }

    private func handleSceneShortcut(_ shortcutItem: UIApplicationShortcutItem) {
        print("🎯 Scene shortcut received: \(shortcutItem.type)")
        if let actionType = QuickActionType(rawValue: shortcutItem.type) {
            quickActionManager.trigger(actionType)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(AppDI.shared)
                .environmentObject(notificationDelegate)
                .environmentObject(themeManager)
                .environmentObject(quickActionManager)
                .handlesExternalEvents(preferring: Set(QuickActionType.allCases.map { $0.rawValue }), allowing: Set(QuickActionType.allCases.map { $0.rawValue }))
                .onAppear {
                    appDelegate.registerQuickActionManager(quickActionManager)
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
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
                .onOpenURL { url in
                    print("🔗 App opened with URL: \(url)")
                    handleURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    print("🔗 App opened with web browsing activity")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIScene.willConnectNotification)) { notification in
                    print("🔗 Scene will connect notification received")
                    if let scene = notification.object as? UIWindowScene,
                       let shortcutItem = scene.session.stateRestorationActivity?.userInfo?["shortcutItem"] as? UIApplicationShortcutItem {
                        print("🔗 Found shortcut item in scene: \(shortcutItem.type)")
                        handleSceneShortcut(shortcutItem)
                    }
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
        // 首先检查今天是否已经显示过
        guard notificationDelegate.shouldShowReminder() else { return }

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

    /// 处理场景阶段变化
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        Task { @MainActor in
            let driveService = AppDI.shared.driveService

            switch newPhase {
            case .background:
                print("App进入后台")
                // 如果正在驾驶，确保后台位置更新继续
                if driveService.isDriving {
                    // 强制保存当前路径点到持久化存储
                    if let route = driveService.currentRoute {
                        try? AppDI.shared.driveRouteRepository.updateRoute(route) { r in
                            r.waypoints = driveService.getCurrentWaypoints()
                        }
                    }
                }

            case .inactive:
                print("App进入非活跃状态")
                // 保存当前状态
                if driveService.isDriving {
                    if let route = driveService.currentRoute {
                        try? AppDI.shared.driveRouteRepository.updateRoute(route) { r in
                            r.waypoints = driveService.getCurrentWaypoints()
                        }
                    }
                }

            case .active:
                print("App进入活跃状态")
                // 恢复驾驶状态
                if driveService.isDriving {
                    // 重新启动位置跟踪（如果需要）
                    driveService.resumeLocationTrackingIfNeeded()
                }

            @unknown default:
                break
            }
        }
    }
}

struct RootTabView: View {
    @EnvironmentObject private var notificationDelegate: NotificationDelegate
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var quickActionManager: QuickActionManager
    @State private var showLaunchScreen = true
    @State private var selectedTab: RootTab = .home
    @State private var quickActionDebugMessage: String?

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView()
                }
                .tabItem { Label("首页", systemImage: "house") }
                .tag(RootTab.home)

                NavigationStack {
                    LogListView()
                }
                .tabItem { Label("日志", systemImage: "list.bullet") }
                .tag(RootTab.logs)

                NavigationStack {
                    ChecklistView()
                }
                .tabItem { Label("清单", systemImage: "checklist") }
                .tag(RootTab.checklist)

                NavigationStack {
                    KnowledgeTodayView()
                }
                .tabItem { Label("知识", systemImage: "book") }
                .tag(RootTab.knowledge)

                NavigationStack {
                    SettingsView()
                }
                .tabItem { Label("设置", systemImage: "gearshape") }
                .tag(RootTab.settings)

                // 测试页 (暂时隐藏)
                /*
                #if DEBUG
                NavigationStack {
                    WeakNetworkTestView()
                }
                .tabItem { Label("测试", systemImage: "testtube.2") }
                .tag(RootTab.test)
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
            .sheet(isPresented: $notificationDelegate.showDelayedAlert) {
                SafetyReminderView {
                    notificationDelegate.showDelayedAlert = false
                    notificationDelegate.markReminderShown()
                }
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)
            }
            .preferredColorScheme(themeManager.colorScheme)
            .onChange(of: quickActionManager.requestedAction) { action in
                guard let action else { return }
                print("[QuickAction] RootTabView observed change -> \(action.rawValue)")
                routeToTab(for: action, source: "onChange")
            }
            .onAppear {
                if let action = quickActionManager.requestedAction {
                    print("[QuickAction] RootTabView onAppear pending action -> \(action.rawValue)")
                    routeToTab(for: action, source: "onAppear")
                }
            }

            if showLaunchScreen {
                LaunchScreenView(onSkip: {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showLaunchScreen = false
                    }
                })
                .transition(.opacity)
                .zIndex(1)
            }

            if let debugMessage = quickActionDebugMessage {
                VStack {
                    QuickActionDebugBanner(message: debugMessage)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(2)
                .allowsHitTesting(false)
            }
        }
    }

    private func routeToTab(for action: QuickActionType, source: String) {
        print("[QuickAction] routeToTab source=\(source) action=\(action.rawValue)")
        withAnimation(.easeInOut) {
            // 快捷操作统一回到首页，由 HomeView 处理后续流程
            selectedTab = .home
        }

        showDebugBanner("触发: \(action.displayName) • 来源: \(source)")
    }

    private func showDebugBanner(_ message: String) {
        print("[QuickAction] debug banner -> \(message)")
        quickActionDebugMessage = message
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeOut) {
                quickActionDebugMessage = nil
            }
        }
    }
}

private enum RootTab: Hashable {
    case home
    case logs
    case checklist
    case knowledge
    case settings
#if DEBUG
    case test
#endif
}

// MARK: - Notification Delegate
@MainActor
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    @Published var showNotificationDetail = false
    @Published var notificationDetailTitle = ""
    @Published var notificationDetailContent = ""
    @Published var showDelayedAlert = false

    // UserDefaults key for tracking last shown date
    private let lastReminderShownKey = "lastSafetyReminderShownDate"

    // 检查今天是否已经显示过提醒
    func shouldShowReminder() -> Bool {
        let defaults = UserDefaults.standard
        if let lastShownDate = defaults.object(forKey: lastReminderShownKey) as? Date {
            return !Calendar.current.isDateInToday(lastShownDate)
        }
        return true
    }

    // 标记提醒已显示
    func markReminderShown() {
        UserDefaults.standard.set(Date(), forKey: lastReminderShownKey)
    }

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

#if DEBUG
private struct QuickActionDebugBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.8))
            .clipShape(Capsule())
            .padding(.top, 48)
    }
}
#endif

extension Notification.Name {
    static let openDrivingRules = Notification.Name("OpenDrivingRules")
    static let beginChecklistAutoPrompt = Notification.Name("BeginChecklistAutoPrompt")
}
