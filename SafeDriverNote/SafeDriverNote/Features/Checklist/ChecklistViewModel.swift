import Foundation
import SwiftUI
import Combine

@MainActor
final class ChecklistViewModel: ObservableObject {
    @Published private(set) var record: ChecklistRecord
    @Published var mode: Mode = .pre
    @Published private(set) var score: Int = 0

    private let repository: ChecklistRepository
    @Published private(set) var itemsPre: [ChecklistItem] = []
    @Published private(set) var itemsPost: [ChecklistItem] = []
    @Published private(set) var punchesTodayPre: [ChecklistPunch] = []
    @Published private(set) var punchesTodayPost: [ChecklistPunch] = []

    enum Mode { case pre, post }

    init(repository: ChecklistRepository) {
        self.repository = repository
        // Load or create
        if let existing = try? repository.todayRecord() { self.record = existing } else {
            self.record = ChecklistRecord(date: Calendar.current.startOfDay(for: Date()), pre: ChecklistConstants.preTemplate, post: ChecklistConstants.postTemplate, score: 0)
        }
        recalcScore()
        reloadItems()
        reloadPunchesToday()

        // 如首次使用，自动种子默认自定义项（各自一遍）
        if (itemsPre.isEmpty && itemsPost.isEmpty) {
            ChecklistConstants.preDefaultTitles.forEach { title in
                try? repository.addItem(ChecklistItem(title: title, mode: .pre))
            }
            ChecklistConstants.postDefaultTitles.forEach { title in
                try? repository.addItem(ChecklistItem(title: title, mode: .post))
            }
            reloadItems()
        }
    }

    func toggle(item key: String) {
        switch mode {
        case .pre:
            if let idx = record.pre.firstIndex(where: { $0.key == key }) { record.pre[idx].checked.toggle() }
        case .post:
            if let idx = record.post.firstIndex(where: { $0.key == key }) { record.post[idx].checked.toggle() }
        }
        recalcScore()
        _ = try? repository.upsertToday { draft in
            draft.pre = record.pre
            draft.post = record.post
            draft.score = score
        }
    }

    private func recalcScore() {
        let total = record.pre.count + record.post.count
        let checked = record.pre.filter { $0.checked }.count + record.post.filter { $0.checked }.count
        score = Int((Double(checked) / Double(total)) * 100.0 + 0.5)
        record.score = score
    }

    // MARK: Items Management
    func reloadItems() {
        itemsPre = (try? repository.fetchItems(mode: .pre)) ?? []
        itemsPost = (try? repository.fetchItems(mode: .post)) ?? []
    }
    func addItem(title: String, mode: Mode) {
        // 新增项排在末尾：设置 sortOrder 为当前末尾 + 1
        let targetList = (mode == .pre ? itemsPre : itemsPost)
        let nextOrder = (targetList.compactMap { $0.sortOrder }.max() ?? 0) + 1
        let item = ChecklistItem(title: title, mode: mode == .pre ? .pre : .post, isPinned: false, sortOrder: nextOrder)
        try? repository.addItem(item)
        reloadItems()
    }
    func editItem(_ item: ChecklistItem, newTitle: String) {
        try? repository.updateItem(item) { it in it.title = newTitle }
        reloadItems()
    }
    func deleteItem(_ item: ChecklistItem) {
        try? repository.deleteItem(item)
        reloadItems()
    }

    // MARK: Pin & Reorder
    func togglePin(_ item: ChecklistItem) {
        try? repository.updateItem(item) { it in it.isPinned = !(it.isPinned ?? false) }
        reloadItems()
    }

    func moveItemsPre(from source: IndexSet, to destination: Int) {
        var arr = itemsPre
        arr.move(fromOffsets: source, toOffset: destination)
        persistOrder(arr: arr)
    }
    func moveItemsPost(from source: IndexSet, to destination: Int) {
        var arr = itemsPost
        arr.move(fromOffsets: source, toOffset: destination)
        persistOrder(arr: arr)
    }

    private func persistOrder(arr: [ChecklistItem]) {
        for (idx, item) in arr.enumerated() {
            try? repository.updateItem(item) { it in it.sortOrder = idx }
        }
        reloadItems()
    }

    // MARK: Punch
    func punch(selectedItemIds: [UUID], locationNote: String? = nil) {
        try? repository.addPunch(
            mode: mode == .pre ? .pre : .post, 
            checkedItemIds: selectedItemIds,
            isQuickComplete: false,
            score: selectedItemIds.count * 10, // 简单的计分逻辑
            locationNote: locationNote
        )
        reloadPunchesToday()
    }

    func reloadPunchesToday() {
        let today = Date()
        punchesTodayPre = (try? repository.fetchPunches(on: today, mode: .pre)) ?? []
        punchesTodayPost = (try? repository.fetchPunches(on: today, mode: .post)) ?? []
    }

    var punchesForCurrentMode: [ChecklistPunch] {
        mode == .pre ? punchesTodayPre : punchesTodayPost
    }

    func titles(for punch: ChecklistPunch) -> [String] {
        let dict: [UUID:String] = Dictionary(uniqueKeysWithValues: (itemsPre + itemsPost).map { ($0.id, $0.title) })
        return punch.checkedItemIds.compactMap { dict[$0] }
    }
    
    // MARK: - New Methods for Enhanced Functionality
    
    /// Save a punch record
    func savePunch(_ punch: ChecklistPunch) {
        try? repository.addPunch(
            mode: punch.mode, 
            checkedItemIds: punch.checkedItemIds,
            isQuickComplete: punch.isQuickComplete,
            score: punch.score,
            locationNote: punch.locationNote
        )
        reloadPunchesToday()
    }
    
    /// Save items for a specific mode
    func saveItems(_ items: [ChecklistItem], for mode: Mode) {
        // First delete existing items for this mode
        let existingItems = mode == .pre ? itemsPre : itemsPost
        for item in existingItems {
            try? repository.deleteItem(item)
        }
        
        // Then add new items
        for item in items {
            try? repository.addItem(item)
        }
        
        reloadItems()
    }
    
    /// Get daily summary for today
    func getDailySummary() -> DailyCheckinSummary {
        let preSummaries = punchesTodayPre.map { punch in
            ChecklistPunchSummary(
                id: punch.id,
                createdAt: punch.createdAt,
                mode: punch.mode,
                checkedItemIds: punch.checkedItemIds,
                isQuickComplete: punch.isQuickComplete,
                score: punch.score,
                locationNote: punch.locationNote
            )
        }
        
        let postSummaries = punchesTodayPost.map { punch in
            ChecklistPunchSummary(
                id: punch.id,
                createdAt: punch.createdAt,
                mode: punch.mode,
                checkedItemIds: punch.checkedItemIds,
                isQuickComplete: punch.isQuickComplete,
                score: punch.score,
                locationNote: punch.locationNote
            )
        }
        
        return DailyCheckinSummary(
            date: Date(),
            prePunches: preSummaries,
            postPunches: postSummaries
        )
    }
    
    /// Get items for current mode
    var currentModeItems: [ChecklistItem] {
        return mode == .pre ? itemsPre : itemsPost
    }
}
