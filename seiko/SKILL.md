---
name: seiko
description: 极致节能 — 不降低LLM输出质量的Token节省体系，综合节省60-90%。基于ccmvp七层节能架构+Headroom/lean-ctx/RTK国际方案。Claude Code & Qoder双平台通用。
version: 1.0.0
triggers: seiko, 节能, 省token, 节省, token report, 成本报告, 极致节能, token报告
role: infrastructure
scope: global
always-on: true
platforms: [claude-code, qoder]
dependencies:
  skills:
    - seiko-output    # L1: 输出压缩
    - seiko-cache     # L2+L3: KV Cache优化
    - seiko-router    # L7: DeepSeek双模型路由
    - seiko-monitor   # L0: 成本监控
  mcp:
    - lean-ctx        # L1: 上下文压缩（MCP工具）
---

# Seiko · 极致节能

> **省工** — AI编程Token节省体系。七层架构，不降低质量，综合节省 **60-90%** Token。

## 核心理念

```
    ┌── AOP Context Interceptor ──────────────────────┐
    │  三色灯监控 + Agent Spawn Guard + 规则注入       │
    │  确保每次 LLM 调用前上下文已被压缩              │
    └──────────────────────┬──────────────────────────┘
         │  L7  模型智能路由        │  DeepSeek Pro↔Flash 按需切换
         │  L6  A2A通信压缩         │  Agent间 ~3x 压缩消息
         │  L5  阶段智能跳过        │  变更小跳过不必要阶段
         │  L4  技能按需加载        │  非活跃技能 → ~25 token stub
         │────────────────────────┬──────────────────────────
         │  L3  长上下文预热        │  PRD/Spec 触发 KV Cache checkpoint
         │  L2  共享前缀缓存        │  200-500 token 固定前缀，命中率 >90%
         │  L1  输出+上下文压缩     │  tokenforge + lean-ctx，压缩比 80-99%
         └────────────────────────┴──────────────────────────
```

## 双平台架构

```
┌──────────────────────────────────────────────────────┐
│              seiko 核心引擎（平台无关）                │
│  tokenforge · skill-loader · cache-monitor · router  │
│         纯 Node.js，__dirname 自定位，零平台依赖       │
├────────────────────┬─────────────────────────────────┤
│   Claude Code      │        Qoder                    │
│   settings.json    │   settings.patch.json           │
│   PreToolUse Hook  │   hook-adapter.cjs              │
│   MCP lean-ctx     │   模型列表锁 DeepSeek            │
│                    │                                 │
│  ⇧ 配置模板在       │  ⇧ 适配器在                     │
│  adapters/claude/  │  adapters/qoder/                │
└────────────────────┴─────────────────────────────────┘
```

> **核心引擎零平台依赖**：所有 helper 脚本使用 `__dirname` 自定位，无需 `.claude/` 或 `.qoder/` 前缀。同一套代码，两个平台即拷即用。

## 快速命令

| 命令 | 说明 |
|------|------|
| `token report` / `成本报告` | 查看本次会话Token消耗与节省统计 |
| `节能` / `省token` | 开启/切换节能预设（quick/standard/extreme） |
| `seiko status` | 查看各层运行状态与缓存命中率 |

## 三层预设

| 预设 | 层级 | 预计节省 | 适用场景 |
|------|------|----------|----------|
| `quick` | L1 (tokenforge + lean-ctx) | ~50-70% | 日常编码，快速启动 |
| `standard` | L1+L2+L3 (含KV Cache) | ~70-85% | 标准项目开发，推荐 |
| `extreme` | 全7层 + Headroom可选 | ~85-95% | 大型项目/长会话，极致节省 |

## 安装

```bash
# 方式一：一键安装（推荐）
./install.sh        # macOS/Linux
.\install.ps1       # Windows PowerShell

# 方式二：即拷即用（零配置）
# 将 seiko/ 目录复制到项目根目录即可
# 核心引擎自动通过 __dirname 定位，无需配置路径
# 仅需根据平台选择 settings 模板：
#   Claude Code → adapters/claude/settings.template.json
#   Qoder       → adapters/qoder/settings.patch.json
```

## 子技能清单

| 技能 | 文件 | 层级 | 职责 |
|------|------|------|------|
| seiko-interceptor | `helpers/context-interceptor.cjs` | AOP | 上下文拦截器，三色灯监控，Agent Spawn Guard |
| seiko-output | `skills/seiko-output/` | L1 | tokenforge输出压缩，4模压缩引擎 |
| seiko-cache | `skills/seiko-cache/` | L2+L3 | KV Cache优化，共享前缀，缓存监控 |
| seiko-router | `skills/seiko-router/` | L7 | DeepSeek Pro↔Flash智能路由 |
| seiko-monitor | `skills/seiko-monitor/` | L0 | Token追踪，成本可视化，收益归因 |

## 技术溯源

- **ccmvp (1234567KF)**：七层节能架构、tokenforge、lean-ctx、skill-loader
- **Headroom (8.5k★)**：CCR可逆压缩、AST感知代码压缩、跨Agent记忆
- **LLMLingua (5k★)**：Microsoft Prompt压缩，BERT级token分类
- **lean-ctx (360★)**：MCP上下文工程，71工具，10种读取模式
- **RTK**：Rust单二进制CLI压缩，零依赖60-90%压缩
