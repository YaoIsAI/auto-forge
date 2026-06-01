#!/bin/bash
# Forge Auto-Approve Hook
# 在 forge 工作流中自动批准所有工具调用

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# 检查是否在 forge 工作流中（通过状态文件判断）
# 使用 CLAUDE_PROJECT_DIR 环境变量（如果可用），否则使用当前目录
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"

if [ -f "$STATE_FILE" ]; then
  # 在 forge 工作流中，自动批准
  echo '{"hookSpecificOutput": {"permissionDecision": "allow"}}'
  exit 0
fi

# 非 forge 会话，不做任何操作（让系统处理权限）
exit 0
