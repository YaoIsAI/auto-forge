#!/bin/bash
# Forge Retry Handler
# 处理失败重试逻辑

set -e

STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检查并执行重试
handle_retry() {
  local phase_id="$1"
  local error_type="$2"

  if [ ! -f "$STATE_FILE" ]; then
    echo "Error: State file not found"
    exit 1
  fi

  # 检查是否可以重试
  local can_retry=$("$SCRIPT_DIR/state-manager.sh" can-retry)
  if [ "$can_retry" = "false" ]; then
    echo "Max retries reached for Phase $phase_id"
    "$SCRIPT_DIR/state-manager.sh" update-phase "$phase_id" "failed"
    return 1
  fi

  # 增加重试计数
  "$SCRIPT_DIR/state-manager.sh" retry

  local retry_count=$(jq -r '.retry_count' "$STATE_FILE")
  echo "Retry $retry_count for Phase $phase_id (error: $error_type)"

  # 根据错误类型决定重试策略
  case "$error_type" in
    build)
      echo "Retrying build..."
      retry_build "$phase_id"
      ;;
    test)
      echo "Retrying tests..."
      retry_test "$phase_id"
      ;;
    *)
      echo "Retrying phase..."
      retry_phase "$phase_id"
      ;;
  esac
}

# 重试构建
retry_build() {
  local phase_id="$1"

  # 检测项目类型并执行构建
  if [ -f "package.json" ]; then
    npm run build 2>&1 || true
  elif [ -f "Cargo.toml" ]; then
    cargo build 2>&1 || true
  elif [ -f "requirements.txt" ]; then
    python -m py_compile *.py 2>&1 || true
  fi
}

# 重试测试
retry_test() {
  local phase_id="$1"

  # 检测项目类型并执行测试
  if [ -f "package.json" ]; then
    npm test 2>&1 || true
  elif [ -f "Cargo.toml" ]; then
    cargo test 2>&1 || true
  elif [ -f "requirements.txt" ]; then
    python -m pytest 2>&1 || true
  fi
}

# 重试整个 Phase
retry_phase() {
  local phase_id="$1"

  # 回滚到 Phase 开始前的状态
  if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Rolling back to pre-phase state..."
    git stash push -m "forge-phase-${phase_id}-retry" 2>/dev/null || true
  fi

  # 重置 Phase 状态为 pending
  "$SCRIPT_DIR/state-manager.sh" update-phase "$phase_id" "pending"
}

# 分析错误类型
analyze_error() {
  local error_output="$1"

  if echo "$error_output" | grep -qi "build\|compile\|syntax"; then
    echo "build"
  elif echo "$error_output" | grep -qi "test\|assert\|expect"; then
    echo "test"
  else
    echo "unknown"
  fi
}

# 主入口
case "$1" in
  handle)
    handle_retry "$2" "$3"
    ;;
  analyze)
    analyze_error "$2"
    ;;
  *)
    echo "Usage: $0 {handle|analyze} [args...]"
    exit 1
    ;;
esac
