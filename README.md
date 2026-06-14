# UltraCostEffective · 极致节能

> **不降低 LLM 输出质量，综合节省 60-90% Token。**
> Claude Code + Qoder 双平台通用，纯 Node.js 核心引擎，即拷即用。

[![Tests](https://img.shields.io/badge/tests-187%20passed-brightgreen)](./ultra-cost-effective/bench/)
[![Node](https://img.shields.io/badge/node-%3E%3D18-blue)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()

---

## 它解决什么问题？

你每次让 AI 跑命令（`npm test`、`grep`、`cat` 等），原始输出可能几千行。这些内容**原封不动塞进上下文**，很快就把窗口塞满了：

- AI 后续回答质量下降
- Token 费用飙升
- 长会话被迫中断

**ultra-cost-effective 在工具输出进入 AI 大脑之前自动压缩它。**

```
工具输出 8000 tokens → [ultra-cost-effective] → 800 tokens → AI 大脑
```

## 30 秒上手

**无需克隆仓库！** 在你的项目根目录直接运行：

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/1234567KF/ultra-cost-effective/main/install.sh | bash
```

带参数：

```bash
# 指定平台
curl -fsSL https://raw.githubusercontent.com/1234567KF/ultra-cost-effective/main/install.sh | bash -s -- --platform qoder

# 极致模式
curl -fsSL https://raw.githubusercontent.com/1234567KF/ultra-cost-effective/main/install.sh | bash -s -- --preset extreme
```

### Windows PowerShell

```powershell
irm https://raw.githubusercontent.com/1234567KF/ultra-cost-effective/main/install.ps1 | iex
```

带参数：

```powershell
irm https://raw.githubusercontent.com/1234567KF/ultra-cost-effective/main/install.ps1 | iex -Platform qoder -Preset extreme
```

脚本自动完成：下载引擎 → 解压到当前目录 → 安装依赖 → 智能合并 settings。

**重启 Claude Code / Qoder 即可，全自动运行，无需任何操作。**

> 如果你已克隆仓库，也可以用 `quick-setup.sh` / `quick-setup.ps1` 从本地安装。

---

## 原理：四层拦截体系

```
工具输出 → [① 规则] → [② Hook] → [③ AOP 拦截器] → [④ Workflow 预压缩] → AI
```

| 层 | 名称 | 做什么 | 触发时机 |
|---|------|--------|---------|
| ① | Always-on 规则 | 告诉 AI "输出要压缩" | 系统提示注入，始终生效 |
| ② | PreToolUse Hook | 拦截 Shell 命令，自动套压缩管道 | 每次 Bash 命令前 |
| ③ | AOP 上下文拦截器 | 监控上下文健康度（三色灯） | 每次 LLM 调用前 |
| ④ | Workflow 预压缩 | 检测到 `ultracode` 触发时预压缩 | Dynamic Workflow 启动前 |

**压缩只发生在"工具输出 → AI"这条路上，AI 的推理能力本身不受影响。**

---

## 怎么省钱？算笔账

你让 AI 跑 `npm test`，输出 500 行测试日志（约 8000 tokens）：

| 场景 | 不装 | 装了 ultra-cost-effective |
|------|------|--------------------------|
| 单次输出 | 8,000 tokens | 800 tokens（压缩 90%）|
| 后续 20 轮对话 | 160,000 tokens | 16,000 tokens |
| **节省** | — | **144,000 tokens（90%）** |

**再乘以 Dynamic Workflows：**

Claude Code 的 `ultracode` 工作流一次能 spawn 50-1000 个子 agent，每个都继承上下文。先压缩再启动工作流 → 节省是**乘法级**的：

```
单体压缩 65% × 50 个 agent = 等效节省 3,250%
```

---

## 三层预设

| 预设 | 节省 | 适用场景 | 一句话 |
|------|------|---------|--------|
| `quick` | 50-70% | 日常编码 | 够快就行 |
| `standard` ⭐ | 70-85% | 项目开发 | 推荐 |
| `extreme` | 85-95% | 大型项目/长会话 | 极致省钱 |

默认 `standard`，对话中说 `节能` 可切换。

---

## 架构全景

```
    ┌── AOP Context Interceptor ──────────────────────┐
    │  三色灯监控 + Agent Spawn Guard + 规则注入       │
    │  确保每次 LLM 调用前上下文已被压缩              │
    └──────────────────────┬──────────────────────────┘
         │  Dynamic Workflows  │  ultracode 触发预压缩 + 乘法级节省
         │  L7 模型智能路由    │  DeepSeek Pro↔Flash 按需切换
         │  L6 A2A通信压缩     │  Agent间 ~3x 压缩消息
         │  L5 阶段智能跳过    │  小变更跳过低价值阶段
         │  L4 技能按需加载    │  非活跃技能 → ~25 token stub
         │────────────────────┬───────────────────────
         │  L3 长上下文预热    │  PRD/Spec 触发 KV Cache checkpoint
         │  L2 共享前缀缓存    │  固定前缀，命中率 >90%
         │  L1 输出+上下文压缩 │  tokenforge + lean-ctx，压缩比 80-99%
         └────────────────────┴───────────────────────
```

```
┌──────────────────────────────────────────────────────┐
│        ultra-cost-effective 核心引擎（平台无关）        │
│  tokenforge · context-interceptor · workflow-integrator│
│  session-memory · guard · cache-monitor · router       │
│         纯 Node.js，__dirname 自定位，零平台依赖        │
├────────────────────┬─────────────────────────────────┤
│   Claude Code      │        Qoder                    │
│   settings.json    │   settings.patch.json           │
│   PreToolUse Hook  │   hook-adapter.cjs              │
│   Dynamic Workflows│   AOP + WF Rules                │
│   MCP lean-ctx     │   模型列表锁 DeepSeek            │
└────────────────────┴─────────────────────────────────┘
```

---

## 目录结构

```
ultra-cost-effective/
├── helpers/                  ← 核心引擎（纯 Node.js，零外部依赖）
│   ├── tokenforge.cjs              L1 输出压缩引擎（4模/3级）
│   ├── tokenforge-hook.cjs         自动管道注入 Hook
│   ├── context-interceptor.cjs     AOP 上下文拦截器（三色灯 + Agent Spawn + Pre-Workflow）
│   ├── workflow-integrator.cjs     Dynamic Workflows 集成（触发检测 + ROI 回测 + 专属预设）
│   ├── session-memory.cjs          压缩记录索引（原文可取回）
│   ├── ultra-cost-effective-guard.cjs  跨技能生效守卫（防绕过 + Workflow 审计）
│   ├── skill-loader.cjs            L4 技能按需加载
│   ├── cache-monitor.cjs           L2 KV Cache 命中率监控
│   ├── prefix-validator.cjs        L2 共享前缀一致性校验
│   └── perf/
│       ├── perf-tracker.cjs        全链路 Token 追踪
│       ├── pricing.json            DeepSeek 双模型价格表
│       └── optimization-registry.json
├── rules/                    ← 规则层（always-on，自动注入）
│   ├── interceptor-aop.md          三色灯 + Agent Spawn Guard
│   ├── workflow-compress.md        Dynamic Workflows 预压缩
│   ├── shared-prefix.md            L2 共享前缀
│   ├── cache-optimization.md       KV Cache 策略
│   ├── lean-ctx.md                 上下文压缩
│   └── compression-default.md      默认压缩
├── adapters/                 ← 平台适配层
│   ├── claude/settings.template.json   Claude Code 配置模板
│   └── qoder/
│       ├── settings.patch.json         Qoder 配置补丁
│       └── hook-adapter.cjs            Qoder Hook 适配器
├── skills/                   ← 子技能定义
│   ├── ultra-cost-effective-output/        L1 输出+上下文压缩
│   ├── ultra-cost-effective-cache/         L2+L3 KV Cache 优化
│   ├── ultra-cost-effective-router/        L7 DeepSeek 双模型路由
│   └── ultra-cost-effective-monitor/       L0 全链路成本监控
├── presets/                  ← 三层节能预设
│   ├── quick.json                仅 L1（50-70%）
│   ├── standard.json             L1+L2+L3（70-85%）⭐
│   └── extreme.json              全七层（85-95%）
├── bench/                    ← 基准测试（187 项全绿）
│   ├── test-workflow.cjs             Workflow 集成测试（92 项）
│   ├── test-interceptor.cjs          AOP 拦截器测试（37 项）
│   ├── test-guard.cjs                生效守卫测试（26 项）
│   ├── test-session-memory.cjs       会话记忆测试（32 项）
│   └── test-hotswitch.cjs            热切换测试
├── install.ps1               Windows 安装（目录已在项目中时）
├── install.sh                macOS/Linux 安装
├── SKILL.md                  Skill 入口声明
├── CLAUDE.md                 Claude Code 项目引导
└── README.md                 操作说明书
```

---

## 使用方法

### 全自动模式（默认）

安装后无需任何操作，框架全自动运行：

- Shell 命令输出 → tokenforge 自动压缩
- 文件读取 → lean-ctx MCP 自动缓存压缩
- 模型选择 → 根据任务类型自动路由 DeepSeek Pro/Flash
- 上下文监控 → 三色灯实时监控，快满时自动提醒
- Workflow 触发 → `ultracode` 工作流前自动预压缩

### 手动命令（可选）

在对话中说：

| 关键词 | 效果 |
|--------|------|
| `token report` / `成本报告` | 查看当前会话 Token 消耗与节省 |
| `节能` / `省token` | 切换预设：quick → standard → extreme |
| `ultra-cost-effective status` | 各层运行状态 |
| `ultra-cost-effective off` | 临时暂停 |
| `ultra-cost-effective on` | 恢复 |

---

## Dynamic Workflows 集成

当你在 Claude Code 中使用 `ultracode` 或 `/deep-research` 等工作流时：

1. **自动检测触发** — 识别 `ultracode`、`/deep-research`、自然语言等所有触发方式
2. **预压缩上下文** — 工作流脚本生成前压缩，所有子 agent 继承压缩上下文
3. **专属预设** — 5 种工作流预设（moderate / aggressive / codeAudit / migration / refactor）
4. **ROI 回测** — 利用工作流脚本的确定性（可重跑）精确测量节省效果

```bash
# 记录一次工作流运行
node helpers/workflow-integrator.cjs track audit-api 320000

# 查看 ROI 报告
node helpers/workflow-integrator.cjs roi
```

---

## 模型路由（DeepSeek）

| 任务类型 | 模型 | 输入价格 | KV Cache 命中 |
|----------|------|---------|--------------|
| 架构/设计/规划 | deepseek-v4-pro | ¥3.0/MTok | ¥0.025/MTok (120x) |
| 编码/测试/修复 | deepseek-v4-flash | ¥1.0/MTok | ¥0.02/MTok |

自动路由：含「架构/设计/规划」→ Pro；含「写代码/实现/修复」→ Flash。

---

## 系统要求

- Node.js ≥ 18
- lean-ctx（`npm install -g lean-ctx-bin`，安装脚本自动处理）
- DeepSeek API 访问
- Claude Code v2.1.154+（Dynamic Workflows 支持）或 Qoder

---

## FAQ

**Q: 会影响代码质量吗？**
不会。所有压缩在输出侧和上下文侧进行，AI 推理能力不受限。

**Q: 两个平台怎么共用？**
核心引擎通过 `__dirname` 自定位，同一份代码两边各合并对应的 settings 即可。

**Q: 如何卸载？**
删除 `ultra-cost-effective/` 目录，移除 settings 中相关配置，重启平台。

**Q: 支持其他模型吗？**
当前路由仅 DeepSeek（利用 120x KV Cache 差价杠杆）。扩展需修改 `adapters/` 路由规则。

**Q: 原文被压缩了还能找回来吗？**
能。session-memory 索引保留了所有原文，通过 `retrieve <id>` 可随时取回。

---

## License

MIT
