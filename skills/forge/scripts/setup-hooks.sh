#!/bin/bash
# Forge Hook 安装脚本
# 自动将 hooks 安装到当前项目

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
HOOKS_SOURCE="$PLUGIN_DIR/../../hooks"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
TARGET_DIR="$PROJECT_DIR/.claude"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查是否在 forge 插件目录中
if [ ! -d "$HOOKS_SOURCE" ]; then
  log_error "未找到 hooks 源目录: $HOOKS_SOURCE"
  exit 1
fi

# 创建目标目录
if [ ! -d "$TARGET_DIR" ]; then
  log_info "创建 .claude 目录..."
  mkdir -p "$TARGET_DIR"
fi

# 复制 hooks
log_info "复制 hooks 文件..."
for hook in "$HOOKS_SOURCE"/*.sh; do
  if [ -f "$hook" ]; then
    filename=$(basename "$hook")
    cp "$hook" "$TARGET_DIR/"
    chmod +x "$TARGET_DIR/$filename"
    log_info "已安装: $filename"
  fi
done

# 复制 settings.json（如果不存在）
SETTINGS_SOURCE="$HOOKS_SOURCE/../settings.json"
if [ -f "$SETTINGS_SOURCE" ] && [ ! -f "$TARGET_DIR/settings.json" ]; then
  log_info "复制 settings.json..."
  cp "$SETTINGS_SOURCE" "$TARGET_DIR/"
fi

# 复制 hooks.json
HOOKS_JSON_SOURCE="$HOOKS_SOURCE/hooks.json"
if [ -f "$HOOKS_JSON_SOURCE" ]; then
  log_info "复制 hooks.json..."
  cp "$HOOKS_JSON_SOURCE" "$TARGET_DIR/"
fi

log_info "Hooks 安装完成！"
log_info "现在可以使用 /forge 命令了。"
