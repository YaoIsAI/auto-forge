#!/bin/bash
# Forge Self-Heal Hook
# 检测未完成的工作流并强制继续

INPUT=$(cat)
STATE_FILE="./.forge-state.json"

if [ ! -f "$STATE_FILE" ]; then
  # 没有 forge 状态文件，不干预
  exit 0
fi

# 读取状态
CURRENT_PHASE=$(jq -r '.current_phase // 0' "$STATE_FILE")
TOTAL_PHASES=$(jq -r '.total_phases // 0' "$STATE_FILE")
RETRY_COUNT=$(jq -r '.retry_count // 0' "$STATE_FILE")
MAX_RETRIES=$(jq -r '.max_retries // 3' "$STATE_FILE")

# 检查是否还有未完成的 Phase
if [ "$CURRENT_PHASE" -lt "$TOTAL_PHASES" ]; then
  # 检查重试次数
  if [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; then
    # 还有未完成的 Phase，强制继续
    echo '{"decision": "block", "reason": "Phases remaining", "systemMessage": "Forge workflow incomplete. Please continue to the next phase."}'
    exit 2
  else
    # 重试次数用完，记录错误并继续
    echo "{\"decision\": \"block\", \"reason\": \"Max retries reached\", \"systemMessage\": \"Forge: Max retries ($MAX_RETRIES) reached for current phase. Recording failure and moving on.\"}"
    exit 2
  fi
fi

# 所有 Phase 都已完成，正常退出
exit 0
