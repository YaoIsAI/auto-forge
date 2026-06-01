#!/bin/bash
# Forge Archive Generator
# 生成 Phase 归档文件

set -e

ARCHIVE_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude-phases"
STATUS_FILE="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"

# 确保归档目录存在
mkdir -p "$ARCHIVE_DIR"

# 生成 CHANGELOG
generate_changelog() {
  local phase_id="$1"
  local phase_name="$2"
  local files_changed="$3"
  local commit_hash="$4"

  # 计算变更文件数
  local file_count=0
  if [ -n "$files_changed" ]; then
    file_count=$(echo "$files_changed" | grep -c . || echo "0")
  fi

  # 获取 git diff 统计
  local git_stats=""
  if [ -n "$commit_hash" ] && git rev-parse --git-dir > /dev/null 2>&1; then
    git_stats=$(git diff --stat HEAD~1 HEAD 2>/dev/null || echo "")
  fi

  cat > "$ARCHIVE_DIR/phase-${phase_id}-CHANGELOG.md" <<EOF
# Phase ${phase_id}: ${phase_name}

## Git Commit
- Commit: ${commit_hash:-N/A}
- 查看变更: \`git show ${commit_hash:-HEAD}\`
- 回撤此 Phase: \`git revert ${commit_hash:-HEAD}\`

## 变更摘要
- 变更文件: ${file_count} 个

## 主要变更
$(echo "$files_changed" | sed 's/^/- /')

## Git 统计
\`\`\`
${git_stats}
\`\`\`

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
| 安全 | ${security_score:-N/A} | ${security_issues:-0} |
| 性能 | ${performance_score:-N/A} | ${performance_issues:-0} |
| 规范 | ${style_score:-N/A} | ${style_issues:-0} |
| 逻辑 | ${logic_score:-N/A} | ${logic_issues:-0} |

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
  local start_time="$4"
  local end_time="$5"
  local duration="$6"
  local commit_hash="$7"

  cat > "$ARCHIVE_DIR/phase-${phase_id}-trace.md" <<EOF
# Phase ${phase_id}: ${phase_name} - 执行日志

## 状态
- 状态: ${status}
- 开始时间: ${start_time:-$(date -u +"%Y-%m-%dT%H:%M:%SZ")}
- 结束时间: ${end_time:-$(date -u +"%Y-%m-%dT%H:%M:%SZ")}
- 耗时: ${duration:-N/A}

## Git 信息
- Commit: ${commit_hash:-N/A}
- 查看变更: \`git show ${commit_hash:-HEAD}\`
- 回撤此 Phase: \`git revert ${commit_hash:-HEAD}\`

## 执行步骤
1. 开发编码
2. 多代理并行评审
3. 自动修复
4. 构建验证
5. 归档
6. Git Commit

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
  local commit_hash="${12}"

  # 将文件列表转换为 JSON 数组
  local files_json="[]"
  if [ -n "$files_changed" ]; then
    files_json=$(echo "$files_changed" | jq -R -s 'split("\n") | map(select(length > 0))')
  fi

  # 确保布尔值正确
  local build_bool="true"
  local tests_bool="true"
  [ "$build_passed" = "false" ] && build_bool="false"
  [ "$tests_passed" = "false" ] && tests_bool="false"

  cat > "$ARCHIVE_DIR/phase-${phase_id}-status.json" <<EOF
{
  "phase_id": ${phase_id},
  "status": "${status}",
  "commit_hash": "${commit_hash:-}",
  "files_changed": ${files_json},
  "review_scores": {
    "security": ${security_score:-null},
    "performance": ${performance_score:-null},
    "style": ${style_score:-null},
    "logic": ${logic_score:-null}
  },
  "issues_found": ${issues_found:-0},
  "issues_fixed": ${issues_fixed:-0},
  "build_passed": ${build_bool},
  "tests_passed": ${tests_bool},
  "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

  echo "Generated: $ARCHIVE_DIR/phase-${phase_id}-status.json"
}

# 生成最终报告
generate_final_report() {
  local total_phases="$1"
  local task="$2"

  # 获取 git 信息
  local git_log=""
  local current_branch=""
  if git rev-parse --git-dir > /dev/null 2>&1; then
    git_log=$(git log --oneline --grep="forge(phase" 2>/dev/null || echo "")
    current_branch=$(git branch --show-current 2>/dev/null || echo "N/A")
  fi

  # 生成 Phase 结果列表
  local phase_results=""
  for i in $(seq 1 $total_phases); do
    if [ -f "$ARCHIVE_DIR/phase-${i}-status.json" ]; then
      local status=$(jq -r '.status' "$ARCHIVE_DIR/phase-${i}-status.json")
      local security=$(jq -r '.review_scores.security' "$ARCHIVE_DIR/phase-${i}-status.json")
      local commit=$(jq -r '.commit_hash // "N/A"' "$ARCHIVE_DIR/phase-${i}-status.json")
      phase_results="${phase_results}- Phase ${i}: ${status} (安全: ${security}) [commit: ${commit:0:7}]
"
    fi
  done

  cat > "$ARCHIVE_DIR/FINAL-REPORT.md" <<EOF
# Forge 最终报告

## 任务
${task}

## 概览
- 总 Phase 数: ${total_phases}
- 完成时间: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- Git 分支: ${current_branch}

## Phase 结果
${phase_results}
## Git 历史
\`\`\`
${git_log}
\`\`\`

## 回撤指南
\`\`\`bash
# 查看所有 Phase 的 commit
git log --oneline --grep="forge(phase"

# 回撤到特定 Phase
/forge --revert <phase-id>

# 或手动回撤
git revert <commit-hash>
\`\`\`

## 生成时间
$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

  echo "Generated: $ARCHIVE_DIR/FINAL-REPORT.md"
}

# 主入口
case "$1" in
  changelog)
    generate_changelog "$2" "$3" "$4" "$5"
    ;;
  review)
    generate_review "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}"
    ;;
  trace)
    generate_trace "$2" "$3" "$4" "$5" "$6" "$7" "$8"
    ;;
  status)
    generate_status "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}" "${11}" "${12}" "${13}"
    ;;
  final)
    generate_final_report "$2" "$3"
    ;;
  *)
    echo "Usage: $0 {changelog|review|trace|status|final} [args...]"
    exit 1
    ;;
esac
