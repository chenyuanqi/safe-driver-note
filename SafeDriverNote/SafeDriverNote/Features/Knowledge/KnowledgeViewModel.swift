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
        
        // 发送通知，告知首页更新学习进度
        NotificationCenter.default.post(name: .knowledgeCardMarked, object: nil)
    }

    func snooze(card: KnowledgeCard) {
        today.removeAll { $0.id == card.id }
    }

    func syncRemote() async {
        do {
            try await AppDI.shared.knowledgeSyncService.sync()
            loadToday()
        } catch {
            // 简单忽略错误，实际可加入用户提示
        }
    }
}

// 扩展Notification.Name以添加自定义通知
extension Notification.Name {
    static let knowledgeCardMarked = Notification.Name("knowledgeCardMarked")
}