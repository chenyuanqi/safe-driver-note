import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    init() {}
    
    /// 请求通知权限
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            print("Notification permission granted: \(granted)")
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    /// 注册每日知识提醒通知
    func scheduleDailyKnowledgeReminder() async {
        // 先取消之前设置的所有通知
        await cancelAllNotifications()
        
        // 从UserDefaults获取自定义时间设置
        let defaults = UserDefaults.standard
        let hour = defaults.integer(forKey: "notificationHour")
        let minute = defaults.integer(forKey: "notificationMinute")
        
        // 如果没有设置，默认为7:00
        let notificationHour = (hour > 0 || minute > 0) ? hour : 7
        let notificationMinute = (hour > 0 || minute > 0) ? minute : 0
        
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = "安全驾驶提醒"
        content.body = "祝您今天开车安全第一！来阅读今天的开车守则吧~"
        content.sound = .default
        content.badge = 1
        
        // 创建每天触发的时间组件
        var dateComponents = DateComponents()
        dateComponents.hour = notificationHour
        dateComponents.minute = notificationMinute
        
        // 创建触发器
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // 创建请求
        let request = UNNotificationRequest(
            identifier: "daily_knowledge_reminder",
            content: content,
            trigger: trigger
        )
        
        // 注册通知
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Daily knowledge reminder scheduled for \(notificationHour):\(String(format: "%02d", notificationMinute))")
        } catch {
            print("Failed to schedule daily knowledge reminder: \(error)")
        }
    }
    
    /// 取消所有通知
    func cancelAllNotifications() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    /// 取消特定通知
    func cancelNotification(withIdentifier identifier: String) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    /// 清除应用图标上的通知红点
    func clearBadges() async {
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(0)
        } catch {
            print("Failed to clear badges: \(error)")
        }
    }
}