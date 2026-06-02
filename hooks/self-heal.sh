#!/bin/bash
# Forge Self-Heal Hook
# 检测未完成的工作流并强制继续

# 读取输入（但不使用，避免阻塞）
INPUT=$(cat)

# 日志文件
LOG_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-hook.log"

# 记录日志
log_hook() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [self-heal] $1" >> "$LOG_FILE"
}

log_hook "Self-heal hook triggered"

# 检查是否在 forge 工作流中
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"

if [ ! -f "$STATE_FILE" ]; then
  # 没有 forge 状态文件，不干预
  log_hook "No state file, exiting"
  exit 0
fi

# 验证状态文件内容
if ! jq -e '.version' "$STATE_FILE" > /dev/null 2>&1; then
  log_hook "Invalid state file, exiting"
  exit 0
fi

# 读取状态
CURRENT_PHASE=$(jq -r '.current_phase // 0' "$STATE_FILE")
TOTAL_PHASES=$(jq -r '.total_phases // 0' "$STATE_FILE")
RETRY_COUNT=$(jq -r '.retry_count // 0' "$STATE_FILE")
MAX_RETRIES=$(jq -r '.max_retries // 3' "$STATE_FILE")

log_hook "Current phase: $CURRENT_PHASE / $TOTAL_PHASES, Retry: $RETRY_COUNT / $MAX_RETRIES"

# 检查最后活动时间
LAST_ACTIVITY_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-last-activity"
if [ -f "$LAST_ACTIVITY_FILE" ]; then
  last_activity=$(cat "$LAST_ACTIVITY_FILE")
  current_time=$(date +%s)
  elapsed=$((current_time - last_activity))

  log_hook "Last activity: $elapsed seconds ago"

  # 如果超过 60 秒没有活动，强制继续
  if [ $elapsed -gt 60 ]; then
    log_hook "Timeout detected ($elapsed seconds), forcing continuation"
    echo '{"decision": "block", "reason": "Timeout", "systemMessage": "Forge: 检测到超时（'"$elapsed"' 秒无活动），自动继续执行。"}'
    exit 2
  fi
fi

# 检查是否还有未完成的 Phase
if [ "$CURRENT_PHASE" -lt "$TOTAL_PHASES" ]; then
  # 检查重试次数
  if [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; then
    # 还有未完成的 Phase，强制继续
    log_hook "Phases remaining, forcing continuation"
    echo '{"decision": "block", "reason": "Phases remaining", "systemMessage": "Forge 工作流未完成，请继续执行下一个 Phase。"}'
    exit 2
  else
    # 重试次数用完，记录错误并继续
    log_hook "Max retries reached"
    echo '{"decision": "block", "reason": "Max retries reached", "systemMessage": "Forge: 已达到最大重试次数 ('"$MAX_RETRIES"')，记录失败并继续。"}'
    exit 2
  fi
fi

# 所有 Phase 都已完成，正常退出
log_hook "All phases completed, exiting"
exit 0
