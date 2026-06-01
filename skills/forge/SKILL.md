---
name: forge
description: >
  全自动多 Phase 工作流引擎。自动拆分任务、编码、多代理并行评审、修复、归档。
  使用方式: /forge <任务描述>
  触发词: forge, 全自动, 无人值守, parallel agents, 多代理评审
argument-hint: <任务描述或需求文件路径> 或 --resume 从断点继续 或 --revert <phase-id> 回撤 或 --log 查看历史
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

# Forge - 全自动工作流引擎

执行全自动多 Phase 工作流，包含并行 AI 评审，完整 Git 版本控制。

## 使用方式

```
/forge 实现一个用户认证模块，支持 JWT + OAuth2
/forge ./docs/requirements.md
/forge --resume  # 从断点继续
/forge --revert 2  # 回撤到 Phase 2 完成后的状态
/forge --log  # 查看所有 Phase 的 git 历史
```

## 工作流程

### 1. 初始化阶段

1. 解析参数 `$ARGUMENTS`
2. 如果参数是文件路径，读取文件内容作为任务描述
3. 如果参数包含 `--resume`，读取 `.forge-state.json` 恢复状态
4. 如果参数包含 `--revert <phase-id>`，执行 git revert 回撤
5. 如果参数包含 `--log`，显示 git 历史
6. 否则创建新的 `.forge-state.json`
7. 检查/初始化 git 仓库
8. 根据任务复杂度拆分为多个 Phase（通常 3-7 个）

### 1.1 Git 初始化

```bash
# 检查是否已有 git 仓库
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  git init
  git add -A
  git commit -m "forge: initial commit before task"
fi

# 创建 forge 分支（可选，便于隔离）
git checkout -b forge/task-{timestamp}
```

### 2. Phase 执行循环

对每个 Phase N 执行以下步骤：

#### Step 2.1: 开发编码

使用 Agent 工具执行编码任务：
```
Agent({
  subagent_type: "general-purpose",
  description: "Phase {N}: {Phase名称}",
  prompt: "你是开发工程师。执行以下任务：\n\n{phase_task_description}\n\n输出变更文件列表。"
})
```

#### Step 2.2: 多代理并行评审

**同时**启动 4 个 Agent（在单条消息中发起多个 tool_use）：

```javascript
// Agent 1: 安全审计
Agent({
  subagent_type: "general-purpose",
  description: "Security audit",
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

// Agent 2: 性能审计
Agent({
  subagent_type: "general-purpose",
  description: "Performance audit",
  prompt: `你是性能专家。审查以下代码的性能问题。

变更文件: {files_changed}

检查项: N+1 查询、缓存策略、时间复杂度、内存泄漏

输出格式: 列表形式，每项包含 [严重程度] 问题描述: 文件:行号
最后给出评分 (0-10) 和总结。`
})

// Agent 3: 代码规范审计
Agent({
  subagent_type: "general-purpose",
  description: "Code style audit",
  prompt: `你是代码规范专家。审查以下代码。

变更文件: {files_changed}

检查项: 命名规范、代码格式、重复代码、注释质量

输出格式: 列表形式，每项包含 [严重程度] 问题描述: 文件:行号
最后给出评分 (0-10) 和总结。`
})

// Agent 4: 逻辑审查
Agent({
  subagent_type: "Explore",
  description: "Logic review",
  prompt: `你是业务逻辑专家。审查以下代码的逻辑完整性。

变更文件: {files_changed}

检查项: 边界条件、错误处理、类型安全

输出格式: 列表形式，每项包含 [严重程度] 问题描述: 文件:行号
最后给出评分 (0-10) 和总结。`
})
```

#### Step 2.3: 自动修复

1. 收集所有 4 个评审代理的输出
2. 按严重程度排序: Critical > High > Medium > Low
3. 逐一修复（Critical 必须修复，其他可标记 TODO）
4. 记录修复结果

#### Step 2.4: 构建验证

```bash
# 根据项目类型执行（检测 package.json / Cargo.toml / requirements.txt）
npm test / cargo test / python -m pytest
npm run lint / cargo clippy / ruff check
```

#### Step 2.5: 归档

写入 `.claude-phases/` 目录：
- `phase-{N}-trace.md`: 完整执行日志
- `phase-{N}-CHANGELOG.md`: 变更摘要
- `phase-{N}-review.md`: 多代理评审汇总
- `phase-{N}-status.json`: 断点状态

#### Step 2.6: Git Commit

```bash
# 添加所有变更
git add -A

# 创建 commit，包含 Phase 信息
git commit -m "forge(phase-{N}): {Phase名称}

- 变更文件: {files_changed}
- 评审评分: Security {score}, Performance {score}, Style {score}, Logic {score}
- 问题修复: {fixed}/{found}

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"

# 记录 commit hash 到状态文件
FORGE_COMMIT_HASH=$(git rev-parse HEAD)
```

#### Step 2.7: 更新全局状态

更新 `.forge-state.json`，标记当前 Phase 为 completed，记录 commit hash

### 3. 完成阶段

1. 汇总所有 Phase 结果
2. 生成最终报告
3. 输出成功/失败摘要

## 状态文件格式

### `.forge-state.json` (项目根目录)

```json
{
  "version": "1.0",
  "task": "任务描述",
  "started_at": "2025-01-15T10:00:00Z",
  "current_phase": 1,
  "total_phases": 5,
  "git_branch": "forge/task-1717200000",
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
  "files_changed": ["file1.ts", "file2.ts"],
  "review_scores": {
    "security": 9.5,
    "performance": 8.0,
    "style": 9.0,
    "logic": 8.5
  },
  "issues_found": 8,
  "issues_fixed": 7,
  "issues_todo": 1,
  "build_passed": true,
  "tests_passed": true
}
```

## 错误处理

### 自动重试策略

1. **构建失败**: 自动分析错误，修复后重试（最多 3 次）
2. **测试失败**: 自动修复测试用例或代码
3. **评审阻塞**: Critical 安全问题必须修复，其他可标记 TODO

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

### Git Log 格式

```
forge(phase-1): 项目初始化
forge(phase-2): 实现 API + 评审
forge(phase-3): 修复 + 归档
```

## 归档文件模板

### phase-{N}-CHANGELOG.md

```markdown
# Phase N: {Phase名称}

## 变更摘要
- 新增文件: X
- 修改文件: Y
- 删除文件: Z

## 主要变更
1. **文件路径**: 变更描述

## 测试覆盖
- 新增测试: X
- 覆盖率: XX%
```

### phase-{N}-review.md

```markdown
# Phase N 多代理评审报告

## 总览
| 代理 | 评分 | 问题数 | 已修复 | TODO |
|------|------|--------|--------|------|
| Security | 9.5 | 2 | 2 | 0 |
| Performance | 8.0 | 3 | 2 | 1 |
| Style | 9.0 | 1 | 1 | 0 |
| Logic | 8.5 | 2 | 2 | 0 |

## 详细发现
### Security Agent
- [FIXED] 问题描述: 文件:行号

### Performance Agent
- [FIXED] 问题描述
- [TODO] 建议描述（非阻塞）
```
