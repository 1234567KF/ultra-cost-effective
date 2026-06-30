# UltraCostEffective · 极致节能

一个轻量、高效的 Token 节省体系，支持 Claude Code 和 Qoder 双平台，**综合节省 60-90% Token，不降低 LLM 输出质量**。

---

## Quick Start (AI-Native 自动安装)

> **本文档专为 AI 助手设计**。AI 请严格按照以下步骤完成安装和配置。

---

### 1. 下载引擎到项目根目录（必需）

将 ultra-cost-effective 完整仓库下载到**当前项目根目录**下（这是确保 hooks 路径 `node ultra-cost-effective/helpers/...` 能正常工作的前提）：

#### macOS / Linux / Git Bash / WSL

```bash
cd <项目根目录>
npx giget github:1234567KF/ultra-cost-effective ultra-cost-effective --force
```

#### Windows (PowerShell)

```powershell
cd <项目根目录>
npx giget github:1234567KF/ultra-cost-effective ultra-cost-effective --force
```

#### Windows (CMD)

```cmd
cd <项目根目录>
npx giget github:1234567KF/ultra-cost-effective ultra-cost-effective --force
```

> 💡 若 `npx giget` 不可用，备选：`git clone https://github.com/1234567KF/ultra-cost-effective.git`

---

### 2. 安装技能到平台目录（Qoder 必需 / Claude Code 可选）

#### macOS / Linux / Git Bash / WSL

* **Qoder（必需）：**
  ```bash
  cp -r ultra-cost-effective/skills/ultra-cost-effective ~/.qoder/skills/ultra-cost-effective
  cp -r ultra-cost-effective/skills/ultra-cost-effective-output ~/.qoder/skills/ultra-cost-effective-output
  cp -r ultra-cost-effective/skills/ultra-cost-effective-cache ~/.qoder/skills/ultra-cost-effective-cache
  cp -r ultra-cost-effective/skills/ultra-cost-effective-router ~/.qoder/skills/ultra-cost-effective-router
  cp -r ultra-cost-effective/skills/ultra-cost-effective-monitor ~/.qoder/skills/ultra-cost-effective-monitor
  ```
* **Claude Code（可选）：**
  ```bash
  cp -r ultra-cost-effective/skills/ultra-cost-effective ~/.claude/skills/ultra-cost-effective
  ```

#### Windows (PowerShell)

* **Qoder（必需）：**
  ```powershell
  Copy-Item -Recurse ultra-cost-effective/skills/ultra-cost-effective "$HOME\.qoder\skills\ultra-cost-effective" -Force
  Copy-Item -Recurse ultra-cost-effective/skills/ultra-cost-effective-output "$HOME\.qoder\skills\ultra-cost-effective-output" -Force
  Copy-Item -Recurse ultra-cost-effective/skills/ultra-cost-effective-cache "$HOME\.qoder\skills\ultra-cost-effective-cache" -Force
  Copy-Item -Recurse ultra-cost-effective/skills/ultra-cost-effective-router "$HOME\.qoder\skills\ultra-cost-effective-router" -Force
  Copy-Item -Recurse ultra-cost-effective/skills/ultra-cost-effective-monitor "$HOME\.qoder\skills\ultra-cost-effective-monitor" -Force
  ```
* **Claude Code（可选）：**
  ```powershell
  Copy-Item -Recurse ultra-cost-effective/skills/ultra-cost-effective "$HOME\.claude\skills\ultra-cost-effective" -Force
  ```

#### Windows (CMD)

* **Qoder（必需）：**
  ```cmd
  xcopy /E /I /Y ultra-cost-effective\skills\ultra-cost-effective "%USERPROFILE%\.qoder\skills\ultra-cost-effective"
  xcopy /E /I /Y ultra-cost-effective\skills\ultra-cost-effective-output "%USERPROFILE%\.qoder\skills\ultra-cost-effective-output"
  xcopy /E /I /Y ultra-cost-effective\skills\ultra-cost-effective-cache "%USERPROFILE%\.qoder\skills\ultra-cost-effective-cache"
  xcopy /E /I /Y ultra-cost-effective\skills\ultra-cost-effective-router "%USERPROFILE%\.qoder\skills\ultra-cost-effective-router"
  xcopy /E /I /Y ultra-cost-effective\skills\ultra-cost-effective-monitor "%USERPROFILE%\.qoder\skills\ultra-cost-effective-monitor"
  ```
* **Claude Code（可选）：**
  ```cmd
  xcopy /E /I /Y ultra-cost-effective\skills\ultra-cost-effective "%USERPROFILE%\.claude\skills\ultra-cost-effective"
  ```

---

### 3. AI 自动配置（在项目目录执行）

检测当前平台后，执行以下配置：

#### 3a. 配置 settings.json

**Claude Code** — 合并 `adapters/claude/settings.template.json` 到 `.claude/settings.json`：

```bash
# 如果 settings.json 不存在，直接复制模板
if [ ! -f .claude/settings.json ]; then
  mkdir -p .claude
  cp ultra-cost-effective/adapters/claude/settings.template.json .claude/settings.json
fi
# 如果已存在，AI 需手动合并 hooks、permissions、mcpServers、env 段落
```

**Qoder** — 合并 `adapters/qoder/settings.patch.json` 到 Qoder 的 settings.json：
- Qoder 的 settings.json 位置需根据实际情况确定
- 将 patch 中的 `models`、`rules`、`skills`、`mcpServers`、`hooks`、`environment` 合并

#### 3b. 导入规则到 CLAUDE.md

在项目根目录的 `CLAUDE.md` 中添加一行（如文件不存在则创建）：

```markdown
@ultra-cost-effective/rules/main.md
```

#### 3c. 安装可选依赖

```bash
npm install -g lean-ctx-bin && lean-ctx init
```

#### 3d. 添加 .gitignore

确保项目 `.gitignore` 包含：

```
# UltraCostEffective
.ultra-cost-effective-tracker.json
```

---

### 4. 验证安装

```bash
# 检查引擎目录（在项目根目录下）
ls ultra-cost-effective/helpers/

# 检查配置文件
cat .claude/settings.json | grep -i "ultra-cost-effective"
cat CLAUDE.md | grep -i "ultra-cost-effective"

# 运行冒烟测试
node ultra-cost-effective/helpers/tokenforge-hook.cjs --test
```

---

### 5. 重启生效

**必须重启 Claude Code 或 Qoder**，hooks 和 rules 才会加载。

---

## 通过 AI 对话触发安装

用户只需在项目中发送以下指令，AI 自动完成全部步骤：

- `安装 UltraCostEffective`
- `启用节能模式`
- `install ultra-cost-effective`
- `配置 token 节省`

---

## 自动生效机制

安装后以下功能自动激活，无需手动操作：

| 触发 | 自动行为 |
|------|---------|
| 任何 `npm test`、`cargo build` 等命令 | PreToolUse Hook 自动追加 `\| node tokenforge.cjs compress` |
| 任何工具调用后 | PostToolUse Hook 追踪 token 消耗 + 评估上下文健康 |
| 上下文超 60% 窗口 | PostToolUse 注入提示 LLM 压缩 |
| `ctx_read` / `ctx_shell` 等 MCP 工具 | lean-ctx 自动缓存压缩，重读仅 ~13 tokens |
| 检测到第三方压缩器 | 自动跳过，避免双重压缩 |

---

## 日常使用

| 关键词 | 效果 |
|--------|------|
| `token report` / `成本报告` | 查看 Token 消耗与节省明细 |
| `节能` / `省token` | 切换预设（quick → standard → extreme） |
| `ultra-cost-effective status` | 查看各层运行状态、缓存命中率 |
| `ultra-cost-effective off` | 临时关闭节能（调试用） |
| `ultra-cost-effective on` | 恢复节能 |

---

## 三层预设

| 预设 | 启用层 | 节省 | 说明 |
|------|--------|------|------|
| `quick` | L1 | 50-70% | 仅输出压缩，日常快速编码 |
| `standard` ⭐ | L1+L2+L3 | 70-85% | 输出压缩 + KV Cache + 上下文压缩（推荐） |
| `extreme` | 全七层 | 85-95% | 大型项目、长会话、极致省钱 |

---

## 项目结构

```
<项目根目录>/
├── ultra-cost-effective/          ← 引擎（下载到这里）
│   ├── adapters/
│   ├── helpers/                   ← 核心脚本
│   ├── rules/                     ← 规则文件
│   └── skills/                    ← 技能目录
├── .claude/settings.json          ← 配置合并后
├── CLAUDE.md                      ← 含 @ultra-cost-effective/rules/main.md
└── .gitignore                     ← 含 tracker 排除
```

---

## 故障排除

### 问题：`node ultra-cost-effective/helpers/...` 找不到文件

```bash
# 确认 ultra-cost-effective 在项目根目录下
ls ultra-cost-effective/helpers/
# 如果不存在，重新执行第 1 步
```

### 问题：Qoder 不识别技能

```bash
# 确认技能已复制到 Qoder 目录
ls ~/.qoder/skills/ultra-cost-effective/
# 如果不存在，执行第 2 步
```

### 问题：Hooks 未生效

```bash
# 检查配置
cat .claude/settings.json | jq '.hooks'
# 确认后重启 Claude Code / Qoder
```

---

## 卸载

```bash
# 1. 删除项目中的引擎目录
rm -rf ultra-cost-effective/

# 2. 删除平台技能目录
rm -rf ~/.qoder/skills/ultra-cost-effective*
rm -rf ~/.claude/skills/ultra-cost-effective*

# 3. 移除 CLAUDE.md 中的规则引用

# 4. 移除 .claude/settings.json 中的相关配置

# 5. 重启 Claude Code / Qoder
```

---

## 更多信息

- **项目仓库**：https://github.com/1234567KF/ultra-cost-effective
- **详细文档**：`ultra-cost-effective/README.md`
- **技术规格**：`ultra-cost-effective/TOKEN-MONITOR-SPEC.md`

---

**安装完成后，重启 Claude Code / Qoder 即可自动生效。**
# UltraCostEffective · 极致节能

一个轻量、高效的 Token 节省体系，支持 Claude Code 和 Qoder 双平台，**综合节省 60-90% Token，不降低 LLM 输出质量**。

---

## Quick Start (AI-Native 自动安装)

本项目支持通过 **AI 技能 (Agent Skill)** 一键安装到您的 AI 助手配置目录中。无论是 Claude Code 还是 Qoder，都支持自动配置和即时生效。

### 1. 安装/更新 AI 技能

您可以通过 `npx giget` 命令，免去克隆整个仓库的开销，直接将技能下载并安装到对应 AI Agent 的全局配置目录中：

#### macOS / Linux / Git Bash / WSL (使用 `~`)

* **Qoder：**
  ```bash
  npx giget github:1234567KF/ultra-cost-effective/skills/ultra-cost-effective ~/.qoder/skills/ultra-cost-effective --force
  ```
* **Claude Code：**
  ```bash
  npx giget github:1234567KF/ultra-cost-effective/skills/ultra-cost-effective ~/.claude/skills/ultra-cost-effective --force
  ```

#### Windows (PowerShell)

* **Qoder：**
  ```powershell
  npx giget github:1234567KF/ultra-cost-effective/skills/ultra-cost-effective "$HOME\.qoder\skills\ultra-cost-effective" --force
  ```
* **Claude Code：**
  ```powershell
  npx giget github:1234567KF/ultra-cost-effective/skills/ultra-cost-effective "$HOME\.claude\skills\ultra-cost-effective" --force
  ```

#### Windows (CMD - 命令提示符)

* **Qoder：**
  ```cmd
  npx giget github:1234567KF/ultra-cost-effective/skills/ultra-cost-effective "%USERPROFILE%\.qoder\skills\ultra-cost-effective" --force
  ```
* **Claude Code：**
  ```cmd
  npx giget github:1234567KF/ultra-cost-effective/skills/ultra-cost-effective "%USERPROFILE%\.claude\skills\ultra-cost-effective" --force
  ```

> 💡 **提示**：若技能后续有更新，只需重新运行上述对应助手的命令即可完成覆盖升级。

---

### 2. 通过 AI 一键配置

在项目目录中开启与 AI 助手的对话，发送以下任意指令激活技能：

- `安装 UltraCostEffective`
- `启用节能模式`
- `install ultra-cost-effective`
- `enable token saving`

AI 助手将自动完成以下配置：
1. 检测当前平台（Claude Code / Qoder）
2. 配置 settings.json（hooks、permissions、mcpServers）
3. 导入规则到 CLAUDE.md
4. 安装可选依赖（lean-ctx）
5. 验证安装结果

---

### 3. 验证安装

安装完成后，AI 助手会自动验证配置。您也可以手动检查：

```bash
# 检查技能目录
ls -la ~/.qoder/skills/ultra-cost-effective/  # Qoder
ls -la ~/.claude/skills/ultra-cost-effective/  # Claude Code

# 检查配置文件
cat .claude/settings.json | grep -i "ultra-cost-effective"
cat CLAUDE.md | grep -i "ultra-cost-effective"

# 运行测试
node ultra-cost-effective/bench/test-workflow.cjs
```

---

## 自动生效机制

安装后以下功能自动激活，无需手动操作：

| 触发 | 自动行为 |
|------|---------|
| 任何 `npm test`、`cargo build` 等命令 | PreToolUse Hook 自动追加 `\| node tokenforge.cjs compress` |
| 任何工具调用后 | PostToolUse Hook 追踪 token 消耗 + 评估上下文健康 |
| 上下文超 60% 窗口 | PostToolUse 注入 `additionalContext` 提示 LLM 压缩 |
| `ctx_read` / `ctx_shell` 等 MCP 工具 | lean-ctx 自动缓存压缩，重读仅 ~13 tokens |
| 检测到第三方压缩器 | 自动跳过，避免双重压缩，记录冲突日志 |

---

## 日常使用

### 手动命令

| 关键词 | 效果 |
|--------|------|
| `token report` / `成本报告` | 查看 Token 消耗与节省明细 |
| `节能` / `省token` | 切换预设（quick → standard → extreme 循环） |
| `ultra-cost-effective status` | 查看各层运行状态、缓存命中率 |
| `ultra-cost-effective off` | 临时关闭节能（调试用） |
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
- 脚本直接调用：`node ultra-cost-effective/helpers/preset-switch.cjs standard`

---

## 项目结构

```
ultra-cost-effective/
├── adapters/
│   ├── claude/
│   │   └── settings.template.json    # Claude Code 配置模板
│   └── qoder/
│       ├── settings.patch.json       # Qoder 配置补丁
│       └── hook-adapter.cjs          # Qoder Hook 适配器
├── helpers/
│   ├── tokenforge.cjs                # 输出压缩引擎
│   ├── tokenforge-hook.cjs           # Hook 管道注入
│   ├── context-interceptor.cjs       # 上下文监控
│   ├── model-router.cjs              # 模型路由
│   ├── perf/
│   │   ├── perf-tracker.cjs          # Token 追踪
│   │   └── pricing.json              # DeepSeek 定价
│   └── ...                           # 其他辅助脚本
├── rules/
│   ├── main.md                       # 主规则集
│   └── ...                           # 其他规则文件
├── skills/
│   ├── ultra-cost-effective-output/  # L1: 输出压缩
│   ├── ultra-cost-effective-cache/   # L2+L3: KV Cache
│   ├── ultra-cost-effective-router/  # L7: 模型路由
│   └── ultra-cost-effective-monitor/ # L0: 成本监控
├── SKILL.md                          # 技能定义
└── AI-INSTALL.md                     # 本文档
```

---

## 故障排除

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

## 更多信息

- **项目仓库**：https://github.com/1234567KF/ultra-cost-effective
- **详细文档**：`ultra-cost-effective/README.md`
- **技术规格**：`ultra-cost-effective/TOKEN-MONITOR-SPEC.md`

---

## 卸载

```bash
# 1. 删除技能目录
rm -rf ~/.qoder/skills/ultra-cost-effective/  # Qoder
rm -rf ~/.claude/skills/ultra-cost-effective/  # Claude Code

# 2. 移除配置（手动编辑 .claude/settings.json）

# 3. 移除规则引用（手动编辑 CLAUDE.md）

# 4. 重启 Claude Code / Qoder
```

---

**安装完成后，重启 Claude Code / Qoder 即可自动生效。**
