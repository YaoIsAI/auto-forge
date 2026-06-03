#!/bin/bash
# Forge Agent Configuration
# 动态调整代理数量

# 默认配置
DEFAULT_SIMPLE=2
DEFAULT_MEDIUM=3
DEFAULT_COMPLEX=4

# 获取代理配置
get_agent_config() {
  local state_file="${CLAUDE_PROJECT_DIR:-.}/.forge-state.json"

  if [ -f "$state_file" ]; then
    local simple=$(jq -r '.agent_config.simple // 2' "$state_file")
    local medium=$(jq -r '.agent_config.medium // 3' "$state_file")
    local complex=$(jq -r '.agent_config.complex // 4' "$state_file")
    echo "$simple $medium $complex"
  else
    echo "$DEFAULT_SIMPLE $DEFAULT_MEDIUM $DEFAULT_COMPLEX"
  fi
}

# 根据文件数量决定代理数量
calculate_agents() {
  local files_changed="$1"

  if [ -z "$files_changed" ] || [ "$files_changed" -eq 0 ]; then
    echo "2"  # 默认简单任务
    return
  fi

  local config=$(get_agent_config)
  local simple=$(echo $config | cut -d' ' -f1)
  local medium=$(echo $config | cut -d' ' -f2)
  local complex=$(echo $config | cut -d' ' -f3)

  if [ "$files_changed" -le 1 ]; then
    echo "$simple"  # 简单任务
  elif [ "$files_changed" -le 5 ]; then
    echo "$medium"  # 中等任务
  else
    echo "$complex"  # 复杂任务
  fi
}

# 获取代理类型列表
get_agent_types() {
  local agent_count="$1"

  case "$agent_count" in
    2)
      echo "security code-quality"
      ;;
    3)
      echo "security performance code-quality"
      ;;
    4)
      echo "security performance code-quality logic"
      ;;
    *)
      echo "security code-quality"
      ;;
  esac
}

# 生成代理提示
generate_agent_prompt() {
  local agent_type="$1"
  local files_changed="$2"

  case "$agent_type" in
    security)
      cat << EOF
你是安全审计专家。审查以下代码变更的安全性。

变更文件: $files_changed

检查项:
- SQL 注入、XSS、CSRF
- 认证/授权逻辑
- 敏感数据暴露
- 依赖安全

输出格式: 列表形式，每项包含 [严重程度] 问题描述: 文件:行号
最后给出评分 (0-10) 和总结。
EOF
      ;;
    performance)
      cat << EOF
你是性能专家。审查以下代码的性能问题。

变更文件: $files_changed

检查项: N+1 查询、缓存策略、时间复杂度、内存泄漏

输出格式: 列表形式，每项包含 [严重程度] 问题描述: 文件:行号
最后给出评分 (0-10) 和总结。
EOF
      ;;
    code-quality)
      cat << EOF
你是代码规范专家。审查以下代码。

变更文件: $files_changed

检查项: 命名规范、代码格式、重复代码、注释质量、逻辑完整性、边界条件、错误处理

输出格式: 列表形式，每项包含 [严重程度] 问题描述: 文件:行号
最后给出评分 (0-10) 和总结。
EOF
      ;;
    logic)
      cat << EOF
你是业务逻辑专家。审查以下代码的逻辑完整性。

变更文件: $files_changed

检查项: 边界条件、错误处理、类型安全

输出格式: 列表形式，每项包含 [严重程度] 问题描述: 文件:行号
最后给出评分 (0-10) 和总结。
EOF
      ;;
  esac
}

# 主入口
case "$1" in
  calculate)
    calculate_agents "$2"
    ;;
  types)
    get_agent_types "$2"
    ;;
  prompt)
    generate_agent_prompt "$2" "$3"
    ;;
  config)
    get_agent_config
    ;;
  *)
    echo "Usage: $0 {calculate|types|prompt|config} [args...]"
    exit 1
    ;;
esac
