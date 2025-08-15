import Foundation
import SwiftUI

@MainActor
final class KnowledgeViewModel: ObservableObject {
    @Published private(set) var today: [KnowledgeCard] = []
    private let repository: KnowledgeRepository

    init(repository: KnowledgeRepository) {
        self.repository = repository
        loadToday()
    }

    func loadToday() {
        if let cards = try? repository.todayCards(limit: 3) { today = cards }
    }

    func mark(card: KnowledgeCard) {
    try? repository.mark(cardId: card.id)
        today.removeAll { $0.id == card.id }
    }
}
