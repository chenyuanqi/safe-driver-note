#!/bin/bash
# 自动执行 SwiftLint（一遍修复 + 一遍严格检查）
set -euo pipefail
CONFIG="$(git rev-parse --show-toplevel)/.swiftlint.yml"
if ! command -v swiftlint >/dev/null 2>&1; then
  echo "SwiftLint 未安装，请先: brew install swiftlint" >&2
  exit 1
fi

# 1. 可自动修复（只对支持的规则）
swiftlint autocorrect --format --config "$CONFIG" || true
# 2. 严格检测
swiftlint lint --config "$CONFIG" --strict

echo "SwiftLint 检查通过。"
