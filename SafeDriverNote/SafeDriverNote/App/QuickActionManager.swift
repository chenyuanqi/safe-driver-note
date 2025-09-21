import SwiftUI
import UIKit
import Combine

enum QuickActionType: String, CaseIterable, Equatable {
    case startDriving = "com.chenyuanqi.SafeDriverNote.startDriving"
    case quickChecklistPre = "com.chenyuanqi.SafeDriverNote.quickChecklistPre"
    case quickChecklistPost = "com.chenyuanqi.SafeDriverNote.quickChecklistPost"
    case drivingRules = "com.chenyuanqi.SafeDriverNote.drivingRules"

    var displayName: String {
        switch self {
        case .startDriving: return "开始驾驶"
        case .quickChecklistPre: return "行前检查"
        case .quickChecklistPost: return "行后检查"
        case .drivingRules: return "开车守则"
        }
    }

    @MainActor
    func dynamicDisplayName() -> String {
        switch self {
        case .startDriving:
            let driveService = AppDI.shared.driveService
            return driveService.isDriving ? "结束驾驶" : "开始驾驶"
        case .quickChecklistPre: return "行前检查"
        case .quickChecklistPost: return "行后检查"
        case .drivingRules: return "开车守则"
        }
    }

    var subtitle: String? {
        switch self {
        case .startDriving: return "立即开启行程记录"
        case .quickChecklistPre: return "快速打卡准备驾驶"
        case .quickChecklistPost: return "行程结束后快速复盘"
        case .drivingRules: return "查看安全驾驶要点"
        }
    }

    @MainActor
    func dynamicSubtitle() -> String? {
        switch self {
        case .startDriving:
            let driveService = AppDI.shared.driveService
            return driveService.isDriving ? "停止当前行程记录" : "立即开启行程记录"
        case .quickChecklistPre: return "快速打卡准备驾驶"
        case .quickChecklistPost: return "行程结束后快速复盘"
        case .drivingRules: return "查看安全驾驶要点"
        }
    }

    var systemImageName: String {
        switch self {
        case .startDriving: return "car.fill"
        case .quickChecklistPre: return "speedometer"
        case .quickChecklistPost: return "checkmark.circle"
        case .drivingRules: return "book"
        }
    }

    @MainActor
    func dynamicSystemImageName() -> String {
        switch self {
        case .startDriving:
            let driveService = AppDI.shared.driveService
            return driveService.isDriving ? "stop.circle" : "car.fill"
        case .quickChecklistPre: return "speedometer"
        case .quickChecklistPost: return "checkmark.circle"
        case .drivingRules: return "book"
        }
    }

    var shortcutItem: UIApplicationShortcutItem {
        let icon = UIApplicationShortcutIcon(systemImageName: systemImageName)
        return UIApplicationShortcutItem(type: rawValue, localizedTitle: displayName, localizedSubtitle: subtitle, icon: icon, userInfo: nil)
    }

    @MainActor
    func dynamicShortcutItem() -> UIApplicationShortcutItem {
        let icon = UIApplicationShortcutIcon(systemImageName: dynamicSystemImageName())
        return UIApplicationShortcutItem(type: rawValue, localizedTitle: dynamicDisplayName(), localizedSubtitle: dynamicSubtitle(), icon: icon, userInfo: nil)
    }
}

@MainActor
final class QuickActionManager: ObservableObject {
    @Published var requestedAction: QuickActionType?

    func trigger(_ action: QuickActionType) {
        print("[QuickAction] manager trigger -> \(action.rawValue)")
        DispatchQueue.main.async {
            self.requestedAction = action
        }
    }

    func clear(_ action: QuickActionType) {
        guard requestedAction == action else { return }
        print("[QuickAction] manager clear -> \(action.rawValue)")
        requestedAction = nil
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    private weak var quickActionManager: QuickActionManager?
    private var pendingShortcutItem: UIApplicationShortcutItem?
    private var driveStateCancellable: AnyCancellable?

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("🚀 AppDelegate.didFinishLaunching called")

        // 立即配置一次
        Task { @MainActor in
            configureShortcutItems()
        }

        // 延迟配置一次，确保系统有时间处理
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Task { @MainActor in
                print("🔄 Reconfiguring shortcut items after delay")
                self.configureShortcutItems()
            }
        }

        if let shortcut = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            print("📱 App launched via shortcut: \(shortcut.type)")
            pendingShortcutItem = shortcut
            return false
        }
        print("📱 App launched normally")
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("📱 App became active")
        print("📱 Current shortcut items count: \(UIApplication.shared.shortcutItems?.count ?? 0)")

        // 检查是否有等待处理的快速操作
        deliverPendingShortcutIfNeeded()

        // 这里添加一个重要的检查：如果应用是通过快速操作激活的，但没有被处理
        if let shortcutItems = UIApplication.shared.shortcutItems {
            print("📱 Available shortcut items:")
            for item in shortcutItems {
                print("   - \(item.localizedTitle): \(item.type)")
            }
        }

        // 确保快速操作在应用激活时也被配置
        Task { @MainActor in
            configureShortcutItems()
        }
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        print("🎯 performActionFor shortcutItem called with: \(shortcutItem.type)")
        print("🎯 shortcutItem details: title=\(shortcutItem.localizedTitle), subtitle=\(shortcutItem.localizedSubtitle ?? "nil")")
        let handled = handleShortcut(shortcutItem)
        print("🎯 Shortcut handled: \(handled)")
        completionHandler(handled)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        Task { @MainActor in
            configureShortcutItems()
        }
    }

    private func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        print("🎯 AppDelegate.handleShortcut called with: \(shortcutItem.type)")
        guard let actionType = QuickActionType(rawValue: shortcutItem.type) else {
            print("❌ Failed to parse action type from: \(shortcutItem.type)")
            return false
        }
        if let manager = quickActionManager {
            print("✅ Found quickActionManager, triggering action")
            manager.trigger(actionType)
        } else {
            print("⏳ quickActionManager not ready, storing as pending")
            pendingShortcutItem = shortcutItem
        }
        return true
    }

    @MainActor
    private func configureShortcutItems() {
        let items = QuickActionType.allCases.map { $0.dynamicShortcutItem() }
        print("🔧 Configuring \(items.count) shortcut items:")
        for item in items {
            print("   - \(item.localizedTitle): \(item.type)")
        }
        UIApplication.shared.shortcutItems = items
        print("✅ Shortcut items configured")
    }

    @MainActor
    func updateShortcutItems() {
        configureShortcutItems()
    }

    func registerQuickActionManager(_ manager: QuickActionManager) {
        quickActionManager = manager
        SceneDelegate.quickActionManager = manager
        deliverPendingShortcutIfNeeded()
        setupDriveStateObserver()
    }

    func setupDriveStateObserver() {
        // 监听驾驶状态变化
        let driveService = AppDI.shared.driveService
        driveStateCancellable = driveService.$isDriving
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateShortcutItems()
                }
            }
    }

    private func deliverPendingShortcutIfNeeded() {
        print("📋 Checking for pending shortcuts...")
        guard let shortcut = pendingShortcutItem else {
            print("📋 No pending shortcuts found")
            return
        }
        print("📋 Found pending shortcut: \(shortcut.type)")
        if let actionType = QuickActionType(rawValue: shortcut.type) {
            print("📋 Triggering pending shortcut action: \(actionType)")
            quickActionManager?.trigger(actionType)
            pendingShortcutItem = nil
        } else {
            print("📋 Failed to parse pending shortcut type")
        }
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    static weak var quickActionManager: QuickActionManager?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let shortcut = connectionOptions.shortcutItem {
            handleShortcut(shortcut)
        }
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handled = handleShortcut(shortcutItem)
        completionHandler(handled)
    }

    @discardableResult
    private func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        print("🎯 SceneDelegate.handleShortcut -> \(shortcutItem.type)")
        guard let actionType = QuickActionType(rawValue: shortcutItem.type) else { return false }
        guard let manager = Self.quickActionManager else {
            print("❌ SceneDelegate missing quickActionManager")
            return false
        }
        manager.trigger(actionType)
        return true
    }
}
