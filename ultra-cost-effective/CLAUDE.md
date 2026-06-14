# UltraCostEffective · 极致节能 — Claude Code 项目引导

## 项目概述

UltraCostEffective（省工）是一个 **Claude Code / Qoder 双平台通用** 的 Token 节省技能体系。以 `1234567KF/ccmvp` 的七层节能架构为核心，融合 Headroom、lean-ctx、RTK 等国际高星项目能力。核心目标：**不降低 LLM 输出质量，综合节省 60-90% Token**。

## 目录结构

```
ultra-cost-effective/
├── SKILL.md                  ← 主技能入口（触发词：ultra-cost-effective / 节能 / 省token）
├── CLAUDE.md                 ← 本文件：项目引导
├── README.md                 ← 用户安装使用文档
├── adapters/                 ← 平台适配层
│   ├── qoder/                ← Qoder 专用适配器
│   │   ├── SKILL.md
│   │   ├── hook-adapter.cjs  ← Qoder Hook 适配器
│   │   └── settings.patch.json
│   └── claude/               ← Claude Code 适配
│       └── settings.template.json
├── rules/                    ← 规则层（always_on 自动注入）
│   ├── shared-prefix.md      ← L2: 共享前缀
│   ├── cache-optimization.md ← L2+L3: KV Cache策略
│   ├── lean-ctx.md           ← L1: 上下文压缩规则
│   ├── compression-default.md← L1: 压缩默认开启
│   └── interceptor-aop.md    ← AOP: 上下文拦截规则（三色灯 + Agent Spawn Guard）
├── helpers/                  ← 可执行脚本（纯Node.js，零外部依赖）
│   ├── tokenforge.cjs        ← L1: Token压缩引擎核心
│   ├── tokenforge-hook.cjs   ← L1: PreToolUse自动注入钩子
│   ├── context-interceptor.cjs← AOP: 上下文拦截器（三色灯+Agent Spawn Guard）
│   ├── skill-loader.cjs      ← L4: 技能按需加载
│   ├── cache-monitor.cjs     ← L2: KV Cache命中率监控
│   ├── prefix-validator.cjs  ← L2: 共享前缀一致性校验
│   └── perf/                 ← 性能追踪子系统
│       ├── perf-tracker.cjs
│       ├── pricing.json
│       └── optimization-registry.json
├── skills/                   ← 子技能
│   ├── ultra-cost-effective-output/         ← L1: 输出压缩
│   ├── ultra-cost-effective-cache/          ← L2+L3: KV Cache优化
│   ├── ultra-cost-effective-router/         ← L7: DeepSeek双模型路由
│   └── ultra-cost-effective-monitor/        ← L0: 成本监控
├── presets/                  ← 预设配置
│   ├── quick.json            ← 快速启动（仅L1）
│   ├── standard.json         ← 标准配置（L1+L2+L3）
│   └── extreme.json          ← 极致配置（全7层+Headroom可选）
└── bench/                    ← 基准测试
```

## 七层节能架构

| 层级 | 名称 | 机制 | 节省比例 |
|------|------|------|----------|
| L7 | 模型智能路由 | DeepSeek Pro↔Flash 按需切换 | 40-60% 成本 |
| L6 | A2A通信压缩 | Agent间 ~3x 压缩消息 | 60-70% |
| L5 | 阶段智能跳过 | CCP Skip 跳过低价值阶段 | 30-50% |
| L4 | 技能按需加载 | 非活跃技能 → ~25 token stub | 85-96% |
| L3 | 长上下文预热 | PRD/Spec 触发 KV Cache Checkpoint | 80-90% |
| L2 | 共享前缀缓存 | 200-500 token 固定前缀 | 120x 差价杠杆 |
| L1 | 输出+上下文压缩 | tokenforge + lean-ctx | 80-99% |

## 快速开始

```bash
# 安装
./install.ps1   # Windows
./install.sh    # macOS/Linux

# 验证
node helpers/prefix-validator.cjs --check-all

# 使用
# 在 Claude Code 或 Qoder 中，ultra-cost-effective 自动激活（always-on: true）
# 手动触发：说出「token report」「节能」「ultra-cost-effective status」
```

## 关键设计决策

1. **模型范围**：仅 DeepSeek-v4-pro + DeepSeek-v4-flash
2. **Qoder 适配**：专用适配器（`adapters/qoder/`），非仅 MCP 通用
3. **Headroom**：`extreme.json` 预设的可选增强，需手动安装
4. **lean-ctx**：跟随最新稳定版，规则层向后兼容

## 集成方式

### 核心引擎（平台无关）
所有 `helpers/` 下的脚本使用 `__dirname` 自定位，不依赖 `.claude/` 或 `.qoder/` 路径前缀。
同一份代码可直接用于任一平台。

### Claude Code
- 使用 `adapters/claude/settings.template.json` 配置 Hook 和权限
- PreToolUse Hook → `tokenforge-hook.cjs` 自动管道注入
- Context Interceptor → `context-interceptor.cjs` 三色灯 + Agent Spawn Guard
- PostToolUse Hook → `perf-tracker.cjs` 事件捕获
- MCP Server → `lean-ctx` 上下文压缩

### Qoder
- 使用 `adapters/qoder/settings.patch.json` 合并到 Qoder settings
- Hook Adapter → `hook-adapter.cjs` 自动适配平台差异
- AOP Rule → `interceptor-aop.md` 系统提示注入（三色灯拦截）
- 模型列表：仅暴露 deepseek-v4-pro / deepseek-v4-flash

### 即拷即用
```
任何项目:  cp -r ultra-cost-effective/ /path/to/project/
Claude Code: 合并 adapters/claude/settings.template.json
Qoder:       合并 adapters/qoder/settings.patch.json
完成。无需修改任何核心脚本路径。
```
