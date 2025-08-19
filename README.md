# Safe Driver Note (iOS MVP)

安全驾驶日记 —— 驾驶日志 / 检查清单 / 知识卡 离线 MVP。

## 功能范围（M1）
* 驾驶日志：新增、筛选（失误/成功）、删除（本地持久化 SwiftData）。
* 检查清单：行前 8 项 / 行后 5 项 勾选，自动计算得分。
* 知识卡：启动播种 3+ 张内置卡片；每日随机抽取 3 张；支持标记掌握。

## 技术栈
* iOS 17+ / Swift 5.9 / SwiftUI / SwiftData
* 模块：Features + Core(Models/Repositories/Services) + SharedUI
* 代码规范：SwiftLint（本仓库根目录 `.swiftlint.yml`）

## 目录结构（节选）
```
SafeDriverNote/
	App/                # 入口与依赖注入
	Core/
		Models/           # SwiftData @Model
		Repositories/     # 数据仓库实现
		Services/         # 预留服务 (Speech/Media/Permissions)
		Utils/            # 全局容器、播种
	Features/
		Checklist/
		DriveLog/
		Knowledge/
	SharedUI/
	Resources/
	Tests/
.swiftlint.yml
```

## 构建步骤
1. 打开 Xcode: `File > Open...` 选择仓库根目录（或直接双击未来生成的 `SafeDriverNote.xcodeproj`）。
2. 目标设备选择 iOS 17 模拟器 (例如 iPhone 15)。
3. 直接运行 (⌘R)。首启会自动播种知识卡数据。

> 目前尚未加入语音 / 照片 / 测试 Target 的具体实现；后续按 `docs/mvp-implementation-plan.md` 推进。

## SwiftLint 集成方式
### 1. 安装（任选其一）
Homebrew:
```bash
brew install swiftlint
```
或 Mint（可选）：
```bash
brew install mint
mint install realm/SwiftLint
```

### 2. 手动在 Xcode 添加 Build Phase（建议）
`Targets > Build Phases > + > New Run Script Phase` 并添加：
```bash
if which swiftlint >/dev/null; then
	swiftlint --config "${SRCROOT}/.swiftlint.yml"
else
	echo "SwiftLint not installed. Run 'brew install swiftlint'"
fi
```

### 3. 命令行快速检查
```bash
swiftlint lint --config .swiftlint.yml
./scripts/swiftlint_fix.sh   # 自动修复 + 严格校验
```

## 运行与调试提示
* 首次运行的知识卡数据只播种一次，如需重置：在模拟器删除 App 或清除 UserDefaults 中 `seed_knowledge_v1`。
* SwiftData 存储位于应用容器沙盒；调试模型结构变更时，如遇崩溃，可先卸载 App 重新安装。

## 持续集成 (GitHub Actions)
工作流文件：`.github/workflows/ios-ci.yml`
触发：对 `main` 的 push / PR
流程：
1. Job `lint`：安装 SwiftLint → (可选) autocorrect → 严格 lint（warning 计入阈值）→ 可选 analyzer（PR 才运行）。
2. Job `build-test`：依赖 `lint` 成功后执行 `xcodebuild clean test` (iPhone 15 模拟器)。
3. 并发控制：同一 ref 的旧工作流自动取消。
4. 产出：失败时上传日志供排查。

若后续添加 UI Tests，可在命令中增加 `-only-testing:` 或 `-parallel-testing-enabled YES` 优化时长。

## 后续待办（节选）
详见 `docs/mvp-implementation-plan.md`。
* 图片选择与缓存
* 语音录制与转写服务
* 单元 & UI 测试补齐
* CI（GitHub Actions）流水线

## 贡献规范
* 使用 feature 分支：`feature/<short-description>`
* PR 需通过 SwiftLint 无 blocker 警告 & 编译成功
* 提交信息建议格式：`feat: xxx` / `fix: xxx` / `refactor: xxx`

## 许可证
当前未指定（默认保留所有权）。可根据需要添加 MIT / Apache-2.0 等 LICENSE 文件。

---
若需自动生成 GitHub Actions 或添加测试骨架，请继续提出。 
