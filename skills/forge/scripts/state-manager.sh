#!/bin/bash
# Forge State Manager
# 管理 .forge-state.json 的读写操作

set -e

STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"

# 创建新状态
create_state() {
  local task="$1"
  local total_phases="$2"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  cat > "$STATE_FILE" <<EOF
{
  "version": "1.0",
  "task": "$task",
  "started_at": "$timestamp",
  "current_phase": 0,
  "total_phases": $total_phases,
  "phases": [],
  "retry_count": 0,
  "max_retries": 3
}
EOF

  echo "State created: $STATE_FILE"
}

# 读取状态
read_state() {
  if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
  else
    echo "{}"
  fi
}

# 获取当前 Phase
get_current_phase() {
  if [ -f "$STATE_FILE" ]; then
    jq -r '.current_phase // 0' "$STATE_FILE"
  else
    echo "0"
  fi
}

# 获取总 Phase 数
get_total_phases() {
  if [ -f "$STATE_FILE" ]; then
    jq -r '.total_phases // 0' "$STATE_FILE"
  else
    echo "0"
  fi
}

# 添加 Phase
add_phase() {
  local phase_id="$1"
  local phase_name="$2"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [ ! -f "$STATE_FILE" ]; then
    echo "Error: State file not found"
    exit 1
  fi

  jq --arg id "$phase_id" --arg name "$phase_name" --arg ts "$timestamp" \
    '.phases += [{"id": ($id | tonumber), "name": $name, "status": "pending", "started_at": $ts}]' \
    "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# 更新 Phase 状态
update_phase_status() {
  local phase_id="$1"
  local status="$2"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [ ! -f "$STATE_FILE" ]; then
    echo "Error: State file not found"
    exit 1
  fi

  if [ "$status" = "completed" ]; then
    jq --arg id "$phase_id" --arg status "$status" --arg ts "$timestamp" \
      '(.phases[] | select(.id == ($id | tonumber))) |= (.status = $status | .completed_at = $ts)' \
      "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  else
    jq --arg id "$phase_id" --arg status "$status" --arg ts "$timestamp" \
      '(.phases[] | select(.id == ($id | tonumber))) |= (.status = $status | .started_at = $ts)' \
      "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  fi
}

# 更新当前 Phase
update_current_phase() {
  local phase="$1"

  if [ ! -f "$STATE_FILE" ]; then
    echo "Error: State file not found"
    exit 1
  fi

  jq --arg phase "$phase" '.current_phase = ($phase | tonumber)' \
    "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# 增加重试计数
increment_retry() {
  if [ ! -f "$STATE_FILE" ]; then
    echo "Error: State file not found"
    exit 1
  fi

  jq '.retry_count += 1' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# 重置重试计数
reset_retry() {
  if [ ! -f "$STATE_FILE" ]; then
    echo "Error: State file not found"
    exit 1
  fi

  jq '.retry_count = 0' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

# 检查是否还有重试次数
can_retry() {
  if [ ! -f "$STATE_FILE" ]; then
    echo "false"
    return
  fi

  local retry_count=$(jq -r '.retry_count // 0' "$STATE_FILE")
  local max_retries=$(jq -r '.max_retries // 3' "$STATE_FILE")

  if [ "$retry_count" -lt "$max_retries" ]; then
    echo "true"
  else
    echo "false"
  fi
}

# 检查是否所有 Phase 完成
is_all_completed() {
  if [ ! -f "$STATE_FILE" ]; then
    echo "false"
    return
  fi

  local current=$(jq -r '.current_phase // 0' "$STATE_FILE")
  local total=$(jq -r '.total_phases // 0' "$STATE_FILE")

  if [ "$current" -ge "$total" ]; then
    echo "true"
  else
    echo "false"
  fi
}

# 清理状态文件
cleanup_state() {
  if [ -f "$STATE_FILE" ]; then
    rm "$STATE_FILE"
    echo "State cleaned up"
  fi
}

# 主入口
case "$1" in
  create)
    create_state "$2" "$3"
    ;;
  read)
    read_state
    ;;
  current-phase)
    get_current_phase
    ;;
  total-phases)
    get_total_phases
    ;;
  add-phase)
    add_phase "$2" "$3"
    ;;
  update-phase)
    update_phase_status "$2" "$3"
    ;;
  set-current)
    update_current_phase "$2"
    ;;
  retry)
    increment_retry
    ;;
  reset-retry)
    reset_retry
    ;;
  can-retry)
    can_retry
    ;;
  is-completed)
    is_all_completed
    ;;
  cleanup)
    cleanup_state
    ;;
  *)
    echo "Usage: $0 {create|read|current-phase|total-phases|add-phase|update-phase|set-current|retry|reset-retry|can-retry|is-completed|cleanup}"
    exit 1
    ;;
esac
