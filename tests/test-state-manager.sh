#!/bin/bash
# 测试 state-manager.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_MANAGER="$SCRIPT_DIR/../skills/forge/scripts/state-manager.sh"

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

# 清理函数
cleanup() {
  rm -f "$STATE_FILE"
}

# 设置测试环境
setup() {
  export CLAUDE_PROJECT_DIR=$(mktemp -d)
  STATE_FILE="$CLAUDE_PROJECT_DIR/.forge-state.json"
  cleanup
}

# 测试用例
test_create_state() {
  echo "=== 测试 create_state ==="

  # 创建状态
  "$STATE_MANAGER" create "测试任务" 3 "main" "abc123"

  # 验证文件存在
  assert_equals "true" "$([ -f "$STATE_FILE" ] && echo "true" || echo "false")" "状态文件已创建"

  # 验证内容
  local task=$(jq -r '.task' "$STATE_FILE")
  assert_equals "测试任务" "$task" "任务描述正确"

  local total=$(jq -r '.total_phases' "$STATE_FILE")
  assert_equals "3" "$total" "Phase 数量正确"

  local branch=$(jq -r '.git_branch' "$STATE_FILE")
  assert_equals "main" "$branch" "Git 分支正确"

  local commit=$(jq -r '.initial_commit' "$STATE_FILE")
  assert_equals "abc123" "$commit" "初始 commit 正确"
}

test_add_phase() {
  echo ""
  echo "=== 测试 add_phase ==="

  # 添加 Phase
  "$STATE_MANAGER" add-phase 1 "Phase 1: 初始化"

  # 验证
  local phase_count=$(jq '.phases | length' "$STATE_FILE")
  assert_equals "1" "$phase_count" "Phase 数量为 1"

  local phase_name=$(jq -r '.phases[0].name' "$STATE_FILE")
  assert_equals "Phase 1: 初始化" "$phase_name" "Phase 名称正确"

  local phase_status=$(jq -r '.phases[0].status' "$STATE_FILE")
  assert_equals "pending" "$phase_status" "Phase 状态为 pending"
}

test_update_phase_status() {
  echo ""
  echo "=== 测试 update_phase_status ==="

  # 更新为 in_progress
  "$STATE_MANAGER" update-phase 1 "in_progress"

  local status=$(jq -r '.phases[0].status' "$STATE_FILE")
  assert_equals "in_progress" "$status" "状态更新为 in_progress"

  # 更新为 completed
  "$STATE_MANAGER" update-phase 1 "completed"

  status=$(jq -r '.phases[0].status' "$STATE_FILE")
  assert_equals "completed" "$status" "状态更新为 completed"

  # 验证 completed_at 时间戳
  local completed_at=$(jq -r '.phases[0].completed_at' "$STATE_FILE")
  assert_equals "true" "$([ -n "$completed_at" ] && echo "true" || echo "false")" "completed_at 已设置"
}

test_update_phase_commit() {
  echo ""
  echo "=== 测试 update_phase_commit ==="

  # 更新 commit hash
  "$STATE_MANAGER" update-commit 1 "def456"

  local commit=$(jq -r '.phases[0].commit_hash' "$STATE_FILE")
  assert_equals "def456" "$commit" "Commit hash 正确"
}

test_get_phase_commit() {
  echo ""
  echo "=== 测试 get_phase_commit ==="

  local commit=$("$STATE_MANAGER" get-commit 1)
  assert_equals "def456" "$commit" "获取 commit hash 正确"
}

test_retry_count() {
  echo ""
  echo "=== 测试 retry_count ==="

  # 增加重试计数
  "$STATE_MANAGER" retry
  local count=$(jq -r '.retry_count' "$STATE_FILE")
  assert_equals "1" "$count" "重试计数为 1"

  # 检查是否可以重试
  local can_retry=$("$STATE_MANAGER" can-retry)
  assert_equals "true" "$can_retry" "还可以重试"

  # 继续增加
  "$STATE_MANAGER" retry
  "$STATE_MANAGER" retry
  count=$(jq -r '.retry_count' "$STATE_FILE")
  assert_equals "3" "$count" "重试计数为 3"

  # 检查是否可以重试（应该不能）
  can_retry=$("$STATE_MANAGER" can-retry)
  assert_equals "false" "$can_retry" "达到最大重试次数"

  # 重置重试计数
  "$STATE_MANAGER" reset-retry
  count=$(jq -r '.retry_count' "$STATE_FILE")
  assert_equals "0" "$count" "重试计数已重置"
}

test_is_all_completed() {
  echo ""
  echo "=== 测试 is_all_completed ==="

  # 添加更多 Phase
  "$STATE_MANAGER" add-phase 2 "Phase 2: 开发"
  "$STATE_MANAGER" add-phase 3 "Phase 3: 测试"

  # 检查是否全部完成（应该不是）
  local is_completed=$("$STATE_MANAGER" is-completed)
  assert_equals "false" "$is_completed" "未全部完成"

  # 完成所有 Phase
  "$STATE_MANAGER" update-phase 2 "completed"
  "$STATE_MANAGER" update-phase 3 "completed"
  "$STATE_MANAGER" set-current 3

  # 检查是否全部完成
  is_completed=$("$STATE_MANAGER" is-completed)
  assert_equals "true" "$is_completed" "全部完成"
}

# 主测试流程
echo "=== Forge State Manager 测试 ==="
echo ""

setup

test_create_state
test_add_phase
test_update_phase_status
test_update_phase_commit
test_get_phase_commit
test_retry_count
test_is_all_completed

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
