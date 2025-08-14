#!/usr/bin/env bash
set -euo pipefail

# Create Sprint 1 issues via GitHub CLI (gh)
# Usage: ./scripts/create_sprint_issues.sh
# Prereq: gh auth login && gh repo set to this repo (run inside repo root)

if ! command -v gh >/dev/null 2>&1; then
  echo "[ERROR] GitHub CLI (gh) 未安装。请参考 https://cli.github.com/ 安装后重试。" >&2
  exit 1
fi

echo "==> 检查仓库上下文..."
gh repo view >/dev/null

# Create label sprint-1 if missing
if ! gh label list --limit 100 | grep -q "^sprint-1\b"; then
  echo "==> 创建标签: sprint-1"
  gh label create sprint-1 --color FF8C00 --description "Sprint 1 backlog"
fi

create_issue() {
  local title="$1"
  local body="$2"
  local labels="$3"

  echo "- 创建: ${title}"
  gh issue create \
    --title "${title}" \
    --body "${body}" \
    --label "${labels}"
}

echo "==> 创建 Sprint 1 Issues ..."

# E1 应用骨架与权限流
create_issue "E1: App Shell + Tab 导航（首页/日志/学习/我的）" \
"参考 docs/sprint-1-backlog.md#E1\n实现 SwiftUI TabView 与基本路由。\n验收：四个 Tab 可切换，状态保持正常。" \
"enhancement,sprint-1"

create_issue "E1: 权限请求与用途文案（定位/麦克风/相机/通知）" \
"参考 docs/sprint-1-backlog.md#E1\n实现权限请求引导与 Info.plist 用途文案。\n验收：首次进入时弹出引导，权限状态可查询。" \
"enhancement,sprint-1"

create_issue "E1: 设计 Token 常量（颜色/字体/间距）与基础组件（按钮/卡片）" \
"参考 design/design-system/* 与 docs/roadmap.md\n实现 SwiftUI 主题常量与通用按钮/卡片组件。" \
"enhancement,sprint-1"

# E2 检查清单
create_issue "E2: 检查清单模型与本地样例数据（pre/post）" \
"参考 docs/samples/checklist.json\n建立数据模型与加载本地样例。" \
"enhancement,sprint-1"

create_issue "E2: 清单列表 UI + 一键勾选、进度与评分" \
"参考 design/wireframes.html（检查清单）\n实现勾选交互与进度/评分展示。" \
"enhancement,sprint-1"

create_issue "E2: 简易徽章触发（连续完成 N 天）" \
"记录完成历史并触发基础徽章逻辑。" \
"enhancement,sprint-1"

create_issue "E2: 快照测试与无障碍检查" \
"为清单页面添加快照测试；检查 VoiceOver 与 Dynamic Type。" \
"test,sprint-1"

# E3 驾驶日志
create_issue "E3: 日志表单（失误/原因/改进/标签/照片占位）" \
"参考 design/wireframes.html（驾驶日志）\n实现表单与媒体占位（拍照/相册稍后实现）。" \
"enhancement,sprint-1"

create_issue "E3: 日志列表（日期/地点/标签展示）" \
"列表与筛选基础，UI 参考线框图。" \
"enhancement,sprint-1"

create_issue "E3: 语音转写占位与接口抽象（先返回固定文本）" \
"封装 Speech 接口，先返回固定文本以打通流程。" \
"enhancement,sprint-1"

create_issue "E3: 单元测试（ViewModel）与本地化" \
"为日志模块添加 ViewModel 单测与中文本地化。" \
"test,sprint-1"

# E4 知识卡
create_issue "E4: 知识卡数据模型与本地卡片（What/Why/How）" \
"参考 docs/samples/knowledge.json 建立数据结构。" \
"enhancement,sprint-1"

create_issue "E4: 今日 3 张卡的轮播浏览" \
"实现卡片滑动切换与进度指示。" \
"enhancement,sprint-1"

create_issue "E4: 标记掌握/需复习（本地状态）" \
"记录卡片掌握状态，为后续复习策略铺垫。" \
"enhancement,sprint-1"

echo "==> 完成。可在 GitHub Issues 中查看 'sprint-1' 标签的任务。"


