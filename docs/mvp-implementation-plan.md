# MVP 开发实施计划（M1）

> 产品：Safe Driver Note  |  目标：M1 = 驾驶日志 + 安全检查清单 + 知识卡（离线）  |  平台：iOS 17+

## 0. 目标与范围裁剪

仅包含：
1. Checklist：行前 8 项、行后 5 项，单日一次记录；得分 = (完成项/总项)*100。暂不做自定义/统计页动画，只做基础进度与当日完成状态。
2. DriveLog：创建/查看/删除日志（失误 | 成功），文本字段 + 最多 3 张照片，本地存储。语音转写第一版直接调用 Apple Speech；无自动标签、无地图轨迹，仅可手动地点描述。
3. Knowledge：自带内置 3~9 张知识卡，提供 “今日 3 张” 随机推送（不重复），标记“已掌握”后当天不再出现；不做复习算法（ReviewState 延后）。
4. 数据层：SwiftData（@Model）+ Repository 封装；无同步、无账户。
5. 基础壳：TabView（三个 Tab：日志 / 清单 / 知识）+ 权限弹窗延迟到首次需要。
6. 测试：至少 5 个单元测试（数据模型 & ViewModel 逻辑），1 个 UI 测试（Checklist 完成流程）。

排除：轨迹/定位自动填充、AI 标签、统计图表、成就徽章、复习算法、通知、背景任务、复杂动画、多语言。

## 1. 模块与目录建议（示例）

```
SafeDriverNote/
  App/
    AppEntry.swift
    DIContainer.swift
  Core/
    Models/ (SwiftData @Model)
    Repositories/
    Services/ (Speech, Media, Permission)
    Utils/
  Features/
    Checklist/
      ChecklistView.swift
      ChecklistViewModel.swift
    DriveLog/
      LogListView.swift
      LogEditorView.swift
      DriveLogViewModel.swift
    Knowledge/
      KnowledgeTodayView.swift
      KnowledgeViewModel.swift
  SharedUI/
    Components/
      TagView.swift
      CardContainer.swift
    Styles/
  Resources/
    checklist.json
    knowledge.json
  Tests/
    CoreTests/
    FeatureTests/
    UITests/
```

## 2. 数据模型（MVP 精简版）

```swift
@Model final class LogEntry {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var type: LogType   // .mistake / .success
    var locationNote: String
    var scene: String   // 场景描述（可合并 locationNote，后期再细化）
    var detail: String  // 失误详情或成功描述
    var cause: String?  // 仅失误
    var improvement: String? // 仅失误
    var tags: [String]
    var photoLocalIds: [String]  // PHAsset.localIdentifier / 文件名
}

enum LogType: String, Codable, CaseIterable { case mistake, success }

@Model final class ChecklistRecord { // 单日一条，包含 pre & post 状态
    @Attribute(.unique) var id: UUID
    var date: Date  // 只保留日粒度（用 day start）
    var pre: [ChecklistItemState]
    var post: [ChecklistItemState]
    var score: Int  // 0-100
}

struct ChecklistItemState: Codable, Hashable {
    var key: String
    var checked: Bool
}

@Model final class KnowledgeCard {
    @Attribute(.unique) var id: String
    var title: String
    var what: String
    var why: String
    var how: String
    var tags: [String]
}

@Model final class KnowledgeProgress { // 简单掌握标记
    @Attribute(.unique) var id: UUID
    var cardId: String
    var markedDates: [Date] // 当日掌握记录
}
```

## 3. Repository 接口（最小）

```swift
protocol LogRepository {
    func fetchAll() throws -> [LogEntry]
    func fetch(by type: LogType?) throws -> [LogEntry]
    func add(_ entry: LogEntry) throws
    func delete(_ entry: LogEntry) throws
}

protocol ChecklistRepository {
    func todayRecord() throws -> ChecklistRecord?
    func upsertToday(update: (inout ChecklistRecord) -> Void) throws -> ChecklistRecord
}

protocol KnowledgeRepository {
    func allCards() throws -> [KnowledgeCard]
    func todayCards(limit: Int) throws -> [KnowledgeCard]
    func mark(cardId: String) throws
}
```

## 4. ViewModel 关键逻辑草稿

```swift
@MainActor final class ChecklistViewModel: ObservableObject {
    @Published private(set) var record: ChecklistRecord
    @Published var mode: Mode = .pre
    let itemsPre: [ChecklistItemMeta]
    let itemsPost: [ChecklistItemMeta]
    // toggle -> recompute score
}

@MainActor final class DriveLogViewModel: ObservableObject {
    @Published private(set) var logs: [LogEntry] = []
    @Published var filter: LogType? = nil
    func createMistake(...) // 组装并保存
    func load() // repository
}

@MainActor final class KnowledgeViewModel: ObservableObject {
    @Published private(set) var today: [KnowledgeCard] = []
    func loadToday()
    func mark(card: KnowledgeCard)
}
```

## 5. 分阶段实施（假设 3 周冲刺）

### Week 1（基础 + Checklist）
Day 1: Xcode 项目初始化、SwiftLint、Targets、SPM 依赖（若需要）、创建 Models。 
Day 2: SwiftData stack & Repository 原型；导入 `checklist.json` / `knowledge.json`。 
Day 3: ChecklistView 基础 UI（列表 + 勾选），ViewModel 逻辑 + 计算分数。 
Day 4: Checklist 数据持久化（当日 upsert），今日完成态展示。 
Day 5: 单元测试（Checklist 分数/持久化），快照基线。 

### Week 2（DriveLog）
Day 6: LogEntry UI 列表 + 筛选（全部/失误/成功），空状态。 
Day 7: 编辑 / 新建表单（文本字段 + 标签输入 + 限制 3 图占位），Repository 接入。 
Day 8: 照片选择（PHPicker）封装; 本地标识存储。 
Day 9: 语音转写最小实现（Speech），权限集中处理。 
Day 10: 单元测试（LogRepository CRUD、过滤），UI 测试（创建→显示）。 

### Week 3（Knowledge + 打磨）
Day 11: KnowledgeTodayView（卡片翻页/列表 + 标记掌握），随机抽样逻辑。 
Day 12: Progress 标记存储；重复过滤。 
Day 13: 轻量样式统一（颜色/字体/卡片组件）。 
Day 14: 性能与可访问性巡检（Dynamic Type、VoiceOver 标签）。 
Day 15: 测试补齐、CI 脚本、README 更新、内部 TestFlight（如需要）。 

## 6. 关键实现步骤（更细指引）

1. Project Setup
   - Xcode 新建 App，启用 SwiftData（iOS 17 Deployment Target）。
   - 添加 SwiftLint（Build Phase 脚本）。
2. SwiftData
   - 创建 `ModelContainer` 在 `AppEntry` 注入环境：`.modelContainer(for: [...])`。
3. 初始数据导入
   - 首次启动检查 UserDefaults 标记，若未导入则解析 JSON 写入 KnowledgeCard；Checklist 不需要持久化模板，直接常量数组。
4. Repository 封装
   - 用 `@Environment(\ .modelContext)` 或通过 DI 传入 `ModelContext`。
5. Checklist 逻辑
   - todayRecord 查找当天（用 `Calendar.current.startOfDay(for:)`）。不存在则创建默认 `checked = false` 的数组。
   - toggle 后重新计算 score：`(preChecked+postChecked)/(13.0)*100.rounded()`。
6. DriveLog
   - 照片：存储至 `FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)` 下以 UUID 命名（或直接存 Asset ID）。
   - 语音：简单按钮录音（AVAudioRecorder）→ 结束后调用 Speech 识别 → 追加到当前表单的文本域末尾。
7. Knowledge
   - 抽样：读取全部后 `shuffled().prefix(3)`；过滤已在当天 `KnowledgeProgress.markedDates` 的卡片。
8. 权限管理
   - 分别在首次使用功能时请求（麦克风、语音、照片）；集中封装 `PermissionService`。
9. UI 结构
   - TabView：Log、Checklist、Knowledge。日志新增使用 sheet/toolbar + 表单导航栈。
10. 测试
   - 核心纯逻辑（score 计算、todayCards 不重复、Log 过滤）。
   - UI Test：启动 → 切到 Checklist → 勾选 2 项 → 分数显示变更。
11. CI（可选）
   - GitHub Actions：`xcodebuild -scheme SafeDriverNote -destination 'platform=iOS Simulator,name=iPhone 15' test`。

## 7. 待办清单（Backlog 粒度）

- [ ] 建立 Xcode 项目与基础文件结构
- [ ] 集成 SwiftLint & 基础规则配置
- [ ] 定义 @Model 数据（LogEntry / ChecklistRecord / KnowledgeCard / KnowledgeProgress）
- [ ] ModelContainer 注入
- [ ] 导入知识卡 JSON 数据（一次性）
- [ ] ChecklistViewModel & 分数计算
- [ ] Checklist 主界面 UI
- [ ] DriveLog Repository & ViewModel
- [ ] Log 列表 & 过滤 UI
- [ ] Log 编辑表单（文本 + 标签 + 图片占位）
- [ ] 照片选择集成
- [ ] 语音录制 + 转写 MVP
- [ ] KnowledgeViewModel + 今日抽样逻辑
- [ ] KnowledgeTodayView UI
- [ ] 权限服务封装
- [ ] 单元测试（Checklist 2, Log 2, Knowledge 1）
- [ ] UI 测试（Checklist 流程）
- [ ] CI 工作流
- [ ] README 更新（构建步骤）

## 8. 质量与风险控制

| 风险 | 影响 | 缓解 |
|------|------|------|
| Speech 识别延迟 | 影响表单流畅 | 录音 < 30s；失败 fallback 手动输入 |
| SwiftData 模型调整频繁 | 迁移成本 | 先锁定 MVP 字段；新增字段加可选 |
| 图片体积 | 占用缓存 | 保存前压缩 JPEG (0.7)，限制 3 张 |
| 权限被拒 | 功能不可用 | 在 UI 显示引导跳系统设置 |
| 随机卡片重复 | 用户体验差 | 使用日期缓存已展示 ID 集合 |

## 9. 可扩展点预留（命名 & 结构）

| 后续能力 | 预留方式 |
|----------|----------|
| 复习算法 (SM-2) | `KnowledgeProgress` 可添加 ease/interval/dueAt |
| 统计图表 | 新增 Feature: Analytics；对现有 Repos 做只读聚合方法 |
| 云同步 | 抽象 Repository 协议 + 本地实现；后续加 RemoteAdapter |
| 徽章/成就 | Checklist 勾选与日志新增时触发事件总线（轻量 Publisher） |

## 10. 最小示例（Entry & Tab）

```swift
@main
struct SafeDriverNoteApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [LogEntry.self, ChecklistRecord.self, KnowledgeCard.self, KnowledgeProgress.self])
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            LogListView()
                .tabItem { Label("日志", systemImage: "list.bullet") }
            ChecklistView()
                .tabItem { Label("清单", systemImage: "checklist") }
            KnowledgeTodayView()
                .tabItem { Label("知识", systemImage: "book") }
        }
    }
}
```

## 11. 验收标准（Definition of Done）

| 条目 | 标准 |
|------|------|
| Checklist | 可切换 pre/post；勾选更新分数；当天重复进入数据持久 |
| DriveLog | 新建/查看/删除；按类型筛选；可添加 ≤3 张图片；语音转写成功追加文字 |
| Knowledge | 每日展示不重复 3 张；标记掌握后当日不再出现 |
| 数据 | 重启后数据存在；无崩溃；模型版本稳定 |
| 性能 | 首屏 < 2s（模拟器）；无明显掉帧滚动 |
| 测试 | 单元测试 ≥5 通过；1 个 UI 测试通过 |
| 代码质量 | SwiftLint 无阻断错误；主线程 UI 更新；无强制 unwrap 崩溃 |

——
如需我下一步直接为你生成项目骨架文件结构或具体某个模块代码，请告诉我优先级。
