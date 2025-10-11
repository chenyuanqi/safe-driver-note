import Foundation

struct BackupMetadata: Codable {
    let exportedAt: Date
    let appVersion: String
}

struct BackupEnvelope: Codable {
    var metadata: BackupMetadata
    var drivingRoutes: [DriveRouteBackup]? = nil
    var drivingLogs: [DrivingLogBackup]? = nil
    var checklistRecords: [ChecklistRecordBackup]? = nil
    var checklistItems: [ChecklistItemBackup]? = nil
    var checklistPunches: [ChecklistPunchBackup]? = nil
    var knowledgeProgress: [KnowledgeProgressBackup]? = nil
    var knowledgeCards: [KnowledgeCardBackup]? = nil
    var userProfile: UserProfileBackup? = nil
    var drivingRules: [DrivingRuleBackup]? = nil
}

struct DriveRouteBackup: Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date?
    let startLocation: RouteLocationBackup?
    let endLocation: RouteLocationBackup?
    let waypoints: [RouteLocationBackup]?
    let distance: Double?
    let duration: TimeInterval?
    let status: DriveStatus
    let notes: String?

    init(route: DriveRoute) {
        self.id = route.id
        self.startTime = route.startTime
        self.endTime = route.endTime
        self.startLocation = route.startLocation.map(RouteLocationBackup.init)
        self.endLocation = route.endLocation.map(RouteLocationBackup.init)
        self.waypoints = route.waypoints?.map(RouteLocationBackup.init)
        self.distance = route.distance
        self.duration = route.duration
        self.status = route.status
        self.notes = route.notes
    }

    func toModel() -> DriveRoute {
        DriveRoute(
            id: id,
            startTime: startTime,
            endTime: endTime,
            startLocation: startLocation?.toModel(),
            endLocation: endLocation?.toModel(),
            waypoints: waypoints?.map { $0.toModel() },
            distance: distance,
            duration: duration,
            status: status,
            notes: notes
        )
    }
}

struct RouteLocationBackup: Codable {
    let latitude: Double
    let longitude: Double
    let address: String
    let timestamp: Date

    init(location: RouteLocation) {
        self.latitude = location.latitude
        self.longitude = location.longitude
        self.address = location.address
        self.timestamp = location.timestamp
    }

    func toModel() -> RouteLocation {
        RouteLocation(latitude: latitude, longitude: longitude, address: address, timestamp: timestamp)
    }
}

struct DrivingLogBackup: Codable {
    let id: UUID
    let createdAt: Date
    let type: LogType
    let locationNote: String
    let scene: String
    let detail: String
    let cause: String?
    let improvement: String?
    let tags: [String]
    let photoLocalIds: [String]
    let audioFileName: String?
    let transcript: String?

    init(entry: LogEntry) {
        self.id = entry.id
        self.createdAt = entry.createdAt
        self.type = entry.type
        self.locationNote = entry.locationNote
        self.scene = entry.scene
        self.detail = entry.detail
        self.cause = entry.cause
        self.improvement = entry.improvement
        self.tags = entry.tags
        self.photoLocalIds = entry.photoLocalIds
        self.audioFileName = entry.audioFileName
        self.transcript = entry.transcript
    }

    func toModel() -> LogEntry {
        LogEntry(
            id: id,
            createdAt: createdAt,
            type: type,
            locationNote: locationNote,
            scene: scene,
            detail: detail,
            cause: cause,
            improvement: improvement,
            tags: tags,
            photoLocalIds: photoLocalIds,
            audioFileName: audioFileName,
            transcript: transcript
        )
    }
}

struct ChecklistRecordBackup: Codable {
    let id: UUID
    let date: Date
    let pre: [ChecklistItemState]
    let post: [ChecklistItemState]
    let score: Int

    init(record: ChecklistRecord) {
        self.id = record.id
        self.date = record.date
        self.pre = record.pre
        self.post = record.post
        self.score = record.score
    }

    func toModel() -> ChecklistRecord {
        ChecklistRecord(id: id, date: date, pre: pre, post: post, score: score)
    }
}

struct ChecklistItemBackup: Codable {
    let id: UUID
    let title: String
    let itemDescription: String?
    let mode: ChecklistMode
    let priority: ChecklistPriority
    let isPinned: Bool?
    let sortOrder: Int?
    let isCustom: Bool
    let createdAt: Date
    let updatedAt: Date

    init(item: ChecklistItem) {
        self.id = item.id
        self.title = item.title
        self.itemDescription = item.itemDescription
        self.mode = item.mode
        self.priority = item.priority
        self.isPinned = item.isPinned
        self.sortOrder = item.sortOrder
        self.isCustom = item.isCustom
        self.createdAt = item.createdAt
        self.updatedAt = item.updatedAt
    }

    func toModel() -> ChecklistItem {
        ChecklistItem(
            id: id,
            title: title,
            itemDescription: itemDescription,
            mode: mode,
            priority: priority,
            isPinned: isPinned,
            sortOrder: sortOrder,
            isCustom: isCustom,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct ChecklistPunchBackup: Codable {
    let id: UUID
    let createdAt: Date
    let mode: ChecklistMode
    let checkedItemIds: [UUID]
    let isQuickComplete: Bool
    let score: Int
    let locationNote: String?

    init(punch: ChecklistPunch) {
        self.id = punch.id
        self.createdAt = punch.createdAt
        self.mode = punch.mode
        self.checkedItemIds = punch.checkedItemIds
        self.isQuickComplete = punch.isQuickComplete
        self.score = punch.score
        self.locationNote = punch.locationNote
    }

    func toModel() -> ChecklistPunch {
        ChecklistPunch(
            id: id,
            createdAt: createdAt,
            mode: mode,
            checkedItemIds: checkedItemIds,
            isQuickComplete: isQuickComplete,
            score: score,
            locationNote: locationNote
        )
    }
}

struct KnowledgeProgressBackup: Codable {
    let id: UUID
    let cardId: String
    let markedDates: [Date]

    init(progress: KnowledgeProgress) {
        self.id = progress.id
        self.cardId = progress.cardId
        self.markedDates = progress.markedDates
    }

    func toModel() -> KnowledgeProgress {
        KnowledgeProgress(id: id, cardId: cardId, markedDates: markedDates)
    }
}

struct KnowledgeCardBackup: Codable {
    let id: String
    let title: String
    let what: String
    let why: String
    let how: String
    let tags: [String]

    init(card: KnowledgeCard) {
        self.id = card.id
        self.title = card.title
        self.what = card.what
        self.why = card.why
        self.how = card.how
        self.tags = card.tags
    }

    func toModel() -> KnowledgeCard {
        KnowledgeCard(id: id, title: title, what: what, why: why, how: how, tags: tags)
    }
}

struct UserProfileBackup: Codable {
    let id: UUID
    let userName: String
    let userAge: Int?
    let drivingYears: Int
    let vehicleType: String
    let avatarImagePath: String?
    let createdAt: Date
    let updatedAt: Date

    init(profile: UserProfile) {
        self.id = profile.id
        self.userName = profile.userName
        self.userAge = profile.userAge
        self.drivingYears = profile.drivingYears
        self.vehicleType = profile.vehicleType
        self.avatarImagePath = profile.avatarImagePath
        self.createdAt = profile.createdAt
        self.updatedAt = profile.updatedAt
    }

    func toModel() -> UserProfile {
        UserProfile(
            id: id,
            userName: userName,
            userAge: userAge,
            drivingYears: drivingYears,
            vehicleType: vehicleType,
            avatarImagePath: avatarImagePath,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct DrivingRuleBackup: Codable {
    let id: UUID
    let content: String
    let sortOrder: Int
    let isCustom: Bool
    let createdAt: Date
    let updatedAt: Date

    init(rule: DrivingRule) {
        self.id = rule.id
        self.content = rule.content
        self.sortOrder = rule.sortOrder
        self.isCustom = rule.isCustom
        self.createdAt = rule.createdAt
        self.updatedAt = rule.updatedAt
    }

    func toModel() -> DrivingRule {
        DrivingRule(
            id: id,
            content: content,
            sortOrder: sortOrder,
            isCustom: isCustom,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

enum BackupError: LocalizedError {
    case contextUnavailable
    case invalidFile
    case decodingFailed
    case encodingFailed
    case emptySelection

    var errorDescription: String? {
        switch self {
        case .contextUnavailable:
            return "数据上下文不可用，无法访问本地数据。"
        case .invalidFile:
            return "无法读取选中的文件，请确认格式正确。"
        case .decodingFailed:
            return "解析备份文件失败，文件可能已损坏。"
        case .encodingFailed:
            return "生成备份数据失败，请稍后再试。"
        case .emptySelection:
            return "请选择至少一项数据进行导出或导入。"
        }
    }
}
