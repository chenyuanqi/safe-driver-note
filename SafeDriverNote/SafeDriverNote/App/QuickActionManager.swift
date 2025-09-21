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
        DispatchQueue.main.async {
            self.requestedAction = action
        }
    }

    func clear(_ action: QuickActionType) {
        guard requestedAction == action else { return }
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
                self.configureShortcutItems()
            }
        }

        if let shortcut = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            pendingShortcutItem = shortcut
            return false
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // 检查是否有等待处理的快速操作
        deliverPendingShortcutIfNeeded()

        // 确保快速操作在应用激活时也被配置
        Task { @MainActor in
            configureShortcutItems()
        }
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handled = handleShortcut(shortcutItem)
        completionHandler(handled)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        Task { @MainActor in
            configureShortcutItems()
        }
    }

    private func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let actionType = QuickActionType(rawValue: shortcutItem.type) else {
            return false
        }
        if let manager = quickActionManager {
            manager.trigger(actionType)
        } else {
            pendingShortcutItem = shortcutItem
        }
        return true
    }

    @MainActor
    private func configureShortcutItems() {
        UIApplication.shared.shortcutItems = QuickActionType.allCases.map { $0.dynamicShortcutItem() }
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
        guard let shortcut = pendingShortcutItem else {
            return
        }
        if let actionType = QuickActionType(rawValue: shortcut.type) {
            quickActionManager?.trigger(actionType)
            pendingShortcutItem = nil
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
        guard let actionType = QuickActionType(rawValue: shortcutItem.type) else { return false }
        guard let manager = Self.quickActionManager else { return false }
        manager.trigger(actionType)
        return true
    }
}
