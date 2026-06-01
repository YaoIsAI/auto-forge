#!/bin/bash
# Forge 测试运行器

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="/c/Users/yao/.local/bin:$PATH"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Forge 测试套件 ===${NC}"
echo ""

# 检查依赖
echo "检查依赖..."
if ! command -v jq &> /dev/null; then
  echo -e "${RED}错误: jq 未安装${NC}"
  echo "请安装 jq: scoop install jq"
  exit 1
fi

echo -e "${GREEN}jq 已安装: $(jq --version)${NC}"
echo ""

# 运行测试
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
  local test_name="$1"
  local test_script="$2"

  echo -e "${YELLOW}运行 $test_name...${NC}"
  echo "---"

  if bash "$test_script"; then
    ((TESTS_PASSED++))
  else
    ((TESTS_FAILED++))
  fi

  echo ""
  echo "---"
  echo ""
}

# 运行所有测试
run_test "State Manager 测试" "$SCRIPT_DIR/test-state-manager.sh"
run_test "Orchestrator 测试" "$SCRIPT_DIR/test-orchestrator.sh"

# 汇总结果
echo -e "${YELLOW}=== 测试汇总 ===${NC}"
echo -e "${GREEN}通过的测试套件: $TESTS_PASSED${NC}"
echo -e "${RED}失败的测试套件: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}所有测试通过!${NC}"
  exit 0
else
  echo -e "${RED}有测试失败!${NC}"
  exit 1
fi
