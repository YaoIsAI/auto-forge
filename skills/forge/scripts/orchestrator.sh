#!/bin/bash
# Forge Orchestrator
# 编排 Phase 执行流程

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"

# 初始化新任务
init_task() {
  local task="$1"
  local total_phases="$2"

  "$SCRIPT_DIR/state-manager.sh" create "$task" "$total_phases"
  echo "Initialized task: $task ($total_phases phases)"
}

# 从断点恢复
resume_task() {
  if [ ! -f "$STATE_FILE" ]; then
    echo "Error: No state file found. Cannot resume."
    exit 1
  fi

  local current_phase=$("$SCRIPT_DIR/state-manager.sh" current-phase)
  local total_phases=$("$SCRIPT_DIR/state-manager.sh" total-phases)

  echo "Resuming from Phase $current_phase of $total_phases"
  echo "$current_phase"
}

# 获取下一个待执行的 Phase
get_next_phase() {
  if [ ! -f "$STATE_FILE" ]; then
    echo "1"
    return
  fi

  local total=$("$SCRIPT_DIR/state-manager.sh" total-phases)

  for i in $(seq 1 $total); do
    local status=$(jq -r ".phases[] | select(.id == $i) | .status" "$STATE_FILE" 2>/dev/null)
    if [ "$status" = "pending" ] || [ -z "$status" ]; then
      echo "$i"
      return
    fi
  done

  # 所有 Phase 都已完成
  echo "0"
}

# 检查 Phase 是否可以执行
can_execute_phase() {
  local phase_id="$1"

  if [ ! -f "$STATE_FILE" ]; then
    echo "false"
    return
  fi

  local status=$(jq -r ".phases[] | select(.id == $phase_id) | .status" "$STATE_FILE" 2>/dev/null)

  if [ "$status" = "pending" ] || [ -z "$status" ]; then
    echo "true"
  else
    echo "false"
  fi
}

# 检测项目类型
detect_project_type() {
  if [ -f "package.json" ]; then
    echo "node"
  elif [ -f "Cargo.toml" ]; then
    echo "rust"
  elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    echo "python"
  elif [ -f "go.mod" ]; then
    echo "go"
  else
    echo "unknown"
  fi
}

# 执行构建命令
run_build() {
  local project_type=$(detect_project_type)

  case "$project_type" in
    node)
      npm run build 2>&1
      ;;
    rust)
      cargo build 2>&1
      ;;
    python)
      python -m py_compile *.py 2>&1
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

# 执行测试命令
run_test() {
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

# 执行 lint 命令
run_lint() {
  local project_type=$(detect_project_type)

  case "$project_type" in
    node)
      npm run lint 2>&1 || true
      ;;
    rust)
      cargo clippy 2>&1 || true
      ;;
    python)
      ruff check . 2>&1 || true
      ;;
    go)
      golangci-lint run 2>&1 || true
      ;;
    *)
      echo "Unknown project type, skipping lint"
      return 0
      ;;
  esac
}

# 生成最终报告
generate_final() {
  local task=""

  if [ -f "$STATE_FILE" ]; then
    task=$(jq -r '.task' "$STATE_FILE")
  fi

  local total=$("$SCRIPT_DIR/state-manager.sh" total-phases)
  "$SCRIPT_DIR/archive-gen.sh" archive final "$total" "$task"
}

# 主入口
case "$1" in
  init)
    init_task "$2" "$3"
    ;;
  resume)
    resume_task
    ;;
  next)
    get_next_phase
    ;;
  can-execute)
    can_execute_phase "$2"
    ;;
  detect)
    detect_project_type
    ;;
  build)
    run_build
    ;;
  test)
    run_test
    ;;
  lint)
    run_lint
    ;;
  final)
    generate_final
    ;;
  *)
    echo "Usage: $0 {init|resume|next|can-execute|detect|build|test|lint|final} [args...]"
    exit 1
    ;;
esac
