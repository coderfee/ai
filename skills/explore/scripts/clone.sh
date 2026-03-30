#!/bin/bash
set -e

REPO="$1"
TARGET_DIR="$1"

# 1. 参数检查
if [ -z "$REPO" ]; then
  echo "错误：请提供仓库路径，格式：owner/repo"
  exit 1
fi

# 2. 检查 gh CLI 是否可用
if ! command -v gh &> /dev/null; then
  echo "错误：GitHub CLI (gh) 未安装，请先安装 gh 工具"
  exit 1
fi

# 3. 检查目录是否已存在
if [ -d "$TARGET_DIR" ]; then
  echo "✅ 仓库已存在于 $TARGET_DIR"
  exit 0
fi

# 4. 检查仓库是否可访问
if ! gh repo view "$REPO" &> /dev/null; then
  echo "错误：无法访问仓库 $REPO，请检查仓库是否存在或当前 GitHub CLI 是否有权限访问"
  exit 1
fi

# 5. 执行克隆
echo "🔽 正在克隆 $REPO 到 $TARGET_DIR..."
gh repo clone "$REPO" "$TARGET_DIR"

# 6. 完成
echo "✅ 克隆完成: $TARGET_DIR"
exit 0
