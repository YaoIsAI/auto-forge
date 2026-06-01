#!/bin/bash
# Forge Retry Handler
# 处理失败重试逻辑

set -e

STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检测项目类型
detect_project_type() {
  if [ -f "package.json" ]; then
    echo "node"
  elif [ -f "Cargo.toml" ]; then
    echo "rust"
  elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
    echo "python"
  elif [ -f "go.mod" ]; then
    echo "go"
  else
    echo "unknown"
  fi
}

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
  local project_type=$(detect_project_type)

  case "$project_type" in
    node)
      npm run build 2>&1
      ;;
    rust)
      cargo build 2>&1
      ;;
    python)
      python -m py_compile *.py 2>&1 || python -m build 2>&1
      ;;
    go)
      go build ./... 2>&1
      ;;
    *)
      echo "Unknown project type, skipping build"
      return 0
      ;;
  esac
}

# 重试测试
retry_test() {
  local phase_id="$1"
  local project_type=$(detect_project_type)

  case "$project_type" in
    node)
      npm test 2>&1
      ;;
    rust)
      cargo test 2>&1
      ;;
    python)
      python -m pytest 2>&1
      ;;
    go)
      go test ./... 2>&1
      ;;
    *)
      echo "Unknown project type, skipping tests"
      return 0
      ;;
  esac
}

# 重试整个 Phase
retry_phase() {
  local phase_id="$1"

  # 回滚到 Phase 开始前的状态
  if git rev-parse --git-dir > /dev/null 2>&1; then
    # 获取该 Phase 的 commit hash
    local commit_hash=$("$SCRIPT_DIR/state-manager.sh" get-commit "$phase_id")

    if [ -n "$commit_hash" ] && [ "$commit_hash" != "null" ]; then
      echo "Reverting commit: $commit_hash"
      git revert --no-edit "$commit_hash" 2>/dev/null || {
        echo "Warning: git revert failed, trying git reset"
        git reset --hard HEAD~1 2>/dev/null || true
      }
    else
      echo "No commit hash found for Phase $phase_id"
    fi
  fi

  # 重置 Phase 状态为 pending
  "$SCRIPT_DIR/state-manager.sh" update-phase "$phase_id" "pending"
}

# 分析错误类型
analyze_error() {
  local error_output="$1"

  if echo "$error_output" | grep -qi "build\|compile\|syntax\|module not found"; then
    echo "build"
  elif echo "$error_output" | grep -qi "test\|assert\|expect\|fail"; then
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
  detect)
    detect_project_type
    ;;
  *)
    echo "Usage: $0 {handle|analyze|detect} [args...]"
    exit 1
    ;;
esac
