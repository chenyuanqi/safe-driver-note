import Foundation
import SwiftData

private func context() throws -> ModelContext {
    guard let ctx = GlobalModelContext.context else { throw RepositoryError.contextUnavailable }
    return ctx
}

enum RepositoryError: Error { case contextUnavailable, notFound }

// MARK: - LogRepository Implementation
struct LogRepositorySwiftData: LogRepository {
    func fetchAll() throws -> [LogEntry] { try fetch(by: nil) }
    func fetch(by type: LogType?) throws -> [LogEntry] {
        let ctx = try context()
        let descriptor = FetchDescriptor<LogEntry>()
        var result = try ctx.fetch(descriptor)
        if let t = type { result = result.filter { $0.type == t } }
        return result.sorted { $0.createdAt > $1.createdAt }
    }
    func add(_ entry: LogEntry) throws {
        let ctx = try context()
        ctx.insert(entry)
        try ctx.save()
    }
    func delete(_ entry: LogEntry) throws {
        let ctx = try context()
        ctx.delete(entry)
        try ctx.save()
    }
    func update(_ entry: LogEntry, mutate: (LogEntry) -> Void) throws {
        let ctx = try context()
        mutate(entry)
        try ctx.save()
    }
}

// MARK: - ChecklistRepository Implementation
struct ChecklistRepositorySwiftData: ChecklistRepository {
    func todayRecord() throws -> ChecklistRecord? {
        let ctx = try context()
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let all = try ctx.fetch(FetchDescriptor<ChecklistRecord>())
        return all.first { $0.date >= start && $0.date < end }
    }
    func upsertToday(update: (inout ChecklistRecord) -> Void) throws -> ChecklistRecord {
        let ctx = try context()
        if var existing = try todayRecord() {
            update(&existing)
            try ctx.save()
            return existing
        } else {
            var new = ChecklistRecord(date: Calendar.current.startOfDay(for: Date()), pre: ChecklistConstants.preTemplate, post: ChecklistConstants.postTemplate, score: 0)
            update(&new)
            ctx.insert(new)
            try ctx.save()
            return new
        }
    }
}

// MARK: - KnowledgeRepository Implementation
struct KnowledgeRepositorySwiftData: KnowledgeRepository {
    func allCards() throws -> [KnowledgeCard] {
        try context().fetch(FetchDescriptor<KnowledgeCard>())
    }
    func todayCards(limit: Int) throws -> [KnowledgeCard] {
        // 简单随机（后续可利用 KnowledgeProgress 过滤当日已标记）
        let cards = try allCards().shuffled()
        return Array(cards.prefix(limit))
    }
    func mark(cardId: String) throws {
        let ctx = try context()
        // 查找是否已有进度
        let progresses = try ctx.fetch(FetchDescriptor<KnowledgeProgress>())
        if let p = progresses.first(where: { $0.cardId == cardId }) {
            p.markedDates.append(Calendar.current.startOfDay(for: Date()))
        } else {
            let np = KnowledgeProgress(cardId: cardId, markedDates: [Calendar.current.startOfDay(for: Date())])
            ctx.insert(np)
        }
        try ctx.save()
    }
}

// MARK: - Checklist Templates
enum ChecklistConstants {
    static let preTemplate: [ChecklistItemState] = [
        "tirePressure","lights","mirrors","wipers","fuel","seatSteering","nav","tools"
    ].map { ChecklistItemState(key: $0, checked: false) }

    static let postTemplate: [ChecklistItemState] = [
        "parkBrake","windows","lightsOff","valuables","lock"
    ].map { ChecklistItemState(key: $0, checked: false) }
}
