import Foundation
import SwiftUI
import Combine

@MainActor
final class ChecklistViewModel: ObservableObject {
    @Published private(set) var record: ChecklistRecord
    @Published var mode: Mode = .pre
    @Published private(set) var score: Int = 0

    private let repository: ChecklistRepository

    enum Mode { case pre, post }

    init(repository: ChecklistRepository) {
        self.repository = repository
        // Load or create
        if let existing = try? repository.todayRecord() { self.record = existing } else {
            self.record = ChecklistRecord(date: Calendar.current.startOfDay(for: Date()), pre: ChecklistConstants.preTemplate, post: ChecklistConstants.postTemplate, score: 0)
        }
        recalcScore()
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
}
