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

    // Custom items CRUD
    func fetchItems(mode: ChecklistMode?) throws -> [ChecklistItem]
    func addItem(_ item: ChecklistItem) throws
    func updateItem(_ item: ChecklistItem, mutate: (ChecklistItem) -> Void) throws
    func deleteItem(_ item: ChecklistItem) throws

    // Punch records
    func addPunch(mode: ChecklistMode, checkedItemIds: [UUID], isQuickComplete: Bool, score: Int, locationNote: String?) throws
    func fetchPunches(on date: Date, mode: ChecklistMode?) throws -> [ChecklistPunch]
    func fetchAllPunches(mode: ChecklistMode?) throws -> [ChecklistPunch]
    func deletePunch(_ punch: ChecklistPunch) throws
}

protocol KnowledgeRepository {
    func allCards() throws -> [KnowledgeCard]
    func todayCards(limit: Int) throws -> [KnowledgeCard]
    func knowledgePageCards(limit: Int) throws -> [KnowledgeCard]
    func mark(cardId: String) throws
    func upsert(cards: [KnowledgeCard]) throws
}

protocol DriveRouteRepository {
    func startRoute(startLocation: RouteLocation?) throws -> DriveRoute
    func getCurrentActiveRoute() throws -> DriveRoute?
    func endRoute(routeId: UUID, endLocation: RouteLocation?, waypoints: [RouteLocation]?) throws
    func fetchAllRoutes() throws -> [DriveRoute]
    func fetchRecentRoutes(limit: Int) throws -> [DriveRoute]
    func deleteRoute(_ route: DriveRoute) throws
    func updateRoute(_ route: DriveRoute, mutate: (DriveRoute) -> Void) throws
}

protocol UserProfileRepository {
    func fetchUserProfile() throws -> UserProfile
    func saveUserProfile(_ profile: UserProfile) throws
    func updateUserProfile(userName: String, userAge: Int?, drivingYears: Int, vehicleType: String, avatarImagePath: String?) throws -> UserProfile
    func calculateUserStats() throws -> UserStats
}
