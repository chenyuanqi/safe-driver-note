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

        // 获取今日已标记的卡片
        let progresses = try ctx.fetch(FetchDescriptor<KnowledgeProgress>())
        let todayMarkedCardIds = Set(progresses.compactMap { progress in
            progress.markedDates.contains { Calendar.current.isDate($0, inSameDayAs: today) } ? progress.cardId : nil
        })

        // 获取今日已显示的卡片记录
        let todayShown = try ctx.fetch(FetchDescriptor<KnowledgeRecentlyShown>())
            .filter { Calendar.current.isDate($0.shownDate, inSameDayAs: today) }

        // 如果今天已经有显示记录，直接返回这些卡片（保持顺序一致）
        if !todayShown.isEmpty {
            // 按照sessionId排序以保持顺序一致
            let sortedShown = todayShown.sorted { $0.sessionId < $1.sessionId }
            let todayShownCardIds = sortedShown.map { $0.cardId }

            // 按照记录的顺序返回卡片
            let todayCards = todayShownCardIds.compactMap { cardId in
                allCards.first { $0.id == cardId }
            }

            return todayCards
        }

        // 如果今天还没有显示记录，生成今日的固定卡片列表

        // 获取最近3天内显示过的卡片（减少排除天数，确保有足够卡片可选）
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today) ?? today
        let recentlyShown = try ctx.fetch(FetchDescriptor<KnowledgeRecentlyShown>())
            .filter { $0.shownDate >= threeDaysAgo && !Calendar.current.isDate($0.shownDate, inSameDayAs: today) }
        let recentlyShownCardIds = Set(recentlyShown.map { $0.cardId })

        // 首先尝试筛选：排除今日已标记和最近显示过的
        var availableCards = allCards.filter { card in
            !todayMarkedCardIds.contains(card.id) && !recentlyShownCardIds.contains(card.id)
        }

        // 如果可用卡片太少（少于需要数量），放宽条件：只排除今日已标记的
        if availableCards.count < limit {
            availableCards = allCards.filter { card in
                !todayMarkedCardIds.contains(card.id)
            }
        }

        // 如果还是不够，使用所有卡片（这种情况下用户可能只有很少的卡片）
        if availableCards.count < limit {
            availableCards = allCards
        }

        // 调试信息
        print("===== 卡片抽取调试信息 =====")
        print("总卡片数: \(allCards.count)")
        print("今日已标记卡片数: \(todayMarkedCardIds.count)")
        print("最近显示过的卡片数: \(recentlyShownCardIds.count)")
        print("可用卡片数: \(availableCards.count)")
        print("需要抽取数量: \(limit)")

        // 基于日期和抽取次数生成随机种子，支持同一天多次重新抽取
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: today)
        let baseSeed = (dateComponents.year ?? 0) * 10000 + (dateComponents.month ?? 0) * 100 + (dateComponents.day ?? 0)

        // 准备日期格式化器
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: today)

        // 计算今天已经抽取的次数（通过已清理的记录推算）
        let refreshCount = UserDefaults.standard.integer(forKey: "TodayRefreshCount_\(dateString)")
        let seed = baseSeed &+ refreshCount &* 1337 // 使用不同的乘数避免重复

        // 使用固定种子的随机打乱
        let shuffledAvailable = availableCards.sorted { $0.id < $1.id } // 先按ID排序以确保稳定性
            .enumerated()
            .map { (index: $0.offset, card: $0.element, randomValue: (seed &+ $0.offset.hashValue) &* 1664525 &+ 1013904223) }
            .sorted { $0.randomValue < $1.randomValue }
            .map { $0.card }

        // 选择今日卡片
        let finalCards: [KnowledgeCard]
        if shuffledAvailable.count >= limit {
            finalCards = Array(shuffledAvailable.prefix(limit))
        } else {
            // 如果可用卡片不足，从所有未标记的卡片中选择
            let fallbackCards = allCards.filter { card in
                !todayMarkedCardIds.contains(card.id)
            }

            // 同样使用固定种子打乱
            let shuffledFallback = fallbackCards.sorted { $0.id < $1.id }
                .enumerated()
                .map { (index: $0.offset, card: $0.element, randomValue: (seed &+ $0.offset.hashValue) &* 1664525 &+ 1013904223) }
                .sorted { $0.randomValue < $1.randomValue }
                .map { $0.card }

            finalCards = Array(shuffledFallback.prefix(limit))
        }

        // 记录今日显示的卡片
        for (index, card) in finalCards.enumerated() {
            let recentRecord = KnowledgeRecentlyShown(
                cardId: card.id,
                shownDate: today,
                sessionId: "\(dateString)_\(String(format: "%02d", index))" // 使用日期和索引作为会话ID，保持顺序
            )
            ctx.insert(recentRecord)
        }

        // 更新今日抽取次数
        UserDefaults.standard.set(refreshCount + 1, forKey: "TodayRefreshCount_\(dateString)")

        // 调试信息：最终结果
        print("最终抽取到的卡片数: \(finalCards.count)")
        if !finalCards.isEmpty {
            print("抽取到的卡片标题: \(finalCards.map { $0.title })")
        }
        print("===========================")

        // 清理30天前的显示记录
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: today) ?? today
        let oldRecords = recentlyShown.filter { $0.shownDate < thirtyDaysAgo }
        for record in oldRecords {
            ctx.delete(record)
        }

        try ctx.save()
        return finalCards
    }

    func knowledgePageCards(limit: Int) throws -> [KnowledgeCard] {
        let ctx = try context()
        let allCards = try allCards()

        // 知识页的抽取逻辑与今日学习分离
        // 使用不同的记录表来追踪知识页的显示记录
        let knowledgePagePrefix = "knowledge_page_"
        let _ = knowledgePagePrefix + UUID().uuidString

        // 获取知识页已显示的卡片记录
        let knowledgePageShown = try ctx.fetch(FetchDescriptor<KnowledgeRecentlyShown>())
            .filter { $0.sessionId.hasPrefix(knowledgePagePrefix) }

        // 检查是否有现有的知识页会话（最近的一次）
        let latestKnowledgePageSession = knowledgePageShown
            .sorted { $0.shownDate > $1.shownDate }
            .first?.sessionId.replacingOccurrences(of: knowledgePagePrefix, with: "")

        if let sessionId = latestKnowledgePageSession {
            // 如果有现有会话，返回该会话的卡片
            let currentSessionCards = knowledgePageShown
                .filter { $0.sessionId == knowledgePagePrefix + sessionId }
                .sorted { $0.shownDate < $1.shownDate } // 按显示时间排序

            let sessionCardIds = currentSessionCards.map { $0.cardId }
            let sessionCards = sessionCardIds.compactMap { cardId in
                allCards.first { $0.id == cardId }
            }

            if sessionCards.count == limit {
                return sessionCards
            }
        }

        // 如果没有现有会话或会话不完整，创建新的会话
        // 获取最近一周内在知识页显示过的卡片（避免短期内重复）
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentlyShownInKnowledgePage = knowledgePageShown
            .filter { $0.shownDate >= oneWeekAgo }
        let recentlyShownCardIds = Set(recentlyShownInKnowledgePage.map { $0.cardId })

        // 筛选可用卡片（排除最近在知识页显示过的）
        var availableCards = allCards.filter { card in
            !recentlyShownCardIds.contains(card.id)
        }

        // 额外排除今日学习中显示的卡片，避免重复
        let todayShownInTodayLearning = try ctx.fetch(FetchDescriptor<KnowledgeRecentlyShown>())
            .filter { !$0.sessionId.hasPrefix(knowledgePagePrefix) &&
                     Calendar.current.isDate($0.shownDate, inSameDayAs: Date()) }
        let todayLearningCardIds = Set(todayShownInTodayLearning.map { $0.cardId })

        availableCards = availableCards.filter { card in
            !todayLearningCardIds.contains(card.id)
        }

        // 如果可用卡片不足，先尝试只排除知识页记录
        if availableCards.count < limit {
            availableCards = allCards.filter { card in
                !recentlyShownCardIds.contains(card.id)
            }
        }

        // 如果还是不足，使用所有卡片
        if availableCards.count < limit {
            availableCards = allCards
        }

        // 使用基于时间戳的种子进行随机选择，确保与今日学习的固定种子不同
        let currentTimestamp = Date().timeIntervalSince1970
        let knowledgePageSeed = Int(currentTimestamp) &* 2654435761 // 使用不同的乘数

        // 使用固定种子的随机打乱，但基于时间戳而非日期
        let shuffledAvailable = availableCards.sorted { $0.id < $1.id } // 先按ID排序以确保稳定性
            .enumerated()
            .map { (index: $0.offset, card: $0.element, randomValue: (knowledgePageSeed &+ $0.offset.hashValue) &* 1664525 &+ 1013904223) }
            .sorted { $0.randomValue < $1.randomValue }
            .map { $0.card }

        let selectedCards = Array(shuffledAvailable.prefix(limit))

        // 记录新的知识页显示记录
        let newSessionId = knowledgePagePrefix + UUID().uuidString
        for (_, card) in selectedCards.enumerated() {
            let record = KnowledgeRecentlyShown(
                cardId: card.id,
                shownDate: Date(),
                sessionId: newSessionId
            )
            ctx.insert(record)
        }

        // 清理旧的知识页记录（保留最近30天）
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let oldKnowledgePageRecords = knowledgePageShown.filter { $0.shownDate < thirtyDaysAgo }
        for record in oldKnowledgePageRecords {
            ctx.delete(record)
        }

        // 调试信息
        print("===== 知识页卡片抽取调试信息 =====")
        print("总卡片数: \(allCards.count)")
        print("排除今日学习后的可用卡片数: \(availableCards.count)")
        print("抽取到的卡片数: \(selectedCards.count)")
        if !selectedCards.isEmpty {
            print("抽取到的卡片标题: \(selectedCards.map { $0.title })")
        }
        print("===========================")

        try ctx.save()
        return selectedCards
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

    /// 随机抽取一张卡片，用于知识页的无限抽取
    func randomCard() throws -> KnowledgeCard? {
        let ctx = try context()
        let allCards = try allCards()

        guard !allCards.isEmpty else { return nil }

        // 获取知识页已显示的卡片记录
        let knowledgePagePrefix = "knowledge_page_"
        let knowledgePageShown = try ctx.fetch(FetchDescriptor<KnowledgeRecentlyShown>())
            .filter { $0.sessionId.hasPrefix(knowledgePagePrefix) }

        // 获取最近7天内在知识页显示过的卡片
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentlyShownInKnowledgePage = knowledgePageShown
            .filter { $0.shownDate >= oneWeekAgo }
        let recentlyShownCardIds = Set(recentlyShownInKnowledgePage.map { $0.cardId })

        // 筛选可用卡片（排除最近7天在知识页显示过的）
        var availableCards = allCards.filter { card in
            !recentlyShownCardIds.contains(card.id)
        }

        // 如果可用卡片太少，放宽条件：排除最近3天的
        if availableCards.count < 3 {
            let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            let recentlyShownInThreeDays = knowledgePageShown
                .filter { $0.shownDate >= threeDaysAgo }
            let recentCardIds = Set(recentlyShownInThreeDays.map { $0.cardId })

            availableCards = allCards.filter { card in
                !recentCardIds.contains(card.id)
            }
        }

        // 如果仍然不足，使用所有卡片
        if availableCards.isEmpty {
            availableCards = allCards
        }

        // 随机选择一张
        let randomIndex = Int.random(in: 0..<availableCards.count)
        let selectedCard = availableCards[randomIndex]

        // 记录这次显示（使用当前的知识页会话）
        let latestKnowledgePageSession = knowledgePageShown
            .sorted { $0.shownDate > $1.shownDate }
            .first?.sessionId

        let sessionId = latestKnowledgePageSession ?? "knowledge_page_" + UUID().uuidString

        let record = KnowledgeRecentlyShown(
            cardId: selectedCard.id,
            shownDate: Date(),
            sessionId: sessionId
        )
        ctx.insert(record)

        // 清理旧的知识页记录（保留最近30天）
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let oldKnowledgePageRecords = knowledgePageShown.filter { $0.shownDate < thirtyDaysAgo }
        for record in oldKnowledgePageRecords {
            ctx.delete(record)
        }

        try ctx.save()
        return selectedCard
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
        // 始终更新头像路径，包括设置为nil的情况（删除头像）
        profile.avatarImagePath = avatarImagePath
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

        // 检查今天和昨天是否有记录
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let hasRecordToday = sortedDays.contains(today)
        let hasRecordYesterday = sortedDays.contains(yesterday)

        // 如果今天有记录，从今天开始往前计算连续天数
        if hasRecordToday {
            var streakCount = 0
            var currentDay = today

            while sortedDays.contains(currentDay) {
                streakCount += 1
                currentDay = calendar.date(byAdding: .day, value: -1, to: currentDay)!
            }

            return streakCount
        }
        // 如果今天没有记录但昨天有记录，保留昨天的连续天数
        else if hasRecordYesterday {
            var streakCount = 0
            var currentDay = yesterday

            while sortedDays.contains(currentDay) {
                streakCount += 1
                currentDay = calendar.date(byAdding: .day, value: -1, to: currentDay)!
            }

            return streakCount
        }
        // 如果今天和昨天都没有记录，重置为0
        else {
            return 0
        }
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
        "阅读「开车守则」，遵守交通规则，安全抵达目的地！"
    ]
    static let postDefaultTitles: [String] = [
        "检查车子的位置是否有问题",
        "关窗、锁门、熄火、防盗，确认停车🅿正常",
        "打开车子厂商的 app 再次确认车子情况",
        "如果陌生停车场，停车拍照 + 设置定位 + 手动记位置",
        "将本次\"失误–反思–改进\"条目补录到行车日记中",
        "记账 - 充电、加油、停车等费用"
    ]
}

// MARK: - DrivingRuleRepository Implementation
@MainActor
struct DrivingRuleRepositorySwiftData: DrivingRuleRepository {
    func fetchAll() throws -> [DrivingRule] {
        let ctx = try context()
        let rules = try ctx.fetch(FetchDescriptor<DrivingRule>())
        return rules.sorted { $0.sortOrder < $1.sortOrder }
    }

    func add(_ rule: DrivingRule) throws {
        let ctx = try context()
        ctx.insert(rule)
        try ctx.save()
    }

    func update(_ rule: DrivingRule, mutate: (DrivingRule) -> Void) throws {
        let ctx = try context()
        mutate(rule)
        rule.updatedAt = Date()
        try ctx.save()
    }

    func delete(_ rule: DrivingRule) throws {
        let ctx = try context()
        ctx.delete(rule)
        try ctx.save()
    }
}
