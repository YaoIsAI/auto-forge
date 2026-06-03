#!/bin/bash
# Forge PreCompact Hook
# 在上下文压缩前保存关键信息

STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"
CONTEXT_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-context-snapshot.md"

# 检查是否在 forge 工作流中
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# 验证状态文件
if ! jq -e '.version' "$STATE_FILE" > /dev/null 2>&1; then
  exit 0
fi

# 记录压缩时间
jq '.compacted_at = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' "$STATE_FILE" > "${STATE_FILE}.tmp.$$"
mv "${STATE_FILE}.tmp.$$" "$STATE_FILE"

# 生成上下文快照
CURRENT_PHASE=$(jq -r '.current_phase // 0' "$STATE_FILE")
TOTAL_PHASES=$(jq -r '.total_phases // 0' "$STATE_FILE")
COMPLETED=$(jq -r '[.phases[] | select(.status == "completed")] | length' "$STATE_FILE")
PENDING=$(jq -r '[.phases[] | select(.status != "completed")] | length' "$STATE_FILE")

cat > "$CONTEXT_FILE" << EOF
# Forge 上下文快照

## 当前状态
- 当前 Phase: $CURRENT_PHASE / $TOTAL_PHASES
- 已完成: $COMPLETED
- 待完成: $PENDING

## 关键信息
- 任务: $(jq -r '.task' "$STATE_FILE")
- 开始时间: $(jq -r '.started_at' "$STATE_FILE")
- 压缩时间: $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Phase 状态
$(jq -r '.phases[] | "- Phase \(.id): \(.name) [\(.status)]"' "$STATE_FILE")
EOF

exit 0
