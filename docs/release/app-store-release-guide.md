# Safe Driver Note App Store 发布实操指南

> 目标：将 iOS App **“安全驾驶日志 (Safe Driver Note)”** 提交并发布到苹果 App Store。本指南假设你使用 Xcode 15+、拥有付费开发者账号，并基于当前仓库 `main` 分支。

## 0. 快速导航
- [Step 1](#step-1-准备账号与工具)：确认账号权限与本地环境
- [Step 2](#step-2-在-apple-developer-完成-app-id-与证书)：App ID / 证书 / Provisioning Profile
- [Step 3](#step-3-完善-xcode-项目配置)：项目配置、版本号、能力开关
- [Step 4](#step-4-资产与合规材料准备)：图标、截图、文案、隐私政策
- [Step 5](#step-5-质量校验与测试回归)：自动化 + 手动测试路线
- [Step 6](#step-6-生成-archive-并上传构建)：Archive + 上传构建
- [Step 7](#step-7-在-app-store-connect-配置新版本)：App 信息、隐私、合规
- [Step 8](#step-8-testflight-与预发布)：TestFlight 内测（可选）
- [Step 9](#step-9-提交审核与版本发布)：提审 & 发布
- [Step 10](#step-10-发布后维护)：发布后检查与版本迭代

---

## Step 1. 准备账号与工具
1. **Apple Developer Program**：确认主 Apple ID 已加入开发者计划并拥有“App Manager / Admin”权限。
2. **App Store Connect 权限**：至少具备以下角色：`App Manager`、`Developer`、`Access to Cloud Managed Distribution Certificates`（如需）。
3. **本地环境**：
   - macOS 13.5+
   - Xcode 15.2+（支持 iOS 17 SDK）
   - 已登录 Xcode (`Xcode > Settings > Accounts`) 并下载所需的 iOS 模拟器/设备支持包。
4. **第三方依赖**：本项目未使用 CocoaPods/Mint 等外部依赖，无需额外安装。
5. **仓库状态**：
   - `git status` 保持干净，确保基于最新主分支。
   - 执行 `swiftlint lint --config .swiftlint.yml` 确认代码规范无阻塞。

## Step 2. 在 Apple Developer 完成 App ID 与证书
1. **创建 App ID**（若尚未存在）：
   - 登录 [developer.apple.com](https://developer.apple.com/account/resources/identifiers/list)
   - 新建 `App IDs > App`，`Bundle ID` 设为 `com.chenyuanqi.SafeDriverNote`（与 `SafeDriverNote.xcodeproj` 中配置一致）。
   - 勾选能力：
     - `Background Modes`（Location updates）
     - `Push Notifications`（本项目仅用本地通知，可选；若保持未启用，请同步更新代码或描述）
     - `iCloud`（若正式启用 iCloud 同步，需要 CloudKit；如暂不启用，请在发布版本中隐藏/下线该入口）
2. **证书**：确保已有有效的 `iOS Distribution (App Store & Ad Hoc)` 证书。若无，使用“Certificates”入口创建并下载，双击导入钥匙串。
3. **Provisioning Profile**：开启 `Automatic` 签名即可；如需手动：
   - 在 `Profiles` 中创建 `App Store` 类型，绑定上述 App ID。
   - 下载 `.mobileprovision` 并导入到 Xcode。

> ⚠️ 如果计划在首个版本禁用 iCloud/后台定位，请同步修改代码和 Info 中的描述，避免审核认为“申请了能力却未使用”。

## Step 3. 完善 Xcode 项目配置
1. **打开项目**：`SafeDriverNote/SafeDriverNote.xcodeproj`
2. **General > Identity**：
   - `Display Name`：`安全驾驶日志`
   - `Bundle Identifier`：`com.chenyuanqi.SafeDriverNote`
   - `Version (MARKETING_VERSION)`：首发建议 `1.0`
   - `Build (CURRENT_PROJECT_VERSION)`：从 `1` 开始，每次上传递增
3. **Signing & Capabilities**：
   - `Team`：切换到正式团队
   - `Automatically manage signing`：保持勾选
   - Capabilities：确保按照 Step 2 配置。若暂不提供 iCloud，同步移除 `iCloud` 相关 Capability，并在 `SettingsView` 中隐藏对应入口。
4. **Info（Build Settings 中的 INFOPLIST_KEY_***）**：本项目已提供权限文案，请核对是否符合上线版本行为：
   - 位置（前台/后台）
   - 麦克风 / 语音识别
   - 照片访问
   - 背景模式（location）
5. **App Icon**：
   - 目前 `Assets.xcassets/AppIcon.appiconset` 仅含 1024 尺寸占位，请按照 `docs/AppIcon-Guide.md` 批量导出全尺寸 PNG 并填充所有槽位（包含 iPhone 60/120/180, iPad 76/152/167, App Store 1024, 通知 20/40/60 等）。
6. **Launch Screen**：工程使用 `LaunchScreen.storyboard` 或 SwiftUI 生成？若使用默认，请确认视觉符合设计稿。
7. **构建设置**：
   - `iOS Deployment Target = 17.0`
   - 如需支持 armv7/bitcode，无需额外操作（Xcode 14+ 默认关闭 bitcode）。

## Step 4. 资产与合规材料准备
1. **App 描述素材**：
   - 参考 `README.md`、`docs/mvp-implementation-plan.md`、`design/prototypes.html` 整理应用核心价值、功能亮点。
   - 建议准备中文主文案 + 英文翻译（方便后续多语言）。
2. **关键词 & 副标题**：结合“驾驶安全”“日志”“检查清单”等高频词。
3. **隐私政策**：
   - App Store Connect 需要可访问的 URL。可在主站或临时 Notion/静态页托管，确保公开可访问。
   - 明确说明数据仅存储本地（或 iCloud）且不会共享给第三方。
4. **截图**：
   - 要求：至少 6.7''（iPhone 15 Pro Max 1290×2796）和 5.5''（iPhone 8 Plus 1242×2208）各 3 张。
   - 使用真机/模拟器录屏并截取画面，或依据 `design/prototypes` 还原界面后拍摄。
   - 覆盖关键流程：`首页驾驶状态`、`日志编辑`、`行前/行后检查`、`知识卡`、`设置 & iCloud 同步`。
5. **App Review 说明**：准备文本说明以下功能使用场景：
   - 背景位置：用于记录行程，提醒驾驶安全。
   - 麦克风/语音识别：快速语音录入驾驶日志。
   - 照片：上传驾驶现场照片或用户头像。
   - 本地通知：每日安全提醒。
   - 若 iCloud 同步暂未开放，请说明该入口将隐藏或提示“即将上线”。
6. **加密合规**：应用仅使用 Apple 提供的 HTTPS/系统加密，可在提审时选择“使用标准加密，符合出口豁免”。

## Step 5. 质量校验与测试回归
1. **自动化测试**：
   - 运行：`xcodebuild test -scheme SafeDriverNote -destination 'platform=iOS Simulator,name=iPhone 15'`
   - 若 UI Test 需禁用弱网等手段，可参考 `SafeDriverNoteUITests`。
2. **手动测试清单**：
   - 参考 `docs/testing` 底下的测试用例（例如 `06-系统权限测试.md`、`08-性能测试.md`）。
   - 核对权限弹窗、后台定位稳定性、日志增删改、知识卡随机策略等。
   - 在开启/关闭 iCloud、弱网场景下验证。
3. **性能与崩溃**：
   - 使用 Xcode Instruments（Time Profiler、Leaks）针对日志列表、连续定位过程做抽查。
   - 确认音频录制、位置追踪在后台不会异常崩溃。
4. **版本锁定**：测试通过后打 Git tag（例如 `v1.0.0-release-candidate`）以便追踪。

## Step 6. 生成 Archive 并上传构建
1. **清理并归档**：
   - Product > Clean Build Folder
   - 设备选择 `Any iOS Device (arm64)`
   - Product > Archive
2. **处理常见报错**：
   - 签名失败 → 检查 Team/证书/Provisioning Profile
   - 缺少位图 → 确认所有 App Icon 槽位都已填充
   - 架构不匹配 → 确认使用 Release 配置
3. **上传**：
   - Archive 成功后进入 Organizer > Distribute App > App Store Connect > Upload
   - 若使用 CI，可运行 `xcodebuild -scheme SafeDriverNote -configuration Release archive -archivePath build/SafeDriverNote.xcarchive`
     再 `xcodebuild -exportArchive -archivePath ... -exportOptionsPlist ExportOptions.plist`
   - CLI 上传需 App 专用密码 (`app-specific password`)
4. **验证**：Organizer 会显示上传进度；App Store Connect 处理需要 10~30 分钟。

## Step 7. 在 App Store Connect 配置新版本
1. **创建 App 条目（首次）**：
   - “我的 App”> “+” > “新建 App”
   - 名称：`安全驾驶日志`
   - 默认语言：`简体中文`
   - Bundle ID：选择 `com.chenyuanqi.SafeDriverNote`
   - SKU：自定义，例如 `safedrivernote-ios`
   - 类别：建议主要 `导航` / 次要 `效率`（可根据目标用户群调整）
2. **App 信息**：
   - 副标题、关键词、支持网址、隐私政策 URL
   - 年龄分级：一般为 `4+`（无不良内容）
   - App 图标：上传 1024×1024 PNG（与 Xcode 里一致）
3. **版本信息**：
   - *描述*：突出核心卖点（驾驶日志、行前后清单、知识卡、语音输入、iCloud 同步）
   - *新功能*：首版可写“首次发布”
   - *截图*：按 Step 4 要求上传
   - *App Clip*（如无则跳过）
4. **App 隐私**：
   - “App 隐私”>“开始申报”
   - 数据类型建议：
     | 数据类别 | 数据类型 | 用途 | 关联性 | 存储 | 备注 |
     | --- | --- | --- | --- | --- | --- |
     | 位置 | 精确位置 | App 功能 | 与用户关联 | 设备上 / 可选 iCloud | 驾驶轨迹、起终点 |
     | 用户内容 | 照片或视频 | 用户生成内容 | 关联 | 设备上 | 驾驶现场/头像 |
     | 用户内容 | 音频数据 | 用户生成内容 | 关联 | 设备上 | 语音日志 |
     | 使用数据 | 产品交互 | App 功能 | 非关联 | 设备上 | 勾选记录、知识学习进度 |
   - 若未采集分析数据，可标注“不收集”。
5. **隐私政策 URL**：必填。
6. **加密合规**：
   - 问题 “Does your app use encryption?” → 选择 Yes（使用系统 HTTPS）
   - 说明仅使用 Apple 提供标准加密并符合豁免（记得勾选“Eligible for export compliance exemption”）。
7. **App Review 说明**：在“审核信息 > 备注”填写示例：
   ```
   - 位置权限用于记录驾驶路线与生成安全提醒。
   - 后台定位只在用户主动开启“开始驾驶”后使用。
   - 麦克风/语音识别用于语音速记驾驶日志，不会上传到服务器。
   - iCloud 同步（若启用）仅用作用户在其 Apple ID 设备之间的数据同步。
   - 无账号系统，审核可直接使用 App。
   ```
8. **联系信息**：确保“审核联系人”电话/邮箱可用。

## Step 8. TestFlight 与预发布
1. **内部测试**：上传构建后，进入 “TestFlight” 选中最新 Build，添加 `Internal Testers`。
2. **外部测试**（可选）：
   - 填写测试信息、营销文本、问卷
   - 提交外测审核（1~3 天）
3. **收集反馈**：利用 TestFlight 自动汇总的日志/崩溃，修复后重新递增 `Build`。

## Step 9. 提交审核与版本发布
1. **选择构建**：在 `版本或平台 > iOS App` 中，选择处理完成的 Build。
2. **完成合规问卷**：
   - `出口合规`、`内容权利`、`广告标识符 (IDFA)`（如果未使用广告，选择“否”）。
3. **提交审核**：
   - 状态变为 `Waiting for Review`。
   - 审核通常 1~3 个工作日；若涉及后台定位，可能要求补充说明。及时在“审核备注”中回应。
4. **审核被拒常见原因**（提前准备）：
   - 背景定位用途不清晰 → 提供更具体的用户流程和截图
   - iCloud 功能无法使用 → 请确保首版中要么下线入口，要么提供完整登录/同步体验
   - 权限弹窗文案与用途不匹配 → 保持 Info.plist 描述与实际功能一致

## Step 10. 发布后维护
1. **发布**：审核通过后，可选择“手动发布”或“立即发布”。
2. **跟踪**：
   - App Store Connect > Analytics 观察崩溃率 / 留存
   - 若发现严重 bug，立刻准备热修复版本（递增 Build & Version）。
3. **仓库同步**：
   - 将实际发布的 `Version`/`Build` 回写到 `project.pbxproj`
   - 打标签 `v1.0.0` 并记录发布说明
4. **客服支持**：
   - 准备邮箱/表单收集用户反馈
   - 定期巡检 App Store Review 回复

---

## 附录 A. 发布前检查清单
- [ ] Apple Developer 账号有效，Xcode 登录
- [ ] App ID / Capabilities 与上线功能一致
- [ ] 版本号、Build 号已更新
- [ ] App Icon 所有尺寸齐备
- [ ] 关键权限申请与提示文案一致
- [ ] 自动化测试通过，关键手动测试完成
- [ ] 隐私政策 URL 可访问
- [ ] App Store Connect 元数据、截图、App Review 说明填写完毕
- [ ] 最新构建已上传并在 Processing/Ready to Submit 状态

## 附录 B. 常用链接
- Apple Developer Identifiers: https://developer.apple.com/account/resources/identifiers/list
- App Store Connect: https://appstoreconnect.apple.com/
- TestFlight 指南: https://developer.apple.com/testflight/
- 出口合规 FAQ: https://developer.apple.com/documentation/security

祝发布顺利！如需补充 CI/CD、自动化上架脚本或后续版本规划，可基于本指南扩展。
