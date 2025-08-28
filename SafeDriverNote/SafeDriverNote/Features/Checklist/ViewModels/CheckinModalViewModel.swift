import SwiftUI
import Foundation

@MainActor
final class CheckinModalViewModel: ObservableObject {
    @Published var selectedItemIds = Set<UUID>()
    private let items: [ChecklistItem]
    
    init(items: [ChecklistItem]) {
        self.items = items
    }
    
    func toggleItem(_ itemId: UUID) {
        if selectedItemIds.contains(itemId) {
            selectedItemIds.remove(itemId)
        } else {
            selectedItemIds.insert(itemId)
        }
    }
    
    func quickCompleteAll() {
        selectedItemIds = Set(items.map { $0.id })
    }
    
    func saveCheckin(mode: ChecklistViewModel.Mode, locationNote: String? = nil, onComplete: @escaping (ChecklistPunch) -> Void) {
        let isQuickComplete = selectedItemIds.count == items.count
        let score = calculateScore()
        
        let punch = ChecklistPunch(
            mode: mode == .pre ? .pre : .post,
            checkedItemIds: Array(selectedItemIds),
            isQuickComplete: isQuickComplete,
            score: score,
            locationNote: locationNote
        )
        
        onComplete(punch)
    }
    
    private func calculateScore() -> Int {
        guard !items.isEmpty else { return 0 }
        let completionRate = Double(selectedItemIds.count) / Double(items.count)
        return Int(completionRate * 100)
    }
}