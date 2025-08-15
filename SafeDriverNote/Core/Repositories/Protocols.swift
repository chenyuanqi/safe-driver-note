import Foundation

protocol LogRepository {
    func fetchAll() throws -> [LogEntry]
    func fetch(by type: LogType?) throws -> [LogEntry]
    func add(_ entry: LogEntry) throws
    func delete(_ entry: LogEntry) throws
    func update(_ entry: LogEntry, mutate: (LogEntry) -> Void) throws
}

protocol ChecklistRepository {
    func todayRecord() throws -> ChecklistRecord?
    @discardableResult func upsertToday(update: (inout ChecklistRecord) -> Void) throws -> ChecklistRecord
}

protocol KnowledgeRepository {
    func allCards() throws -> [KnowledgeCard]
    func todayCards(limit: Int) throws -> [KnowledgeCard]
    func mark(cardId: String) throws
}
