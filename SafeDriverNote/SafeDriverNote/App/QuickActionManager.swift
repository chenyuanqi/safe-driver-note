import SwiftUI
import UIKit

enum QuickActionType: String, CaseIterable, Equatable {
    case startDriving = "com.chenyuanqi.SafeDriverNote.startDriving"
    case quickChecklist = "com.chenyuanqi.SafeDriverNote.quickChecklist"
    case drivingRules = "com.chenyuanqi.SafeDriverNote.drivingRules"

    var displayName: String {
        switch self {
        case .startDriving: return "开始驾驶"
        case .quickChecklist: return "行前检查"
        case .drivingRules: return "开车守则"
        }
    }

    var subtitle: String? {
        switch self {
        case .startDriving: return "立即开启行程记录"
        case .quickChecklist: return "快速打卡准备驾驶"
        case .drivingRules: return "查看安全驾驶要点"
        }
    }

    var systemImageName: String {
        switch self {
        case .startDriving: return "car.fill"
        case .quickChecklist: return "speedometer"
        case .drivingRules: return "book"
        }
    }

    var shortcutItem: UIApplicationShortcutItem {
        let icon = UIApplicationShortcutIcon(systemImageName: systemImageName)
        return UIApplicationShortcutItem(type: rawValue, localizedTitle: displayName, localizedSubtitle: subtitle, icon: icon, userInfo: nil)
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

    func clear() {
        requestedAction = nil
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    private weak var quickActionManager: QuickActionManager?
    private var pendingShortcutItem: UIApplicationShortcutItem?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        configureShortcutItems()
        if let shortcut = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            pendingShortcutItem = shortcut
            return false
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        deliverPendingShortcutIfNeeded()
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handled = handleShortcut(shortcutItem)
        completionHandler(handled)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        configureShortcutItems()
    }

    private func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let actionType = QuickActionType(rawValue: shortcutItem.type) else { return false }
        if let manager = quickActionManager {
            manager.trigger(actionType)
        } else {
            pendingShortcutItem = shortcutItem
        }
        return true
    }

    private func configureShortcutItems() {
        UIApplication.shared.shortcutItems = QuickActionType.allCases.map { $0.shortcutItem }
    }

    func registerQuickActionManager(_ manager: QuickActionManager) {
        quickActionManager = manager
        deliverPendingShortcutIfNeeded()
    }

    private func deliverPendingShortcutIfNeeded() {
        guard let shortcut = pendingShortcutItem else { return }
        if let actionType = QuickActionType(rawValue: shortcut.type) {
            quickActionManager?.trigger(actionType)
            pendingShortcutItem = nil
        }
    }
}
