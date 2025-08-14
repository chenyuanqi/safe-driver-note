# Figma 链接与版本规范

> 目的：集中管理 Figma 链接与交接规范，保证设计与开发的一致性与可追踪性。

> 没有 Figma？请直接使用「[无需 Figma 的设计流程](./design-without-figma.md)」。仓库内置 HTML 原型可一键查看与修改。

## 链接总览（占位，待替换）
- 设计系统（Design System）
  - URL：`https://www.figma.com/file/xxxxxxxx/Design-System?node-id=0-0`  （TODO：替换为真实链接）
- 用户流程与信息架构（Flows & IA）
  - URL：`https://www.figma.com/file/xxxxxxxx/User-Flows-IA?node-id=0-0`
- 核心页面线框图（Wireframes）
  - URL：`https://www.figma.com/file/xxxxxxxx/Wireframes?node-id=0-0`
- 高保真原型（Prototypes）
  - URL：`https://www.figma.com/file/xxxxxxxx/HiFi-Prototypes?node-id=0-0`

> 更新指引：将以上链接替换为真实 Figma 文件地址，并在每次重大更新后在本页记录“更新记录”。

## 页面与命名规范
- 文件结构：顶层 Page 建议分为「Design System / Flows / Wireframes / Prototypes / Assets」。
- 画板命名：`[平台]-[页面]-[状态]-[版本]`，例如：`iOS-Home-Default-v1.0`。
- 组件命名：遵循 BEM 风格或语义命名，保持与代码组件库一致（Button/Card/Input/Tag 等）。
- 尺寸基准：iPhone 14/15（390×844 pt）为主，适配 iPhone SE（375×667 pt）。

## 版本与变更
- 版本标记：在 Page 名称或封面 Frame 上标注里程碑标签，如 `[M1]`、`[M2]`。
- 变更日志：在 Figma “文件备注”与本页“更新记录”中同步记录（变更原因/影响/相关 Issue）。
- 评审流程：设计评审 → 走查验收 → 同步到代码（设计 token、标注、导出资源）。

## 交接规范（给开发）
1. 标注：使用 Figma Inspect 提供尺寸、间距、颜色、字体等标注。
2. 设计 Token：颜色、字体、间距采用命名变量，确保与代码一致（参考 `design/design-system/*`）。
3. 资源导出：
   - 图标优先 SF Symbols；自定义图标用 SVG/PDF（矢量），必要时提供 @2x/@3x PNG。
   - 插画/位图：WebP/PNG，控制尺寸与体积（≤300KB 优先）。
4. 交互说明：原型中补充过渡、手势与空状态；复杂交互在节点上添加注释。

## 与代码的映射（SwiftUI）
- 颜色（示例）：`primary/secondary/warning/danger/info` 对应 `Color` 扩展或资产目录。
- 字体层级：`text-4xl/3xl/2xl/xl/lg/base/sm/xs` → `Font.system(size:, weight:)` 映射表。
- 间距：8pt 网格 → `Spacing` 常量枚举（4/8/12/16/24/32/48/64）。
- 组件：Button/Card/Input/Tag/Progress 等与 UIComponents 保持同名同义。

## 更新记录
- 2025-01-xx：创建 Figma 链接占位与交接规范（待替换真实链接）。


