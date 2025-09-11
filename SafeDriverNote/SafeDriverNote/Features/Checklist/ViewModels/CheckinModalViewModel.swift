import SwiftUI
import Foundation

@MainActor
final class CheckinModalViewModel: ObservableObject {
    @Published var selectedItemIds = Set<UUID>()
    @Published var isSaving = false
    @Published var saveError: Error? = nil
    @Published var showRetryAlert = false
    
    private let items: [ChecklistItem]
    private var pendingPunch: ChecklistPunch?
    private var pendingCompletion: ((ChecklistPunch) -> Void)?
    
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
        
        // 保存待处理的打卡记录和完成回调
        self.pendingPunch = punch
        self.pendingCompletion = onComplete
        
        // 开始保存过程
        savePunchInternal()
    }
    
    private func savePunchInternal() {
        guard let punch = pendingPunch, let completion = pendingCompletion else { return }
        
        isSaving = true
        saveError = nil
        
        // 在实际应用中，这里会调用真正的保存逻辑
        // 目前我们简化处理，直接完成保存
        Task {
            // 模拟网络延迟
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            await MainActor.run {
                isSaving = false
                completion(punch)
            }
        }
    }
    
    func retrySave() {
        if pendingPunch != nil && pendingCompletion != nil {
            savePunchInternal()
        }
    }
    
    func cancelSave() {
        isSaving = false
        saveError = nil
        pendingPunch = nil
        pendingCompletion = nil
    }
    
    private func calculateScore() -> Int {
        guard !items.isEmpty else { return 0 }
        let completionRate = Double(selectedItemIds.count) / Double(items.count)
        return Int(completionRate * 100)
    }
}