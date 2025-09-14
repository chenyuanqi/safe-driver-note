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
    init() {
        GlobalModelContext.container = sharedModelContainer
        // 首次启动播种知识卡
        DataSeeder.seedIfNeeded(context: sharedModelContainer.mainContext)
    }
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(AppDI.shared)
                .onAppear {
                    // 应用启动时设置通知
                    Task {
                        await setupNotifications()
                    }
                    // 应用启动时清除通知红点
                    Task {
                        await clearNotificationBadges()
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
}

struct RootTabView: View {
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
    }
}
