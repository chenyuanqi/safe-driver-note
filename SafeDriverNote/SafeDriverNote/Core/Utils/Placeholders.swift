import Foundation
import SwiftData

// 简化的全局容器引用（MVP 阶段；后续可替换为依赖注入）
enum GlobalModelContext {
    static var container: ModelContainer?
    @MainActor static var context: ModelContext? { container?.mainContext }
}

enum SeedFlag {
    static let knowledge = "seed_knowledge_v1"
}

enum DataSeeder {
    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: SeedFlag.knowledge) else { return }
        // 基础知识卡（与 docs/samples/knowledge.json 对齐子集）
        let cards: [KnowledgeCard] = [
            KnowledgeCard(id: "card_follow_distance", title: "安全跟车距离", what: "正常情况下保持3秒车距，恶劣天气增至5-6秒。", why: "包含观察、判断、制动时间与距离的安全余量。", how: "选路边参照物，前车过后心中数到‘一千零三’，再到参照物。", tags: ["跟车", "安全距离"]),
            KnowledgeCard(id: "card_mirror_adjust", title: "后视镜正确调整", what: "内后视镜覆盖后窗，中外后视镜减小盲区。", why: "减少变道与倒车盲区，避免剐蹭与并线事故。", how: "坐姿正确后调整；外后视镜略见车身；倒车时必要时下调。", tags: ["后视镜", "倒车"]),
            KnowledgeCard(id: "card_rain_night", title: "雨夜行车要点", what: "降低车速、增大车距、避免急刹与猛打方向。", why: "湿滑路面制动距离增加，视线受限。", how: "开启近光灯与雾灯（视情况），保持 5-6 秒车距，轻柔操作。", tags: ["雨夜", "车距", "灯光"])
        ]
        cards.forEach { context.insert($0) }
        try? context.save()
        defaults.set(true, forKey: SeedFlag.knowledge)
    }
}
