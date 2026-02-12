import Foundation
import SwiftData

// 简化的全局容器引用（MVP 阶段；后续可替换为依赖注入）
enum GlobalModelContext {
    static var container: ModelContainer?
    @MainActor static var context: ModelContext? { container?.mainContext }
}

enum SeedFlag {
    static let knowledge = "seed_knowledge_v3"
}

enum DataSeeder {
    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: SeedFlag.knowledge) else { return }

        // 扩展的知识卡片数据源，涵盖多个驾驶场景
        let cards: [KnowledgeCard] = [
            // ========== 基础驾驶技能 ==========
            KnowledgeCard(id: "card_follow_distance", title: "安全跟车距离", what: "正常情况下保持3秒车距，恶劣天气增至5-6秒。", why: "包含观察、判断、制动时间与距离的安全余量。", how: "选路边参照物，前车过后心中数到'一千零三'，再到参照物。", tags: ["跟车", "安全距离"]),

            KnowledgeCard(id: "card_mirror_adjust", title: "后视镜正确调整", what: "内后视镜覆盖后窗，外后视镜减小盲区。", why: "减少变道与倒车盲区，避免剐蹭与并线事故。", how: "坐姿正确后调整；外后视镜略见车身；倒车时必要时下调。", tags: ["后视镜", "倒车"]),

            KnowledgeCard(id: "card_parking_skills", title: "停车入位技巧", what: "掌握侧方停车、倒车入库等基本停车技能。", why: "避免剐蹭，提高停车效率，保证车辆安全。", how: "利用后视镜观察，找准参照点，控制车速缓慢调整。", tags: ["停车", "倒车入库"]),

            KnowledgeCard(id: "card_steering_grip", title: "方向盘正确握法", what: "双手握在9点和3点位置，拇指放在方向盘外侧。", why: "提供最佳控制力，紧急情况下能快速反应。", how: "坐姿端正，手臂微曲，转向时推拉操作，避免单手或掏轮。", tags: ["方向盘", "驾驶姿势"]),

            KnowledgeCard(id: "card_smooth_driving", title: "平稳驾驶技巧", what: "油门、刹车、转向都要柔和渐进，避免突然操作。", why: "提高乘坐舒适性，减少车辆磨损，降低油耗。", how: "提前预判路况，轻踩油门加速，提前松油门滑行，刹车分段轻踩。", tags: ["平稳", "舒适性"]),

            KnowledgeCard(id: "card_blind_spot", title: "盲区意识培养", what: "了解车辆周围的盲区位置，变道前回头确认。", why: "后视镜无法覆盖所有区域，盲区内的车辆或行人容易被忽视。", how: "变道前先看后视镜，再快速回头看盲区，确认安全后再变道。", tags: ["盲区", "变道", "安全"]),

            KnowledgeCard(id: "card_defensive_driving", title: "防御性驾驶", what: "预判其他车辆可能的危险行为，提前做好应对准备。", why: "不能假设其他司机都会遵守规则，要为他人的错误留出余地。", how: "保持安全距离，观察周围车辆动态，预判可能的变道或急刹，随时准备应对。", tags: ["防御性驾驶", "预判", "安全"]),

            // ========== 恶劣天气驾驶 ==========
            KnowledgeCard(id: "card_rain_night", title: "雨夜行车要点", what: "降低车速、增大车距、避免急刹与猛打方向。", why: "湿滑路面制动距离增加，视线受限。", how: "开启近光灯与雾灯（视情况），保持5-6秒车距，轻柔操作。", tags: ["雨夜", "车距", "灯光"]),

            KnowledgeCard(id: "card_fog_driving", title: "雾天行车安全", what: "开启雾灯，降低车速，保持更大安全距离。", why: "雾天能见度极低，反应时间缩短，易发生追尾。", how: "开启前后雾灯和危险警示灯，跟随前车尾灯行驶，必要时靠边停车。", tags: ["雾天", "能见度", "雾灯"]),

            KnowledgeCard(id: "card_snow_ice", title: "雪地冰面驾驶", what: "换雪地胎，缓慢起步，提前制动，避免急转弯。", why: "路面附着力极低，车辆容易失控打滑。", how: "起步轻踩油门，制动提前且轻柔，转弯前提前减速，保持直线行驶。", tags: ["雪地", "冰面", "防滑"]),

            KnowledgeCard(id: "card_heavy_rain", title: "暴雨行车", what: "遇暴雨能见度低于50米时，应开启危险警示灯并靠边停车。", why: "暴雨导致视线极差，路面积水可能导致失控。", how: "降低车速至30km/h以下，避开积水路段，必要时找安全地点停车等待。", tags: ["暴雨", "积水", "停车"]),

            KnowledgeCard(id: "card_aquaplaning", title: "水滑现象应对", what: "车辆在积水路面失去抓地力，方向盘变轻。", why: "轮胎与路面之间形成水膜，失去摩擦力。", how: "松开油门，不要急刹车或急转向，握稳方向盘，等待车速自然降低恢复抓地力。", tags: ["积水", "水滑", "失控"]),

            KnowledgeCard(id: "card_strong_wind", title: "大风天气驾驶", what: "注意侧风影响，降低车速，双手握稳方向盘。", why: "侧风会推动车辆偏离车道，尤其在高速和空旷路段。", how: "降低车速，预判风向，提前微调方向盘，经过桥梁和山口时格外小心。", tags: ["大风", "侧风", "方向控制"]),

            KnowledgeCard(id: "card_hail_driving", title: "冰雹天气应对", what: "遇冰雹立即寻找遮蔽物停车，避免继续行驶。", why: "冰雹会损坏车辆外观，影响视线，危及安全。", how: "找桥下、加油站、地下车库等遮蔽处停车，关闭空调外循环，等待冰雹结束。", tags: ["冰雹", "停车", "遮蔽"]),

            // ========== 夜间驾驶 ==========
            KnowledgeCard(id: "card_night_visibility", title: "夜间视线管理", what: "合理使用灯光，避免疲劳，注意观察路边。", why: "夜间视线受限，距离判断困难，易疲劳。", how: "开启近光灯，会车时切换远近光，定期休息，注意路边行人和动物。", tags: ["夜间", "视线", "灯光"]),

            KnowledgeCard(id: "card_headlight_glare", title: "对向车灯眩光", what: "遇对向远光灯时，视线右移，减速慢行。", why: "强光会造成短暂失明，无法看清路况。", how: "视线移向右侧路沿，用余光观察，减速慢行，不要用远光灯报复。", tags: ["眩光", "远光灯", "夜间"]),

            KnowledgeCard(id: "card_night_speed", title: "夜间速度控制", what: "夜间行车速度应比白天降低10-20%。", why: "视线受限，反应时间需要更长，突发情况难以应对。", how: "根据灯光照射范围控制车速，确保能在可见范围内停车。", tags: ["夜间", "速度", "安全"]),

            KnowledgeCard(id: "card_night_fatigue", title: "夜间疲劳预防", what: "夜间驾驶更易疲劳，需要更频繁的休息。", why: "人体生物钟在夜间倾向于休息，注意力下降。", how: "每1-2小时休息一次，开窗通风，播放节奏明快的音乐，感到困倦立即停车。", tags: ["夜间", "疲劳", "休息"]),

            KnowledgeCard(id: "card_night_pedestrian", title: "夜间行人识别", what: "夜间特别注意穿深色衣服的行人和骑车人。", why: "深色衣物在夜间难以识别，容易发生事故。", how: "降低车速，注意路边阴影，看到反光物体立即减速，经过路口格外小心。", tags: ["夜间", "行人", "识别"]),

            // ========== 高速公路驾驶 ==========
            KnowledgeCard(id: "card_highway_merge", title: "高速匝道并入", what: "在加速车道充分加速，观察主车道车流，找准时机并入。", why: "速度差过大会造成追尾风险，影响主车道交通。", how: "加速至与主车道相近速度，打转向灯，观察后视镜，快速并入后关闭转向灯。", tags: ["高速", "并道", "加速"]),

            KnowledgeCard(id: "card_highway_exit", title: "高速公路出口", what: "提前观察路牌，提前变道至右侧车道，在减速车道减速。", why: "避免错过出口或在主车道急减速造成危险。", how: "距离出口2-3公里开始准备，提前变道，进入减速车道后再减速。", tags: ["高速", "出口", "变道"]),

            KnowledgeCard(id: "card_highway_lane", title: "高速车道选择", what: "根据车速选择合适车道，慢车靠右，超车用左道。", why: "车道使用不当会影响交通流，增加事故风险。", how: "正常行驶走中间车道，超车时用左侧车道，超车后及时回到原车道。", tags: ["高速", "车道", "超车"]),

            KnowledgeCard(id: "card_highway_distance", title: "高速安全距离", what: "时速100km/h时保持100米以上车距。", why: "高速行驶制动距离长，需要更大的安全余量。", how: "用车速数字作为车距米数参考，恶劣天气加倍，观察地面标线辅助判断。", tags: ["高速", "车距", "安全"]),

            KnowledgeCard(id: "card_highway_rest", title: "高速休息规划", what: "每2小时或200公里休息一次，每次15-20分钟。", why: "长时间高速行驶易疲劳，注意力下降。", how: "提前规划服务区位置，到达后下车活动，喝水进食，不要在应急车道休息。", tags: ["高速", "休息", "疲劳"]),

            KnowledgeCard(id: "card_highway_emergency", title: "高速应急处理", what: "车辆故障时，开启危险警示灯，驶入应急车道，放置警告标志。", why: "高速路上停车极度危险，必须做好警示。", how: "打开双闪，缓慢驶入应急车道，人员撤离到护栏外，在车后150米处放置三角警告牌。", tags: ["高速", "故障", "应急"]),

            // ========== 隧道与桥梁 ==========
            KnowledgeCard(id: "card_tunnel_entry", title: "隧道入口减速", what: "进入隧道前减速，开启近光灯，摘下墨镜。", why: "隧道内外光线差异大，眼睛需要适应时间。", how: "提前减速至限速，开启近光灯，摘下墨镜，保持车距，不要变道。", tags: ["隧道", "灯光", "减速"]),

            KnowledgeCard(id: "card_tunnel_driving", title: "隧道内行驶", what: "保持车距，不随意变道，注意限速标志。", why: "隧道内空间受限，视线受限，事故后果严重。", how: "跟随前车保持安全距离，不要超车，注意观察路面和标志，保持匀速。", tags: ["隧道", "车距", "限速"]),

            KnowledgeCard(id: "card_tunnel_exit", title: "隧道出口注意", what: "出隧道时注意强光刺激，不要急加速。", why: "突然的强光会造成短暂失明，容易发生事故。", how: "提前预判出口位置，眯眼适应光线，保持车速，出口后再加速。", tags: ["隧道", "出口", "光线"]),

            KnowledgeCard(id: "card_bridge_wind", title: "桥梁侧风应对", what: "过桥时注意侧风，降低车速，握稳方向盘。", why: "桥面空旷，侧风强劲，容易推动车辆偏离。", how: "提前减速，双手握稳方向盘，预判风向，微调方向保持直线。", tags: ["桥梁", "侧风", "方向"]),

            KnowledgeCard(id: "card_bridge_ice", title: "桥面结冰警惕", what: "冬季桥面比普通路面更易结冰，需格外小心。", why: "桥面上下都是空气，散热快，温度低于路面。", how: "看到桥梁标志提前减速，轻踩刹车测试路面，避免急刹和急转向。", tags: ["桥梁", "结冰", "冬季"]),

            // ========== 山路驾驶 ==========
            KnowledgeCard(id: "card_mountain_uphill", title: "山路上坡技巧", what: "保持动力，选择合适档位，不要中途停车。", why: "上坡需要持续动力，中途停车再起步困难。", how: "提前降档保持转速，匀速上坡，避免急加速，预判坡顶情况。", tags: ["山路", "上坡", "档位"]),

            KnowledgeCard(id: "card_mountain_downhill", title: "山路下坡控制", what: "使用发动机制动，避免长时间踩刹车。", why: "长时间刹车会导致刹车过热失效，极度危险。", how: "挂低档利用发动机制动，间歇性轻踩刹车，避免空档滑行。", tags: ["山路", "下坡", "制动"]),

            KnowledgeCard(id: "card_mountain_curve", title: "山路弯道驾驶", what: "弯前减速，弯中保持，弯后加速。", why: "弯道中刹车或加速会导致车辆失控。", how: "进弯前减速到安全速度，转向时保持匀速，出弯后再加速。", tags: ["山路", "弯道", "速度"]),

            KnowledgeCard(id: "card_mountain_meeting", title: "山路会车规则", what: "上坡车优先，下坡车让行，靠山一侧让行。", why: "上坡车起步困难，下坡车控制相对容易。", how: "下坡时遇会车提前减速靠右，必要时停车让行，等上坡车通过后再行驶。", tags: ["山路", "会车", "让行"]),

            KnowledgeCard(id: "card_mountain_brake", title: "山路刹车保养", what: "长下坡后检查刹车温度，必要时停车冷却。", why: "刹车过热会导致制动力下降甚至失效。", how: "下坡后找安全地点停车，不要立即洗车，等待刹车自然冷却10-15分钟。", tags: ["山路", "刹车", "保养"]),

            // ========== 城市道路驾驶 ==========
            KnowledgeCard(id: "card_intersection_safety", title: "路口安全通行", what: "减速观察，让行优先车辆，确认安全后通过。", why: "路口是事故高发区，涉及多方向车流和行人。", how: "提前减速，观察左右来车，礼让直行车、右转车，确认行人通过后再行驶。", tags: ["路口", "让行", "观察"]),

            KnowledgeCard(id: "card_school_zone", title: "学校区域驾驶", what: "严格限速，注意儿童，随时准备停车。", why: "儿童行为不可预测，反应能力较弱。", how: "降至30km/h以下，扫视人行道，看到儿童立即减速，耐心等待。", tags: ["学校", "儿童", "限速"]),

            KnowledgeCard(id: "card_traffic_light", title: "红绿灯路口技巧", what: "绿灯闪烁不抢行，黄灯亮起不加速，红灯停车不越线。", why: "抢行和闯黄灯是路口事故的主要原因。", how: "绿灯闪烁时减速准备停车，黄灯亮起立即刹车，红灯时停在停止线后。", tags: ["红绿灯", "路口", "规则"]),

            KnowledgeCard(id: "card_pedestrian_crossing", title: "人行横道礼让", what: "遇人行横道减速，有行人时必须停车让行。", why: "行人拥有绝对优先权，不让行违法且危险。", how: "提前减速，观察两侧行人，有人等待或通过时停车让行，确认安全后再通过。", tags: ["人行横道", "行人", "礼让"]),

            KnowledgeCard(id: "card_narrow_street", title: "狭窄街道通行", what: "降低车速，注意两侧，必要时停车让行。", why: "狭窄街道容易发生剐蹭和与行人的冲突。", how: "减速至20km/h以下，收起后视镜，观察两侧距离，遇对向车辆主动让行。", tags: ["狭窄", "街道", "让行"]),

            KnowledgeCard(id: "card_parking_lot", title: "停车场安全", what: "低速行驶，注意倒车车辆和行人，倒车时多次确认。", why: "停车场空间狭小，视线受阻，事故频发。", how: "车速控制在10km/h以下，看到倒车灯立即停车，倒车时反复确认周围。", tags: ["停车场", "倒车", "行人"]),

            KnowledgeCard(id: "card_residential_area", title: "住宅区驾驶", what: "低速慢行，注意儿童和宠物，避免鸣笛。", why: "住宅区人员活动频繁，需要格外小心。", how: "车速不超过20km/h，注意楼栋出口，看到儿童或宠物立即停车，避免噪音扰民。", tags: ["住宅区", "低速", "安静"]),

            // ========== 行人与非机动车 ==========
            KnowledgeCard(id: "card_cyclist_safety", title: "与自行车共处", what: "超越自行车时保持1.5米以上横向距离。", why: "自行车容易突然摇晃或转向，需要足够安全空间。", how: "提前减速，确认对向无来车，保持足够距离超越，不要鸣笛惊吓。", tags: ["自行车", "超车", "距离"]),

            KnowledgeCard(id: "card_motorcycle_awareness", title: "摩托车注意事项", what: "注意盲区中的摩托车，变道前仔细确认。", why: "摩托车体积小速度快，容易被忽视。", how: "变道前多看几次后视镜，回头确认盲区，给摩托车留出足够空间。", tags: ["摩托车", "盲区", "变道"]),

            KnowledgeCard(id: "card_electric_bike", title: "电动车防范", what: "路口和路边特别注意突然出现的电动车。", why: "电动车速度快且无声，经常不遵守交通规则。", how: "路口减速观察，注意路边电动车动向，预判可能的违规行为，保持安全距离。", tags: ["电动车", "路口", "预判"]),

            KnowledgeCard(id: "card_elderly_pedestrian", title: "老年行人关注", what: "遇老年人过马路时，耐心等待，不要催促。", why: "老年人行动缓慢，反应迟钝，容易受惊。", how: "提前减速停车，保持耐心，不要鸣笛，等待完全通过后再起步。", tags: ["老年人", "行人", "耐心"]),

            KnowledgeCard(id: "card_child_safety", title: "儿童安全防护", what: "看到儿童立即减速，预判可能的突然行为。", why: "儿童缺乏安全意识，行为不可预测。", how: "看到儿童降至20km/h以下，注意是否有其他儿童，随时准备紧急制动。", tags: ["儿童", "减速", "预判"]),

            // ========== 大型车辆 ==========
            KnowledgeCard(id: "card_truck_blind_spot", title: "大货车盲区", what: "远离大货车，不要长时间并行或跟随。", why: "大货车盲区大，制动距离长，转弯时容易卷入。", how: "超越时快速通过，不要在两侧并行，保持3倍以上车距，转弯时远离内侧。", tags: ["大货车", "盲区", "危险"]),

            KnowledgeCard(id: "card_bus_safety", title: "公交车注意", what: "公交车起步时主动让行，注意下车乘客。", why: "公交车体积大，起步慢，下车乘客可能横穿马路。", how: "看到公交车打转向灯主动减速让行，经过停靠站时注意下车乘客。", tags: ["公交车", "让行", "乘客"]),

            KnowledgeCard(id: "card_truck_overtake", title: "超越大货车", what: "确认安全后快速超越，不要犹豫。", why: "长时间与大货车并行危险，要么超越要么跟随。", how: "提前观察，确认对向无车，打转向灯，加速快速超越，超越后保持距离再变回。", tags: ["大货车", "超车", "快速"]),

            // ========== 车辆技术 ==========
            KnowledgeCard(id: "card_abs_usage", title: "ABS正确使用", what: "紧急制动时全力踩下刹车，不要松开。", why: "ABS会自动调节制动力，松开会降低制动效果。", how: "紧急情况全力踩死刹车，感受踏板震动，保持踩下直到停车。", tags: ["ABS", "制动", "技术"]),

            KnowledgeCard(id: "card_esp_function", title: "ESP车身稳定", what: "ESP灯闪烁说明车辆接近失控，应立即减速。", why: "ESP在纠正车辆姿态，说明驾驶超出安全范围。", how: "看到ESP灯闪烁立即松油门，不要急刹车或急转向，让车辆恢复稳定。", tags: ["ESP", "稳定", "失控"]),

            KnowledgeCard(id: "card_cruise_control", title: "定速巡航使用", what: "在高速公路平直路段使用，复杂路况关闭。", why: "定速巡航无法应对复杂路况，可能造成危险。", how: "高速平直路段开启，遇弯道、雨雪、车多时关闭，随时准备接管控制。", tags: ["定速巡航", "高速", "使用"]),

            KnowledgeCard(id: "card_parking_sensor", title: "倒车雷达辅助", what: "倒车雷达是辅助工具，不能完全依赖。", why: "雷达有盲区，低矮物体和细杆可能探测不到。", how: "倒车时结合雷达和后视镜，低速缓慢，必要时下车查看。", tags: ["倒车雷达", "辅助", "倒车"]),

            KnowledgeCard(id: "card_blind_spot_monitor", title: "盲区监测系统", what: "盲区监测提示时不要变道，但仍需回头确认。", why: "系统可能误报或漏报，人工确认更安全。", how: "看到盲区警告灯不要变道，即使没有警告也要回头确认后再变道。", tags: ["盲区监测", "变道", "辅助"]),

            KnowledgeCard(id: "card_lane_assist", title: "车道保持辅助", what: "车道保持是辅助功能，驾驶员需保持注意力。", why: "系统无法应对所有情况，驾驶员仍需主动控制。", how: "开启后仍需双手握方向盘，注意观察路况，随时准备接管。", tags: ["车道保持", "辅助", "注意力"]),

            KnowledgeCard(id: "card_auto_brake", title: "自动刹车系统", what: "自动刹车是最后防线，不能依赖它避免事故。", why: "系统有局限性，可能无法识别所有障碍物。", how: "保持安全距离和注意力，把自动刹车当作备用，不要测试它的极限。", tags: ["自动刹车", "辅助", "安全"]),

            // ========== 紧急情况处理 ==========
            KnowledgeCard(id: "card_tire_blowout", title: "轮胎爆胎处理", what: "握紧方向盘，避免急刹车，缓慢减速靠边停车。", why: "急刹车会导致车辆失控，增加事故风险。", how: "双手紧握方向盘，松油门让车自然减速，轻点刹车，打转向灯缓慢驶向应急车道。", tags: ["爆胎", "紧急", "应急"]),

            KnowledgeCard(id: "card_brake_failure", title: "刹车失灵应对", what: "连续踩刹车，拉手刹，利用发动机制动，寻找缓冲区。", why: "刹车失灵是严重的安全隐患，需要冷静应对。", how: "连续快速踩刹车尝试恢复，逐渐拉手刹，挂低档利用发动机制动，必要时选择安全区域摩擦减速。", tags: ["刹车", "故障", "制动"]),

            KnowledgeCard(id: "card_engine_fire", title: "发动机起火", what: "立即停车熄火，人员撤离，使用灭火器扑救。", why: "汽车火灾蔓延快，人员安全第一。", how: "靠边停车熄火，人员远离车辆，用灭火器对准火源根部扑救，火势大时立即报警撤离。", tags: ["起火", "灭火器", "紧急"]),

            KnowledgeCard(id: "card_water_crossing", title: "涉水行驶", what: "不明水深不要冒险，涉水时低档匀速通过。", why: "水深超过进气口会导致发动机损坏。", how: "观察其他车辆通过情况，确认水深低于半个轮胎，挂低档匀速通过，不要停车或熄火。", tags: ["涉水", "积水", "发动机"]),

            KnowledgeCard(id: "card_accident_scene", title: "事故现场处理", what: "确保安全，保护现场，及时报警，救助伤员。", why: "正确处理事故现场关系到责任认定和人员安全。", how: "开启双闪，放置警告标志，拍照记录，报警，有伤员先救人，轻微事故快速撤离。", tags: ["事故", "现场", "处理"]),

            KnowledgeCard(id: "card_steering_failure", title: "转向失灵应对", what: "保持冷静，使用手刹减速，寻找安全停车位置。", why: "转向失灵极度危险，需要立即采取措施。", how: "不要急刹车，逐渐拉手刹减速，利用路边护栏或缓冲区停车，开启双闪警示。", tags: ["转向", "故障", "紧急"]),

            KnowledgeCard(id: "card_hood_open", title: "行驶中引擎盖打开", what: "不要急刹车，从车窗或缝隙观察，缓慢靠边停车。", why: "引擎盖遮挡视线，急刹车可能导致追尾。", how: "保持冷静，从侧窗观察路况，打开双闪，缓慢减速靠边，停车后关闭引擎盖。", tags: ["引擎盖", "视线", "紧急"]),

            // ========== 车辆保养知识 ==========
            KnowledgeCard(id: "card_tire_pressure", title: "轮胎气压检查", what: "定期检查轮胎气压，保持标准气压值。", why: "气压不足增加油耗，过高影响抓地力和舒适性。", how: "每月用气压表检查，参考车门贴纸标准值，冷胎时测量最准确。", tags: ["轮胎", "气压", "保养"]),

            KnowledgeCard(id: "card_oil_check", title: "机油液位检查", what: "定期检查机油液位，确保在标准范围内。", why: "机油不足会导致发动机磨损，过多影响性能。", how: "停车5分钟后，拔出机油尺，清洁后重新插入，查看液位在最高和最低刻度之间。", tags: ["机油", "发动机", "检查"]),

            KnowledgeCard(id: "card_tire_wear", title: "轮胎磨损检查", what: "定期检查轮胎花纹深度，磨损严重及时更换。", why: "花纹过浅会降低抓地力，雨天易打滑。", how: "用硬币插入花纹，花纹深度低于1.6mm需更换，注意异常磨损模式。", tags: ["轮胎", "磨损", "更换"]),

            KnowledgeCard(id: "card_brake_pad", title: "刹车片检查", what: "定期检查刹车片厚度，听到异响及时检修。", why: "刹车片磨损会降低制动效果，危及安全。", how: "每次保养检查刹车片，听到刹车异响立即检查，厚度低于3mm需更换。", tags: ["刹车片", "制动", "保养"]),

            KnowledgeCard(id: "card_coolant_check", title: "冷却液检查", what: "定期检查冷却液液位和颜色，不足时补充。", why: "冷却液不足会导致发动机过热损坏。", how: "冷车时检查膨胀壶液位，应在最高和最低刻度之间，颜色变浑浊需更换。", tags: ["冷却液", "发动机", "检查"]),

            KnowledgeCard(id: "card_battery_maintain", title: "电瓶维护", what: "定期检查电瓶接头，清洁腐蚀物，检查电压。", why: "电瓶老化会导致启动困难或抛锚。", how: "检查接头是否松动或腐蚀，用热水清洗白色粉末，3年以上定期检测电压。", tags: ["电瓶", "维护", "启动"]),

            KnowledgeCard(id: "card_wiper_blade", title: "雨刷保养", what: "定期检查雨刷条，刮不干净及时更换。", why: "雨刷老化会影响雨天视线，危及安全。", how: "每半年检查一次，出现跳动、异响、刮不净时更换，避免干刮。", tags: ["雨刷", "视线", "保养"]),

            KnowledgeCard(id: "card_air_filter", title: "空气滤芯更换", what: "按保养手册定期更换空气滤芯。", why: "滤芯堵塞会降低动力，增加油耗。", how: "一般1-2万公里更换，经常在灰尘大的环境行驶应缩短周期。", tags: ["空气滤芯", "保养", "动力"]),

            // ========== 驾驶心理与状态 ==========
            KnowledgeCard(id: "card_road_rage", title: "路怒症预防", what: "保持冷静心态，避免情绪化驾驶。", why: "愤怒情绪会影响判断力，增加事故风险。", how: "深呼吸调节情绪，播放舒缓音乐，给其他司机更多理解和耐心。", tags: ["情绪", "心态", "安全"]),

            KnowledgeCard(id: "card_fatigue_driving", title: "疲劳驾驶识别", what: "识别疲劳信号，及时休息，避免强行驾驶。", why: "疲劳驾驶反应迟钝，容易发生严重事故。", how: "感到困倦、频繁眨眼、注意力不集中时，立即找安全地点休息20-30分钟。", tags: ["疲劳", "休息", "安全"]),

            KnowledgeCard(id: "card_stress_driving", title: "压力下驾驶", what: "情绪不佳时避免驾驶，或格外小心。", why: "压力和负面情绪会分散注意力，影响判断。", how: "出发前调整心态，驾驶时专注路况，必要时推迟行程。", tags: ["压力", "情绪", "专注"]),

            KnowledgeCard(id: "card_phone_distraction", title: "手机干扰防范", what: "驾驶时不使用手机，设置勿扰模式。", why: "使用手机会严重分散注意力，事故风险增加数倍。", how: "出发前设置导航和音乐，开启勿扰模式，需要用手机时靠边停车。", tags: ["手机", "分心", "专注"]),

            KnowledgeCard(id: "card_passenger_distraction", title: "乘客干扰管理", what: "礼貌请求乘客配合，复杂路况时减少交谈。", why: "与乘客交谈会分散注意力，尤其在复杂路况。", how: "提前说明安全第一，复杂路况时专注驾驶，必要时请乘客帮忙导航。", tags: ["乘客", "分心", "沟通"]),

            KnowledgeCard(id: "card_confidence_building", title: "新手信心建立", what: "从简单路况开始，逐步提高难度，积累经验。", why: "过度紧张或盲目自信都会影响安全。", how: "先在空旷路段练习，逐步尝试复杂路况，不要急于上高速，接受自己的节奏。", tags: ["新手", "信心", "练习"]),

            // ========== 停车技巧 ==========
            KnowledgeCard(id: "card_parallel_parking", title: "侧方位停车", what: "掌握参照点，分步骤完成侧方位停车。", why: "侧方位是城市最常用的停车方式。", how: "与前车平行，倒车至后轮过前车尾部，向右打满，车身45度时回正，继续倒车入位。", tags: ["侧方停车", "技巧", "参照点"]),

            KnowledgeCard(id: "card_perpendicular_parking", title: "垂直停车技巧", what: "选择合适车位，利用后视镜判断距离。", why: "垂直停车是停车场最常见的方式。", how: "车身与车位线成30度角，观察后视镜中车位线，适时打方向，调整车身位置。", tags: ["垂直停车", "停车场", "后视镜"]),

            KnowledgeCard(id: "card_hill_parking", title: "坡道停车", what: "拉紧手刹，挂入档位，打轮靠边。", why: "防止溜车造成事故。", how: "上坡挂1档，下坡挂倒档，拉紧手刹，方向盘向路边打，让轮胎靠近路沿。", tags: ["坡道", "停车", "手刹"]),

            KnowledgeCard(id: "card_underground_parking", title: "地下车库停车", what: "开启车灯，降低车速，注意限高和转弯半径。", why: "地下车库光线暗，空间受限，易发生剐蹭。", how: "开启近光灯，车速控制在10km/h以下，注意柱子和墙壁，转弯时注意内轮差。", tags: ["地下车库", "停车", "灯光"]),

            KnowledgeCard(id: "card_tight_parking", title: "狭窄车位停车", what: "多次调整，利用空间，必要时请人指挥。", why: "狭窄车位需要精确控制，避免剐蹭。", how: "慢速多次调整，利用后视镜判断距离，必要时下车查看或请人帮忙指挥。", tags: ["狭窄", "车位", "调整"]),

            // ========== 季节性驾驶 ==========
            KnowledgeCard(id: "card_spring_rain", title: "春季多雨驾驶", what: "春季雨水多，注意路面湿滑和视线受阻。", why: "春雨频繁，路面湿滑，易发生事故。", how: "降低车速，增大车距，开启雨刷和灯光，避免积水路段。", tags: ["春季", "雨天", "湿滑"]),

            KnowledgeCard(id: "card_summer_heat", title: "夏季高温应对", what: "检查冷却系统，避免爆胎，防止疲劳。", why: "高温会导致车辆故障和驾驶员疲劳。", how: "出发前检查冷却液和轮胎气压，避免暴晒，开空调保持舒适，多休息。", tags: ["夏季", "高温", "防暑"]),

            KnowledgeCard(id: "card_summer_tire", title: "夏季轮胎保养", what: "高温下适当降低胎压，避免爆胎。", why: "高温会使胎压升高，增加爆胎风险。", how: "早晨测量胎压，比标准值低0.1-0.2bar，避免在高温时段长途行驶。", tags: ["夏季", "轮胎", "胎压"]),

            KnowledgeCard(id: "card_autumn_leaves", title: "秋季落叶路面", what: "落叶覆盖路面时降低车速，避免急刹车。", why: "湿润的落叶会降低路面摩擦力。", how: "看到落叶路面提前减速，避免急刹车和急转向，保持匀速通过。", tags: ["秋季", "落叶", "湿滑"]),

            KnowledgeCard(id: "card_autumn_fog", title: "秋季大雾", what: "秋季早晚易起雾，注意开启雾灯和降低车速。", why: "秋季温差大，容易形成浓雾。", how: "遇雾降低车速，开启雾灯，保持更大车距，能见度极低时靠边停车。", tags: ["秋季", "大雾", "能见度"]),

            KnowledgeCard(id: "card_winter_prep", title: "冬季行车准备", what: "更换防冻液，检查电瓶，准备应急物品。", why: "冬季气温低，车辆容易出现故障。", how: "更换冬季防冻液，检查电瓶电量，准备防滑链、铲子、毛毯等应急物品。", tags: ["冬季", "准备", "防冻"]),

            KnowledgeCard(id: "card_winter_warmup", title: "冬季热车", what: "冷启动后怠速30秒至1分钟即可行驶。", why: "现代发动机不需要长时间热车，低速行驶即可预热。", how: "启动后等待30秒，水温表开始上升即可行驶，初期保持低速温柔驾驶。", tags: ["冬季", "热车", "启动"]),

            KnowledgeCard(id: "card_winter_window", title: "冬季车窗除雾", what: "开启空调除雾功能，调高温度和风量。", why: "冬季车内外温差大，容易起雾影响视线。", how: "开启前挡除雾，调高温度和风量，打开外循环，必要时开窗加速空气流通。", tags: ["冬季", "除雾", "视线"]),

            KnowledgeCard(id: "card_black_ice", title: "黑冰路面识别", what: "桥面、阴影处、清晨时段警惕黑冰。", why: "黑冰透明难以识别，极度湿滑危险。", how: "冬季清晨经过桥面和阴影处提前减速，轻点刹车测试路面，发现打滑立即松开刹车。", tags: ["黑冰", "冬季", "危险"]),

            // ========== 燃油经济性 ==========
            KnowledgeCard(id: "card_eco_driving", title: "经济驾驶技巧", what: "平稳加速，提前滑行，避免急刹车。", why: "温和驾驶可以降低油耗15-30%。", how: "轻踩油门缓加速，提前松油门滑行，避免急刹车，保持匀速行驶。", tags: ["省油", "经济", "驾驶"]),

            KnowledgeCard(id: "card_speed_fuel", title: "经济车速", what: "大多数车辆在60-90km/h时最省油。", why: "过低或过高的车速都会增加油耗。", how: "城市道路保持50-60km/h，高速公路保持90-100km/h，避免频繁加减速。", tags: ["车速", "省油", "经济"]),

            KnowledgeCard(id: "card_idle_fuel", title: "减少怠速", what: "停车超过1分钟建议熄火，减少怠速时间。", why: "怠速时发动机效率低，浪费燃油。", how: "等人或临时停车超过1分钟熄火，减少热车时间，避免长时间怠速开空调。", tags: ["怠速", "省油", "熄火"]),

            KnowledgeCard(id: "card_weight_fuel", title: "减轻车重", what: "清理后备箱，移除不必要的物品。", why: "车重每增加50kg，油耗增加约2%。", how: "定期清理后备箱，不要把车当仓库，移除车顶行李架等增加风阻的装置。", tags: ["车重", "省油", "整理"]),

            KnowledgeCard(id: "card_ac_fuel", title: "空调使用优化", what: "合理使用空调，低速开窗，高速开空调。", why: "空调会增加油耗10-20%，但高速开窗风阻更大。", how: "低速时开窗通风，高速时开空调，温度设置适中，避免过冷或过热。", tags: ["空调", "省油", "优化"]),

            // ========== 环保驾驶 ==========
            KnowledgeCard(id: "card_emission_reduce", title: "减少排放", what: "温和驾驶，定期保养，减少短途行驶。", why: "减少排放保护环境，也能降低油耗。", how: "避免急加速急刹车，按时保养，短途考虑步行或骑车，拼车出行。", tags: ["环保", "排放", "保养"]),

            KnowledgeCard(id: "card_noise_reduce", title: "降低噪音", what: "避免不必要的鸣笛，控制发动机转速。", why: "噪音污染影响他人生活质量。", how: "住宅区避免鸣笛，不要轰油门，关闭车窗减少音响音量，夜间格外注意。", tags: ["噪音", "环保", "文明"]),

            // ========== 施工区域 ==========
            KnowledgeCard(id: "card_construction_zone", title: "施工区域驾驶", what: "严格遵守限速，注意工人和设备，保持车距。", why: "施工区域路况复杂，工人安全第一。", how: "看到施工标志立即减速，注意临时标志，保持车距，不要变道，耐心通过。", tags: ["施工", "限速", "安全"]),

            KnowledgeCard(id: "card_road_work", title: "道路维修注意", what: "注意路面不平，避开坑洞，降低车速。", why: "路面不平会损坏车辆，影响控制。", how: "提前观察路面，避开明显坑洞，无法避开时减速通过，双手握稳方向盘。", tags: ["维修", "路面", "坑洞"]),

            // ========== 特殊情况 ==========
            KnowledgeCard(id: "card_animal_crossing", title: "动物穿越应对", what: "看到动物立即减速，不要急打方向。", why: "急打方向可能导致失控或撞到对向车辆。", how: "看到动物减速鸣笛，如无法避免宁可撞击小动物也不要急打方向，大型动物尽量避让。", tags: ["动物", "避让", "安全"]),

            KnowledgeCard(id: "card_emergency_vehicle", title: "让行急救车辆", what: "听到警笛立即观察，安全情况下靠边让行。", why: "急救车辆执行紧急任务，关系生命安全。", how: "听到警笛观察来向，靠右减速或停车，不要急刹车或突然变道，确保安全让行。", tags: ["急救车", "让行", "警笛"]),

            KnowledgeCard(id: "card_funeral_procession", title: "葬礼车队礼让", what: "遇葬礼车队主动让行，不要穿插。", why: "尊重逝者和家属，也是文明驾驶的体现。", how: "看到葬礼车队减速让行，不要鸣笛或穿插，耐心等待车队通过。", tags: ["葬礼", "礼让", "文明"]),

            KnowledgeCard(id: "card_police_stop", title: "交警检查配合", what: "看到交警示意停车，安全靠边配合检查。", why: "配合执法是公民义务，也能避免误会。", how: "看到示意减速靠边，熄火降窗，准备好证件，礼貌配合，不要争执。", tags: ["交警", "检查", "配合"]),

            KnowledgeCard(id: "card_dash_cam", title: "行车记录仪使用", what: "安装行车记录仪，定期检查工作状态。", why: "记录仪是事故责任认定的重要证据。", how: "选择高清广角记录仪，定期检查是否正常录制，及时备份重要视频，清理存储空间。", tags: ["记录仪", "证据", "维护"]),

            KnowledgeCard(id: "card_insurance_knowledge", title: "保险理赔知识", what: "了解保险条款，事故后及时报案。", why: "正确理赔能减少经济损失。", how: "熟悉保险范围，事故后48小时内报案，保护现场拍照，保留相关单据。", tags: ["保险", "理赔", "事故"]),

            KnowledgeCard(id: "card_long_trip_prep", title: "长途出行准备", what: "检查车况，规划路线，准备应急物品。", why: "充分准备能避免途中故障和意外。", how: "出发前全面检查车辆，规划路线和休息点，准备水、食物、药品、工具等应急物品。", tags: ["长途", "准备", "检查"]),

            KnowledgeCard(id: "card_passenger_safety", title: "乘客安全管理", what: "确保所有乘客系好安全带，儿童使用安全座椅。", why: "安全带是最有效的安全保护装置。", how: "出发前检查所有乘客安全带，儿童必须使用合适的安全座椅，后排乘客也要系安全带。", tags: ["乘客", "安全带", "儿童"]),

            KnowledgeCard(id: "card_cargo_secure", title: "货物固定", what: "货物必须固定牢靠，不能遮挡视线。", why: "松散货物会移动影响驾驶，甚至飞出伤人。", how: "使用绳索或网兜固定货物，重物放低，不要超高超宽，确保后视镜视线清晰。", tags: ["货物", "固定", "安全"]),

            KnowledgeCard(id: "card_trailer_driving", title: "拖挂车驾驶", what: "拖挂车时降低车速，增大转弯半径，提前制动。", why: "拖挂车改变车辆特性，需要调整驾驶方式。", how: "车速降低20%，转弯半径加大，提前制动，倒车时方向相反，定期检查连接。", tags: ["拖挂", "车速", "转弯"])
        ]

        cards.forEach { context.insert($0) }
        try? context.save()
        defaults.set(true, forKey: SeedFlag.knowledge)
    }
}

