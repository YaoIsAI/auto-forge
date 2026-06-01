#!/bin/bash
# Forge Auto-Approve Hook
# 在 forge 工作流中自动批准安全的工具调用

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')

# 检查是否在 forge 工作流中（通过状态文件判断）
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"

if [ ! -f "$STATE_FILE" ]; then
  # 非 forge 会话，不做任何操作（让系统处理权限）
  exit 0
fi

# 验证状态文件内容
if ! jq -e '.version' "$STATE_FILE" > /dev/null 2>&1; then
  # 状态文件无效，不自动批准
  exit 0
fi

# 危险命令黑名单（即使在 forge 工作流中也不自动批准）
DANGEROUS_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "git push --force"
  "git reset --hard"
  "git clean -f"
  "sudo"
  "chmod 777"
  "curl.*|.*sh"
  "wget.*|.*sh"
)

# 检查 Bash 命令是否危险
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty')

  for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qi "$pattern"; then
      # 危险命令，不自动批准
      exit 0
    fi
  done
fi

# 安全的工具，自动批准
echo '{"hookSpecificOutput": {"permissionDecision": "allow"}}'
exit 0
