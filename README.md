# Forge - Multi-Phase Workflow Engine

[English](#english) | [中文](#中文)

---

## English

A multi-phase workflow engine for Claude Code with automatic task decomposition, parallel multi-agent review, and complete Git version control.

### Features

- **Multi-Phase Execution**: Automatically decompose tasks into phases
- **Parallel Multi-Agent Review**: 4 AI agents review simultaneously (security/performance/style/logic)
- **Git Version Control**: Auto-commit each phase with full history
- **Breakpoint Resume**: Resume from failed phases
- **Auto Archiving**: Generate documentation for each phase

### Installation

#### Option 1: Install from Marketplace (Recommended)

```bash
/plugin install auto-forge@claude-plugins-official
```

> **Note**: This requires the PR to be approved. Check status: https://github.com/anthropics/claude-plugins-official/pull/2153

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

```
/forge Implement a user authentication module with JWT + OAuth2
/forge --resume              # Resume from breakpoint
/forge --revert 2            # Revert to Phase 2
/forge --log                 # View git history
```

### Prerequisites

- `git` - Version control
- `jq` - JSON processing (manual install on Windows)
- Build tools for your language (npm/cargo/python/go)

#### Install jq (Windows)

```bash
# Using scoop
scoop install jq

# Or manual download
curl -sL https://github.com/jqlang/jq/releases/latest/download/jq-windows-amd64.exe -o /c/Users/yao/.local/bin/jq.exe
```

---

## 中文

Claude Code 的全自动多 Phase 工作流插件，支持并行 AI 评审和完整 Git 版本控制。

### 功能特性

- **多 Phase 串行执行**: 自动拆分任务，按阶段执行
- **多代理并行评审**: 4 个 AI 代理同时审查（安全/性能/规范/逻辑）
- **Git 版本控制**: 每个 Phase 自动 commit，支持回撤
- **断点续跑**: 支持从失败点恢复
- **自动归档**: 每个 Phase 生成完整文档
- **自动批准**: 在工作流中自动批准操作（可配置）

### 安装方式

#### 方式 1: 从官方市场安装（推荐）

```bash
/plugin install auto-forge@claude-plugins-official
```

> **注意**: 需要 PR 审核通过。查看状态: https://github.com/anthropics/claude-plugins-official/pull/2153

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

```
/forge 实现一个用户认证模块，支持 JWT + OAuth2
/forge --resume              # 从断点继续
/forge --revert 2            # 回撤到 Phase 2 完成后的状态
/forge --log                 # 查看所有 Phase 的 git 历史
```

### 前置条件

- `git` - 版本控制
- `jq` - JSON 处理（Windows 需手动安装）
- 各语言构建工具（npm/cargo/python/go）

#### 安装 jq (Windows)

```bash
# 使用 scoop
scoop install jq

# 或手动下载
curl -sL https://github.com/jqlang/jq/releases/latest/download/jq-windows-amd64.exe -o /c/Users/yao/.local/bin/jq.exe
```

---

## Links

- **GitHub**: https://github.com/YaoIsAI/auto-forge
- **Marketplace PR**: https://github.com/anthropics/claude-plugins-official/pull/2153

## License

MIT
