import SwiftUI
import UserNotifications
import Foundation

struct NotificationSettingsView: View {
    @State private var permissionGranted: Bool? = nil
    @State private var isLoading = false
    @State private var notificationHour = 7
    @State private var notificationMinute = 0
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            // 标题（移除）
            
            // 通知状态卡片
            Card(shadow: true) {
                VStack(spacing: Spacing.lg) {
                    HStack {
                        Image(systemName: permissionGranted == true ? "bell.fill" : "bell.slash.fill")
                            .font(.title2)
                            .foregroundColor(permissionGranted == true ? .brandPrimary500 : .brandSecondary400)
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(permissionGranted == true ? "通知已开启" : "通知已关闭")
                                .font(.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundColor(.brandSecondary900)
                            
                            Text(permissionGranted == true ? "您将每天收到安全驾驶提醒" : "您不会收到任何通知")
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary500)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    // 操作按钮
                    Button(action: toggleNotificationPermission) {
                        HStack {
                            Image(systemName: permissionGranted == true ? "bell.slash" : "bell")
                            Text(permissionGranted == true ? "关闭通知" : "开启通知")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                    }
                    .primaryStyle()
                    .disabled(isLoading)
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
                isLoading = false
            }
        }
    }
    
    /// 切换通知权限
    private func toggleNotificationPermission() {
        isLoading = true
        Task {
            if permissionGranted == true {
                // 关闭通知
                await NotificationService.shared.cancelAllNotifications()
                await MainActor.run {
                    permissionGranted = false
                    isLoading = false
                }
            } else {
                // 请求权限并开启通知
                let granted = await NotificationService.shared.requestPermission()
                if granted {
                    await NotificationService.shared.scheduleDailyKnowledgeReminder()
                }
                await MainActor.run {
                    permissionGranted = granted
                    isLoading = false
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
        if permissionGranted == true {
            Task {
                await NotificationService.shared.scheduleDailyKnowledgeReminder()
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}