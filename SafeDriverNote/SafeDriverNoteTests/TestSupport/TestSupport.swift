import Foundation
import SwiftData
@testable import SafeDriverNote

enum TestSupport {
    static func makeInMemoryContainer() -> ModelContainer {
        let schema = Schema([LogEntry.self, ChecklistRecord.self, KnowledgeCard.self, KnowledgeProgress.self, KnowledgeRecentlyShown.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do { return try ModelContainer(for: schema, configurations: [config]) } catch { fatalError("Failed to create in-memory container: \(error)") }
    }

    static func withFreshContainer(_ block: () throws -> Void) rethrows {
        let c = makeInMemoryContainer()
        GlobalModelContext.container = c
        try block()
    }

    @discardableResult
    static func insertSampleKnowledge(count: Int = 3) -> [KnowledgeCard] {
        guard let ctx = GlobalModelContext.context else { return [] }
        let samples: [KnowledgeCard] = (0..<count).map { idx in
            KnowledgeCard(id: "k_\(idx)", title: "Card \(idx)", what: "What \(idx)", why: "Why \(idx)", how: "How \(idx)", tags: ["t\(idx)"])
        }
        samples.forEach { ctx.insert($0) }
        try? ctx.save()
        return samples
    }
}
