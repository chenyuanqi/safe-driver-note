# 迭代与看板指南（Scrum/Kanban）

## 节奏与会议
- Sprint 周期：2 周
- 会议：
  - 计划会（1.5h）：确定 Sprint 目标与范围，拆分与估算
  - 每日站会（15m）：进展/阻塞/当天计划
  - 评审会（45m）：演示已完成功能，对照验收标准
  - 回顾会（30m）：做得好/待改进/行动项

## 看板列与 WIP 限制
- 列：Backlog → Ready → In Progress → In Review → Testing → Done
- WIP：In Progress ≤ 3；In Review ≤ 5（可按团队规模调整）

## DoR / DoD
- 就绪定义 DoR（进入开发前）：
  - 目标清晰、原型/设计可用、数据/接口明确、依赖与风险已识别
- 完成定义 DoD（进入 Done 前）：
  - 代码合并、CI 绿灯、测试通过、无障碍与暗色模式检查、文档/CHANGELOG 更新

## 估算与容量
- 估算单位：Story Points（1/2/3/5/8）
- 容量：以最近 3 个 Sprint 的 Velocity 作为参考
- 追踪：维护 Sprint 燃尽图（见 `../metrics/burndown.md`）

## 提交流程（建议）
- 使用 Issue 模板创建需求/任务/缺陷
- 以 Issue 为单位建立分支：`feature/ISSUE-123-title`
- 提交 PR，对应 Issue，附截图/录屏与测试说明
- 代码评审：至少 1 位 Reviewer 通过

## 上线前检查
- 必须：测试用例通过、性能回归、权限与隐私说明确认、崩溃监控接入
- 可选：灰度发布/A-B 实验、埋点校验
