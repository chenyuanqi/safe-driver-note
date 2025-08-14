# 开发路线图（iOS）

> 项目：安全驾驶日记（Safe Driver Note）
> 版本：v0.1（迭代更新中）
> 平台：iOS 17+，iPhone 优先

## 一、产品里程碑

- M0：需求梳理与原型（已完成）
  - 参考：`design/` HTML 原型与 `init.md`
- M1：MVP（日志 + 清单 + 知识卡离线）
  - 驾驶日志：失误-反思-改进，语音转写，图片/视频上传（本地）
  - 安全清单：行前8项、行后5项，完成度评分与徽章
  - 知识卡：What/Why/How，3张/天，离线本地存储
- M2：智能化与同步
  - 标签与热力图（基础聚合）
  - 间隔复习引擎（简化版 SM-2）
  - 账户体系与云同步（增量同步）
- M3：问答与推荐
  - FAQ + AI Chat（可配置 OpenAI/学术文档）
  - 基于失误标签与车型的好物推荐
- M4：增长与合规
  - 数据导入导出、隐私与合规完善
  - 上线运营、A/B 实验与埋点分析

## 二、技术选型

- 应用框架：Swift 5.9+ / SwiftUI / Combine
- 数据存储：SwiftData（iOS 17+）或 Core Data（如需兼容更低版本）
- 多媒体：AVFoundation（录音/视频截取）、Photos（相册权限）
- 位置与地图：CoreLocation + MapKit（起讫点与轨迹）
- 语音：Speech（语音转文字，中文支持），可预留第三方 ASR 接口
- 后台：BackgroundTasks（最小化干扰、任务调度）
- 通知：UserNotifications（学习/检查提醒）
- 网络：URLSession（或基于 async/await 的轻量封装）
- 日志与监控：OSLog、MetricKit

## 三、架构与模块划分（参考信息架构）

- AppCore（应用壳 + 路由 + 会话与权限）
- Features
  - DriveLog：驾驶日志（录入、列表、统计）
  - Checklist：行前/行后检查与成就
  - Knowledge：知识卡、复习计划
  - QA：问答中心（后续）
  - Recommendations：好物推荐（后续）
  - Profile：个人中心与设置
- Shared
  - DataLayer：SwiftData/CoreData 模型与仓库
  - Services：定位、语音、相机/媒体、通知、同步
  - Utils：格式化、错误/权限处理、配置
  - UIComponents：通用组件库（按钮、卡片、进度、标签）

## 四、数据模型（初稿）

> 若使用 SwiftData，可直接定义 @Model；如用 Core Data，对应 Entity/Attributes。

- Trip（行程）
  - id、startAt、endAt、startLocation、endLocation、distance、duration
- LogEntry（驾驶日志）
  - id、date、scene、mistake、cause、improvement、mediaRefs[]、tags[]、tripRef?
- ChecklistRecord（检查记录）
  - id、date、type(pre/post)、items[{key, checked}]、score
- KnowledgeCard（知识卡）
  - id、title、what、why、how、tags[]
- ReviewState（复习状态）
  - cardId、ease、interval、dueAt、streak
- UserProfile（用户）
  - id、nickname、experienceYears、carModel、preferences
- Badge（成就）
  - id、name、condition、awardedAt

## 五、关键用例与接口（ViewModel 草案）

- DriveLogViewModel
  - func startTrip()/endTrip()
  - func createLogEntry(...)/update/delete
  - func transcribeVoice(url: URL) async -> String
- ChecklistViewModel
  - func loadChecklist(type: .pre/.post)
  - func toggleItem(key: String)
  - var scorePublisher: AnyPublisher<Int, Never>
- KnowledgeViewModel
  - func fetchTodayCards() -> [KnowledgeCard]
  - func mark(cardId: , mastered: Bool)
  - func scheduleReview(for cardId: )

## 六、权限与隐私

- 必要权限：定位（WhenInUse/Always?）、麦克风、相机/相册、通知
- 隐私合规：仅本地存储（MVP 阶段），显示用途说明与关闭入口
- 敏感数据：行车位置、音频/视频；默认不开启云端同步，用户显式同意后再开

## 七、质量保障

- 代码规范：SwiftLint（基础规则）
- 单元测试：XCTest（ViewModel/服务层）
- 快照测试：ViewInspector 或 SwiftUI Snapshot（关键UI）
- 集成测试：XCUITest（关键用户旅程）
- 性能：Instruments（启动时间、内存、卡顿、耗电）
- 无障碍：VoiceOver、Dynamic Type、对比度

## 八、构建与发布

- 包管理：Swift Package Manager
- 配置：Debug/Release 两套环境（日志级别、埋点开关）
- CI/CD：GitHub Actions（构建 + 单测）→ TestFlight 分发
- 版本策略：语义化版本（MAJOR.MINOR.PATCH）
- 上架材料：截图、隐私说明、权限用途、支持机型、关键词

## 九、迭代计划（12周样例）

- W1-W2：项目骨架、权限流、设计系统组件化（按钮/卡片/输入/进度）
- W3-W4：Checklist 功能完成（模型、UI、评分、徽章触发）
- W5-W6：DriveLog MVP（语音转写、媒体选择、定位起讫点、列表/详情）
- W7：统计与可视化（基础趋势/热力占位）、本地化/可访问性
- W8：Knowledge MVP（卡片浏览、离线数据、简单复习策略）
- W9：通知与复习提醒、背景任务打磨、崩溃/日志监控
- W10：稳定性优化、性能优化、快照测试补齐
- W11：TestFlight 内测、问题修复、上架素材准备
- W12：提交审核与上架（或继续M2）

## 十、风险与对策

- 语音识别准确率：优先本地 API + 降噪；保留第三方 ASR 兜底
- 位置精度与耗电：显式开关 + 显著提示；仅在驾驶模式采集
- 媒体体积：转码压缩与自动清理；限制单次上传/缓存大小
- 数据一致性：离线优先 + 增量同步 + 冲突合并策略
- 审核合规：权限用途与隐私说明到位；可选云服务开关

——
本路线图将随设计与实现进展持续更新。建议每周例会回顾里程碑，按需调整优先级。
