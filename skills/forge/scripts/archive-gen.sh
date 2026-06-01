#!/bin/bash
# Forge Archive Generator
# 生成 Phase 归档文件

set -e

ARCHIVE_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude-phases"
PHASE_ID="$1"
PHASE_NAME="$2"
STATUS_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"

# 确保归档目录存在
mkdir -p "$ARCHIVE_DIR"

# 生成 CHANGELOG
generate_changelog() {
  local phase_id="$1"
  local phase_name="$2"
  local files_changed="$3"

  cat > "$ARCHIVE_DIR/phase-${phase_id}-CHANGELOG.md" <<EOF
# Phase ${phase_id}: ${phase_name}

## 变更摘要
$(echo "$files_changed" | wc -l | xargs -I {} echo "- 变更文件: {} 个")

## 主要变更
$(echo "$files_changed" | sed 's/^/- /')

## 生成时间
$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

  echo "Generated: $ARCHIVE_DIR/phase-${phase_id}-CHANGELOG.md"
}

# 生成 Review 报告
generate_review() {
  local phase_id="$1"
  local security_score="$2"
  local performance_score="$3"
  local style_score="$4"
  local logic_score="$5"
  local security_issues="$6"
  local performance_issues="$7"
  local style_issues="$8"
  local logic_issues="$9"

  cat > "$ARCHIVE_DIR/phase-${phase_id}-review.md" <<EOF
# Phase ${phase_id} 多代理评审报告

## 总览
| 代理 | 评分 | 问题数 |
|------|------|--------|
| Security | ${security_score:-N/A} | ${security_issues:-0} |
| Performance | ${performance_score:-N/A} | ${performance_issues:-0} |
| Style | ${style_score:-N/A} | ${style_issues:-0} |
| Logic | ${logic_score:-N/A} | ${logic_issues:-0} |

## 生成时间
$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

  echo "Generated: $ARCHIVE_DIR/phase-${phase_id}-review.md"
}

# 生成 Trace 日志
generate_trace() {
  local phase_id="$1"
  local phase_name="$2"
  local status="$3"
  local duration="$4"

  cat > "$ARCHIVE_DIR/phase-${phase_id}-trace.md" <<EOF
# Phase ${phase_id}: ${phase_name} - 执行日志

## 状态
- 状态: ${status}
- 开始时间: ${5:-$(date -u +"%Y-%m-%dT%H:%M:%SZ")}
- 结束时间: ${6:-$(date -u +"%Y-%m-%dT%H:%M:%SZ")}
- 耗时: ${duration:-N/A}

## 执行步骤
1. 开发编码
2. 多代理并行评审
3. 自动修复
4. 构建验证
5. 归档

## 生成时间
$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

  echo "Generated: $ARCHIVE_DIR/phase-${phase_id}-trace.md"
}

# 生成 Status JSON
generate_status() {
  local phase_id="$1"
  local status="$2"
  local files_changed="$3"
  local security_score="$4"
  local performance_score="$5"
  local style_score="$6"
  local logic_score="$7"
  local issues_found="$8"
  local issues_fixed="$9"
  local build_passed="${10}"
  local tests_passed="${11}"

  # 将文件列表转换为 JSON 数组
  local files_json=$(echo "$files_changed" | jq -R -s 'split("\n") | map(select(length > 0))')

  cat > "$ARCHIVE_DIR/phase-${phase_id}-status.json" <<EOF
{
  "phase_id": ${phase_id},
  "status": "${status}",
  "files_changed": ${files_json},
  "review_scores": {
    "security": ${security_score:-null},
    "performance": ${performance_score:-null},
    "style": ${style_score:-null},
    "logic": ${logic_score:-null}
  },
  "issues_found": ${issues_found:-0},
  "issues_fixed": ${issues_fixed:-0},
  "build_passed": ${build_passed:-true},
  "tests_passed": ${tests_passed:-true},
  "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

  echo "Generated: $ARCHIVE_DIR/phase-${phase_id}-status.json"
}

# 生成最终报告
generate_final_report() {
  local total_phases="$1"
  local task="$2"

  cat > "$ARCHIVE_DIR/FINAL-REPORT.md" <<EOF
# Forge 最终报告

## 任务
${task}

## 概览
- 总 Phase 数: ${total_phases}
- 完成时间: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Phase 结果
$(for i in $(seq 1 $total_phases); do
  if [ -f "$ARCHIVE_DIR/phase-${i}-status.json" ]; then
    local status=$(jq -r '.status' "$ARCHIVE_DIR/phase-${i}-status.json")
    local security=$(jq -r '.review_scores.security' "$ARCHIVE_DIR/phase-${i}-status.json")
    echo "- Phase ${i}: ${status} (Security: ${security})"
  fi
done)

## 生成时间
$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

  echo "Generated: $ARCHIVE_DIR/FINAL-REPORT.md"
}

# 主入口
case "$2" in
  changelog)
    generate_changelog "$3" "$4" "$5"
    ;;
  review)
    generate_review "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}" "${11}"
    ;;
  trace)
    generate_trace "$3" "$4" "$5" "$6" "$7" "$8"
    ;;
  status)
    generate_status "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}" "${11}" "${12}" "${13}"
    ;;
  final)
    generate_final_report "$3" "$4"
    ;;
  *)
    echo "Usage: $0 archive {changelog|review|trace|status|final} [args...]"
    exit 1
    ;;
esac
