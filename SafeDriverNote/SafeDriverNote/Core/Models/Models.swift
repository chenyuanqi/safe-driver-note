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

enum ChecklistPriority: String, Codable, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .high: return "高"
        case .medium: return "中"
        case .low: return "低"
        }
    }
    
    var color: String {
        switch self {
        case .high: return "brandDanger500"
        case .medium: return "brandWarning500"
        case .low: return "brandSecondary400"
        }
    }
}

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
    var itemDescription: String? // 新增：检查项详细描述
    var mode: ChecklistMode
    var priority: ChecklistPriority // 新增：优先级设置
    var isPinned: Bool?
    var sortOrder: Int?
    var isCustom: Bool // 新增：区分系统默认和用户自定义
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String, itemDescription: String? = nil, mode: ChecklistMode, priority: ChecklistPriority = .medium, isPinned: Bool? = false, sortOrder: Int? = 0, isCustom: Bool = true, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.itemDescription = itemDescription
        self.mode = mode
        self.priority = priority
        self.isPinned = isPinned
        self.sortOrder = sortOrder
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// 每次打卡记录
@Model final class ChecklistPunch {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var mode: ChecklistMode
    var checkedItemIds: [UUID]
    var isQuickComplete: Bool // 新增：标记是否为快速完成
    var score: Int // 新增：本次打卡得分
    var locationNote: String? // 新增：位置信息

    init(id: UUID = UUID(), createdAt: Date = .now, mode: ChecklistMode, checkedItemIds: [UUID], isQuickComplete: Bool = false, score: Int = 0, locationNote: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.mode = mode
        self.checkedItemIds = checkedItemIds
        self.isQuickComplete = isQuickComplete
        self.score = score
        self.locationNote = locationNote
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

@Model final class KnowledgeRecentlyShown {
    @Attribute(.unique) var id: UUID
    var cardId: String
    var shownDate: Date
    var sessionId: String // 用于标识同一个学习会话

    init(id: UUID = UUID(), cardId: String, shownDate: Date = Date(), sessionId: String) {
        self.id = id
        self.cardId = cardId
        self.shownDate = shownDate
        self.sessionId = sessionId
    }
}

// MARK: - Driving Rules
@Model final class DrivingRule {
    @Attribute(.unique) var id: UUID
    var content: String
    var sortOrder: Int
    var isCustom: Bool // 区分系统默认和用户自定义
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), content: String, sortOrder: Int = 0, isCustom: Bool = true, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.content = content
        self.sortOrder = sortOrder
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Daily Checkin Summary
struct ChecklistPunchSummary: Codable {
    let id: UUID
    let createdAt: Date
    let mode: ChecklistMode
    let checkedItemIds: [UUID]
    let isQuickComplete: Bool
    let score: Int
    let locationNote: String? // 新增：位置信息
}

struct DailyCheckinSummary: Codable {
    let date: Date
    let prePunches: [ChecklistPunchSummary]
    let postPunches: [ChecklistPunchSummary]
    
    var totalScore: Int {
        let preScore = prePunches.reduce(0) { $0 + $1.score }
        let postScore = postPunches.reduce(0) { $0 + $1.score }
        return preScore + postScore
    }
    
    var completionStatus: String {
        let hasPreCheck = !prePunches.isEmpty
        let hasPostCheck = !postPunches.isEmpty
        
        switch (hasPreCheck, hasPostCheck) {
        case (true, true):
            return "已完成行前行后检查"
        case (true, false):
            return "仅完成行前检查"
        case (false, true):
            return "仅完成行后检查"
        case (false, false):
            return "未进行检查"
        }
    }
}

// MARK: - Drive Route
@Model final class DriveRoute: Identifiable {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date?
    var startLocation: RouteLocation?
    var endLocation: RouteLocation?
    var waypoints: [RouteLocation]? // 添加中间路径点
    var distance: Double? // 距离（米）
    var duration: TimeInterval? // 驾驶时长（秒）
    var status: DriveStatus
    var notes: String?
    
    init(id: UUID = UUID(), startTime: Date = .now, endTime: Date? = nil, startLocation: RouteLocation? = nil, endLocation: RouteLocation? = nil, waypoints: [RouteLocation]? = nil, distance: Double? = nil, duration: TimeInterval? = nil, status: DriveStatus = .active, notes: String? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.waypoints = waypoints
        self.distance = distance
        self.duration = duration
        self.status = status
        self.notes = notes
    }
}

struct RouteLocation: Codable {
    let latitude: Double
    let longitude: Double
    var address: String
    let timestamp: Date
    
    init(latitude: Double, longitude: Double, address: String, timestamp: Date = .now) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.timestamp = timestamp
    }
}

enum DriveStatus: String, Codable, CaseIterable {
    case active = "active"     // 正在驾驶
    case completed = "completed" // 已完成
    case cancelled = "cancelled" // 已取消

    var displayName: String {
        switch self {
        case .active: return "驾驶中"
        case .completed: return "已完成"
        case .cancelled: return "已取消"
        }
    }

    var color: String {
        switch self {
        case .active: return "brandWarning500"
        case .completed: return "brandPrimary500"
        case .cancelled: return "brandSecondary400"
        }
    }
}

// MARK: - User Profile
@Model final class UserProfile {
    @Attribute(.unique) var id: UUID
    var userName: String
    var userAge: Int?
    var drivingYears: Int
    var vehicleType: String
    var avatarImagePath: String?
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), userName: String = "安全驾驶人", userAge: Int? = nil, drivingYears: Int = 0, vehicleType: String = "小型汽车", avatarImagePath: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.userName = userName
        self.userAge = userAge
        self.drivingYears = drivingYears
        self.vehicleType = vehicleType
        self.avatarImagePath = avatarImagePath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Achievement Statistics
struct AchievementStats {
    let safetyScore: Int
    let continuousDays: Int
    let totalDistance: Double
    let recentAchievement: RecentAchievement?

    struct RecentAchievement {
        let title: String
        let description: String
        let achievedDate: Date
    }
}

struct UserStats {
    let totalDrivingLogs: Int
    let totalSuccessLogs: Int
    let totalMistakeLogs: Int
    let totalChecklistDays: Int
    let totalRouteDistance: Double
    let currentStreakDays: Int
    let safetyScore: Int
    let recentAchievement: AchievementStats.RecentAchievement?

    var improvementRate: Double {
        guard totalDrivingLogs > 0 else { return 0.0 }
        return Double(totalSuccessLogs) / Double(totalDrivingLogs)
    }
}
