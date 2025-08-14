# 文档索引（docs）

> 项目：安全驾驶日记（Safe Driver Note）

## 文档导航
- [开发路线图（Roadmap）](./roadmap.md)
- [Figma 链接与交接规范](./figma.md) · [无需 Figma 的设计流程](./design-without-figma.md)
- 设计原型（浏览器打开）：
  - [设计首页](../design/index.html)
  - [设计系统](../design/design-system.html)
  - [线框图](../design/wireframes.html)
  - [交互原型](../design/prototypes.html)
  - [用户体验](../design/user-flow.html)
- 流程规范：
  - [迭代与看板指南](./process/sprint-guide.md)
  - 指标模板：[迭代燃尽图](./metrics/burndown.md)
- Issue 模板：
  - 功能需求模板：[issue-feature.md](./templates/issue-feature.md)
  - 缺陷问题模板：[issue-bug.md](./templates/issue-bug.md)
  - 技术任务模板：[issue-task.md](./templates/issue-task.md)
- Sprint：
  - [Sprint 1 Backlog](./sprint-1-backlog.md)
- 样例数据：
  - 清单数据：[`samples/checklist.json`](./samples/checklist.json)
  - 知识卡片：[`samples/knowledge.json`](./samples/knowledge.json)
- 需求初稿：[`init.md`](../init.md)

## 目标与范围（摘录）
- 核心价值：把“每一次失误”变成“下一次安全”的筹码
- MVP 范围：驾驶日志 + 安全检查清单 + 知识卡（离线）
- 设计原则：简约、大气、实用；符合 Apple HIG；安全优先

## 快速开始（面向开发）
- iOS 版本：iOS 17+
- 技术栈：Swift 5.9+ / SwiftUI / Combine / SwiftData（或 Core Data）
- 系统能力：CoreLocation、Speech、AVFoundation、Photos、Notifications、BackgroundTasks、MapKit

更多细节请见《开发路线图》。
