#!/bin/bash
# Forge Session Manager
# 会话隔离管理

# 获取会话 ID（基于进程 ID）
get_session_id() {
  echo "$$"
}

# 获取会话状态文件路径
get_session_state_file() {
  local session_id=$(get_session_id)
  local project_dir="${CLAUDE_PROJECT_DIR:-.}"
  echo "$project_dir/.forge-state.session-${session_id}.json"
}

# 创建会话状态
create_session_state() {
  local session_state_file=$(get_session_state_file)
  local main_state_file="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"

  # 如果主状态文件存在，复制到会话状态
  if [ -f "$main_state_file" ]; then
    cp "$main_state_file" "$session_state_file"
    echo "Session state created: $session_state_file"
  fi
}

# 获取当前状态文件（优先会话状态）
get_state_file() {
  local session_state_file=$(get_session_state_file)
  local main_state_file="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"

  if [ -f "$session_state_file" ]; then
    echo "$session_state_file"
  else
    echo "$main_state_file"
  fi
}

# 合并会话状态到主状态
merge_session_state() {
  local session_state_file=$(get_session_state_file)
  local main_state_file="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"

  if [ -f "$session_state_file" ] && [ -f "$main_state_file" ]; then
    # 使用会话状态覆盖主状态
    cp "$session_state_file" "$main_state_file"
    echo "Session state merged to main state"
  fi
}

# 清理会话状态
cleanup_session() {
  local session_state_file=$(get_session_state_file)

  if [ -f "$session_state_file" ]; then
    # 合并到主状态
    merge_session_state
    # 删除会话状态
    rm "$session_state_file"
    echo "Session state cleaned up"
  fi
}

# 主入口
case "$1" in
  create)
    create_session_state
    ;;
  get)
    get_state_file
    ;;
  merge)
    merge_session_state
    ;;
  cleanup)
    cleanup_session
    ;;
  session-id)
    get_session_id
    ;;
  *)
    echo "Usage: $0 {create|get|merge|cleanup|session-id}"
    exit 1
    ;;
esac
