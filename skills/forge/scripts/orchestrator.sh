#!/bin/bash
# Forge Orchestrator
# 编排 Phase 执行流程

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# 初始化新任务
init_task() {
  local task="$1"
  local total_phases="$2"

  # 验证参数
  if [ -z "$task" ]; then
    log_error "任务描述不能为空"
    return 1
  fi

  if [ -z "$total_phases" ] || [ "$total_phases" -lt 1 ] 2>/dev/null; then
    log_error "Phase 数量必须大于 0"
    return 1
  fi

  "$SCRIPT_DIR/state-manager.sh" create "$task" "$total_phases"
  if [ $? -ne 0 ]; then
    log_error "创建状态文件失败"
    return 1
  fi

  log_info "任务已初始化: $task ($total_phases phases)"
}

# 从断点恢复
resume_task() {
  if [ ! -f "$STATE_FILE" ]; then
    log_error "状态文件不存在，无法恢复"
    return 1
  fi

  # 验证状态文件
  if ! jq -e '.version' "$STATE_FILE" > /dev/null 2>&1; then
    log_error "状态文件格式无效"
    return 1
  fi

  local current_phase=$("$SCRIPT_DIR/state-manager.sh" current-phase)
  local total_phases=$("$SCRIPT_DIR/state-manager.sh" total-phases)

  log_info "从 Phase $current_phase / $total_phases 恢复"
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
    log_info "初始化 Git 仓库..."
    git init
    if [ $? -ne 0 ]; then
      log_error "Git 初始化失败"
      return 1
    fi

    git add -A
    git commit -m "forge: initial commit before task"
    if [ $? -ne 0 ]; then
      log_error "Git 初始提交失败"
      return 1
    fi

    log_info "Git 仓库已初始化"
  else
    log_info "检测到 Git 仓库"

    # 检查是否有 commit
    if git rev-parse HEAD > /dev/null 2>&1; then
      local current_head=$(git rev-parse HEAD)
      log_info "当前 HEAD: ${current_head:0:7}"
    else
      log_warn "空仓库（暂无提交）"
    fi

    # 检查是否有未提交的更改
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
      log_info "保存当前更改..."
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

  # 验证参数
  if [ -z "$phase_id" ] || [ -z "$phase_name" ]; then
    log_error "Phase ID 和名称不能为空"
    return 1
  fi

  git add -A
  if [ $? -ne 0 ]; then
    log_error "Git add 失败"
    return 1
  fi

  git commit -m "forge(phase-${phase_id}): ${phase_name}

${commit_msg}

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
  if [ $? -ne 0 ]; then
    log_error "Git commit 失败"
    return 1
  fi

  log_info "已提交: forge(phase-${phase_id}): ${phase_name}"

  # 返回 commit hash
  git rev-parse HEAD
}

# Git revert to phase
git_revert() {
  local phase_id="$1"

  if [ ! -f "$STATE_FILE" ]; then
    log_error "状态文件不存在"
    return 1
  fi

  # 验证 phase_id
  if [ -z "$phase_id" ] || ! [[ "$phase_id" =~ ^[0-9]+$ ]]; then
    log_error "无效的 Phase ID: $phase_id"
    return 1
  fi

  local commit_hash=$(jq -r --arg id "$phase_id" '.phases[] | select(.id == ($id | tonumber)) | .commit_hash // ""' "$STATE_FILE" 2>/dev/null)

  if [ -z "$commit_hash" ] || [ "$commit_hash" = "null" ]; then
    log_error "Phase $phase_id 没有对应的 commit"
    return 1
  fi

  log_info "=== 回撤预览 ==="
  log_info "Phase $phase_id commit: $commit_hash"
  echo ""
  echo "将要回撤的变更:"
  git show --stat "$commit_hash" | head -20
  echo ""

  # 执行 revert
  log_info "正在回撤..."
  git revert --no-edit "$commit_hash"
  if [ $? -ne 0 ]; then
    log_error "Git revert 失败"
    return 1
  fi

  echo ""
  log_info "=== 回撤完成 ==="
  log_info "Phase $phase_id 已回撤"
  log_info "当前 HEAD: $(git rev-parse HEAD | head -c 7)"
}

# Git log
git_log() {
  log_info "=== Forge Phase 历史 ==="
  echo ""

  local forge_commits=$(git log --oneline --grep="forge(phase" 2>/dev/null)
  if [ -n "$forge_commits" ]; then
    echo "$forge_commits"
  else
    log_warn "未找到 forge commit"
  fi
  echo ""

  if [ -f "$STATE_FILE" ]; then
    log_info "=== Phase 详情 ==="
    local total=$(jq -r '.total_phases' "$STATE_FILE" 2>/dev/null)
    if [ -n "$total" ] && [ "$total" -gt 0 ] 2>/dev/null; then
      for i in $(seq 1 "$total"); do
        local status=$(jq -r ".phases[] | select(.id == $i) | .status" "$STATE_FILE" 2>/dev/null)
        local commit=$(jq -r ".phases[] | select(.id == $i) | .commit_hash // \"N/A\"" "$STATE_FILE" 2>/dev/null)
        local name=$(jq -r ".phases[] | select(.id == $i) | .name" "$STATE_FILE" 2>/dev/null)

        # 状态着色
        local status_display=""
        case "$status" in
          completed) status_display="${GREEN}✓ completed${NC}" ;;
          in_progress) status_display="${YELLOW}● in_progress${NC}" ;;
          pending) status_display="○ pending" ;;
          failed) status_display="${RED}✗ failed${NC}" ;;
          *) status_display="$status" ;;
        esac

        echo -e "Phase $i: $name [$status_display] commit: ${commit:0:7}"
      done
    fi
    echo ""
  fi

  log_info "=== 最近提交 (最近 10 条) ==="
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
