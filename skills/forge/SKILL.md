---
name: forge
description: >
  Multi-phase workflow engine with automatic task decomposition, parallel multi-agent review, complete Git version control.
  Usage: /forge <task description>
  Triggers: forge, workflow, automation, parallel agents, code review
argument-hint: <task description or requirements file> or --resume to continue or --revert <phase-id> to rollback or --log to view history
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
  - TaskCreate
  - TaskUpdate
  - WebSearch
  - WebFetch
disable-model-invocation: true
---

# Forge - Multi-Phase Workflow Engine

**English** | **中文**

Execute fully automated multi-phase workflows with parallel AI review and complete Git version control.

---

## English

### Prerequisites

- `git` - Version control
- `jq` - JSON processing
- Build tools for your language (npm/cargo/python/go)
- `claude` - Claude Code CLI

### Important: Permission Mode

Forge requires `bypassPermissions` mode for fully automatic execution.

**Without bypass mode:**
- Every Bash command, file modification, Git operation requires manual confirmation
- You need to type `y` or click confirm each time
- Cannot achieve "unattended" development

**With bypass mode:**
- All operations auto-approved, no confirmation needed
- True "one-click start, fully automatic"
- Recommended only for trusted projects

### Usage

#### Start Claude Code (Important)

```bash
# Method 1: Command line parameter (Recommended)
claude --permission-mode bypassPermissions

# Method 2: Start in project directory
cd /path/to/your/project
claude --permission-mode bypassPermissions
```

#### Use Forge Command

```
/forge Implement a user authentication module with JWT + OAuth2
/forge --resume              # Resume from breakpoint
/forge --revert 2            # Revert to Phase 2
/forge --log                 # View git history
```

#### Complete Workflow

```bash
# 1. Start Claude Code (must use bypassPermissions)
claude --permission-mode bypassPermissions

# 2. Enter project directory
cd /path/to/your/project

# 3. Install hooks (first time)
bash ~/.claude/skills/forge/scripts/setup-hooks.sh

# 4. Use forge
/forge Implement a user authentication module with JWT + OAuth2

# 5. Wait for automatic completion (no manual intervention needed)
```

### Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Still requires manual confirmation | Not using bypass mode | Restart with `claude --permission-mode bypassPermissions` |
| Hooks not working | Hooks not installed | Run `bash ~/.claude/skills/forge/scripts/setup-hooks.sh` |
| State file not found | Forge not initialized | Run `/forge your task description` |
| View logs | - | `tail -50 .forge-hook.log` |
| Rollback | - | `/forge --revert 2` or `git revert <commit-hash>` |

---

## 中文

### 前置条件

- `git` - 版本控制
- `jq` - JSON 处理
- 各语言构建工具（npm/cargo/python/go）
- `claude` - Claude Code CLI

### 重要提示：权限模式

Forge 需要 `bypassPermissions` 权限模式才能实现全自动执行。

**如果不使用 bypass 模式：**
- 每次 Bash 命令、文件修改、Git 操作都会弹出确认提示
- 需要手动输入 `y` 或点击确认
- 无法实现"无人值守"开发

**如果使用 bypass 模式：**
- 所有操作自动批准，无需确认
- 真正的"一键启动，全程自动"
- 建议仅在可信项目中使用

### 使用方式

#### 启动 Claude Code（重要）

```bash
# 方式 1: 命令行参数（推荐）
claude --permission-mode bypassPermissions

# 方式 2: 在项目目录启动
cd /path/to/your/project
claude --permission-mode bypassPermissions
```

#### 使用 Forge 命令

```
/forge 实现一个用户认证模块，支持 JWT + OAuth2
/forge --resume              # 从断点继续
/forge --revert 2            # 回撤到 Phase 2 完成后的状态
/forge --log                 # 查看所有 Phase 的 git 历史
```

#### 完整使用流程

```bash
# 1. 启动 Claude Code（必须带 bypassPermissions）
claude --permission-mode bypassPermissions

# 2. 进入项目目录
cd /path/to/your/project

# 3. 安装 hooks（首次使用）
bash ~/.claude/skills/forge/scripts/setup-hooks.sh

# 4. 使用 forge
/forge 实现一个用户认证模块，支持 JWT + OAuth2

# 5. 等待自动完成（无需任何人工干预）
```

### 故障排除

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 仍然需要手动确认 | 未使用 bypass 模式 | 重启 `claude --permission-mode bypassPermissions` |
| Hook 未生效 | Hooks 未安装 | 运行 `bash ~/.claude/skills/forge/scripts/setup-hooks.sh` |
| 状态文件不存在 | Forge 未初始化 | 运行 `/forge 你的任务描述` |
| 查看日志 | - | `tail -50 .forge-hook.log` |
| 回滚 | - | `/forge --revert 2` 或 `git revert <commit-hash>` |

---

## Workflow

## 前置条件

- `git` - 版本控制
- `jq` - JSON 处理
- 各语言构建工具（npm/cargo/python/go）
- `claude` - Claude Code CLI

## 重要提示：权限模式

Forge 需要 `bypassPermissions` 权限模式才能实现全自动执行。

**如果不使用 bypass 模式：**
- 每次 Bash 命令、文件修改、Git 操作都会弹出确认提示
- 需要手动输入 `y` 或点击确认
- 无法实现"无人值守"开发

**如果使用 bypass 模式：**
- 所有操作自动批准，无需确认
- 真正的"一键启动，全程自动"
- 建议仅在可信项目中使用

## 使用方式

### 启动 Claude Code（重要）

**推荐使用 bypass 模式启动，实现全自动执行：**

```bash
# 方式 1: 命令行参数（推荐）
claude --permission-mode bypassPermissions

# 方式 2: 在项目目录启动
cd /path/to/your/project
claude --permission-mode bypassPermissions
```

### 使用 Forge 命令

```
/forge 实现一个用户认证模块，支持 JWT + OAuth2
/forge ./docs/requirements.md
/forge --resume  # 从断点继续
/forge --revert 2  # 回撤到 Phase 2 完成后的状态
/forge --log  # 查看所有 Phase 的 git 历史
```

### 完整使用流程

```bash
# 1. 启动 Claude Code（必须带 bypassPermissions）
claude --permission-mode bypassPermissions

# 2. 进入项目目录
cd /path/to/your/project

# 3. 安装 hooks（首次使用）
bash ~/.claude/skills/forge/scripts/setup-hooks.sh

# 4. 使用 forge
/forge 实现一个用户认证模块，支持 JWT + OAuth2

# 5. 等待自动完成（无需任何人工干预）
```

## 工作流程

### 1. 初始化阶段

1. 解析参数 `$ARGUMENTS`
2. 如果参数是文件路径，读取文件内容作为任务描述
3. 如果参数包含 `--resume`，读取 `.forge-state.json` 恢复状态
4. 如果参数包含 `--revert <阶段号>`，执行 git revert 回撤
5. 如果参数包含 `--log`，显示 git 历史
6. 否则创建新的 `.forge-state.json`
7. 检查/初始化 git 仓库
8. 根据任务复杂度拆分为多个 Phase（通常 3-7 个）

### 1.1 Hook 安装（重要）

Forge 需要在项目中安装 hooks 才能实现全自动执行。

**自动安装（推荐）：**
```bash
# 运行安装脚本
bash ~/.claude/skills/forge/scripts/setup-hooks.sh
```

**手动安装（如果自动安装失败）：**
```bash
# 创建 .claude 目录
mkdir -p .claude

# 复制 hooks
cp ~/.claude/skills/forge/hooks/*.sh .claude/

# 复制 settings.json
cp ~/.claude/skills/forge/settings.json .claude/
```

**验证安装：**
```bash
# 检查 hooks 是否已安装
ls -la .claude/*.sh
```

### 1.2 Git 处理策略

根据项目当前的 Git 状态，采取不同的处理策略：

**场景 1: 项目没有 git**
```bash
# 初始化 git
git init
git add -A
git commit -m "forge: initial commit before task"
```

**场景 2: 项目已有 git（推荐）**
```bash
# 1. 记录当前 HEAD（用于参考）
FORGE_INITIAL_COMMIT=$(git rev-parse HEAD)

# 2. 可选：保存当前未提交的更改
git stash push -m "forge: save current work"

# 3. 在当前分支上直接 commit（不创建新分支）
# forge 的 commit 使用特殊前缀：forge(phase-N):
```

**关键原则：**
- **不创建新分支** - 避免干扰用户现有工作流
- **使用 commit 前缀** - `forge(phase-N):` 标识 forge 的 commit
- **支持 stash** - 保存用户未提交的更改
- **独立回撤** - 只回撤 forge 的 commit，不影响用户代码

### 2. Phase 执行循环

对每个 Phase N 执行以下步骤：

#### 步骤 2.1: 开发编码

使用 Agent 工具执行编码任务：
```
Agent({
  subagent_type: "general-purpose",
  description: "Phase {N}: {Phase名称}",
  prompt: "你是开发工程师。执行以下任务：\n\n{任务描述}\n\n输出变更文件列表。"
})
```

#### 步骤 2.2: 多代理并行评审

**同时**启动 4 个 Agent（在单条消息中发起多个 tool_use）：

```text
// 代理 1: 安全审计
Agent({
  subagent_type: "general-purpose",
  description: "安全审计",
  prompt: `你是安全审计专家。审查以下代码变更的安全性。

变更文件: {files_changed}

检查项:
- SQL 注入、XSS、CSRF
- 认证/授权逻辑
- 敏感数据暴露
- 依赖安全

输出格式: 列表形式，每项包含 [严重程度] 问题描述: 文件:行号
最后给出评分 (0-10) 和总结。`
})

// 代理 2: 性能审计
Agent({
  subagent_type: "general-purpose",
  description: "性能审计",
  prompt: `你是性能专家。审查以下代码的性能问题。

变更文件: {files_changed}

检查项: N+1 查询、缓存策略、时间复杂度、内存泄漏

输出格式: 列表形式，每项包含 [严重程度] 问题描述: 文件:行号
最后给出评分 (0-10) 和总结。`
})

// 代理 3: 代码规范审计
Agent({
  subagent_type: "general-purpose",
  description: "代码规范审计",
  prompt: `你是代码规范专家。审查以下代码。

变更文件: {files_changed}

检查项: 命名规范、代码格式、重复代码、注释质量

输出格式: 列表形式，每项包含 [严重程度] 问题描述: 文件:行号
最后给出评分 (0-10) 和总结。`
})

// 代理 4: 逻辑审查
Agent({
  subagent_type: "general-purpose",
  description: "逻辑审查",
  prompt: `你是业务逻辑专家。审查以下代码的逻辑完整性。

变更文件: {files_changed}

检查项: 边界条件、错误处理、类型安全

输出格式: 列表形式，每项包含 [严重程度] 问题描述: 文件:行号
最后给出评分 (0-10) 和总结。`
})
```

#### 步骤 2.3: 自动修复

1. 收集所有 4 个评审代理的输出
2. 按严重程度排序: 严重（Critical） > 高（High） > 中（Medium） > 低（Low）
3. 逐一修复（严重问题必须修复，其他可标记 TODO）
4. 记录修复结果

#### 步骤 2.4: 构建验证

根据项目类型执行相应的构建和测试命令：

```bash
# Node.js 项目
npm run build
npm test
npm run lint

# Rust 项目
cargo build
cargo test
cargo clippy

# Python 项目
python -m py_compile *.py
python -m pytest
ruff check .

# Go 项目
go build ./...
go test ./...
golangci-lint run
```

#### 步骤 2.5: 归档

写入 `.claude-phases/` 目录：
- `phase-{N}-trace.md`: 完整执行日志
- `phase-{N}-CHANGELOG.md`: 变更摘要
- `phase-{N}-review.md`: 多代理评审汇总
- `phase-{N}-status.json`: 断点状态

#### 步骤 2.6: Git Commit

```bash
# 添加所有变更
git add -A

# 创建 commit，包含 Phase 信息
git commit -m "forge(phase-{N}): {Phase名称}

- 变更文件: {files_changed}
- 评审评分: 安全 {score}, 性能 {score}, 规范 {score}, 逻辑 {score}
- 问题修复: {fixed}/{found}"

# 记录 commit hash 到状态文件
FORGE_COMMIT_HASH=$(git rev-parse HEAD)
```

#### 步骤 2.7: 更新全局状态

更新 `.forge-state.json`，标记当前 Phase 为 completed，记录 commit hash

### 3. 完成阶段

1. 汇总所有 Phase 结果
2. 生成最终报告写入 `.claude-phases/FINAL-REPORT.md`
3. 输出成功/失败摘要

## 状态文件格式

### `.forge-state.json` (项目根目录)

```json
{
  "version": "1.0",
  "task": "任务描述",
  "started_at": "2026-06-01T10:00:00Z",
  "current_phase": 1,
  "total_phases": 5,
  "git_branch": "main",
  "initial_commit": "abc1234",
  "phases": [
    {
      "id": 1,
      "name": "Phase名称",
      "status": "completed|in_progress|pending|failed",
      "started_at": "...",
      "completed_at": "...",
      "commit_hash": "def5678"
    }
  ],
  "retry_count": 0,
  "max_retries": 3
}
```

### `.claude-phases/phase-{N}-status.json`

```json
{
  "phase_id": 1,
  "status": "completed",
  "commit_hash": "def5678",
  "files_changed": ["file1.ts", "file2.ts"],
  "review_scores": {
    "security": 9.5,
    "performance": 8.0,
    "style": 9.0,
    "logic": 8.5
  },
  "issues_found": 8,
  "issues_fixed": 7,
  "build_passed": true,
  "tests_passed": true
}
```

## 错误处理

### 自动重试策略

1. **构建失败**: 自动分析错误，修复后重试（最多 3 次）
2. **测试失败**: 自动修复测试用例或代码
3. **评审阻塞**: 严重安全问题必须修复，其他可标记 TODO

### 断点续跑

- 每个 Phase 完成后写入 status.json
- 使用 `--resume` 时读取最后一个未完成 Phase
- 跳过已完成的 Phase

### 回滚机制

```bash
# 方式 1: 回撤到某个 Phase 完成后的状态
/forge --revert 2  # 回撤到 Phase 2 完成后

# 方式 2: 查看 git 历史
/forge --log

# 方式 3: 手动 git 操作
git log --oneline  # 查看所有 commit
git revert <commit-hash>  # 回撤特定 commit
git diff <commit1> <commit2>  # 比较两个版本
```

### Git 日志格式

```
forge(phase-1): 项目初始化
forge(phase-2): 实现 API + 评审
forge(phase-3): 修复 + 归档
```

## 归档文件模板

### phase-{N}-CHANGELOG.md

```markdown
# Phase N: {Phase名称}

## Git Commit
- Commit: {commit_hash}
- 查看变更: `git show {commit_hash}`
- 回撤此 Phase: `git revert {commit_hash}`

## 变更摘要
- 变更文件: X 个

## 主要变更
1. **文件路径**: 变更描述
```

### phase-{N}-review.md

```markdown
# Phase N 多代理评审报告

## 总览
| 代理 | 评分 | 问题数 |
|------|------|--------|
| 安全 | 9.5 | 2 |
| 性能 | 8.0 | 3 |
| 规范 | 9.0 | 1 |
| 逻辑 | 8.5 | 2 |

## 详细发现
### 安全审计
- [已修复] 问题描述: 文件:行号

### 性能审计
- [已修复] 问题描述
- [待办] 建议描述（非阻塞）
```

## 故障排除

### 问题 1: 仍然需要手动确认

**原因**: 未使用 bypass 模式启动 Claude Code

**解决**:
```bash
# 重新启动 Claude Code，使用 bypass 模式
claude --permission-mode bypassPermissions
```

### 问题 2: Hook 未生效

**原因**: Hooks 未安装到项目

**解决**:
```bash
# 运行安装脚本
bash ~/.claude/skills/forge/scripts/setup-hooks.sh

# 验证安装
ls -la .claude/*.sh
```

### 问题 3: 状态文件不存在

**原因**: Forge 未初始化或状态文件被删除

**解决**:
```bash
# 检查状态文件
cat .forge-state.json

# 如果不存在，重新运行 forge
/forge 你的任务描述
```

### 问题 4: 查看日志

```bash
# 查看 hook 执行日志
tail -50 .forge-hook.log

# 监控 hook 状态
bash ~/.claude/skills/forge/scripts/monitor-hooks.sh
```

### 问题 5: 回滚到之前的状态

```bash
# 查看 git 历史
git log --oneline --grep="forge(phase"

# 回撤到特定 Phase
/forge --revert 2

# 或手动回撤
git revert <commit-hash>
```
