# Forge Hooks

Forge 的 hooks 用于实现全自动执行和自愈功能。

## 文件说明

- `auto-approve.sh` - 自动批准工具调用
- `self-heal.sh` - 自愈和超时检测
- `hooks.json` - Hook 配置

## 安装

### 方式 1: 自动安装（推荐）

```bash
# 在你的项目目录中运行
bash ~/.claude/skills/forge/scripts/setup-hooks.sh
```

### 方式 2: 手动安装

```bash
# 创建 .claude 目录
mkdir -p .claude

# 复制 hooks
cp ~/.claude/skills/forge/hooks/*.sh .claude/

# 复制 settings.json
cp ~/.claude/skills/forge/settings.json .claude/
```

## 功能

### 自动批准

`auto-approve.sh` 会在 forge 工作流中自动批准所有安全的工具调用，包括：
- Bash 命令
- 文件读写
- Git 操作
- 依赖安装

危险命令（如 `rm -rf /`、`git push --force`）不会被自动批准。

### 自愈和超时检测

`self-heal.sh` 会：
1. 检测未完成的 Phase 并强制继续
2. 检测超时（60 秒无活动）并自动继续
3. 记录日志用于调试

## 监控

```bash
# 检查 hooks 状态
bash ~/.claude/skills/forge/scripts/monitor-hooks.sh
```

## 日志

Hooks 会生成日志文件 `.forge-hook.log`，用于调试：

```bash
# 查看最近日志
tail -20 .forge-hook.log
```

## 故障排除

### 问题：Hooks 未生效

检查：
1. `.claude/` 目录是否存在
2. `auto-approve.sh` 是否有执行权限
3. `settings.json` 中的 hooks 配置是否正确

### 问题：仍然需要手动确认

检查：
1. `.forge-state.json` 是否存在
2. 状态文件内容是否有效
3. 查看 `.forge-hook.log` 日志
