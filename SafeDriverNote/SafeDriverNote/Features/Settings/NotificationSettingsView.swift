import SwiftUI
import UserNotifications
import Foundation
import UIKit

struct NotificationSettingsView: View {
    @State private var permissionGranted: Bool? = nil
    @State private var isLoading = false
    @State private var notificationHour = 7
    @State private var notificationMinute = 0
    @State private var notificationsEnabled = true
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            // 标题（移除）
            
            // 通知状态卡片
            Card(shadow: true) {
                VStack(spacing: Spacing.lg) {
                    HStack {
                        Image(systemName: isNotificationsActive ? "bell.fill" : "bell.slash.fill")
                            .font(.title2)
                            .foregroundColor(isNotificationsActive ? .brandPrimary500 : .brandSecondary400)
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(statusTitle)
                                .font(.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundColor(.brandSecondary900)
                            
                            Text(statusSubtitle)
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary500)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    // 操作按钮
                    Button(action: toggleNotificationPermission) {
                        HStack {
                            Image(systemName: isNotificationsActive ? "bell.slash" : "bell")
                            Text(isNotificationsActive ? "关闭通知" : "开启通知")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                    }
                    .primaryStyle()
                    .disabled(isLoading)
                    
                    if permissionGranted == false {
                        Button(action: openSystemSettings) {
                            HStack {
                                Image(systemName: "gear")
                                Text("前往系统设置开启通知")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                        }
                        .secondaryStyle()
                    }
                }
                .padding(Spacing.lg)
            }
            
            // 通知时间设置
            Card(shadow: true) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Image(systemName: "clock")
                            .font(.bodyLarge)
                            .foregroundColor(.brandInfo500)
                        Text("通知时间")
                            .font(.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("设置每日安全驾驶提醒的时间")
                            .font(.bodySmall)
                            .foregroundColor(.brandSecondary500)
                        
                        // 时间选择器
                        HStack {
                            Spacer()
                            Picker("小时", selection: $notificationHour) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour)点").tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100)
                            
                            Text(":")
                                .font(.title2)
                                .foregroundColor(.brandSecondary500)
                            
                            Picker("分钟", selection: $notificationMinute) {
                                ForEach(0..<60) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 100)
                            Spacer()
                        }
                        .padding(.vertical, Spacing.md)
                    }
                }
                .padding(Spacing.lg)
            }
            
            // 通知说明
            Card(backgroundColor: .brandInfo100, shadow: false) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.bodyLarge)
                            .foregroundColor(.brandInfo500)
                        Text("通知说明")
                            .font(.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("• 每天推送安全驾驶提醒")
                            .font(.bodySmall)
                            .foregroundColor(.brandSecondary700)
                        Text("• 提醒您阅读今日的开车守则")
                            .font(.bodySmall)
                            .foregroundColor(.brandSecondary700)
                        Text("• 祝您今天开车安全第一")
                            .font(.bodySmall)
                            .foregroundColor(.brandSecondary700)
                    }
                }
                .padding(Spacing.lg)
            }
            
            Spacer()
        }
        .padding(Spacing.pagePadding)
        .background(Color.brandSecondary50)
        .navigationTitle("") // 移除导航标题
        .navigationBarTitleDisplayMode(.inline) // 隐藏标题显示
        .onAppear {
            loadNotificationPreference()
            checkNotificationPermission()
            loadNotificationTime()
        }
        .onChange(of: notificationHour) { _, _ in
            updateNotificationTime()
        }
        .onChange(of: notificationMinute) { _, _ in
            updateNotificationTime()
        }
    }
    
    /// 检查通知权限状态
    private func checkNotificationPermission() {
        isLoading = true
        Task {
            let status = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                permissionGranted = status.alertSetting == .enabled
                if status.alertSetting != .enabled {
                    saveNotificationPreference(false)
                }
                isLoading = false
            }
        }
    }
    
    /// 切换通知权限
    private func toggleNotificationPermission() {
        isLoading = true
        Task {
            if isNotificationsActive {
                await NotificationService.shared.cancelAllNotifications()
                await MainActor.run {
                    saveNotificationPreference(false)
                    isLoading = false
                }
            } else {
                if permissionGranted == true {
                    await NotificationService.shared.scheduleDailyKnowledgeReminder()
                    await MainActor.run {
                        saveNotificationPreference(true)
                        isLoading = false
                    }
                } else {
                    let granted = await NotificationService.shared.requestPermission()
                    if granted {
                        await NotificationService.shared.scheduleDailyKnowledgeReminder()
                    }
                    await MainActor.run {
                        permissionGranted = granted
                        saveNotificationPreference(granted)
                        isLoading = false
                    }
                }
            }
        }
    }
    
    /// 加载通知时间设置
    private func loadNotificationTime() {
        // 从UserDefaults加载保存的时间设置
        let defaults = UserDefaults.standard
        notificationHour = defaults.integer(forKey: "notificationHour")
        notificationMinute = defaults.integer(forKey: "notificationMinute")
        
        // 如果没有保存过，默认设置为7:00
        if notificationHour == 0 && notificationMinute == 0 {
            notificationHour = 7
            notificationMinute = 0
        }
    }
    
    /// 更新通知时间设置
    private func updateNotificationTime() {
        // 保存时间设置到UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(notificationHour, forKey: "notificationHour")
        defaults.set(notificationMinute, forKey: "notificationMinute")
        
        // 如果通知已开启，重新设置通知
        if isNotificationsActive {
            Task {
                await NotificationService.shared.scheduleDailyKnowledgeReminder()
            }
        }
    }
    
    private var isNotificationsActive: Bool {
        (permissionGranted ?? false) && notificationsEnabled
    }
    
    private var statusTitle: String {
        if permissionGranted == true {
            return notificationsEnabled ? "通知已开启" : "通知已暂停"
        } else if permissionGranted == false {
            return "通知权限未开启"
        }
        return "正在检测通知状态"
    }
    
    private var statusSubtitle: String {
        if permissionGranted == true {
            return notificationsEnabled ? "将按设定时间提醒您进行安全驾驶记录" : "您已在应用内关闭提醒，可随时重新开启"
        } else if permissionGranted == false {
            return "请前往系统设置 > 通知，允许 SafeDriverNote 推送"
        }
        return "..."
    }
    
    private func loadNotificationPreference() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "notificationsEnabled") == nil {
            notificationsEnabled = true
        } else {
            notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        }
    }
    
    private func saveNotificationPreference(_ enabled: Bool) {
        notificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "notificationsEnabled")
    }
    
    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
