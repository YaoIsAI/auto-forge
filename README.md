# Forge - Multi-Phase Workflow Engine

[中文](#中文说明) | [English](#english)

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

```bash
# Clone the repository
git clone https://github.com/YaoIsAI/auto-forge.git

# Create symbolic link
# Windows (Git Bash)
ln -s /path/to/auto-forge/.claude/skills/forge ~/.claude/skills/forge

# Linux/macOS
ln -s /path/to/auto-forge/.claude/skills/forge ~/.claude/skills/forge
```

### Usage

```
/forge Implement a user authentication module with JWT + OAuth2
/forge --resume              # Resume from breakpoint
/forge --revert 2            # Revert to Phase 2
/forge --log                 # View git history
```

---

## 中文说明

Claude Code 的全自动多 Phase 工作流插件，支持并行 AI 评审和完整 Git 版本控制。

### 功能特性

- **多 Phase 串行执行**: 自动拆分任务，按阶段执行
- **多代理并行评审**: 4 个 AI 代理同时审查（安全/性能/规范/逻辑）
- **Git 版本控制**: 每个 Phase 自动 commit，支持回撤
- **断点续跑**: 支持从失败点恢复
- **自动归档**: 每个 Phase 生成完整文档
- **自动批准**: 在工作流中自动批准操作（可配置）

## 前置条件

- `git` - 版本控制
- `jq` - JSON 处理（Windows 需手动安装）
- 各语言构建工具（npm/cargo/python/go）

### 安装 jq (Windows)

```bash
# 使用 scoop
scoop install jq

# 或手动下载
curl -sL https://github.com/jqlang/jq/releases/latest/download/jq-windows-amd64.exe -o /c/Users/yao/.local/bin/jq.exe
```

## 安装

### 方式 1: 符号链接（推荐）

```bash
# Windows (Git Bash)
ln -s /c/Users/yao/Desktop/openclaw/projects/auto-forge/.claude/skills/forge /c/Users/yao/.claude/skills/forge

# Linux/macOS
ln -s ~/path/to/auto-forge/.claude/skills/forge ~/.claude/skills/forge
```

### 方式 2: 插件目录测试

```bash
claude --plugin-dir /path/to/auto-forge
```

## 使用方式

### 启动 Claude Code

```bash
# 推荐使用自动权限模式
claude --permission-mode bypassPermissions

# 或在项目目录下启动（已配置权限）
cd /path/to/your/project
claude
```

### 基本用法

```
/forge 实现一个用户认证模块，支持 JWT + OAuth2
/forge ./docs/requirements.md
```

### 高级用法

```
/forge --resume              # 从断点继续
/forge --revert 2            # 回撤到 Phase 2 完成后的状态
/forge --log                 # 查看所有 Phase 的 git 历史
```

## 工作流程

### 1. 初始化阶段

- 解析任务描述
- 检查/初始化 Git 仓库
- 拆分为多个 Phase（通常 3-7 个）

### 2. Phase 执行循环

对每个 Phase 执行：

1. **开发编码** - 使用 Agent 工具执行编码任务
2. **多代理并行评审** - 4 个代理同时审查
3. **自动修复** - 按严重程度修复问题
4. **构建验证** - 执行构建和测试
5. **归档** - 生成文档
6. **Git Commit** - 提交变更

### 3. 完成阶段

- 汇总所有 Phase 结果
- 生成最终报告

## Git 集成

### Commit 格式

```
forge(phase-1): 项目初始化

- 变更文件: file1.js, file2.js
- 评审评分: 安全 9.0, 性能 8.5, 规范 9.0, 逻辑 8.5
- 问题修复: 5/8
```

### 回撤操作

```bash
# 查看所有 Phase 的 commit
git log --oneline --grep="forge(phase"

# 回撤特定 Phase
git revert <commit-hash>

# 或使用 forge 命令
/forge --revert 2
```

## 文件结构

### 插件结构

```
auto-forge/
├── .claude-plugin/
│   └── plugin.json           # 插件清单
├── skills/forge/
│   ├── SKILL.md              # 主入口
│   └── scripts/
│       ├── state-manager.sh  # 状态管理
│       ├── orchestrator.sh   # 流程编排
│       ├── retry-handler.sh  # 重试处理
│       ├── archive-gen.sh    # 归档生成
│       └── common.sh         # 公共函数
├── hooks/
│   ├── hooks.json            # Hook 配置
│   ├── auto-approve.sh       # 自动批准
│   └── self-heal.sh          # 自愈逻辑
├── tests/
│   ├── run-tests.sh          # 测试运行器
│   ├── test-state-manager.sh # 状态管理测试
│   └── test-orchestrator.sh  # 编排器测试
└── README.md
```

### 项目执行结构

```
your-project/
├── .forge-state.json         # 全局状态
├── .claude-phases/
│   ├── phase-1-trace.md      # 执行日志
│   ├── phase-1-CHANGELOG.md  # 变更记录
│   ├── phase-1-review.md     # 评审报告
│   ├── phase-1-status.json   # 断点状态
│   └── FINAL-REPORT.md       # 最终报告
└── src/                      # 你的代码
```

## 配置

### 权限配置

项目 `.claude/settings.json` 已预设权限：

```json
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read",
      "Write",
      "Edit",
      "Glob",
      "Grep",
      "Agent",
      "WebSearch",
      "WebFetch"
    ]
  }
}
```

### Hook 配置

`hooks/hooks.json` 配置了自动批准和自愈 hooks。

## 测试

```bash
# 运行所有测试
bash tests/run-tests.sh

# 运行单个测试
bash tests/test-state-manager.sh
bash tests/test-orchestrator.sh
```

## 限制与注意事项

1. **首次运行**: 建议使用 `--permission-mode bypassPermissions`
2. **并行 Agent 数**: 建议不超过 4 个
3. **状态持久化**: 依赖文件系统，异常断电可能丢失进度
4. **Windows 兼容性**: 需要 Git Bash 环境

## 故障排除

### jq 未安装

```bash
# Windows
scoop install jq

# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### 权限问题

确保 hooks 脚本有执行权限：

```bash
chmod +x hooks/*.sh
chmod +x .claude/*.sh
```

### Git 问题

如果遇到 Git 错误，检查：

```bash
git status
git log --oneline -5
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## License

MIT
