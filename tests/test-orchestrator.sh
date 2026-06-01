#!/bin/bash
# 测试 orchestrator.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCHESTRATOR="$SCRIPT_DIR/../skills/forge/scripts/orchestrator.sh"
export PATH="/c/Users/yao/.local/bin:$PATH"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 测试计数
TESTS_PASSED=0
TESTS_FAILED=0

# 测试函数
assert_equals() {
  local expected="$1"
  local actual="$2"
  local description="$3"

  if [ "$expected" = "$actual" ]; then
    echo -e "${GREEN}✓ PASS${NC}: $description"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗ FAIL${NC}: $description"
    echo "  Expected: $expected"
    echo "  Actual: $actual"
    ((TESTS_FAILED++))
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local description="$3"

  if echo "$haystack" | grep -q "$needle"; then
    echo -e "${GREEN}✓ PASS${NC}: $description"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗ FAIL${NC}: $description"
    echo "  Expected to contain: $needle"
    echo "  Actual: $haystack"
    ((TESTS_FAILED++))
  fi
}

# 清理函数
cleanup() {
  rm -rf "$CLAUDE_PROJECT_DIR"
}

# 设置测试环境
setup() {
  export CLAUDE_PROJECT_DIR=$(mktemp -d)
  cd "$CLAUDE_PROJECT_DIR"
}

# 测试用例
test_detect_project_type() {
  echo "=== 测试 detect_project_type ==="

  # 测试 Node.js 项目
  touch package.json
  local type=$("$ORCHESTRATOR" detect)
  assert_equals "node" "$type" "检测 Node.js 项目"
  rm package.json

  # 测试 Rust 项目
  touch Cargo.toml
  type=$("$ORCHESTRATOR" detect)
  assert_equals "rust" "$type" "检测 Rust 项目"
  rm Cargo.toml

  # 测试 Python 项目
  touch requirements.txt
  type=$("$ORCHESTRATOR" detect)
  assert_equals "python" "$type" "检测 Python 项目"
  rm requirements.txt

  # 测试 Go 项目
  touch go.mod
  type=$("$ORCHESTRATOR" detect)
  assert_equals "go" "$type" "检测 Go 项目"
  rm go.mod

  # 测试未知项目
  type=$("$ORCHESTRATOR" detect)
  assert_equals "unknown" "$type" "检测未知项目"
}

test_init_task() {
  echo ""
  echo "=== 测试 init_task ==="

  # 初始化任务
  "$ORCHESTRATOR" init "测试任务" 3

  # 验证状态文件
  assert_equals "true" "$([ -f .forge-state.json ] && echo "true" || echo "false")" "状态文件已创建"

  local task=$(jq -r '.task' .forge-state.json)
  assert_equals "测试任务" "$task" "任务描述正确"

  local total=$(jq -r '.total_phases' .forge-state.json)
  assert_equals "3" "$total" "Phase 数量正确"
}

test_resume_task() {
  echo ""
  echo "=== 测试 resume_task ==="

  # 先创建任务
  "$ORCHESTRATOR" init "恢复测试" 5 > /dev/null 2>&1

  # 恢复任务（只获取最后一行输出）
  local current=$("$ORCHESTRATOR" resume 2>/dev/null | tail -1)
  assert_equals "0" "$current" "恢复到初始状态"
}

test_next_phase() {
  echo ""
  echo "=== 测试 next_phase ==="

  # 初始化任务
  "$ORCHESTRATOR" init "Next Phase 测试" 3

  # 获取下一个 Phase
  local next=$("$ORCHESTRATOR" next)
  assert_equals "1" "$next" "下一个 Phase 为 1"

  # 添加并完成 Phase 1
  "$SCRIPT_DIR/../skills/forge/scripts/state-manager.sh" add-phase 1 "Phase 1"
  "$SCRIPT_DIR/../skills/forge/scripts/state-manager.sh" update-phase 1 "completed"

  # 获取下一个 Phase
  next=$("$ORCHESTRATOR" next)
  assert_equals "2" "$next" "下一个 Phase 为 2"
}

test_git_init() {
  echo ""
  echo "=== 测试 git_init ==="

  # 初始化 git
  local branch=$("$ORCHESTRATOR" git-init)

  # 验证 git 仓库已初始化
  assert_equals "true" "$(git rev-parse --git-dir > /dev/null 2>&1 && echo "true" || echo "false")" "Git 仓库已初始化"

  # 验证有初始 commit
  local commit_count=$(git rev-list --count HEAD 2>/dev/null || echo "0")
  assert_equals "1" "$commit_count" "有初始 commit"
}

test_git_commit() {
  echo ""
  echo "=== 测试 git_commit ==="

  # 初始化 git
  "$ORCHESTRATOR" git-init > /dev/null 2>&1

  # 创建测试文件
  echo "test" > test.txt

  # 提交
  local commit_hash=$("$ORCHESTRATOR" git-commit 1 "测试 Phase" "测试提交")

  # 验证 commit
  assert_equals "true" "$([ -n "$commit_hash" ] && echo "true" || echo "false")" "Commit hash 已返回"

  local commit_msg=$(git log -1 --pretty=%B)
  assert_contains "$commit_msg" "forge(phase-1)" "Commit message 包含 forge(phase-1)"
}

test_git_log() {
  echo ""
  echo "=== 测试 git_log ==="

  # 初始化 git
  "$ORCHESTRATOR" git-init > /dev/null 2>&1

  # 创建一些 commit
  echo "test1" > test1.txt
  "$ORCHESTRATOR" git-commit 1 "Phase 1" "第一次提交" > /dev/null 2>&1

  echo "test2" > test2.txt
  "$ORCHESTRATOR" git-commit 2 "Phase 2" "第二次提交" > /dev/null 2>&1

  # 获取日志
  local log_output=$("$ORCHESTRATOR" git-log)

  assert_contains "$log_output" "forge(phase-1)" "日志包含 Phase 1"
  assert_contains "$log_output" "forge(phase-2)" "日志包含 Phase 2"
}

# 主测试流程
echo "=== Forge Orchestrator 测试 ==="
echo ""

setup

test_detect_project_type
test_init_task
test_resume_task
test_next_phase
test_git_init
test_git_commit
test_git_log

# 清理
cleanup

echo ""
echo "=== 测试结果 ==="
echo -e "${GREEN}通过: $TESTS_PASSED${NC}"
echo -e "${RED}失败: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}所有测试通过!${NC}"
  exit 0
else
  echo -e "${RED}有测试失败!${NC}"
  exit 1
fi
