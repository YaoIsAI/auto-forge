#!/bin/bash
# Forge Hook 监控脚本
# 检查 hooks 是否正常工作

LOG_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-hook.log"
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"
LAST_ACTIVITY_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-last-activity"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "=== Forge Hook 监控 ==="
echo ""

# 检查状态文件
if [ -f "$STATE_FILE" ]; then
  log_info "状态文件存在: $STATE_FILE"
  current_phase=$(jq -r '.current_phase // 0' "$STATE_FILE")
  total_phases=$(jq -r '.total_phases // 0' "$STATE_FILE")
  echo "  当前 Phase: $current_phase / $total_phases"
else
  log_warn "状态文件不存在"
fi

echo ""

# 检查日志文件
if [ -f "$LOG_FILE" ]; then
  log_info "日志文件存在: $LOG_FILE"
  echo "  最近 10 条日志:"
  tail -10 "$LOG_FILE" | sed 's/^/    /'
  echo ""
  echo "  总日志条数: $(wc -l < "$LOG_FILE")"
else
  log_warn "日志文件不存在: $LOG_FILE"
  echo "  如果 hooks 正在运行，日志应该会生成"
fi

echo ""

# 检查最后活动时间
if [ -f "$LAST_ACTIVITY_FILE" ]; then
  last_activity=$(cat "$LAST_ACTIVITY_FILE")
  current_time=$(date +%s)
  elapsed=$((current_time - last_activity))

  log_info "最后活动时间: $(date -d @$last_activity 2>/dev/null || date -r $last_activity 2>/dev/null || echo "$last_activity")"
  echo "  距今: $elapsed 秒"

  if [ $elapsed -gt 300 ]; then
    log_warn "超过 5 分钟没有活动，hooks 可能未正常运行"
  fi
else
  log_warn "最后活动时间文件不存在"
fi

echo ""

# 检查 hooks 文件
HOOKS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude"
if [ -d "$HOOKS_DIR" ]; then
  log_info "Hooks 目录存在: $HOOKS_DIR"
  echo "  文件列表:"
  ls -la "$HOOKS_DIR"/*.sh 2>/dev/null | sed 's/^/    /'
else
  log_warn "Hooks 目录不存在: $HOOKS_DIR"
  echo "  请运行 setup-hooks.sh 安装 hooks"
fi
