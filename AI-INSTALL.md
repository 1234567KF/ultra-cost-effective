# UltraCostEffective · AI 自动安装指南

> **本文档专为 AI 设计**。如果你是 AI 助手，请按以下步骤自动安装和配置 UltraCostEffective。

---

## 🎯 安装目标

为当前项目启用 UltraCostEffective Token 节省体系，综合节省 60-90% Token。

---

## 📋 前置检查

执行以下命令检查环境：

```bash
# 1. 检查 Node.js 版本（需要 ≥ 18）
node --version

# 2. 检查当前项目目录
pwd

# 3. 检查是否已存在 ultra-cost-effective
ls -la ultra-cost-effective/ 2>/dev/null || echo "未安装"
```

---

## 🚀 自动安装步骤

### 步骤 1：克隆仓库

```bash
# 克隆到当前项目的 ultra-cost-effective/ 子目录
git clone https://github.com/1234567KF/ultra-cost-effective.git ultra-cost-effective
```

### 步骤 2：配置 Claude Code / Qoder

**对于 Claude Code：**

```bash
# 创建 .claude 目录（如果不存在）
mkdir -p .claude

# 复制配置模板
cp ultra-cost-effective/adapters/claude/settings.template.json .claude/settings.json

# 如果已有 settings.json，需要合并配置（见下方说明）
```

**对于 Qoder：**

```bash
# Qoder 需要手动合并 settings.patch.json 到 Qoder 的 settings.json
# 参考 ultra-cost-effective/adapters/qoder/settings.patch.json
```

### 步骤 3：导入规则

在项目根目录创建或编辑 `CLAUDE.md`：

```bash
# 如果 CLAUDE.md 不存在，创建它
if [ ! -f CLAUDE.md ]; then
  echo "# 项目说明" > CLAUDE.md
fi

# 添加 UltraCostEffective 规则引用
echo "" >> CLAUDE.md
echo "## Token 节能" >> CLAUDE.md
echo "@ultra-cost-effective/rules/main.md" >> CLAUDE.md
```

### 步骤 4：安装可选依赖（推荐）

```bash
# 安装 lean-ctx（上下文压缩 MCP）
npm install -g lean-ctx-bin
lean-ctx init
```

### 步骤 5：重启 Claude Code / Qoder

**重要**：配置完成后必须重启 Claude Code 或 Qoder 才能生效。

---

## ✅ 安装验证

执行以下命令验证安装：

```bash
# 1. 检查文件结构
ls -la ultra-cost-effective/
ls -la ultra-cost-effective/helpers/
ls -la ultra-cost-effective/rules/

# 2. 检查配置文件
cat .claude/settings.json | grep -i "ultra-cost-effective" || echo "配置未找到"
cat CLAUDE.md | grep -i "ultra-cost-effective" || echo "规则未导入"

# 3. 运行测试（可选）
node ultra-cost-effective/bench/test-workflow.cjs
node ultra-cost-effective/helpers/tokenforge-hook.cjs --test

# 4. 查看上下文健康状态
node ultra-cost-effective/helpers/context-interceptor.cjs health
```

---

## 🔧 配置合并说明

如果已有 `.claude/settings.json`，需要合并以下内容：

### 环境变量（env）

```json
{
  "env": {
    "ULTRA_COST_EFFECTIVE_PLATFORM": "claude",
    "ULTRA_COST_EFFECTIVE_LEVEL": "medium",
    "ULTRA_COST_EFFECTIVE_PRESET": "standard"
  }
}
```

### Hooks（关键）

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "node ultra-cost-effective/helpers/tokenforge-hook.cjs",
            "timeout": 5000
          }
        ]
      },
      {
        "matcher": "Agent",
        "hooks": [
          {
            "type": "command",
            "command": "node ultra-cost-effective/helpers/agent-spawn-guard.cjs",
            "timeout": 5000
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "node ultra-cost-effective/helpers/perf/perf-tracker.cjs --capture",
            "timeout": 3000
          },
          {
            "type": "command",
            "command": "node ultra-cost-effective/helpers/context-interceptor.cjs post-tool-use",
            "timeout": 3000
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "node ultra-cost-effective/helpers/model-router.cjs hook",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

### MCP Servers（可选但推荐）

```json
{
  "mcpServers": {
    "lean-ctx": {
      "command": "lean-ctx",
      "args": ["mcp"]
    }
  }
}
```

### 权限白名单

```json
{
  "permissions": {
    "allow": [
      "Bash(node ultra-cost-effective/helpers/*.cjs:*)",
      "Bash(node ultra-cost-effective/helpers/perf/*.cjs:*)",
      "Bash(npm install -g lean-ctx-bin:*)",
      "Bash(lean-ctx:*)"
    ]
  }
}
```

---

## 📊 安装后使用

### 自动生效功能

安装后以下功能自动激活：

| 功能 | 触发时机 | 效果 |
|------|---------|------|
| 输出压缩 | 每次 Bash 命令 | 自动追加 `\| node tokenforge.cjs compress` |
| Token 追踪 | 每次工具调用后 | 记录 token 消耗 |
| 上下文监控 | 每次工具调用后 | 评估上下文健康度 |
| 模型路由 | 每次用户输入 | 建议最优模型 |

### 手动命令

| 命令 | 说明 |
|------|------|
| `token report` | 查看 Token 消耗报告 |
| `节能` | 切换节能预设 |
| `ultra-cost-effective status` | 查看运行状态 |

---

## 🐛 故障排除

### 问题：Hooks 未生效

```bash
# 检查 hooks 配置
cat .claude/settings.json | jq '.hooks'

# 检查脚本权限
ls -la ultra-cost-effective/helpers/*.cjs

# 手动测试 hook
echo '{"tool_name":"Bash","tool_input":{"command":"echo test"}}' | node ultra-cost-effective/helpers/tokenforge-hook.cjs
```

### 问题：lean-ctx 不可用

```bash
# 检查 lean-ctx 安装
which lean-ctx
lean-ctx --version

# 重新安装
npm install -g lean-ctx-bin
lean-ctx init
```

### 问题：Token 报告无数据

```bash
# 检查 tracker 文件
ls -la .ultra-cost-effective-tracker.json

# 手动触发追踪
node ultra-cost-effective/helpers/perf/perf-tracker.cjs --capture

# 查看报告
node ultra-cost-effective/helpers/perf/perf-tracker.cjs --report
```

---

## 📚 更多信息

- **项目仓库**：https://github.com/1234567KF/ultra-cost-effective
- **详细文档**：`ultra-cost-effective/README.md`
- **技术规格**：`ultra-cost-effective/TOKEN-MONITOR-SPEC.md`

---

## 🔄 卸载

```bash
# 1. 删除引擎目录
rm -rf ultra-cost-effective/

# 2. 移除配置（手动编辑 .claude/settings.json）

# 3. 移除规则引用（手动编辑 CLAUDE.md）

# 4. 重启 Claude Code / Qoder
```

---

**安装完成后，重启 Claude Code / Qoder 即可自动生效。**
