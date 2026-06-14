# Seiko · 极致节能

> **省工** — Claude Code / Qoder 双平台通用 Token 节省技能包。核心引擎纯 Node.js、零路径依赖，同一套代码即拷即用。综合节省 **60-90%** Token，不降低 LLM 输出质量。

---

## 快速开始（30 秒）

```bash
# 1. 复制到任意项目根目录
cp -r seiko/ /path/to/your-project/

# 2. 安装 lean-ctx（MCP 上下文压缩工具）
npm install -g lean-ctx-bin
lean-ctx init
```

然后根据你的平台合并 settings：

- **Claude Code** → 将 `adapters/claude/settings.template.json` 内容复制到项目的 `settings.json`
- **Qoder** → 将 `adapters/qoder/settings.patch.json` 中的字段合并到 Qoder 的 `settings.json`

重启平台即可，Seiko 会全自动运行。

---

## 目录结构

```
seiko/
├── helpers/           ← 核心引擎（平台无关，__dirname 自定位）
│   ├── tokenforge.cjs          L1 输出压缩引擎（4模/3级）
│   ├── tokenforge-hook.cjs     自动管道注入 Hook
│   ├── skill-loader.cjs        L4 技能按需加载
│   ├── cache-monitor.cjs       L2 KV Cache 命中监控
│   ├── prefix-validator.cjs    前缀一致性验证
│   └── perf/
│       ├── perf-tracker.cjs    全链路 Token 追踪
│       ├── pricing.json        DeepSeek 双模型价格表
│       └── optimization-registry.json  优化机制注册表
├── adapters/
│   ├── claude/
│   │   └── settings.template.json   Claude Code 配置模板
│   └── qoder/
│       ├── settings.patch.json      Qoder 配置补丁
│       ├── hook-adapter.cjs         Qoder Hook 适配器
│       └── SKILL.md                 Qoder Skill 声明
├── rules/             ← 通用规则（双平台自动加载）
│   ├── shared-prefix.md        L2 共享前缀规范
│   ├── cache-optimization.md   KV Cache 优化指导
│   ├── lean-ctx.md             L3 上下文压缩规范
│   └── compression-default.md  L1 输出压缩规范
├── skills/            ← 子技能定义
│   ├── seiko-output/           L1 输出+上下文压缩
│   ├── seiko-cache/            L2+L3 KV Cache 优化
│   ├── seiko-router/           L7 模型路由
│   └── seiko-monitor/          L0 全链路监控
├── presets/           ← 三层节能预设
│   ├── quick.json              仅 L1（50-70% 节省）
│   ├── standard.json           L1+L2+L3（70-85% 节省，默认推荐）
│   └── extreme.json            全七层（85-95% 节省）
├── bench/             ← 基准测试工具
├── install.ps1         Windows 一键安装
├── install.sh          macOS/Linux 一键安装
├── SKILL.md            Skill 入口声明
└── README.md           本文件
```

---

## 使用方法

### 自动模式（默认）

安装后 Seiko 全自动运行，无需干预：

- 所有 Shell 命令输出 → tokenforge 自动压缩再传给 LLM
- 文件读取 → lean-ctx MCP 自动缓存压缩
- 模型选择 → 根据任务类型自动路由 DeepSeek Pro / Flash
- 成本追踪 → perf-tracker 持续运行，按会话汇总

### 命令模式（可选）

在对话中说出以下关键词触发：

| 说出 | 效果 |
|------|------|
| `token report` / `成本报告` | 显示当前会话 Token 消耗详情 |
| `节能` / `省token` | 切换预设：quick → standard → extreme 循环 |
| `seiko status` | 显示各层运行状态、缓存命中率、预计节省 |
| `seiko off` | 临时暂停节能（调试用） |
| `seiko on` | 恢复节能 |

### 预设切换（脚本直接调用）

```bash
node helpers/preset-switch.cjs quick     # 仅 L1 输出压缩，最轻量
node helpers/preset-switch.cjs standard  # L1+L2+L3，默认推荐
node helpers/preset-switch.cjs extreme   # 全七层，极致效果
```

### 压缩级别说明

| 级别 | 效果 | 适用场景 |
|------|------|----------|
| light | 轻量压缩，保持可读性 | 调试、explore |
| medium | 中度压缩，去除冗余 | 日常开发（默认） |
| aggressive | 激进压缩，只保留关键信息 | CI/CD、大量输出 |

压缩仅发生在输出侧和上下文侧，不影响 LLM 推理质量。

---

## 三层预设对比

| 预设 | 启用层级 | 预计 Token 节省 | 适用场景 |
|------|----------|----------------|----------|
| **quick** | L1 | 50-70% | 日常编码，轻量项目 |
| **standard** ⭐ | L1+L2+L3 | 70-85% | 标准项目开发 |
| **extreme** | 全七层 | 85-95% | 大型项目，长会话 |

---

## 模型路由（仅 DeepSeek）

| 任务类型 | 使用模型 | 输入价格 | KV Cache 命中 |
|----------|----------|---------|--------------|
| 架构/设计/规划/分析 | deepseek-v4-pro | ¥3.0/MTok | ¥0.025/MTok (120x) |
| 编码/测试/修复/文档 | deepseek-v4-flash | ¥1.0/MTok | ¥0.02/MTok |

路由规则：含「架构/设计/规划」→ Pro；含「写代码/实现/修复」→ Flash；上下文字段过多 → 降级 Flash。

---

## 验证

```bash
# 验证核心引擎
node helpers/prefix-validator.cjs --check-all

# 运行基准测试
node bench/bench-runner.cjs

# 测试 tokenforge 压缩
node helpers/tokenforge.cjs --test
```

---

## 系统要求

- Node.js ≥ 18
- lean-ctx（`npm install -g lean-ctx-bin`）
- DeepSeek API 访问

---

## 常见问题

**Q: 会影响代码质量吗？**
不会。所有压缩在输出侧和上下文侧进行，不影响 LLM 推理质量。

**Q: 两个平台怎么共用？**
核心引擎通过 `__dirname` 自动定位，无需修改任何路径。同一份 `seiko/` 目录，两边各自合并对应的 settings 即可。

**Q: 如何卸载？**
删除 `seiko/` 目录，移除 settings 中 seiko 相关配置，重启平台。

**Q: 支持其他模型吗？**
当前路由仅限 DeepSeek（充分利用 120x KV Cache 差价杠杆）。如需扩展，修改 `adapters/` 中的路由规则。
