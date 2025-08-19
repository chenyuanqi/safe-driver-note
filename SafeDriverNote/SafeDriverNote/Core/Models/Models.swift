import Foundation
import SwiftData

// MARK: - LogEntry
@Model final class LogEntry: Identifiable {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var type: LogType
    var locationNote: String
    var scene: String
    var detail: String
    var cause: String?
    var improvement: String?
    var tags: [String]
    var photoLocalIds: [String]
    var audioFileName: String?   // 语音文件名（占位）
    var transcript: String?      // 语音转写文本（占位）

    init(id: UUID = UUID(), createdAt: Date = .now, type: LogType, locationNote: String = "", scene: String = "", detail: String, cause: String? = nil, improvement: String? = nil, tags: [String] = [], photoLocalIds: [String] = [], audioFileName: String? = nil, transcript: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.type = type
        self.locationNote = locationNote
        self.scene = scene
        self.detail = detail
        self.cause = cause
        self.improvement = improvement
        self.tags = tags
        self.photoLocalIds = photoLocalIds
        self.audioFileName = audioFileName
        self.transcript = transcript
    }
}

enum LogType: String, Codable, CaseIterable { case mistake, success }

// MARK: - Checklist
enum ChecklistMode: String, Codable, CaseIterable { case pre, post }

@Model final class ChecklistRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var pre: [ChecklistItemState]
    var post: [ChecklistItemState]
    var score: Int

    init(id: UUID = UUID(), date: Date, pre: [ChecklistItemState], post: [ChecklistItemState], score: Int = 0) {
        self.id = id
        self.date = date
        self.pre = pre
        self.post = post
        self.score = score
    }
}

struct ChecklistItemState: Codable, Hashable {
    var key: String
    var checked: Bool
}

// 自定义清单项
@Model final class ChecklistItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var mode: ChecklistMode

    init(id: UUID = UUID(), title: String, mode: ChecklistMode) {
        self.id = id
        self.title = title
        self.mode = mode
    }
}

// 每次打卡记录
@Model final class ChecklistPunch {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var mode: ChecklistMode
    var checkedItemIds: [UUID]

    init(id: UUID = UUID(), createdAt: Date = .now, mode: ChecklistMode, checkedItemIds: [UUID]) {
        self.id = id
        self.createdAt = createdAt
        self.mode = mode
        self.checkedItemIds = checkedItemIds
    }
}

// MARK: - Knowledge
@Model final class KnowledgeCard {
    @Attribute(.unique) var id: String
    var title: String
    var what: String
    var why: String
    var how: String
    var tags: [String]

    init(id: String, title: String, what: String, why: String, how: String, tags: [String]) {
        self.id = id
        self.title = title
        self.what = what
        self.why = why
        self.how = how
        self.tags = tags
    }
}

@Model final class KnowledgeProgress {
    @Attribute(.unique) var id: UUID
    var cardId: String
    var markedDates: [Date]

    init(id: UUID = UUID(), cardId: String, markedDates: [Date] = []) {
        self.id = id
        self.cardId = cardId
        self.markedDates = markedDates
    }
}
