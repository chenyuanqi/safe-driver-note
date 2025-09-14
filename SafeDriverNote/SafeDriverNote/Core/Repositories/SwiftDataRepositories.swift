import Foundation
import SwiftData
import CoreLocation

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
    func addPunch(mode: ChecklistMode, checkedItemIds: [UUID], isQuickComplete: Bool = false, score: Int = 0, locationNote: String? = nil) throws {
        let ctx = try context()
        let punch = ChecklistPunch(mode: mode, checkedItemIds: checkedItemIds, isQuickComplete: isQuickComplete, score: score, locationNote: locationNote)
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
        let ctx = try context()
        let allCards = try allCards()
        let today = Calendar.current.startOfDay(for: Date())
        let sessionId = DateFormatter().string(from: Date()) // 使用当前时间作为会话ID

        // 获取今日已标记的卡片
        let progresses = try ctx.fetch(FetchDescriptor<KnowledgeProgress>())
        let todayMarkedCardIds = Set(progresses.compactMap { progress in
            progress.markedDates.contains { Calendar.current.isDate($0, inSameDayAs: today) } ? progress.cardId : nil
        })

        // 获取最近7天内显示过的卡片（避免短期重复）
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: today) ?? today
        let recentlyShown = try ctx.fetch(FetchDescriptor<KnowledgeRecentlyShown>())
            .filter { $0.shownDate >= sevenDaysAgo }
        let recentlyShownCardIds = Set(recentlyShown.map { $0.cardId })

        // 筛选候选卡片：排除今日已标记和最近显示过的
        let availableCards = allCards.filter { card in
            !todayMarkedCardIds.contains(card.id) && !recentlyShownCardIds.contains(card.id)
        }

        // 如果可用卡片不足，则允许包含一些最近显示过的卡片（但仍排除今日已标记的）
        let finalCards: [KnowledgeCard]
        if availableCards.count >= limit {
            finalCards = Array(availableCards.shuffled().prefix(limit))
        } else {
            // 添加一些最近显示过但未标记的卡片
            let fallbackCards = allCards.filter { card in
                !todayMarkedCardIds.contains(card.id)
            }
            finalCards = Array(fallbackCards.shuffled().prefix(limit))
        }

        // 记录本次显示的卡片，便于下次避免重复
        for card in finalCards {
            let recentRecord = KnowledgeRecentlyShown(
                cardId: card.id,
                shownDate: Date(),
                sessionId: sessionId
            )
            ctx.insert(recentRecord)
        }

        // 清理30天前的显示记录
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: today) ?? today
        let oldRecords = recentlyShown.filter { $0.shownDate < thirtyDaysAgo }
        for record in oldRecords {
            ctx.delete(record)
        }

        try ctx.save()
        return finalCards
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

// MARK: - DriveRouteRepository Implementation
@MainActor
struct DriveRouteRepositorySwiftData: DriveRouteRepository {
    func startRoute(startLocation: RouteLocation?) throws -> DriveRoute {
        let ctx = try context()
        let route = DriveRoute(
            startLocation: startLocation,
            status: .active
        )
        ctx.insert(route)
        try ctx.save()
        return route
    }
    
    func getCurrentActiveRoute() throws -> DriveRoute? {
        let ctx = try context()
        let routes = try ctx.fetch(FetchDescriptor<DriveRoute>())
        return routes.first { $0.status == .active }
    }
    
    func endRoute(routeId: UUID, endLocation: RouteLocation?, waypoints: [RouteLocation]? = nil) throws {
        let ctx = try context()
        let routes = try ctx.fetch(FetchDescriptor<DriveRoute>())
        guard let route = routes.first(where: { $0.id == routeId }) else {
            throw RepositoryError.notFound
        }
        
        route.endTime = Date()
        route.endLocation = endLocation
        route.status = .completed
        
        // 如果提供了路径点，则更新路径点
        if let waypoints = waypoints, !waypoints.isEmpty {
            route.waypoints = waypoints
        }
        
        // 计算驾驶时长
        route.duration = route.endTime!.timeIntervalSince(route.startTime)
        
        // 计算距离
        if let waypoints = route.waypoints, !waypoints.isEmpty {
            // 如果有路径点，计算所有路径点之间的总距离
            var totalDistance: Double = 0
            
            // 如果有起始点，先计算起始点到第一个路径点的距离
            if let start = route.startLocation {
                let startCLLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
                let firstWaypointCLLocation = CLLocation(latitude: waypoints[0].latitude, longitude: waypoints[0].longitude)
                totalDistance += startCLLocation.distance(from: firstWaypointCLLocation)
            }
            
            // 计算路径点之间的距离
            for i in 0..<waypoints.count-1 {
                let location1 = CLLocation(latitude: waypoints[i].latitude, longitude: waypoints[i].longitude)
                let location2 = CLLocation(latitude: waypoints[i+1].latitude, longitude: waypoints[i+1].longitude)
                totalDistance += location1.distance(from: location2)
            }
            
            // 如果有终点，再计算最后一个路径点到终点的距离
            if let end = endLocation {
                let lastWaypointCLLocation = CLLocation(latitude: waypoints.last!.latitude, longitude: waypoints.last!.longitude)
                let endCLLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
                totalDistance += lastWaypointCLLocation.distance(from: endCLLocation)
            }
            
            route.distance = totalDistance
            
        } else if let start = route.startLocation, let end = endLocation {
            // 如果没有路径点，但有起始和结束位置，则计算直线距离
            let startCLLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
            let endCLLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
            route.distance = startCLLocation.distance(from: endCLLocation)
        }
        
        try ctx.save()
    }
    
    func fetchAllRoutes() throws -> [DriveRoute] {
        let ctx = try context()
        let routes = try ctx.fetch(FetchDescriptor<DriveRoute>())
        return routes.sorted { $0.startTime > $1.startTime }
    }
    
    func fetchRecentRoutes(limit: Int) throws -> [DriveRoute] {
        let routes = try fetchAllRoutes()
        return Array(routes.prefix(limit))
    }
    
    func deleteRoute(_ route: DriveRoute) throws {
        let ctx = try context()
        ctx.delete(route)
        try ctx.save()
    }
    
    func updateRoute(_ route: DriveRoute, mutate: (DriveRoute) -> Void) throws {
        let ctx = try context()
        mutate(route)
        try ctx.save()
    }
}

// MARK: - UserProfileRepository Implementation
@MainActor
struct UserProfileRepositorySwiftData: UserProfileRepository {
    func fetchUserProfile() throws -> UserProfile {
        let ctx = try context()
        let profiles = try ctx.fetch(FetchDescriptor<UserProfile>())

        // 如果没有用户资料，创建默认的
        if profiles.isEmpty {
            let defaultProfile = UserProfile()
            ctx.insert(defaultProfile)
            try ctx.save()
            return defaultProfile
        }

        return profiles.first!
    }

    func saveUserProfile(_ profile: UserProfile) throws {
        let ctx = try context()
        profile.updatedAt = Date()
        try ctx.save()
    }

    func updateUserProfile(userName: String, userAge: Int?, drivingYears: Int, vehicleType: String, avatarImagePath: String? = nil) throws -> UserProfile {
        let profile = try fetchUserProfile()
        profile.userName = userName
        profile.userAge = userAge
        profile.drivingYears = drivingYears
        profile.vehicleType = vehicleType
        if let avatarImagePath = avatarImagePath {
            profile.avatarImagePath = avatarImagePath
        }
        try saveUserProfile(profile)
        return profile
    }

    func calculateUserStats() throws -> UserStats {
        let ctx = try context()

        // 获取所有驾驶日志
        let logs = try ctx.fetch(FetchDescriptor<LogEntry>())

        // 获取所有打卡记录
        let punches = try ctx.fetch(FetchDescriptor<ChecklistPunch>())

        // 获取所有已完成的驾驶路线
        let routes = try ctx.fetch(FetchDescriptor<DriveRoute>()).filter { $0.status == .completed }

        // 计算统计数据
        let totalDrivingLogs = logs.count
        let totalSuccessLogs = logs.filter { $0.type == .success }.count
        let totalMistakeLogs = logs.filter { $0.type == .mistake }.count

        // 计算打卡天数（按日期去重）
        let checklistDays = Set(punches.map { Calendar.current.startOfDay(for: $0.createdAt) }).count

        // 计算总里程
        let totalRouteDistance = routes.compactMap { $0.distance }.reduce(0, +)

        // 计算连续打卡天数
        let currentStreakDays = calculateCurrentStreak(from: punches)

        // 计算安全评分
        let safetyScore = calculateSafetyScore(logs: logs, punches: punches, routes: routes)

        // 查找最近成就
        let recentAchievement = findRecentAchievement(
            totalLogs: totalDrivingLogs,
            streakDays: currentStreakDays,
            checklistDays: checklistDays
        )

        return UserStats(
            totalDrivingLogs: totalDrivingLogs,
            totalSuccessLogs: totalSuccessLogs,
            totalMistakeLogs: totalMistakeLogs,
            totalChecklistDays: checklistDays,
            totalRouteDistance: totalRouteDistance,
            currentStreakDays: currentStreakDays,
            safetyScore: safetyScore,
            recentAchievement: recentAchievement
        )
    }

    // MARK: - Private Helper Methods

    private func calculateCurrentStreak(from punches: [ChecklistPunch]) -> Int {
        guard !punches.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 按日期分组
        let punchesByDay = Dictionary(grouping: punches) { punch in
            calendar.startOfDay(for: punch.createdAt)
        }

        let sortedDays = punchesByDay.keys.sorted(by: >)

        // 从今天开始往前计算连续天数
        var streakCount = 0
        var currentDay = today

        while sortedDays.contains(currentDay) {
            streakCount += 1
            currentDay = calendar.date(byAdding: .day, value: -1, to: currentDay)!
        }

        return streakCount
    }

    private func calculateSafetyScore(logs: [LogEntry], punches: [ChecklistPunch], routes: [DriveRoute]) -> Int {
        var score = 50 // 基础分数

        // 成功记录加分
        let successCount = logs.filter { $0.type == .success }.count
        score += successCount * 5

        // 失误记录扣分
        let mistakeCount = logs.filter { $0.type == .mistake }.count
        score -= mistakeCount * 3

        // 打卡记录加分
        let totalPunchScore = punches.reduce(0) { $0 + $1.score }
        score += totalPunchScore / 10

        // 完成路线加分
        score += routes.count * 2

        // 确保分数在0-100范围内
        return max(0, min(100, score))
    }

    private func findRecentAchievement(totalLogs: Int, streakDays: Int, checklistDays: Int) -> AchievementStats.RecentAchievement? {
        let calendar = Calendar.current
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date())!

        // 检查各种成就条件
        if streakDays == 7 {
            return AchievementStats.RecentAchievement(
                title: "坚持不懈",
                description: "🎉 连续打卡7天",
                achievedDate: threeDaysAgo
            )
        } else if streakDays == 15 {
            return AchievementStats.RecentAchievement(
                title: "习惯养成",
                description: "🎉 连续打卡15天",
                achievedDate: threeDaysAgo
            )
        } else if streakDays == 30 {
            return AchievementStats.RecentAchievement(
                title: "安全达人",
                description: "🎉 连续打卡30天",
                achievedDate: threeDaysAgo
            )
        } else if totalLogs >= 10 {
            return AchievementStats.RecentAchievement(
                title: "记录专家",
                description: "🎉 累计记录10条日志",
                achievedDate: threeDaysAgo
            )
        } else if checklistDays >= 5 {
            return AchievementStats.RecentAchievement(
                title: "检查能手",
                description: "🎉 完成5天检查清单",
                achievedDate: threeDaysAgo
            )
        }

        return nil
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
        "规划好行车路线",
        "阅读安全驾驶知识，遵守交通规则，安全抵达目的地！"
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
