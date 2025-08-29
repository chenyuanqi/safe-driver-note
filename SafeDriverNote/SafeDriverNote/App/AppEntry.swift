import SwiftUI
import SwiftData

// 创建并共享一个 SwiftData ModelContainer（MVP 简化处理）
let sharedModelContainer: ModelContainer = {
    let schema = Schema([LogEntry.self, ChecklistRecord.self, KnowledgeCard.self, KnowledgeProgress.self, ChecklistItem.self, ChecklistPunch.self, DriveRoute.self])
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
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("首页", systemImage: "house") }
            LogListView()
                .tabItem { Label("日志", systemImage: "list.bullet") }
            ChecklistView()
                .tabItem { Label("清单", systemImage: "checklist") }
            KnowledgeTodayView()
                .tabItem { Label("知识", systemImage: "book") }
        }
    }
}
