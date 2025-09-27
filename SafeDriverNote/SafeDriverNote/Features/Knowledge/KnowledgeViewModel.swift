import Foundation
import SwiftUI

@MainActor
final class KnowledgeViewModel: ObservableObject {
    @Published private(set) var today: [KnowledgeCard] = []
    @Published private(set) var allCards: [KnowledgeCard] = []
    @Published private(set) var learnedCountInCurrentSet: Int = 0

    private let repository: KnowledgeRepository

    // 知识页独立的抽取逻辑，与今日学习分离
    private let knowledgePageCardsKey = "KnowledgePageCards"
    private let knowledgePageLearnedCountKey = "KnowledgePageLearnedCount"

    init(repository: KnowledgeRepository) {
        self.repository = repository
        loadKnowledgePageCards()
        loadAllCards()
    }

    func loadKnowledgePageCards() {
        // 知识页独立的卡片抽取逻辑
        if let cards = try? repository.knowledgePageCards(limit: 3) {
            today = cards
        }

        // 加载当前这组卡片的学习进度
        loadLearnedCountForCurrentSet()
    }

    func loadAllCards() {
        if let cards = try? repository.allCards() {
            allCards = cards
        }
    }

    /// 根据卡片标题调整顺序，将指定标题的卡片移到第一位
    func prioritizeCard(withTitle title: String) {
        guard !today.isEmpty else { return }

        // 查找匹配标题的卡片
        if let index = today.firstIndex(where: { $0.title == title }), index != 0 {
            // 将该卡片移到数组第一位
            let card = today.remove(at: index)
            today.insert(card, at: 0)
        }
    }

    /// 获取指定标题卡片的索引
    func indexOfCard(withTitle title: String) -> Int? {
        return today.firstIndex(where: { $0.title == title })
    }

    func mark(card: KnowledgeCard) {
        try? repository.mark(cardId: card.id)
        today.removeAll { $0.id == card.id }

        // 更新当前组的学习计数
        learnedCountInCurrentSet += 1
        UserDefaults.standard.set(learnedCountInCurrentSet, forKey: knowledgePageLearnedCountKey)

        // 检查是否完成了3张，如果是则可以重新抽取
        if learnedCountInCurrentSet >= 3 {
            // 可以重新抽取新卡片
            refreshKnowledgePageCards()
        }

        // 发送通知，告知首页更新学习进度
        NotificationCenter.default.post(name: .knowledgeCardMarked, object: nil)
    }

    func snooze(card: KnowledgeCard) {
        today.removeAll { $0.id == card.id }
    }

    // 知识页专用的重新抽取方法
    func refreshKnowledgePageCards() {
        // 重置学习计数
        learnedCountInCurrentSet = 0
        UserDefaults.standard.set(0, forKey: knowledgePageLearnedCountKey)

        // 重新抽取卡片
        loadKnowledgePageCards()
    }

    // 检查是否可以重新抽取（学习了3张卡片）
    var canRefreshCards: Bool {
        return learnedCountInCurrentSet >= 3
    }

    // 加载当前组卡片的学习进度
    private func loadLearnedCountForCurrentSet() {
        learnedCountInCurrentSet = UserDefaults.standard.integer(forKey: knowledgePageLearnedCountKey)
    }

    func syncRemote() async {
        do {
            try await AppDI.shared.knowledgeSyncService.sync()
            loadKnowledgePageCards()
            loadAllCards()
        } catch {
            // 简单忽略错误，实际可加入用户提示
        }
    }
}

// 扩展Notification.Name以添加自定义通知
extension Notification.Name {
    static let knowledgeCardMarked = Notification.Name("knowledgeCardMarked")
}
