import SwiftUI
import SwiftData

// 创建并共享一个 SwiftData ModelContainer（MVP 简化处理）
let sharedModelContainer: ModelContainer = {
    let schema = Schema([LogEntry.self, ChecklistRecord.self, KnowledgeCard.self, KnowledgeProgress.self, ChecklistItem.self, ChecklistPunch.self])
    let config = ModelConfiguration()
    do { return try ModelContainer(for: schema, configurations: [config]) } catch {
        fatalError("⚠️ Failed to create ModelContainer: \(error)")
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
            LogListView()
                .tabItem { Label("日志", systemImage: "list.bullet") }
            ChecklistView()
                .tabItem { Label("清单", systemImage: "checklist") }
            KnowledgeTodayView()
                .tabItem { Label("知识", systemImage: "book") }
        }
    }
}
