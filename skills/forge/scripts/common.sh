#!/bin/bash
# Forge Common Functions
# 公共函数库，供其他脚本使用

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

# 错误处理函数
handle_error() {
  local exit_code=$1
  local line_number=$2
  local script_name=$3

  log_error "脚本 $script_name 在第 $line_number 行发生错误，退出码: $exit_code"
  exit $exit_code
}

# 设置错误陷阱
setup_error_trap() {
  local script_name="$1"
  trap 'handle_error $? $LINENO "$script_name"' ERR
}

# 检查依赖工具
check_dependencies() {
  local deps=("$@")
  local missing=()

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      missing+=("$dep")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    log_error "缺少依赖工具: ${missing[*]}"
    log_error "请安装后重试"
    return 1
  fi

  return 0
}

# 检查文件是否存在
check_file_exists() {
  local file="$1"
  local description="${2:-文件}"

  if [ ! -f "$file" ]; then
    log_error "$description 不存在: $file"
    return 1
  fi

  return 0
}

# 检查目录是否存在
check_dir_exists() {
  local dir="$1"
  local description="${2:-目录}"

  if [ ! -d "$dir" ]; then
    log_error "$description 不存在: $dir"
    return 1
  fi

  return 0
}

# 安全的文件写入（原子操作）
safe_write() {
  local target_file="$1"
  local content="$2"

  local tmp_file="${target_file}.tmp.$$"

  echo "$content" > "$tmp_file"

  if [ $? -eq 0 ]; then
    mv -f "$tmp_file" "$target_file"
    return 0
  else
    rm -f "$tmp_file"
    return 1
  fi
}

# JSON 转义
json_escape() {
  local str="$1"
  # 转义双引号、反斜杠、换行符等
  str="${str//\\/\\\\}"
  str="${str//\"/\\\"}"
  str="${str//$'\n'/\\n}"
  str="${str//$'\r'/\\r}"
  str="${str//$'\t'/\\t}"
  echo "$str"
}

# 验证 JSON 文件
validate_json() {
  local file="$1"

  if [ ! -f "$file" ]; then
    return 1
  fi

  if ! jq -e '.' "$file" > /dev/null 2>&1; then
    return 1
  fi

  return 0
}

# 获取当前时间戳
get_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# 检查 git 仓库
check_git_repo() {
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    return 1
  fi
  return 0
}

# 获取当前分支
get_current_branch() {
  git branch --show-current 2>/dev/null || echo "HEAD"
}

# 安全的 git 操作
safe_git_commit() {
  local message="$1"

  git add -A
  if [ $? -ne 0 ]; then
    log_error "git add 失败"
    return 1
  fi

  git commit -m "$message"
  if [ $? -ne 0 ]; then
    log_error "git commit 失败"
    return 1
  fi

  return 0
}

# 导出函数供其他脚本使用
export -f log_info log_warn log_error handle_error setup_error_trap
export -f check_dependencies check_file_exists check_dir_exists
export -f safe_write json_escape validate_json get_timestamp
export -f check_git_repo get_current_branch safe_git_commit
