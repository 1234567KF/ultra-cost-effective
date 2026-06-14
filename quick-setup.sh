#!/usr/bin/env bash
# ============================================================
#  UltraCostEffective · 极致节能 — 一键接入脚本 (macOS/Linux)
#
#  用法:
#    ./quick-setup.sh /path/to/your-project
#    ./quick-setup.sh /path/to/your-project --platform claude
#    ./quick-setup.sh /path/to/your-project --platform qoder
#    ./quick-setup.sh /path/to/your-project --preset extreme
#    ./quick-setup.sh /path/to/your-project --skip-lean-ctx
#    ./quick-setup.sh /path/to/your-project --force
#
#  自动完成:
#    [1/5] 检测环境 (Node.js)
#    [2/5] 复制 ultra-cost-effective/ 引擎到目标项目
#    [3/5] 安装 lean-ctx MCP 工具
#    [4/5] 合并 settings 配置 (自动检测 Claude Code / Qoder)
#    [5/5] 验证安装
# ============================================================

set -e

# ─── 参数解析 ──────────────────────────────────

TARGET=""
PLATFORM="auto"
PRESET="standard"
SKIP_LEAN_CTX=false
SKIP_VERIFY=false
FORCE=false

for arg in "$@"; do
  case $arg in
    --platform=*) PLATFORM="${arg#*=}" ;;
    --platform) shift; PLATFORM="$1" ;;
    --preset=*) PRESET="${arg#*=}" ;;
    --preset) shift; PRESET="$1" ;;
    --skip-lean-ctx) SKIP_LEAN_CTX=true ;;
    --skip-verify) SKIP_VERIFY=true ;;
    --force) FORCE=true ;;
    -h|--help)
      echo "用法: ./quick-setup.sh <目标项目路径> [选项]"
      echo ""
      echo "选项:"
      echo "  --platform=claude|qoder|auto  指定平台 (默认: auto)"
      echo "  --preset=quick|standard|extreme  节能预设 (默认: standard)"
      echo "  --skip-lean-ctx               跳过 lean-ctx 安装"
      echo "  --skip-verify                 跳过验证"
      echo "  --force                       强制覆盖已有安装"
      exit 0
      ;;
    -*)
      echo "未知选项: $arg"
      exit 1
      ;;
    *)
      if [ -z "$TARGET" ]; then
        TARGET="$arg"
      fi
      ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "错误: 请指定目标项目路径"
  echo "用法: ./quick-setup.sh /path/to/your-project"
  exit 1
fi

# ─── 工具函数 ──────────────────────────────────

SCRIPT_ROOT="$(cd "$(dirname "$0")" && pwd)"
ENGINE_DIR="$SCRIPT_ROOT/ultra-cost-effective"
TARGET_ABS="$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

step() { echo -e "\n${YELLOW}[$1/5] $2${NC}" }
ok()   { echo -e "  ${GREEN}✓ $1${NC}" }
warn() { echo -e "  ${YELLOW}⚠ $1${NC}" }
fail() { echo -e "  ${RED}❌ $1${NC}" }
info() { echo -e "  ${GRAY}$1${NC}" }

# ─── Banner ────────────────────────────────────

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  UltraCostEffective · 极致节能           ║${NC}"
echo -e "${CYAN}║  一键接入脚本 (macOS/Linux)               ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  目标项目: $TARGET_ABS"
echo -e "  平台:     $PLATFORM"
echo -e "  预设:     $PRESET"

# ─── [1/5] 检测环境 ────────────────────────────

step 1 "检测环境..."

if ! command -v node &> /dev/null; then
  fail "Node.js 未安装"
  info "请先安装 Node.js ≥ 18: https://nodejs.org/"
  exit 1
fi
ok "Node.js $(node --version)"

if [ ! -d "$ENGINE_DIR" ]; then
  fail "引擎目录不存在: $ENGINE_DIR"
  info "请确保 quick-setup.sh 在仓库根目录执行"
  exit 1
fi
ok "引擎目录存在"

if [ ! -d "$TARGET_ABS" ]; then
  if [ "$FORCE" = true ]; then
    mkdir -p "$TARGET_ABS"
    ok "已创建目标目录: $TARGET_ABS"
  else
    fail "目标目录不存在: $TARGET_ABS"
    info "使用 --force 自动创建，或手动创建后重试"
    exit 1
  fi
else
  ok "目标目录存在"
fi

TARGET_ENGINE="$TARGET_ABS/ultra-cost-effective"
if [ -d "$TARGET_ENGINE" ] && [ "$FORCE" != true ]; then
  warn "目标项目已有 ultra-cost-effective/"
  info "使用 --force 覆盖更新"
  read -p "  覆盖? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "已取消"
    exit 0
  fi
fi

# ─── [2/5] 复制引擎 ────────────────────────────

step 2 "复制引擎到目标项目..."

mkdir -p "$TARGET_ENGINE"

# rsync 如果可用用 rsync（更快），否则用 cp
if command -v rsync &> /dev/null; then
  rsync -a --exclude='node_modules' --exclude='.git' "$ENGINE_DIR/" "$TARGET_ENGINE/"
  ok "引擎已同步到 $TARGET_ENGINE (rsync)"
else
  cp -R "$ENGINE_DIR/"* "$TARGET_ENGINE/" 2>/dev/null
  # 排除 node_modules 和 .git
  rm -rf "$TARGET_ENGINE/node_modules" "$TARGET_ENGINE/.git" 2>/dev/null
  ok "引擎已复制到 $TARGET_ENGINE"
fi

# ─── [3/5] 安装 lean-ctx ───────────────────────

step 3 "安装 lean-ctx MCP 工具..."

if [ "$SKIP_LEAN_CTX" = true ]; then
  warn "跳过 lean-ctx 安装 (--skip-lean-ctx)"
else
  if command -v lean-ctx &> /dev/null; then
    ok "lean-ctx 已安装"
  else
    info "正在安装 lean-ctx..."
    if npm install -g lean-ctx-bin 2>/dev/null; then
      ok "lean-ctx 安装成功"
    else
      warn "lean-ctx 安装失败，可稍后手动安装:"
      info "npm install -g lean-ctx-bin"
    fi
  fi
fi

# ─── [4/5] 合并 settings ──────────────────────

step 4 "合并 settings 配置..."

# 检测平台
if [ "$PLATFORM" = "auto" ]; then
  if [ -n "$QODER_SESSION_ID" ] || [ -n "$QODER_WORKSPACE" ]; then
    PLATFORM="qoder"
  elif [ -n "$CLAUDE_CODE_SESSION_ID" ] || command -v claude &> /dev/null; then
    PLATFORM="claude"
  elif [ -d "$TARGET_ABS/.claude" ]; then
    PLATFORM="claude"
  else
    PLATFORM="claude"
    warn "未检测到平台，默认 Claude Code"
  fi
fi
ok "平台: $PLATFORM"

if [ "$PLATFORM" = "claude" ]; then
  CLAUDE_DIR="$TARGET_ABS/.claude"
  mkdir -p "$CLAUDE_DIR"

  SETTINGS_FILE="$CLAUDE_DIR/settings.json"
  TEMPLATE_FILE="$TARGET_ENGINE/adapters/claude/settings.template.json"

  if [ -f "$SETTINGS_FILE" ]; then
    warn "已有 .claude/settings.json"
    info "请手动将以下内容合并到 $SETTINGS_FILE:"
    info "  来源: $TEMPLATE_FILE"

    # 尝试用 node 智能合并
    if command -v node &> /dev/null; then
      node -e "
        const fs = require('fs');
        const existing = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf-8'));
        const template = JSON.parse(fs.readFileSync('$TEMPLATE_FILE', 'utf-8'));

        // 合并 hooks
        if (template.hooks) {
          if (!existing.hooks) existing.hooks = {};
          for (const [type, hooks] of Object.entries(template.hooks)) {
            if (!existing.hooks[type]) existing.hooks[type] = [];
            existing.hooks[type].push(...hooks);
          }
        }

        // 合并 permissions
        if (template.permissions && template.permissions.allow) {
          if (!existing.permissions) existing.permissions = { allow: [] };
          if (!existing.permissions.allow) existing.permissions.allow = [];
          for (const p of template.permissions.allow) {
            if (!existing.permissions.allow.includes(p)) existing.permissions.allow.push(p);
          }
        }

        // 合并 mcpServers
        if (template.mcpServers) {
          if (!existing.mcpServers) existing.mcpServers = {};
          for (const [k, v] of Object.entries(template.mcpServers)) {
            if (!existing.mcpServers[k]) existing.mcpServers[k] = v;
          }
        }

        // 合并 environment
        if (template.environment) {
          if (!existing.environment) existing.environment = {};
          Object.assign(existing.environment, template.environment);
        }

        existing.environment = existing.environment || {};
        existing.environment.ULTRA_COST_EFFECTIVE_LEVEL = '$PRESET';

        fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(existing, null, 2), 'utf-8');
        console.log('merged');
      " 2>/dev/null && ok "settings.json 已智能合并" || warn "智能合并失败，请手动合并"
    fi
  else
    cp "$TEMPLATE_FILE" "$SETTINGS_FILE"
    # 更新预设
    if command -v node &> /dev/null; then
      node -e "
        const fs = require('fs');
        const s = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf-8'));
        s.environment = s.environment || {};
        s.environment.ULTRA_COST_EFFECTIVE_LEVEL = '$PRESET';
        fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(s, null, 2), 'utf-8');
      " 2>/dev/null
    fi
    ok ".claude/settings.json 已从模板创建"
  fi
  ok "预设: $PRESET"

else
  PATCH_FILE="$TARGET_ENGINE/adapters/qoder/settings.patch.json"
  ok "Qoder 配置补丁: $PATCH_FILE"
  info "请将此文件内容合并到 Qoder 的 settings.json 中"
fi

# ─── [5/5] 验证安装 ────────────────────────────

step 5 "验证安装..."

if [ "$SKIP_VERIFY" = true ]; then
  warn "跳过验证 (--skip-verify)"
else
  CORE_FILES=(
    "helpers/tokenforge.cjs"
    "helpers/context-interceptor.cjs"
    "helpers/workflow-integrator.cjs"
    "helpers/ultra-cost-effective-guard.cjs"
    "rules/interceptor-aop.md"
    "rules/workflow-compress.md"
  )

  for f in "${CORE_FILES[@]}"; do
    if [ -f "$TARGET_ENGINE/$f" ]; then
      ok "$f"
    else
      fail "缺失: $f"
    fi
  done

  VALIDATOR="$TARGET_ENGINE/helpers/prefix-validator.cjs"
  if [ -f "$VALIDATOR" ]; then
    if node "$VALIDATOR" --check-all >/dev/null 2>&1; then
      ok "prefix-validator 通过"
    else
      warn "prefix-validator 有警告 (非致命)"
    fi
  fi
fi

# ─── 完成 ──────────────────────────────────────

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✓ 安装完成！                           ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  下一步:"
echo -e "    1. 重启 Claude Code / Qoder"
echo -e "    2. 在目标项目中正常使用"
echo -e "    3. 说 'token report' 查看节省效果"
echo ""
echo -e "  ${GRAY}卸载: 删除 ultra-cost-effective/ 目录，移除 settings 中相关配置${NC}"
echo ""
