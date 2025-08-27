import Foundation
import SwiftData

// 简化的全局容器引用（MVP 阶段；后续可替换为依赖注入）
enum GlobalModelContext {
    static var container: ModelContainer?
    @MainActor static var context: ModelContext? { container?.mainContext }
}

enum SeedFlag {
    static let knowledge = "seed_knowledge_v2"
}

enum DataSeeder {
    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: SeedFlag.knowledge) else { return }
        
        // 扩展的知识卡片数据源，涵盖多个驾驶场景
        let cards: [KnowledgeCard] = [
            // 基础驾驶技能
            KnowledgeCard(id: "card_follow_distance", title: "安全跟车距离", what: "正常情况下保持3秒车距，恶劣天气增至5-6秒。", why: "包含观察、判断、制动时间与距离的安全余量。", how: "选路边参照物，前车过后心中数到'一千零三'，再到参照物。", tags: ["跟车", "安全距离"]),
            
            KnowledgeCard(id: "card_mirror_adjust", title: "后视镜正确调整", what: "内后视镜覆盖后窗，外后视镜减小盲区。", why: "减少变道与倒车盲区，避免剐蹭与并线事故。", how: "坐姿正确后调整；外后视镜略见车身；倒车时必要时下调。", tags: ["后视镜", "倒车"]),
            
            KnowledgeCard(id: "card_parking_skills", title: "停车入位技巧", what: "掌握侧方停车、倒车入库等基本停车技能。", why: "避免剐蹭，提高停车效率，保证车辆安全。", how: "利用后视镜观察，找准参照点，控制车速缓慢调整。", tags: ["停车", "倒车入库"]),
            
            // 恶劣天气驾驶
            KnowledgeCard(id: "card_rain_night", title: "雨夜行车要点", what: "降低车速、增大车距、避免急刹与猛打方向。", why: "湿滑路面制动距离增加，视线受限。", how: "开启近光灯与雾灯（视情况），保持5-6秒车距，轻柔操作。", tags: ["雨夜", "车距", "灯光"]),
            
            KnowledgeCard(id: "card_fog_driving", title: "雾天行车安全", what: "开启雾灯，降低车速，保持更大安全距离。", why: "雾天能见度极低，反应时间缩短，易发生追尾。", how: "开启前后雾灯和危险警示灯，跟随前车尾灯行驶，必要时靠边停车。", tags: ["雾天", "能见度", "雾灯"]),
            
            KnowledgeCard(id: "card_snow_ice", title: "雪地冰面驾驶", what: "换雪地胎，缓慢起步，提前制动，避免急转弯。", why: "路面附着力极低，车辆容易失控打滑。", how: "起步轻踩油门，制动提前且轻柔，转弯前提前减速，保持直线行驶。", tags: ["雪地", "冰面", "防滑"]),
            
            // 高速公路驾驶
            KnowledgeCard(id: "card_highway_merge", title: "高速匝道并入", what: "在加速车道充分加速，观察主车道车流，找准时机并入。", why: "速度差过大会造成追尾风险，影响主车道交通。", how: "加速至与主车道相近速度，打转向灯，观察后视镜，快速并入后关闭转向灯。", tags: ["高速", "并道", "加速"]),
            
            KnowledgeCard(id: "card_highway_exit", title: "高速公路出口", what: "提前观察路牌，提前变道至右侧车道，在减速车道减速。", why: "避免错过出口或在主车道急减速造成危险。", how: "距离出口2-3公里开始准备，提前变道，进入减速车道后再减速。", tags: ["高速", "出口", "变道"]),
            
            // 城市道路驾驶
            KnowledgeCard(id: "card_intersection_safety", title: "路口安全通行", what: "减速观察，让行优先车辆，确认安全后通过。", why: "路口是事故高发区，涉及多方向车流和行人。", how: "提前减速，观察左右来车，礼让直行车、右转车，确认行人通过后再行驶。", tags: ["路口", "让行", "观察"]),
            
            KnowledgeCard(id: "card_school_zone", title: "学校区域驾驶", what: "严格限速，注意儿童，随时准备停车。", why: "儿童行为不可预测，反应能力较弱。", how: "降至30km/h以下，扫视人行道，看到儿童立即减速，耐心等待。", tags: ["学校", "儿童", "限速"]),
            
            // 紧急情况处理
            KnowledgeCard(id: "card_tire_blowout", title: "轮胎爆胎处理", what: "握紧方向盘，避免急刹车，缓慢减速靠边停车。", why: "急刹车会导致车辆失控，增加事故风险。", how: "双手紧握方向盘，松油门让车自然减速，轻点刹车，打转向灯缓慢驶向应急车道。", tags: ["爆胎", "紧急", "应急"]),
            
            KnowledgeCard(id: "card_brake_failure", title: "刹车失灵应对", what: "连续踩刹车，拉手刹，利用发动机制动，寻找缓冲区。", why: "刹车失灵是严重的安全隐患，需要冷静应对。", how: "连续快速踩刹车尝试恢复，逐渐拉手刹，挂低档利用发动机制动，必要时选择安全区域摩擦减速。", tags: ["刹车", "故障", "制动"]),
            
            // 车辆保养知识
            KnowledgeCard(id: "card_tire_pressure", title: "轮胎气压检查", what: "定期检查轮胎气压，保持标准气压值。", why: "气压不足增加油耗，过高影响抓地力和舒适性。", how: "每月用气压表检查，参考车门贴纸标准值，冷胎时测量最准确。", tags: ["轮胎", "气压", "保养"]),
            
            KnowledgeCard(id: "card_oil_check", title: "机油液位检查", what: "定期检查机油液位，确保在标准范围内。", why: "机油不足会导致发动机磨损，过多影响性能。", how: "停车5分钟后，拔出机油尺，清洁后重新插入，查看液位在最高和最低刻度之间。", tags: ["机油", "发动机", "检查"]),
            
            // 驾驶心理与状态
            KnowledgeCard(id: "card_road_rage", title: "路怒症预防", what: "保持冷静心态，避免情绪化驾驶。", why: "愤怒情绪会影响判断力，增加事故风险。", how: "深呼吸调节情绪，播放舒缓音乐，给其他司机更多理解和耐心。", tags: ["情绪", "心态", "安全"]),
            
            KnowledgeCard(id: "card_fatigue_driving", title: "疲劳驾驶识别", what: "识别疲劳信号，及时休息，避免强行驾驶。", why: "疲劳驾驶反应迟钝，容易发生严重事故。", how: "感到困倦、频繁眨眼、注意力不集中时，立即找安全地点休息20-30分钟。", tags: ["疲劳", "休息", "安全"])
        ]
        
        cards.forEach { context.insert($0) }
        try? context.save()
        defaults.set(true, forKey: SeedFlag.knowledge)
    }
}