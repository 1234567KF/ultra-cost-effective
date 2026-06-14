#!/usr/bin/env bash
# ============================================================
#  UltraCostEffective · 极致节能 — 远程一键安装 (macOS/Linux)
#
#  无需克隆仓库！在你的项目根目录直接运行：
#
#    curl -fsSL https://raw.githubusercontent.com/1234567KF/ultra-cost-effective/main/install.sh | bash
#
#  或带参数：
#    curl -fsSL https://raw.githubusercontent.com/1234567KF/ultra-cost-effective/main/install.sh | bash -s -- --platform qoder
#    curl -fsSL https://raw.githubusercontent.com/1234567KF/ultra-cost-effective/main/install.sh | bash -s -- --preset extreme
#
#  自动完成:
#    [1/4] 下载引擎 (从 GitHub tarball)
#    [2/4] 解压到当前目录
#    [3/4] 安装 lean-ctx + 合并 settings
#    [4/4] 验证安装
# ============================================================

set -e

REPO="1234567KF/ultra-cost-effective"
BRANCH="main"
PLATFORM="auto"
PRESET="standard"
SKIP_LEAN_CTX=false
FORCE=false
ENGINE_NAME="ultra-cost-effective"

# ─── 参数解析 ──────────────────────────────────

for arg in "$@"; do
  case $arg in
    --platform=*) PLATFORM="${arg#*=}" ;;
    --preset=*)   PRESET="${arg#*=}" ;;
    --repo=*)     REPO="${arg#*=}" ;;
    --branch=*)   BRANCH="${arg#*=}" ;;
    --skip-lean-ctx) SKIP_LEAN_CTX=true ;;
    --force)      FORCE=true ;;
    -h|--help)
      echo "UltraCostEffective Remote Install"
      echo ""
      echo "Usage: curl ... | bash -s -- [options]"
      echo ""
      echo "Options:"
      echo "  --platform=claude|qoder|auto  (default: auto)"
      echo "  --preset=quick|standard|extreme  (default: standard)"
      echo "  --skip-lean-ctx               Skip lean-ctx install"
      echo "  --force                       Overwrite existing install"
      exit 0
      ;;
  esac
done

# ─── 工具函数 ──────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

step() { echo -e "\n${YELLOW}[$1/4] $2${NC}" }
ok()   { echo -e "  ${GREEN}OK${NC}  $1" }
warn() { echo -e "  ${YELLOW}!!${NC}  $1" }
fail() { echo -e "  ${RED}XX${NC}  $1" }
info() { echo -e "  ${GRAY}$1${NC}" }

# ─── Banner ────────────────────────────────────

echo ""
echo -e "${CYAN}  UltraCostEffective - Remote Install${NC}"
echo -e "${CYAN}  Repo: $REPO ($BRANCH)${NC}"
echo -e "${CYAN}  Target: $(pwd)${NC}"
echo ""

# ─── [1/4] 下载引擎 ────────────────────────────

step 1 "Downloading engine from GitHub..."

TEMP_DIR=$(mktemp -d)
TARBALL_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz"

if command -v curl &> /dev/null; then
  if ! curl -fsSL "$TARBALL_URL" -o "$TEMP_DIR/repo.tar.gz" 2>/dev/null; then
    fail "Download failed"
    info "Check your internet connection or try: --branch=develop"
    rm -rf "$TEMP_DIR"
    exit 1
  fi
elif command -v wget &> /dev/null; then
  if ! wget -q "$TARBALL_URL" -O "$TEMP_DIR/repo.tar.gz" 2>/dev/null; then
    fail "Download failed (wget)"
    rm -rf "$TEMP_DIR"
    exit 1
  fi
else
  fail "Neither curl nor wget found"
  info "Please install curl: apt install curl / brew install curl"
  rm -rf "$TEMP_DIR"
  exit 1
fi

FILE_SIZE=$(wc -c < "$TEMP_DIR/repo.tar.gz" 2>/dev/null || stat -f%z "$TEMP_DIR/repo.tar.gz" 2>/dev/null || echo "?")
ok "Downloaded ${FILE_SIZE} bytes"

# ─── [2/4] 解压引擎 ────────────────────────────

step 2 "Extracting engine..."

mkdir -p "$TEMP_DIR/extracted"
tar -xzf "$TEMP_DIR/repo.tar.gz" -C "$TEMP_DIR/extracted" 2>/dev/null

# tar 结构: repo-branch/ultra-cost-effective/...
SOURCE_DIR=$(ls -d "$TEMP_DIR/extracted"/*/ 2>/dev/null | head -1)
ENGINE_SOURCE="$SOURCE_DIR$ENGINE_NAME"

if [ ! -d "$ENGINE_SOURCE" ]; then
  fail "Engine directory not found in archive"
  info "Expected: $ENGINE_SOURCE"
  rm -rf "$TEMP_DIR"
  exit 1
fi

TARGET_ENGINE="$(pwd)/$ENGINE_NAME"

if [ -d "$TARGET_ENGINE" ] && [ "$FORCE" != true ]; then
  warn "$ENGINE_NAME/ already exists"
  read -p "  Overwrite? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Cancelled"
    rm -rf "$TEMP_DIR"
    exit 0
  fi
fi

# 复制
if [ -d "$TARGET_ENGINE" ]; then
  rm -rf "$TARGET_ENGINE"
fi
cp -R "$ENGINE_SOURCE" "$TARGET_ENGINE"

# 清理 node_modules/.git
rm -rf "$TARGET_ENGINE/node_modules" "$TARGET_ENGINE/.git" 2>/dev/null

ok "Engine installed to ./$ENGINE_NAME/"

# 清理临时文件
rm -rf "$TEMP_DIR"

# ─── [3/4] 安装依赖 + 合并 settings ────────────

step 3 "Installing dependencies & merging settings..."

# lean-ctx
if [ "$SKIP_LEAN_CTX" != true ]; then
  if command -v lean-ctx &> /dev/null; then
    ok "lean-ctx already installed"
  else
    if npm install -g lean-ctx-bin >/dev/null 2>&1; then
      ok "lean-ctx installed"
    else
      warn "lean-ctx install failed (non-fatal, run: npm install -g lean-ctx-bin)"
    fi
  fi
else
  warn "Skipping lean-ctx (--skip-lean-ctx)"
fi

# 平台检测
if [ "$PLATFORM" = "auto" ]; then
  if [ -n "$QODER_SESSION_ID" ] || [ -n "$QODER_WORKSPACE" ]; then
    PLATFORM="qoder"
  elif [ -n "$CLAUDE_CODE_SESSION_ID" ] || command -v claude &> /dev/null; then
    PLATFORM="claude"
  elif [ -d ".claude" ]; then
    PLATFORM="claude"
  else
    PLATFORM="claude"
  fi
fi
ok "Platform: $PLATFORM"

# 合并 settings
TEMPLATE_FILE="$TARGET_ENGINE/adapters/claude/settings.template.json"

if [ "$PLATFORM" = "claude" ]; then
  mkdir -p .claude
  SETTINGS_FILE=".claude/settings.json"

  if [ -f "$SETTINGS_FILE" ]; then
    # 智能合并
    if command -v node &> /dev/null; then
      node -e "
        const fs = require('fs');
        const e = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf-8'));
        const t = JSON.parse(fs.readFileSync('$TEMPLATE_FILE', 'utf-8'));
        if (t.hooks) {
          e.hooks = e.hooks || {};
          for (const [k, v] of Object.entries(t.hooks)) {
            e.hooks[k] = (e.hooks[k] || []).concat(v);
          }
        }
        if (t.permissions && t.permissions.allow) {
          e.permissions = e.permissions || { allow: [] };
          e.permissions.allow = e.permissions.allow || [];
          t.permissions.allow.forEach(p => { if (!e.permissions.allow.includes(p)) e.permissions.allow.push(p); });
        }
        if (t.mcpServers) {
          e.mcpServers = e.mcpServers || {};
          for (const [k, v] of Object.entries(t.mcpServers)) { if (!e.mcpServers[k]) e.mcpServers[k] = v; }
        }
        e.environment = e.environment || {};
        Object.assign(e.environment, t.environment || {});
        e.environment.ULTRA_COST_EFFECTIVE_LEVEL = '$PRESET';
        fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(e, null, 2), 'utf-8');
      " 2>/dev/null && ok "settings.json merged" || warn "Smart merge failed, please merge manually: $TEMPLATE_FILE"
    else
      warn "Node.js not found, please merge manually: $TEMPLATE_FILE"
    fi
  else
    cp "$TEMPLATE_FILE" "$SETTINGS_FILE"
    if command -v node &> /dev/null; then
      node -e "
        const fs = require('fs');
        const s = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf-8'));
        s.environment = s.environment || {};
        s.environment.ULTRA_COST_EFFECTIVE_LEVEL = '$PRESET';
        fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(s, null, 2), 'utf-8');
      " 2>/dev/null
    fi
    ok ".claude/settings.json created from template"
  fi
else
  PATCH_FILE="$TARGET_ENGINE/adapters/qoder/settings.patch.json"
  ok "Qoder patch: $PATCH_FILE"
  info "Merge into your Qoder settings.json"
fi

# ─── [4/4] 验证安装 ────────────────────────────

step 4 "Verifying installation..."

CORE_FILES=(
  "helpers/tokenforge.cjs"
  "helpers/context-interceptor.cjs"
  "helpers/workflow-integrator.cjs"
  "helpers/ultra-cost-effective-guard.cjs"
  "rules/interceptor-aop.md"
  "rules/workflow-compress.md"
)

ALL_OK=true
for f in "${CORE_FILES[@]}"; do
  if [ -f "$TARGET_ENGINE/$f" ]; then
    ok "$f"
  else
    fail "Missing: $f"
    ALL_OK=false
  fi
done

# ─── Done ──────────────────────────────────────

echo ""
if [ "$ALL_OK" = true ]; then
  echo -e "  ${GREEN}Install complete!${NC}"
else
  echo -e "  ${YELLOW}Install complete with warnings${NC}"
fi
echo ""
echo "  Next steps:"
echo "    1. Restart Claude Code / Qoder"
echo "    2. Say 'token report' to see savings"
echo ""
echo -e "  ${GRAY}Uninstall: rm -rf $ENGINE_NAME/ and remove settings entries${NC}"
echo ""
