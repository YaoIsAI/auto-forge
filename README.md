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

### Installation

**Option 1: Install from Marketplace (Recommended)**

```bash
/plugin install auto-forge@claude-plugins-official
```

> Note: Requires PR approval. Check status: https://github.com/anthropics/claude-plugins-official/pull/2153

**Option 2: Install from GitHub**

```bash
git clone https://github.com/YaoIsAI/auto-forge.git
ln -s /path/to/auto-forge/.claude/skills/forge ~/.claude/skills/forge
```

**Option 3: Plugin Directory Test**

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

### 安装方式

**方式 1: 从官方市场安装（推荐）**

```bash
/plugin install auto-forge@claude-plugins-official
```

> 注意: 需要 PR 审核通过。查看状态: https://github.com/anthropics/claude-plugins-official/pull/2153

**方式 2: 从 GitHub 安装**

```bash
git clone https://github.com/YaoIsAI/auto-forge.git
ln -s /path/to/auto-forge/.claude/skills/forge ~/.claude/skills/forge
```

**方式 3: 插件目录测试**

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

---

## Links

- **GitHub**: https://github.com/YaoIsAI/auto-forge
- **Marketplace PR**: https://github.com/anthropics/claude-plugins-official/pull/2153

## License

MIT
