# Forge - 全自动工作流引擎

Claude Code 的全自动多 Phase 工作流插件，支持并行 AI 评审。

## 功能特性

- **多 Phase 串行执行**: 自动拆分任务，按阶段执行
- **多代理并行评审**: 4 个 AI 代理同时审查（安全/性能/规范/逻辑）
- **自动批准**: 在工作流中自动批准所有操作
- **断点续跑**: 支持从失败点恢复
- **自动归档**: 每个 Phase 生成完整文档

## 安装

### 1. 克隆项目

```bash
cd ~/Desktop/openclaw/projects
# 项目已在 auto-forge 目录
```

### 2. 创建符号链接

```bash
# Windows (Git Bash)
ln -s /c/Users/yao/Desktop/openclaw/projects/auto-forge/.claude/skills/forge /c/Users/yao/.claude/skills/forge
```

### 3. 安装 Hooks（可选）

将 `hooks/` 目录中的文件复制到你的项目中，或在 `~/.claude/settings.json` 中配置全局 hooks。

## 使用方式

### 基本用法

```bash
# 启动 Claude Code 时使用自动权限模式
claude --permission-mode auto

# 然后使用 /forge 命令
/forge 实现一个用户认证模块，支持 JWT + OAuth2
```

### 从文件读取任务

```bash
/forge ./docs/requirements.md
```

### 从断点继续

```bash
/forge --resume
```

## 工作流程

1. **初始化**: 解析任务，拆分为多个 Phase
2. **Phase 执行**:
   - 开发编码（Agent 工具）
   - 多代理并行评审（4 个 Agent）
   - 自动修复问题
   - 构建验证
   - 归档
3. **完成**: 生成最终报告

## 文件结构

```
项目根目录/
├── .forge-state.json          # 全局状态
├── .claude-phases/
│   ├── phase-1-trace.md       # 执行日志
│   ├── phase-1-CHANGELOG.md   # 变更记录
│   ├── phase-1-review.md      # 评审报告
│   └── phase-1-status.json    # 断点状态
└── FINAL-REPORT.md            # 最终报告
```

## 配置

### 权限配置

项目 `.claude/settings.json` 已预设所有必要权限：

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

## 限制

1. **首次运行**: 需要使用 `--permission-mode auto` 或手动批准一次
2. **并行 Agent 数**: 建议不超过 4 个
3. **状态持久化**: 依赖文件系统，异常断电可能丢失进度

## 开发

### 目录结构

```
auto-forge/
├── .claude/
│   ├── settings.json
│   └── skills/forge/
│       ├── SKILL.md           # 主入口
│       └── scripts/           # 辅助脚本
├── hooks/                     # Hook 脚本
├── examples/                  # 使用示例
└── README.md
```

### 脚本说明

- `state-manager.sh`: 状态管理
- `orchestrator.sh`: 流程编排
- `retry-handler.sh`: 重试处理
- `archive-gen.sh`: 归档生成

## License

MIT
