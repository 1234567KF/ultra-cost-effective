# UltraCostEffective · 操作说明书

> 本文件是面向用户的详细操作指南。项目介绍请查看根目录 README.md。

---

## 快速接入（两种方式任选）

### 方式一：一键脚本（推荐）

```bash
# 在 ultra-cost-effective/ 目录下执行：

# Windows PowerShell
.\install.ps1 -Preset standard

# macOS / Linux
./install.sh --standard
```

脚本自动完成全部 5 步，重启平台即可。

**可选参数：**

| 参数 | 说明 | 默认 |
|------|------|------|
| `-Preset quick/standard/extreme` | 节能预设 | standard |
| `-SkipLeanCtx` | 跳过 lean-ctx 安装 | — |
| `-SkipHeadroom` | 跳过 Headroom 安装 | — |

### 方式二：手动 5 步

#### 第 1 步：复制引擎

```bash
cp -r ultra-cost-effective/ /path/to/your-project/
```

放到项目根目录，与 `package.json`、`src/` 同级。

#### 第 2 步：安装全局依赖（只需一次）

以下两个依赖为**全局安装**，换项目时不需重复安装：

**lean-ctx**（上下文压缩 — L1）：
```bash
npm install -g lean-ctx-bin
lean-ctx init
```

**Headroom**（CCR 可逆压缩 — extreme 预设可选）：
```bash
pip install headroom-ai[all]
```

> Headroom 为 extreme 预设的可选增强。不安装不影响 quick/standard 预设。

#### 第 3 步：合并 settings

**Claude Code 用户：**

```bash
# 如果项目已有 .claude/settings.json，手动合并以下字段：
# - env (添加 ULTRA_COST_EFFECTIVE_*)
# - hooks (PreToolUse, PostToolUse)
# - permissions.allow
# - mcpServers

# 如果没有，直接复制模板：
cp ultra-cost-effective/adapters/claude/settings.template.json .claude/settings.json
```

**Qoder 用户：**

将 `ultra-cost-effective/adapters/qoder/settings.patch.json` 的内容合并到 Qoder settings。

#### 第 4 步：重启平台

关掉 Claude Code / Qoder，重新打开。

#### 第 5 步：正常使用

框架全自动运行，无需任何操作。

---

## 日常使用

### 全自动模式

安装后所有功能自动激活：

| 触发 | 自动行为 |
|------|---------|
| 任何 Shell 命令 | tokenforge 自动压缩输出 |
| 文件读取 | lean-ctx MCP 自动缓存压缩 |
| 模型调用 | DeepSeek Pro/Flash 自动路由 |
| 上下文增长 | 三色灯实时监控，快满时提醒 |
| `ultracode` 触发 | 工作流预压缩 + session-memory 传递 |

### 手动命令

在对话中说以下关键词：

| 关键词 | 效果 |
|--------|------|
| `token report` / `成本报告` | 查看 Token 消耗与节省明细 |
| `节能` / `省token` | 切换预设（quick → standard → extreme 循环）|
| `ultra-cost-effective status` | 查看各层运行状态、缓存命中率 |
| `ultra-cost-effective off` | 临时关闭节能（调试用）|
| `ultra-cost-effective on` | 恢复节能 |

---

## 三层预设详解

| 预设 | 启用层 | 节省 | 说明 |
|------|--------|------|------|
| `quick` | L1 | 50-70% | 仅输出压缩，最轻量。适合日常快速编码 |
| `standard` ⭐ | L1+L2+L3 | 70-85% | 输出压缩 + KV Cache + 上下文压缩。推荐 |
| `extreme` | 全七层 | 85-95% | 全开。大型项目、长会话、极致省钱 |

**切换方式：**
- 对话中说 `节能`（循环切换）
- 脚本直接调用：`node helpers/preset-switch.cjs standard`

---

## 压缩级别说明

| 级别 | 效果 | 适用 |
|------|------|------|
| light | 轻量压缩，保持可读性 | 调试、探索 |
| medium | 中度压缩，去除冗余 | 日常开发（默认）|
| aggressive | 激进压缩，只保留关键 | CI/CD、大量输出 |

**压缩仅发生在输出侧和上下文侧，不影响 LLM 推理质量。**

---

## Dynamic Workflows 集成

当你使用 Claude Code 的 `ultracode` 或 `/deep-research` 等工作流时：

### 自动行为

1. 检测到 `ultracode` / `/deep-research` / 自然语言触发
2. 在脚本生成前压缩上下文
3. 所有子 agent 自动继承压缩上下文
4. 乘法级节省：单体 65% × N 个 agent

### 5 种工作流预设

| 预设 | 适用 | 压缩比 | 特点 |
|------|------|--------|------|
| moderate | 研究分析 | 65% | 保留引用追溯 |
| aggressive | 大量 agent | 80% | 代码精确，丢弃引用 |
| codeAudit | 代码审计 | 75% | 代码精确，文档激进 |
| migration | 迁移 | 70% | 代码精确，保留文档引用 |
| refactor | 重构 | 60% | 高可靠性，保守压缩 |

### ROI 追踪

```bash
# 记录运行
node helpers/workflow-integrator.cjs track my-workflow 320000

# 查看报告
node helpers/workflow-integrator.cjs roi

# 按名称过滤
node helpers/workflow-integrator.cjs roi my-workflow
```

---

## 三色灯上下文监控

| 状态 | 含义 | 行为 |
|------|------|------|
| 🟢 green | 上下文健康 (<60% 窗口) | 正常处理 |
| 🟡 yellow | 中度占用 (60-80%) | 优先用索引引用 |
| 🔴 red | 高危 (>80% 窗口) | 立即压缩，仅传摘要 |

**检查命令：**
```bash
node helpers/context-interceptor.cjs check
```

---

## 模型路由

| 任务 | 模型 | 输入价 | KV Cache |
|------|------|--------|---------|
| 架构/设计/规划 | deepseek-v4-pro | ¥3.0/MTok | ¥0.025/MTok |
| 编码/测试/修复 | deepseek-v4-flash | ¥1.0/MTok | ¥0.02/MTok |

路由规则：
- 含「架构/设计/规划/分析」→ Pro
- 含「写代码/实现/修复/测试」→ Flash
- 上下文过长 → 自动降级 Flash

---

## 验证与调试

```bash
# 验证核心引擎
node helpers/prefix-validator.cjs --check-all

# 运行全量测试 (187 项)
node bench/test-workflow.cjs
node bench/test-interceptor.cjs
node bench/test-guard.cjs
node bench/test-session-memory.cjs
node bench/test-hotswitch.cjs

# 测试 tokenforge 压缩
node helpers/tokenforge.cjs --test

# 查看上下文健康
node helpers/context-interceptor.cjs health

# 查看 guard 审计
node helpers/ultra-cost-effective-guard.cjs audit
```

---

## 卸载

```bash
# 1. 删除引擎目录
rm -rf ultra-cost-effective/

# 2. 移除 settings 中的 ultra-cost-effective 相关配置
#    (hooks, permissions, mcpServers, environment)

# 3. 重启平台
```

---

## 常见问题

**Q: 压缩后原文还能找回来吗？**
能。session-memory 索引保留所有原文，通过 `retrieve <id>` 取回。

**Q: 影响其他技能吗？**
不影响。其他技能看到的工具输出已是压缩版本，如需原文同样通过索引取回。

**Q: 两个项目能共用吗？**
核心引擎通过 `__dirname` 自定位，每个项目独立安装，互不干扰。

**Q: 支持其他模型吗？**
当前路由仅 DeepSeek。扩展需修改 `adapters/` 中的路由规则。

**Q: lean-ctx 装不上怎么办？**
框架不强制依赖 lean-ctx。跳过安装后 L1 中的 MCP 压缩层不生效，其他层正常工作。

---

## 系统要求

- Node.js ≥ 18
- lean-ctx（可选，`npm install -g lean-ctx-bin`）
- DeepSeek API 访问
- Claude Code v2.1.154+（Dynamic Workflows）或 Qoder
