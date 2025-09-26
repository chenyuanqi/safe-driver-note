import Foundation
import SwiftData

/// 统一管理今日学习内容的服务类
/// 确保首页和知识页显示相同的内容和顺序
@MainActor
class TodayLearningService: ObservableObject {
    static let shared = TodayLearningService()

    @Published private(set) var todayCards: [KnowledgeCard] = []
    @Published private(set) var learnedCount: Int = 0
    @Published private(set) var laterViewedCardIds: Set<String> = [] // 追踪"稍后看"的卡片

    private let knowledgeRepository = AppDI.shared.knowledgeRepository
    private var lastRefreshDate: Date?

    private init() {
        loadTodayCards()
    }

    /// 加载今日学习卡片
    func loadTodayCards() {
        let today = Calendar.current.startOfDay(for: Date())

        // 如果是同一天且已经有数据，则不重新加载（保持顺序一致性）
        if let lastDate = lastRefreshDate,
           Calendar.current.isDate(lastDate, inSameDayAs: today),
           !todayCards.isEmpty {
            updateLearnedCount()
            return
        }

        // 获取今日学习卡片（固定3张）
        if let cards = try? knowledgeRepository.todayCards(limit: 3) {
            todayCards = cards
            lastRefreshDate = today
            updateLearnedCount()
        } else {
            // 如果获取失败，使用默认数据确保一致性
            loadDefaultCards()
        }
    }

    /// 强制重新抽取今日卡片（重置当天的学习内容）
    func refreshTodayCards() {
        print("===== 开始重新抽取卡片 =====")
        print("清理前的状态:")
        print("- 当前卡片数: \(todayCards.count)")
        print("- 稍后看的卡片数: \(laterViewedCardIds.count)")

        // 清理今日的显示记录，允许重新抽取
        clearTodayShownRecords()

        // 清理"稍后看"的记录
        laterViewedCardIds.removeAll()

        lastRefreshDate = nil
        loadTodayCards()

        print("清理后的状态:")
        print("- 新卡片数: \(todayCards.count)")
        print("- 稍后看的卡片数: \(laterViewedCardIds.count)")
        print("=============================")

        // 通知其他地方更新
        NotificationCenter.default.post(name: .todayLearningRefreshed, object: nil)
    }

    /// 标记卡片为已学习
    func markCardAsLearned(_ card: KnowledgeCard) {
        // 获取或创建学习进度
        guard let context = GlobalModelContext.context else { return }

        let today = Date()
        let cardId = card.id
        var progress: KnowledgeProgress?

        // 查找现有进度
        let descriptor = FetchDescriptor<KnowledgeProgress>(
            predicate: #Predicate<KnowledgeProgress> { progress in
                progress.cardId == cardId
            }
        )

        if let existingProgress = try? context.fetch(descriptor).first {
            progress = existingProgress
        } else {
            // 创建新的进度记录
            progress = KnowledgeProgress(cardId: card.id)
            context.insert(progress!)
        }

        // 添加今天的学习日期
        progress?.markedDates.append(today)

        // 保存上下文
        try? context.save()

        // 更新学习计数
        updateLearnedCount()

        // 发送通知
        NotificationCenter.default.post(name: .knowledgeCardMarked, object: nil)
    }

    /// 标记卡片为稍后查看
    func markCardAsLaterViewed(_ card: KnowledgeCard) {
        laterViewedCardIds.insert(card.id)
        // 发送通知
        NotificationCenter.default.post(name: .knowledgeCardMarked, object: nil)
    }

    /// 检查卡片是否已学习
    func isCardLearned(_ card: KnowledgeCard) -> Bool {
        guard let context = GlobalModelContext.context else { return false }

        let cardId = card.id
        let descriptor = FetchDescriptor<KnowledgeProgress>(
            predicate: #Predicate<KnowledgeProgress> { progress in
                progress.cardId == cardId
            }
        )

        guard let progress = try? context.fetch(descriptor).first else { return false }

        let today = Calendar.current.startOfDay(for: Date())
        return progress.markedDates.contains { date in
            Calendar.current.isDate(date, inSameDayAs: today)
        }
    }

    /// 获取今日卡片在指定索引的卡片
    func cardAt(index: Int) -> KnowledgeCard? {
        guard index >= 0 && index < todayCards.count else { return nil }
        return todayCards[index]
    }

    /// 获取指定标题的卡片索引
    func indexOfCard(withTitle title: String) -> Int? {
        return todayCards.firstIndex { $0.title == title }
    }

    /// 检查是否所有卡片都已掌握或处理过（包括"稍后看"）
    var isAllCardsLearned: Bool {
        guard !todayCards.isEmpty else { return false }

        // 计算已处理的卡片数（掌握 + 稍后看）
        let processedCount = todayCards.reduce(0) { count, card in
            let isLearned = isCardLearned(card)
            let isLaterViewed = laterViewedCardIds.contains(card.id)
            return count + (isLearned || isLaterViewed ? 1 : 0)
        }

        return processedCount >= todayCards.count
    }

    // MARK: - Private Methods

    /// 更新已学习计数
    private func updateLearnedCount() {
        learnedCount = todayCards.reduce(0) { count, card in
            return count + (isCardLearned(card) ? 1 : 0)
        }
    }

    /// 清理今日的显示记录，允许重新抽取
    private func clearTodayShownRecords() {
        guard let context = GlobalModelContext.context else { return }

        let today = Calendar.current.startOfDay(for: Date())

        // 获取今日的显示记录
        let descriptor = FetchDescriptor<KnowledgeRecentlyShown>()
        if let allShownRecords = try? context.fetch(descriptor) {
            let todayRecords = allShownRecords.filter { record in
                Calendar.current.isDate(record.shownDate, inSameDayAs: today)
            }

            // 删除今日的显示记录
            for record in todayRecords {
                context.delete(record)
            }

            // 保存更改
            try? context.save()
            print("已清理今日显示记录 \(todayRecords.count) 条，准备重新抽取")
        }
    }

    /// 加载默认卡片（保证一致性）
    private func loadDefaultCards() {
        // 确保默认数据在所有地方都一致
        todayCards = [
            createMockCard(
                id: "default_1",
                title: "安全跟车距离",
                what: "保持3秒车距原则，在高速公路上应保持更长的跟车距离，确保有足够的反应时间。",
                why: "足够的跟车距离能够为驾驶员提供充分的反应时间，避免追尾事故的发生。特别是在高速行驶时，制动距离会显著增加。",
                how: "使用3秒法则：选择前车经过的固定参照物，数3秒后自己的车辆才通过该参照物。雨雾天气应延长至4-6秒。",
                tags: ["安全距离", "跟车", "防追尾"]
            ),
            createMockCard(
                id: "default_2",
                title: "雨天驾驶技巧",
                what: "雨天路面湿滑，要降低车速，保持更大的跟车距离，避免急刹车和急转弯。",
                why: "雨天路面摩擦系数降低，制动距离增加，车辆容易失控打滑。降低车速和保持距离是预防事故的关键。",
                how: "车速比平时降低20-30%，跟车距离增加一倍，轻踩刹车提前减速，避免急打方向盘，开启示宽灯增加可见性。",
                tags: ["雨天", "湿滑路面", "安全驾驶"]
            ),
            createMockCard(
                id: "default_3",
                title: "停车技巧",
                what: "倒车入库时要多观察后视镜，利用参照物判断车位，耐心慢速操作。",
                why: "准确的停车技能不仅体现驾驶水平，更能避免剐蹭事故，在狭窄空间中确保车辆和他人财产安全。",
                how: "先观察车位大小，选择合适入库角度，利用后视镜中的参照线，控制车速在5km/h以下，必要时多次调整。",
                tags: ["停车", "倒车入库", "技巧"]
            )
        ]
        lastRefreshDate = Calendar.current.startOfDay(for: Date())
        updateLearnedCount()
    }

    /// 创建模拟卡片
    private func createMockCard(id: String, title: String, what: String, why: String, how: String, tags: [String]) -> KnowledgeCard {
        let card = KnowledgeCard(id: id, title: title, what: what, why: why, how: how, tags: tags)
        return card
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let todayLearningRefreshed = Notification.Name("todayLearningRefreshed")
    static let todayLearningAllCompleted = Notification.Name("todayLearningAllCompleted")
}