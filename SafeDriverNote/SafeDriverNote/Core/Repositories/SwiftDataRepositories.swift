import Foundation
import SwiftData

@MainActor
private func context() throws -> ModelContext {
    guard let ctx = GlobalModelContext.context else { throw RepositoryError.contextUnavailable }
    return ctx
}

enum RepositoryError: Error { case contextUnavailable, notFound }

// MARK: - LogRepository Implementation
@MainActor
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
@MainActor
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

    // MARK: Items CRUD
    func fetchItems(mode: ChecklistMode?) throws -> [ChecklistItem] {
        let ctx = try context()
        var items = try ctx.fetch(FetchDescriptor<ChecklistItem>())
        if let m = mode { items = items.filter { $0.mode == m } }
        return items.sorted { lhs, rhs in
            let lp = lhs.isPinned ?? false
            let rp = rhs.isPinned ?? false
            if lp != rp { return lp && !rp }
            let lo = lhs.sortOrder ?? Int.max
            let ro = rhs.sortOrder ?? Int.max
            return lo < ro
        }
    }
    func addItem(_ item: ChecklistItem) throws {
        let ctx = try context(); ctx.insert(item); try ctx.save()
    }
    func updateItem(_ item: ChecklistItem, mutate: (ChecklistItem) -> Void) throws {
        let ctx = try context(); mutate(item); try ctx.save()
    }
    func deleteItem(_ item: ChecklistItem) throws {
        let ctx = try context(); ctx.delete(item); try ctx.save()
    }

    // MARK: Punches
    func addPunch(mode: ChecklistMode, checkedItemIds: [UUID]) throws {
        let ctx = try context()
        let punch = ChecklistPunch(mode: mode, checkedItemIds: checkedItemIds)
        ctx.insert(punch)
        try ctx.save()
    }
    func fetchPunches(on date: Date, mode: ChecklistMode?) throws -> [ChecklistPunch] {
        let ctx = try context()
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        var punches = try ctx.fetch(FetchDescriptor<ChecklistPunch>())
        punches = punches.filter { $0.createdAt >= start && $0.createdAt < end }
        if let m = mode { punches = punches.filter { $0.mode == m } }
        return punches.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchAllPunches(mode: ChecklistMode?) throws -> [ChecklistPunch] {
        let ctx = try context()
        var punches = try ctx.fetch(FetchDescriptor<ChecklistPunch>())
        if let m = mode { punches = punches.filter { $0.mode == m } }
        return punches.sorted { $0.createdAt > $1.createdAt }
    }

    func deletePunch(_ punch: ChecklistPunch) throws {
        let ctx = try context()
        ctx.delete(punch)
        try ctx.save()
    }
}

// MARK: - KnowledgeRepository Implementation
@MainActor
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
    func upsert(cards: [KnowledgeCard]) throws {
        let ctx = try context()
        // 读取已有，构建索引
        let existing = try ctx.fetch(FetchDescriptor<KnowledgeCard>())
        var map: [String: KnowledgeCard] = [:]
        for c in existing { map[c.id] = c }
        for src in cards {
            if let dst = map[src.id] {
                dst.title = src.title
                dst.what = src.what
                dst.why = src.why
                dst.how = src.how
                dst.tags = src.tags
            } else {
                ctx.insert(src)
            }
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

    // 用于首次种子化自定义清单项（中文默认清单）
    static let preDefaultTitles: [String] = [
        "检查周围环境是否安全（车底，周边行人、小孩等）",
        "检查车子是否正常（胎压、仪表盘显示）",
        "调整好方向盘、座椅，以及内后视镜和外后视镜",
        "如果下雨天，提前做准备（雨刷检查、空调对两边吹、后视镜加热，去油膜处理）",
        "如果在停车场，提前缴费再开车出去",
        "规划好行车路线"
    ]
    static let postDefaultTitles: [String] = [
        "检查车子位置是否有问题",
        "关窗、锁门、熄火，ok 后再确认停车🅿",
        "打开\"王朝\"app 再次确认车子情况",
        "如果陌生停车场，停车拍照 + 设置定位 + 手动记位置",
        "将本次\"失误–反思–改进\"条目补录到行车日记中",
        "记账 - 充电、加油、停车等费用"
    ]
}
