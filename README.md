# Forge - Multi-Phase Workflow Engine

> Claude Code 全自动多 Phase 工作流引擎 | Multi-phase workflow engine for Claude Code

[English](#english-1) | [中文](#中文-1)

---

<a name="english-1"></a>

## English

A multi-phase workflow engine for Claude Code with automatic task decomposition, parallel multi-agent review, and complete Git version control.

### Features

- **Multi-Phase Execution**: Automatically decompose tasks into phases
- **Parallel Multi-Agent Review**: 4 AI agents review simultaneously (security/performance/style/logic)
- **Git Version Control**: Auto-commit each phase with full history
- **Breakpoint Resume**: Resume from failed phases
- **Auto Archiving**: Generate documentation for each phase
- **Auto-Approve**: Automatically approve safe operations in workflow

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

### Installation

#### Option 1: Install from Marketplace (Recommended)

```bash
/plugin install auto-forge@claude-plugins-official
```

> Note: Requires PR approval. Check status: https://github.com/anthropics/claude-plugins-official/pull/2153

#### Option 2: Install from GitHub

```bash
# Clone the repository
git clone https://github.com/YaoIsAI/auto-forge.git

# Create symbolic link
# Windows (Git Bash)
ln -s /path/to/auto-forge/.claude/skills/forge ~/.claude/skills/forge

# Linux/macOS
ln -s /path/to/auto-forge/.claude/skills/forge ~/.claude/skills/forge
```

#### Option 3: Plugin Directory Test

```bash
claude --plugin-dir /path/to/auto-forge
```

### Usage

#### Step 1: Start Claude Code (Important)

**Recommended: Use bypass mode for fully automatic execution:**

```bash
# Method 1: Command line parameter (Recommended)
claude --permission-mode bypassPermissions

# Method 2: Start in project directory
cd /path/to/your/project
claude --permission-mode bypassPermissions
```

#### Step 2: Use Forge Command

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

#### Issue 1: Still requires manual confirmation

**Cause**: Claude Code not started with bypass mode

**Solution**:
```bash
# Restart Claude Code with bypass mode
claude --permission-mode bypassPermissions
```

#### Issue 2: Hooks not working

**Cause**: Hooks not installed in project

**Solution**:
```bash
# Run installation script
bash ~/.claude/skills/forge/scripts/setup-hooks.sh

# Verify installation
ls -la .claude/*.sh
```

#### Issue 3: State file not found

**Cause**: Forge not initialized or state file deleted

**Solution**:
```bash
# Check state file
cat .forge-state.json

# If not exists, run forge again
/forge your task description
```

#### Issue 4: View logs

```bash
# View hook execution logs
tail -50 .forge-hook.log

# Monitor hook status
bash ~/.claude/skills/forge/scripts/monitor-hooks.sh
```

#### Issue 5: Rollback to previous state

```bash
# View git history
git log --oneline --grep="forge(phase"

# Revert to specific phase
/forge --revert 2

# Or manual revert
git revert <commit-hash>
```

---

<a name="中文-1"></a>

## 中文

Claude Code 的全自动多 Phase 工作流插件，支持并行 AI 评审和完整 Git 版本控制。

### 功能特性

- **多 Phase 串行执行**: 自动拆分任务，按阶段执行
- **多代理并行评审**: 4 个 AI 代理同时审查（安全/性能/规范/逻辑）
- **Git 版本控制**: 每个 Phase 自动 commit，支持回撤
- **断点续跑**: 支持从失败点恢复
- **自动归档**: 每个 Phase 生成完整文档
- **自动批准**: 工作流中自动批准安全操作

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

### 安装方式

#### 方式 1: 从官方市场安装（推荐）

```bash
/plugin install auto-forge@claude-plugins-official
```

> 注意: 需要 PR 审核通过。查看状态: https://github.com/anthropics/claude-plugins-official/pull/2153

#### 方式 2: 从 GitHub 安装

```bash
# 克隆仓库
git clone https://github.com/YaoIsAI/auto-forge.git

# 创建符号链接
# Windows (Git Bash)
ln -s /path/to/auto-forge/.claude/skills/forge ~/.claude/skills/forge

# Linux/macOS
ln -s /path/to/auto-forge/.claude/skills/forge ~/.claude/skills/forge
```

#### 方式 3: 插件目录测试

```bash
claude --plugin-dir /path/to/auto-forge
```

### 使用方式

#### 第一步：启动 Claude Code（重要）

**推荐使用 bypass 模式启动，实现全自动执行：**

```bash
# 方式 1: 命令行参数（推荐）
claude --permission-mode bypassPermissions

# 方式 2: 在项目目录启动
cd /path/to/your/project
claude --permission-mode bypassPermissions
```

#### 第二步：使用 Forge 命令

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

#### 问题 1: 仍然需要手动确认

**原因**: 未使用 bypass 模式启动 Claude Code

**解决**:
```bash
# 重新启动 Claude Code，使用 bypass 模式
claude --permission-mode bypassPermissions
```

#### 问题 2: Hook 未生效

**原因**: Hooks 未安装到项目

**解决**:
```bash
# 运行安装脚本
bash ~/.claude/skills/forge/scripts/setup-hooks.sh

# 验证安装
ls -la .claude/*.sh
```

#### 问题 3: 状态文件不存在

**原因**: Forge 未初始化或状态文件被删除

**解决**:
```bash
# 检查状态文件
cat .forge-state.json

# 如果不存在，重新运行 forge
/forge 你的任务描述
```

#### 问题 4: 查看日志

```bash
# 查看 hook 执行日志
tail -50 .forge-hook.log

# 监控 hook 状态
bash ~/.claude/skills/forge/scripts/monitor-hooks.sh
```

#### 问题 5: 回滚到之前的状态

```bash
# 查看 git 历史
git log --oneline --grep="forge(phase"

# 回撤到特定 Phase
/forge --revert 2

# 或手动回撤
git revert <commit-hash>
```

---

## Links

- **GitHub**: https://github.com/YaoIsAI/auto-forge
- **Marketplace PR**: https://github.com/anthropics/claude-plugins-official/pull/2153

## License

MIT
