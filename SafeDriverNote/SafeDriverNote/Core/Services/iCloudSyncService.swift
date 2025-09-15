import Foundation
import CloudKit
import SwiftData

// MARK: - 同步状态
enum iCloudSyncStatus {
    case idle           // 空闲
    case syncing        // 同步中
    case success        // 同步成功
    case failed(Error)  // 同步失败
}

// MARK: - 同步统计
struct iCloudSyncStats {
    let uploadedRecords: Int
    let downloadedRecords: Int
    let totalDataSize: Int64 // bytes
    let lastSyncTime: Date?
    let syncDuration: TimeInterval
}

// MARK: - 可同步的数据类型
enum SyncableDataType: String, CaseIterable {
    case logEntries = "LogEntries"
    case checklistRecords = "ChecklistRecords"
    case checklistItems = "ChecklistItems"
    case checklistPunches = "ChecklistPunches"
    case knowledgeProgress = "KnowledgeProgress"
    case driveRoutes = "DriveRoutes"
    case userProfile = "UserProfile"

    var displayName: String {
        switch self {
        case .logEntries: return "驾驶日志"
        case .checklistRecords: return "检查记录"
        case .checklistItems: return "检查项目"
        case .checklistPunches: return "打卡记录"
        case .knowledgeProgress: return "学习进度"
        case .driveRoutes: return "行驶路线"
        case .userProfile: return "用户资料"
        }
    }
}

// MARK: - iCloud 同步服务
class iCloudSyncService: ObservableObject {
    @Published var syncStatus: iCloudSyncStatus = .idle
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncStats: iCloudSyncStats?

    private let container: CKContainer
    private let database: CKDatabase
    private let modelContainer: ModelContainer

    // 记录类型
    private let recordTypes = [
        "SafeDriverNote_LogEntry",
        "SafeDriverNote_ChecklistRecord",
        "SafeDriverNote_ChecklistItem",
        "SafeDriverNote_ChecklistPunch",
        "SafeDriverNote_KnowledgeProgress",
        "SafeDriverNote_DriveRoute",
        "SafeDriverNote_UserProfile"
    ]

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        // 使用默认容器，避免容器标识符配置问题
        self.container = CKContainer.default()
        self.database = container.privateCloudDatabase
    }

    // MARK: - 公共接口

    /// 检查 iCloud 可用性
    func checkiCloudAvailability() async -> Bool {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                print("✅ iCloud 可用")
                return true
            case .noAccount:
                print("❌ 未登录 iCloud 账户")
                return false
            case .restricted:
                print("❌ iCloud 访问受限")
                return false
            case .couldNotDetermine:
                print("❌ 无法确定 iCloud 状态")
                return false
            case .temporarilyUnavailable:
                print("❌ iCloud 暂时不可用")
                return false
            @unknown default:
                print("❌ 未知的 iCloud 状态")
                return false
            }
        } catch {
            print("❌ 检查 iCloud 状态时出错: \(error)")
            return false
        }
    }

    /// 执行完整同步
    func performFullSync() async throws -> iCloudSyncStats {
        guard await checkiCloudAvailability() else {
            throw iCloudSyncError.iCloudUnavailable
        }

        await MainActor.run {
            syncStatus = .syncing
            syncProgress = 0.0
        }

        let startTime = Date()
        var uploadCount = 0
        var downloadCount = 0
        var totalDataSize: Int64 = 0

        do {
            // 1. 上传本地数据到 iCloud (70% 进度)
            let uploadStats = try await uploadLocalDataToiCloud()
            uploadCount = uploadStats.recordCount
            totalDataSize += uploadStats.dataSize

            await MainActor.run {
                syncProgress = 0.7
            }

            // 2. 从 iCloud 下载数据 (30% 进度)
            let downloadStats = try await downloadDataFromiCloud()
            downloadCount = downloadStats.recordCount
            totalDataSize += downloadStats.dataSize

            await MainActor.run {
                syncProgress = 1.0
            }

            let stats = iCloudSyncStats(
                uploadedRecords: uploadCount,
                downloadedRecords: downloadCount,
                totalDataSize: totalDataSize,
                lastSyncTime: Date(),
                syncDuration: Date().timeIntervalSince(startTime)
            )

            await MainActor.run {
                lastSyncStats = stats
                syncStatus = .success
            }

            // 保存最后同步时间
            UserDefaults.standard.set(Date(), forKey: "LastiCloudSyncTime")

            return stats

        } catch {
            await MainActor.run {
                syncStatus = .failed(error)
            }
            throw error
        }
    }

    /// 仅上传数据到 iCloud
    func uploadToiCloud() async throws -> iCloudSyncStats {
        guard await checkiCloudAvailability() else {
            throw iCloudSyncError.iCloudUnavailable
        }

        await MainActor.run {
            syncStatus = .syncing
            syncProgress = 0.0
        }

        let startTime = Date()

        do {
            let uploadStats = try await uploadLocalDataToiCloud()

            await MainActor.run {
                syncProgress = 1.0
            }

            let stats = iCloudSyncStats(
                uploadedRecords: uploadStats.recordCount,
                downloadedRecords: 0,
                totalDataSize: uploadStats.dataSize,
                lastSyncTime: Date(),
                syncDuration: Date().timeIntervalSince(startTime)
            )

            await MainActor.run {
                lastSyncStats = stats
                syncStatus = .success
            }
            UserDefaults.standard.set(Date(), forKey: "LastiCloudUploadTime")

            return stats

        } catch {
            await MainActor.run {
                syncStatus = .failed(error)
            }
            throw error
        }
    }

    /// 从 iCloud 恢复数据
    func restoreFromiCloud() async throws -> iCloudSyncStats {
        guard await checkiCloudAvailability() else {
            throw iCloudSyncError.iCloudUnavailable
        }

        await MainActor.run {
            syncStatus = .syncing
            syncProgress = 0.0
        }

        let startTime = Date()

        do {
            let downloadStats = try await downloadDataFromiCloud()

            await MainActor.run {
                syncProgress = 1.0
            }

            let stats = iCloudSyncStats(
                uploadedRecords: 0,
                downloadedRecords: downloadStats.recordCount,
                totalDataSize: downloadStats.dataSize,
                lastSyncTime: Date(),
                syncDuration: Date().timeIntervalSince(startTime)
            )

            await MainActor.run {
                lastSyncStats = stats
                syncStatus = .success
            }
            UserDefaults.standard.set(Date(), forKey: "LastiCloudRestoreTime")

            return stats

        } catch {
            await MainActor.run {
                syncStatus = .failed(error)
            }
            throw error
        }
    }

    // MARK: - 私有方法

    private func uploadLocalDataToiCloud() async throws -> (recordCount: Int, dataSize: Int64) {
        let context = ModelContext(modelContainer)
        var totalRecords = 0
        var totalSize: Int64 = 0

        // 上传驾驶日志
        let logEntries = try context.fetch(FetchDescriptor<LogEntry>())
        let logRecords = logEntries.map { createCKRecord(from: $0) }
        if !logRecords.isEmpty {
            try await saveRecordsToiCloud(logRecords)
            totalRecords += logRecords.count
            totalSize += calculateDataSize(logRecords)
        }

        // 上传检查记录
        let checklistRecords = try context.fetch(FetchDescriptor<ChecklistRecord>())
        let checklistCKRecords = checklistRecords.map { createCKRecord(from: $0) }
        if !checklistCKRecords.isEmpty {
            try await saveRecordsToiCloud(checklistCKRecords)
            totalRecords += checklistCKRecords.count
            totalSize += calculateDataSize(checklistCKRecords)
        }

        // 上传自定义检查项
        let checklistItems = try context.fetch(FetchDescriptor<ChecklistItem>())
        let itemRecords = checklistItems.map { createCKRecord(from: $0) }
        if !itemRecords.isEmpty {
            try await saveRecordsToiCloud(itemRecords)
            totalRecords += itemRecords.count
            totalSize += calculateDataSize(itemRecords)
        }

        // 上传打卡记录
        let checklistPunches = try context.fetch(FetchDescriptor<ChecklistPunch>())
        let punchRecords = checklistPunches.map { createCKRecord(from: $0) }
        if !punchRecords.isEmpty {
            try await saveRecordsToiCloud(punchRecords)
            totalRecords += punchRecords.count
            totalSize += calculateDataSize(punchRecords)
        }

        // 上传学习进度
        let knowledgeProgress = try context.fetch(FetchDescriptor<KnowledgeProgress>())
        let progressRecords = knowledgeProgress.map { createCKRecord(from: $0) }
        if !progressRecords.isEmpty {
            try await saveRecordsToiCloud(progressRecords)
            totalRecords += progressRecords.count
            totalSize += calculateDataSize(progressRecords)
        }

        // 上传行驶路线
        let driveRoutes = try context.fetch(FetchDescriptor<DriveRoute>())
        let routeRecords = driveRoutes.map { createCKRecord(from: $0) }
        if !routeRecords.isEmpty {
            try await saveRecordsToiCloud(routeRecords)
            totalRecords += routeRecords.count
            totalSize += calculateDataSize(routeRecords)
        }

        // 上传用户资料
        let userProfiles = try context.fetch(FetchDescriptor<UserProfile>())
        let profileRecords = userProfiles.map { createCKRecord(from: $0) }
        if !profileRecords.isEmpty {
            try await saveRecordsToiCloud(profileRecords)
            totalRecords += profileRecords.count
            totalSize += calculateDataSize(profileRecords)
        }

        return (totalRecords, totalSize)
    }

    private func downloadDataFromiCloud() async throws -> (recordCount: Int, dataSize: Int64) {
        var totalRecords = 0
        var totalSize: Int64 = 0

        for recordType in recordTypes {
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let (matchResults, _) = try await database.records(matching: query)
            let records = matchResults.compactMap { try? $0.1.get() }

            if !records.isEmpty {
                try await processDownloadedRecords(records, recordType: recordType)
                totalRecords += records.count
                totalSize += calculateDataSize(records)
            }
        }

        return (totalRecords, totalSize)
    }

    private func saveRecordsToiCloud(_ records: [CKRecord]) async throws {
        let operation = CKModifyRecordsOperation(recordsToSave: records)
        operation.savePolicy = .allKeys

        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            database.add(operation)
        }
    }

    private func processDownloadedRecords(_ records: [CKRecord], recordType: String) async throws {
        let context = ModelContext(modelContainer)

        for record in records {
            switch recordType {
            case "SafeDriverNote_LogEntry":
                let logEntry = createLogEntry(from: record)
                context.insert(logEntry)

            case "SafeDriverNote_ChecklistRecord":
                let checklistRecord = createChecklistRecord(from: record)
                context.insert(checklistRecord)

            case "SafeDriverNote_ChecklistItem":
                let checklistItem = createChecklistItem(from: record)
                context.insert(checklistItem)

            case "SafeDriverNote_ChecklistPunch":
                let checklistPunch = createChecklistPunch(from: record)
                context.insert(checklistPunch)

            case "SafeDriverNote_KnowledgeProgress":
                let knowledgeProgress = createKnowledgeProgress(from: record)
                context.insert(knowledgeProgress)

            case "SafeDriverNote_DriveRoute":
                let driveRoute = createDriveRoute(from: record)
                context.insert(driveRoute)

            case "SafeDriverNote_UserProfile":
                let userProfile = createUserProfile(from: record)
                context.insert(userProfile)

            default:
                break
            }
        }

        try context.save()
    }

    private func calculateDataSize(_ records: [CKRecord]) -> Int64 {
        return records.reduce(0) { total, record in
            let data = try? NSKeyedArchiver.archivedData(withRootObject: record, requiringSecureCoding: true)
            return total + Int64(data?.count ?? 0)
        }
    }
}

// MARK: - CloudKit Record 转换
extension iCloudSyncService {
    private func createCKRecord(from logEntry: LogEntry) -> CKRecord {
        let record = CKRecord(recordType: "SafeDriverNote_LogEntry")
        record["id"] = logEntry.id.uuidString
        record["createdAt"] = logEntry.createdAt
        record["type"] = logEntry.type.rawValue
        record["locationNote"] = logEntry.locationNote
        record["scene"] = logEntry.scene
        record["detail"] = logEntry.detail
        record["cause"] = logEntry.cause
        record["improvement"] = logEntry.improvement
        record["tags"] = logEntry.tags
        record["photoLocalIds"] = logEntry.photoLocalIds
        record["audioFileName"] = logEntry.audioFileName
        record["transcript"] = logEntry.transcript
        return record
    }

    private func createCKRecord(from checklistRecord: ChecklistRecord) -> CKRecord {
        let record = CKRecord(recordType: "SafeDriverNote_ChecklistRecord")
        record["id"] = checklistRecord.id.uuidString
        record["date"] = checklistRecord.date
        record["score"] = checklistRecord.score

        // 将 ChecklistItemState 数组序列化为 Data
        if let preData = try? JSONEncoder().encode(checklistRecord.pre) {
            record["pre"] = preData
        }
        if let postData = try? JSONEncoder().encode(checklistRecord.post) {
            record["post"] = postData
        }

        return record
    }

    private func createCKRecord(from checklistItem: ChecklistItem) -> CKRecord {
        let record = CKRecord(recordType: "SafeDriverNote_ChecklistItem")
        record["id"] = checklistItem.id.uuidString
        record["title"] = checklistItem.title
        record["itemDescription"] = checklistItem.itemDescription
        record["mode"] = checklistItem.mode.rawValue
        record["priority"] = checklistItem.priority.rawValue
        record["isPinned"] = checklistItem.isPinned
        record["sortOrder"] = checklistItem.sortOrder
        record["isCustom"] = checklistItem.isCustom
        record["createdAt"] = checklistItem.createdAt
        record["updatedAt"] = checklistItem.updatedAt
        return record
    }

    private func createCKRecord(from checklistPunch: ChecklistPunch) -> CKRecord {
        let record = CKRecord(recordType: "SafeDriverNote_ChecklistPunch")
        record["id"] = checklistPunch.id.uuidString
        record["createdAt"] = checklistPunch.createdAt
        record["mode"] = checklistPunch.mode.rawValue
        record["checkedItemIds"] = checklistPunch.checkedItemIds.map { $0.uuidString }
        record["isQuickComplete"] = checklistPunch.isQuickComplete
        record["score"] = checklistPunch.score
        record["locationNote"] = checklistPunch.locationNote
        return record
    }

    private func createCKRecord(from knowledgeProgress: KnowledgeProgress) -> CKRecord {
        let record = CKRecord(recordType: "SafeDriverNote_KnowledgeProgress")
        record["id"] = knowledgeProgress.id.uuidString
        record["cardId"] = knowledgeProgress.cardId
        record["markedDates"] = knowledgeProgress.markedDates
        return record
    }

    private func createCKRecord(from driveRoute: DriveRoute) -> CKRecord {
        let record = CKRecord(recordType: "SafeDriverNote_DriveRoute")
        record["id"] = driveRoute.id.uuidString
        record["startTime"] = driveRoute.startTime
        record["endTime"] = driveRoute.endTime
        record["distance"] = driveRoute.distance
        record["duration"] = driveRoute.duration
        record["status"] = driveRoute.status.rawValue
        record["notes"] = driveRoute.notes

        // 序列化位置数据
        if let startLocation = driveRoute.startLocation,
           let startLocationData = try? JSONEncoder().encode(startLocation) {
            record["startLocation"] = startLocationData
        }

        if let endLocation = driveRoute.endLocation,
           let endLocationData = try? JSONEncoder().encode(endLocation) {
            record["endLocation"] = endLocationData
        }

        if let waypoints = driveRoute.waypoints,
           let waypointsData = try? JSONEncoder().encode(waypoints) {
            record["waypoints"] = waypointsData
        }

        return record
    }

    private func createCKRecord(from userProfile: UserProfile) -> CKRecord {
        let record = CKRecord(recordType: "SafeDriverNote_UserProfile")
        record["id"] = userProfile.id.uuidString
        record["userName"] = userProfile.userName
        record["userAge"] = userProfile.userAge
        record["drivingYears"] = userProfile.drivingYears
        record["vehicleType"] = userProfile.vehicleType
        record["avatarImagePath"] = userProfile.avatarImagePath
        record["createdAt"] = userProfile.createdAt
        record["updatedAt"] = userProfile.updatedAt
        return record
    }
}

// MARK: - CloudKit Record 解析
extension iCloudSyncService {
    private func createLogEntry(from record: CKRecord) -> LogEntry {
        return LogEntry(
            id: UUID(uuidString: record["id"] as? String ?? "") ?? UUID(),
            createdAt: record["createdAt"] as? Date ?? Date(),
            type: LogType(rawValue: record["type"] as? String ?? "mistake") ?? .mistake,
            locationNote: record["locationNote"] as? String ?? "",
            scene: record["scene"] as? String ?? "",
            detail: record["detail"] as? String ?? "",
            cause: record["cause"] as? String,
            improvement: record["improvement"] as? String,
            tags: record["tags"] as? [String] ?? [],
            photoLocalIds: record["photoLocalIds"] as? [String] ?? [],
            audioFileName: record["audioFileName"] as? String,
            transcript: record["transcript"] as? String
        )
    }

    private func createChecklistRecord(from record: CKRecord) -> ChecklistRecord {
        var pre: [ChecklistItemState] = []
        var post: [ChecklistItemState] = []

        if let preData = record["pre"] as? Data,
           let decodedPre = try? JSONDecoder().decode([ChecklistItemState].self, from: preData) {
            pre = decodedPre
        }

        if let postData = record["post"] as? Data,
           let decodedPost = try? JSONDecoder().decode([ChecklistItemState].self, from: postData) {
            post = decodedPost
        }

        return ChecklistRecord(
            id: UUID(uuidString: record["id"] as? String ?? "") ?? UUID(),
            date: record["date"] as? Date ?? Date(),
            pre: pre,
            post: post,
            score: record["score"] as? Int ?? 0
        )
    }

    private func createChecklistItem(from record: CKRecord) -> ChecklistItem {
        return ChecklistItem(
            id: UUID(uuidString: record["id"] as? String ?? "") ?? UUID(),
            title: record["title"] as? String ?? "",
            itemDescription: record["itemDescription"] as? String,
            mode: ChecklistMode(rawValue: record["mode"] as? String ?? "pre") ?? .pre,
            priority: ChecklistPriority(rawValue: record["priority"] as? String ?? "medium") ?? .medium,
            isPinned: record["isPinned"] as? Bool,
            sortOrder: record["sortOrder"] as? Int,
            isCustom: record["isCustom"] as? Bool ?? true,
            createdAt: record["createdAt"] as? Date ?? Date(),
            updatedAt: record["updatedAt"] as? Date ?? Date()
        )
    }

    private func createChecklistPunch(from record: CKRecord) -> ChecklistPunch {
        let checkedItemIds = (record["checkedItemIds"] as? [String])?.compactMap { UUID(uuidString: $0) } ?? []

        return ChecklistPunch(
            id: UUID(uuidString: record["id"] as? String ?? "") ?? UUID(),
            createdAt: record["createdAt"] as? Date ?? Date(),
            mode: ChecklistMode(rawValue: record["mode"] as? String ?? "pre") ?? .pre,
            checkedItemIds: checkedItemIds,
            isQuickComplete: record["isQuickComplete"] as? Bool ?? false,
            score: record["score"] as? Int ?? 0,
            locationNote: record["locationNote"] as? String
        )
    }

    private func createKnowledgeProgress(from record: CKRecord) -> KnowledgeProgress {
        return KnowledgeProgress(
            id: UUID(uuidString: record["id"] as? String ?? "") ?? UUID(),
            cardId: record["cardId"] as? String ?? "",
            markedDates: record["markedDates"] as? [Date] ?? []
        )
    }

    private func createDriveRoute(from record: CKRecord) -> DriveRoute {
        var startLocation: RouteLocation?
        var endLocation: RouteLocation?
        var waypoints: [RouteLocation]?

        if let startLocationData = record["startLocation"] as? Data,
           let decodedStartLocation = try? JSONDecoder().decode(RouteLocation.self, from: startLocationData) {
            startLocation = decodedStartLocation
        }

        if let endLocationData = record["endLocation"] as? Data,
           let decodedEndLocation = try? JSONDecoder().decode(RouteLocation.self, from: endLocationData) {
            endLocation = decodedEndLocation
        }

        if let waypointsData = record["waypoints"] as? Data,
           let decodedWaypoints = try? JSONDecoder().decode([RouteLocation].self, from: waypointsData) {
            waypoints = decodedWaypoints
        }

        return DriveRoute(
            id: UUID(uuidString: record["id"] as? String ?? "") ?? UUID(),
            startTime: record["startTime"] as? Date ?? Date(),
            endTime: record["endTime"] as? Date,
            startLocation: startLocation,
            endLocation: endLocation,
            waypoints: waypoints,
            distance: record["distance"] as? Double,
            duration: record["duration"] as? TimeInterval,
            status: DriveStatus(rawValue: record["status"] as? String ?? "active") ?? .active,
            notes: record["notes"] as? String
        )
    }

    private func createUserProfile(from record: CKRecord) -> UserProfile {
        return UserProfile(
            id: UUID(uuidString: record["id"] as? String ?? "") ?? UUID(),
            userName: record["userName"] as? String ?? "安全驾驶人",
            userAge: record["userAge"] as? Int,
            drivingYears: record["drivingYears"] as? Int ?? 0,
            vehicleType: record["vehicleType"] as? String ?? "小型汽车",
            avatarImagePath: record["avatarImagePath"] as? String,
            createdAt: record["createdAt"] as? Date ?? Date(),
            updatedAt: record["updatedAt"] as? Date ?? Date()
        )
    }
}

// MARK: - 错误类型
enum iCloudSyncError: LocalizedError {
    case iCloudUnavailable
    case networkError
    case dataCorruption
    case quotaExceeded
    case unauthorized
    case cloudKitNotConfigured

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            return "iCloud 不可用，请检查您的 iCloud 设置"
        case .networkError:
            return "网络连接失败，请检查网络设置"
        case .dataCorruption:
            return "数据损坏，同步失败"
        case .quotaExceeded:
            return "iCloud 存储空间不足"
        case .unauthorized:
            return "iCloud 访问权限不足"
        case .cloudKitNotConfigured:
            return "CloudKit 配置错误，请联系开发者"
        }
    }
}