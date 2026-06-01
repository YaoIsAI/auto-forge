#!/bin/bash
# Forge Orchestrator
# 编排 Phase 执行流程

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

  # 检查 total 是否有效
  if [ -z "$total" ] || [ "$total" -eq 0 ] 2>/dev/null; then
    echo "0"
    return
  fi

  for i in $(seq 1 "$total"); do
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
  elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
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
  local exit_code=0

  case "$project_type" in
    node)
      npm run build 2>&1 || exit_code=$?
      ;;
    rust)
      cargo build 2>&1 || exit_code=$?
      ;;
    python)
      python -m py_compile *.py 2>&1 || python -m build 2>&1 || exit_code=$?
      ;;
    go)
      go build ./... 2>&1 || exit_code=$?
      ;;
    *)
      echo "Unknown project type, skipping build"
      return 0
      ;;
  esac

  return $exit_code
}

# 执行测试命令
run_test() {
  local project_type=$(detect_project_type)
  local exit_code=0

  case "$project_type" in
    node)
      npm test 2>&1 || exit_code=$?
      ;;
    rust)
      cargo test 2>&1 || exit_code=$?
      ;;
    python)
      python -m pytest 2>&1 || exit_code=$?
      ;;
    go)
      go test ./... 2>&1 || exit_code=$?
      ;;
    *)
      echo "Unknown project type, skipping tests"
      return 0
      ;;
  esac

  return $exit_code
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

  if [ -z "$total" ] || [ "$total" -eq 0 ] 2>/dev/null; then
    echo "Error: No phases found"
    return 1
  fi

  "$SCRIPT_DIR/archive-gen.sh" final "$total" "$task"
}

# Git 初始化
git_init() {
  local has_git=false

  if git rev-parse --git-dir > /dev/null 2>&1; then
    has_git=true
  fi

  if [ "$has_git" = false ]; then
    # 没有 git，初始化
    git init
    git add -A
    git commit -m "forge: initial commit before task"
    echo "Git repository initialized"
  else
    # 已有 git，保存当前状态
    echo "Git repository detected"

    # 检查是否有 commit
    if git rev-parse HEAD > /dev/null 2>&1; then
      local current_head=$(git rev-parse HEAD)
      echo "Current HEAD: $current_head"
    else
      echo "Empty repository (no commits yet)"
    fi

    # 检查是否有未提交的更改
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
      echo "Saving current changes..."
      git stash push -m "forge: save current work before task" 2>/dev/null || true
    fi
  fi

  # 返回当前分支名
  git branch --show-current 2>/dev/null || echo "HEAD"
}

# Git commit
git_commit() {
  local phase_id="$1"
  local phase_name="$2"
  local commit_msg="$3"

  git add -A
  git commit -m "forge(phase-${phase_id}): ${phase_name}

${commit_msg}

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"

  # 返回 commit hash
  git rev-parse HEAD
}

# Git revert to phase
git_revert() {
  local phase_id="$1"

  if [ ! -f "$STATE_FILE" ]; then
    echo "Error: No state file found"
    exit 1
  fi

  local commit_hash=$(jq -r --arg id "$phase_id" '.phases[] | select(.id == ($id | tonumber)) | .commit_hash // ""' "$STATE_FILE" 2>/dev/null)

  if [ -z "$commit_hash" ] || [ "$commit_hash" = "null" ]; then
    echo "Error: No commit hash found for Phase $phase_id"
    exit 1
  fi

  echo "=== Revert Preview ==="
  echo "Phase $phase_id commit: $commit_hash"
  echo ""
  echo "Changes to be reverted:"
  git show --stat "$commit_hash" | head -20
  echo ""

  # 执行 revert
  echo "Reverting..."
  git revert --no-edit "$commit_hash"

  echo ""
  echo "=== Revert Complete ==="
  echo "Phase $phase_id has been reverted"
  echo "Current HEAD: $(git rev-parse HEAD)"
}

# Git log
git_log() {
  echo "=== Forge Phase History ==="
  echo ""
  git log --oneline --grep="forge(phase" 2>/dev/null || echo "No forge commits found"
  echo ""

  if [ -f "$STATE_FILE" ]; then
    echo "=== Phase Details ==="
    local total=$(jq -r '.total_phases' "$STATE_FILE" 2>/dev/null)
    if [ -n "$total" ] && [ "$total" -gt 0 ] 2>/dev/null; then
      for i in $(seq 1 "$total"); do
        local status=$(jq -r ".phases[] | select(.id == $i) | .status" "$STATE_FILE" 2>/dev/null)
        local commit=$(jq -r ".phases[] | select(.id == $i) | .commit_hash // \"N/A\"" "$STATE_FILE" 2>/dev/null)
        local name=$(jq -r ".phases[] | select(.id == $i) | .name" "$STATE_FILE" 2>/dev/null)
        echo "Phase $i: $name [$status] commit: ${commit:0:7}"
      done
    fi
    echo ""
  fi

  echo "=== Recent Commits (last 10) ==="
  git log --oneline -10
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
  git-init)
    git_init
    ;;
  git-commit)
    git_commit "$2" "$3" "$4"
    ;;
  git-revert)
    git_revert "$2"
    ;;
  git-log)
    git_log
    ;;
  *)
    echo "Usage: $0 {init|resume|next|can-execute|detect|build|test|lint|final|git-init|git-commit|git-revert|git-log} [args...]"
    exit 1
    ;;
esac
