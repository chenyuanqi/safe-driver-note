# SafeDriverNote 项目文档

欢迎来到 SafeDriverNote 项目文档中心！这里包含了项目的所有相关文档，按类别组织以便于查找和维护。

## 📁 文档结构

### 🏗️ 设计文档 (`design/`)
设计相关的所有文档，包括界面设计、用户体验和视觉规范。

- **[设计系统](design/design-system/)** - 颜色、字体、组件等设计规范
  - [颜色规范](design/design-system/colors.md)
  - [字体规范](design/design-system/typography.md)
  - [间距规范](design/design-system/spacing.md)
  - [组件库](design/design-system/components.md)

- **[线框图](design/wireframes/)** - 各页面的线框图设计
  - [首页设计](design/wireframes/01-home.md)
  - [驾驶日志](design/wireframes/02-drive-log.md)
  - [检查清单](design/wireframes/03-checklist.md)
  - [知识卡片](design/wireframes/04-knowledge-cards.md)

- **[用户流程](design/user-flow/)** - 用户体验和交互流程
  - [信息架构](design/user-flow/information-architecture.md)
  - [用户旅程](design/user-flow/user-journey.md)

- **[原型设计](design/prototypes/)** - 交互原型和流程设计
  - [交互流程](design/prototypes/interaction-flows.md)

### 🚀 发布文档 (`release/`)
应用发布相关的所有文档和指南。

- **[App Store 发布指南](release/app-store-release-guide.md)** - 完整的 App Store 发布流程
- **[App Store 提交指南](release/app-store-submission-guide.md)** - 详细的提交步骤和要求
- **[TestFlight 测试指南](release/testflight-guide.md)** - 内部测试和 Beta 版本管理
- **[Xcode Cloud 故障排除](release/xcode-cloud-troubleshooting.md)** - 构建和部署问题解决

### 📱 营销文档 (`marketing/`)
应用推广和营销相关的所有材料。

- **[App Store 营销材料](marketing/app-store-marketing.md)** - 应用描述、关键词和推广文案
- **[截图指南](marketing/app-screenshots-guide.md)** - App Store 截图要求和最佳实践
- **[截图模板](marketing/screenshot-templates.md)** - 截图设计模板和规范

### ⚖️ 法律文档 (`legal/`)
隐私政策、服务条款等法律相关文档。

- **[隐私政策](legal/privacy-policy.md)** - 完整的隐私政策文档
- **[隐私政策托管指南](legal/privacy-policy-hosting-guide.md)** - 如何部署隐私政策页面

### 🛠️ 技术支持 (`support/`)
用户支持和技术文档。

- **[技术支持页面](support/technical-support.md)** - 用户技术支持文档
- **[支持页面托管指南](support/support-hosting-guide.md)** - 如何部署支持页面

### 💻 开发文档 (`development/`)
开发过程中的任务记录和技术文档。

- **[开发任务](development/quests/)** - 功能开发的详细记录
  - [首页预检查重设计](development/quests/home-pre-checklist-redesign.md)
  - [首页语音录制功能](development/quests/home-voice-recording-feature.md)
  - [语音录制功能开发](development/quests/voice-record-feature-development.md)

### 🏗️ 构建文档 (`build/`)
构建配置和部署相关文档。

- **[Xcode Cloud 配置](build/xcode-cloud-config.md)** - 自动构建配置说明

### 📊 项目管理
项目管理相关的文档和流程规范。

- **[迭代与看板指南](process/sprint-guide.md)** - 敏捷开发流程指南
- **[燃尽图](metrics/burndown.md)** - 项目进度跟踪

### 🧪 测试文档 (`testing/`)
测试计划、测试用例和测试报告。

- **[测试用例](testing/)** - 各功能模块的测试用例
  - [首页功能测试](testing/01-首页功能测试.md)
  - [驾驶日志测试](testing/02-驾驶日志测试.md)
  - [检查清单测试](testing/03-检查清单测试.md)
  - [知识学习测试](testing/04-知识学习测试.md)

### 📋 模板文档 (`templates/`)
项目中使用的各种模板。

- **[问题模板](templates/issue-bug.md)** - Bug 报告模板
- **[功能请求模板](templates/issue-feature.md)** - 功能请求模板
- **[任务模板](templates/issue-task.md)** - 任务跟踪模板

### 📦 样例数据 (`samples/`)
测试和开发用的示例数据。

- **[清单数据](samples/checklist.json)** - 检查清单示例数据
- **[知识卡片](samples/knowledge.json)** - 知识学习示例数据

## 🔍 快速导航

### 对于开发者
- [MVP 实现计划](mvp-implementation-plan.md) - 产品最小可行版本开发计划
- [项目路线图](roadmap.md) - 长期发展规划
- [冲刺1待办事项](sprint-1-backlog.md) - 当前迭代任务

### 对于设计师
- [设计系统概览](design/README.md) - 设计规范总览
- [Figma 使用指南](figma.md) - 设计工具使用说明
- [无 Figma 设计指南](design-without-figma.md) - 替代设计流程

### 对于产品经理
- [应用图标指南](AppIcon-Guide.md) - 应用图标设计要求
- [iCloud 同步指南](icloud-sync-guide.md) - 数据同步实现方案

### 对于测试人员
- [TestFlight 测试指南](release/testflight-guide.md) - Beta 测试流程
- [测试用例库](testing/) - 完整的测试用例集合

### 对于发布管理
- [App Store 发布完整指南](release/app-store-submission-guide.md) - 一站式发布指南
- [营销材料准备](marketing/) - 推广素材制作

## 🎯 项目概览

### 核心价值
把"每一次失误"变成"下一次安全"的筹码

### MVP 范围
驾驶日志 + 检查清单 + 知识卡（离线优先）

### 设计原则
简约、大气、实用；符合 Apple HIG；安全优先

### 技术栈
- **平台**: iOS 17+
- **语言**: Swift 5.9+
- **框架**: SwiftUI / Combine / SwiftData
- **系统能力**: CoreLocation、Speech、AVFoundation、Photos、Notifications、BackgroundTasks、MapKit

## 📝 文档维护

### 更新原则
1. **实时更新** - 功能变更时及时更新相关文档
2. **版本控制** - 重要文档变更需要记录版本历史
3. **清晰简洁** - 保持文档内容准确、易懂
4. **分类明确** - 新增文档放入合适的分类目录

### 贡献指南
- 新增文档请遵循现有的目录结构
- 文档标题使用中文，文件名使用英文或拼音
- 重要链接失效时及时更新
- 定期清理过时的文档内容

### 文档规范
- 使用 Markdown 格式编写
- 文件编码使用 UTF-8
- 图片资源放在对应目录的 `images/` 子目录中
- 外部链接需要定期检查有效性

---

**最后更新**: 2024年9月28日
**维护人员**: 项目开发团队

如有文档相关问题或建议，请创建 Issue 或直接联系项目维护人员。
