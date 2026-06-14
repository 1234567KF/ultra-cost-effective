#!/usr/bin/env pwsh
# ============================================================
#  UltraCostEffective · 极致节能 — 远程一键安装 (Windows)
#
#  无需克隆仓库！在你的项目根目录直接运行：
#
#    irm https://raw.githubusercontent.com/1234567KF/ultra-cost-effective/main/install.ps1 | iex
#
#  或手动下载后运行：
#    .\install.ps1
#    .\install.ps1 -Platform claude
#    .\install.ps1 -Platform qoder
#    .\install.ps1 -Preset extreme
#
#  自动完成:
#    [1/4] 下载引擎 (从 GitHub release tarball)
#    [2/4] 解压到当前目录
#    [3/4] 安装 lean-ctx + 合并 settings
#    [4/4] 验证安装
# ============================================================

param(
    [ValidateSet("claude", "qoder", "auto")]
    [string]$Platform = "auto",

    [ValidateSet("quick", "standard", "extreme")]
    [string]$Preset = "standard",

    [string]$Repo = "1234567KF/ultra-cost-effective",
    [string]$Branch = "main",
    [switch]$SkipLeanCtx,
    [switch]$Force
)

$ErrorActionPreference = "Continue"
$REPO_TARBALL = "https://github.com/$Repo/archive/refs/heads/$Branch.zip"
$ENGINE_NAME = "ultra-cost-effective"

# ─── 颜色工具 ──────────────────────────────────

function Write-Step($n, $msg) { Write-Host "[$n/4] $msg" -ForegroundColor Yellow }
function Write-Ok($msg)   { Write-Host "  OK  $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  !!  $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "  XX  $msg" -ForegroundColor Red }
function Write-Info($msg) { Write-Host "      $msg" -ForegroundColor Gray }

# ─── Banner ────────────────────────────────────

Write-Host ""
Write-Host "  UltraCostEffective - Remote Install" -ForegroundColor Cyan
Write-Host "  Repo: $Repo ($Branch)" -ForegroundColor Cyan
Write-Host "  Target: $(Get-Location)" -ForegroundColor Cyan
Write-Host ""

# ─── [1/4] 下载引擎 ────────────────────────────

Write-Step 1 "Downloading engine from GitHub..."

$tempDir = Join-Path $env:TEMP "uce-install-$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

$zipFile = Join-Path $tempDir "repo.zip"

try {
    $oldProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $REPO_TARBALL -OutFile $zipFile -UseBasicParsing
    $ProgressPreference = $oldProgress
    Write-Ok "Downloaded $(("{0:N0}" -f (Get-Item $zipFile).Length)) bytes"
} catch {
    Write-Fail "Download failed: $_"
    Write-Info "Check your internet connection or try a different branch"
    exit 1
}

# ─── [2/4] 解压引擎 ────────────────────────────

Write-Step 2 "Extracting engine..."

$extractDir = Join-Path $tempDir "extracted"
Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force

# GitHub zip 结构: repo-branch/ultra-cost-effective/...
$sourceDir = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
$engineSource = Join-Path $sourceDir.FullName $ENGINE_NAME

if (-not (Test-Path $engineSource)) {
    Write-Fail "Engine directory not found in archive"
    Write-Info "Expected: $engineSource"
    exit 1
}

# 复制到当前目录
$targetEngine = Join-Path (Get-Location) $ENGINE_NAME

if ((Test-Path $targetEngine) -and -not $Force) {
    Write-Warn "$ENGINE_NAME/ already exists in current directory"
    $overwrite = Read-Host "  Overwrite? (y/N)"
    if ($overwrite -ne 'y' -and $overwrite -ne 'Y') {
        Write-Info "Cancelled"
        Remove-Item $tempDir -Recurse -Force
        exit 0
    }
}

# 复制（跳过 node_modules/.git）
if (Test-Path $targetEngine) {
    Remove-Item $targetEngine -Recurse -Force
}
Copy-Item -Path $engineSource -Destination $targetEngine -Recurse -Force

# 清理 node_modules/.git（如有）
$cleanDirs = @("node_modules", ".git")
foreach ($d in $cleanDirs) {
    $cleanPath = Join-Path $targetEngine $d
    if (Test-Path $cleanPath) { Remove-Item $cleanPath -Recurse -Force }
}

Write-Ok "Engine installed to ./$ENGINE_NAME/"

# 清理临时文件
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# ─── [3/4] 安装依赖 + 合并 settings ────────────

Write-Step 3 "Installing dependencies & merging settings..."

# lean-ctx
if (-not $SkipLeanCtx) {
    $leanCtxInstalled = $false
    try { $null = lean-ctx --version 2>$null; if ($LASTEXITCODE -eq 0) { $leanCtxInstalled = $true } } catch {}
    if ($leanCtxInstalled) {
        Write-Ok "lean-ctx already installed"
    } else {
        npm install -g lean-ctx-bin 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Ok "lean-ctx installed" }
        else { Write-Warn "lean-ctx install failed (non-fatal, run: npm install -g lean-ctx-bin)" }
    }
} else {
    Write-Warn "Skipping lean-ctx (-SkipLeanCtx)"
}

# 平台检测
if ($Platform -eq "auto") {
    if ($env:QODER_SESSION_ID -or $env:QODER_WORKSPACE) { $Platform = "qoder" }
    elseif ($env:CLAUDE_CODE_SESSION_ID -or (Get-Command claude -ErrorAction SilentlyContinue)) { $Platform = "claude" }
    else {
        $claudeDir = Join-Path (Get-Location) ".claude"
        if (Test-Path $claudeDir) { $Platform = "claude" }
        else { $Platform = "claude" }
    }
}
Write-Ok "Platform: $Platform"

# 合并 settings
if ($Platform -eq "claude") {
    $claudeDir = Join-Path (Get-Location) ".claude"
    if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null }

    $settingsFile = Join-Path $claudeDir "settings.json"
    $templateFile = Join-Path $targetEngine "adapters" "claude" "settings.template.json"

    if (Test-Path $settingsFile) {
        try {
            $existing = Get-Content $settingsFile -Raw | ConvertFrom-Json
            $template = Get-Content $templateFile -Raw | ConvertFrom-Json

            if ($template.hooks) {
                if (-not $existing.hooks) { $existing | Add-Member -NotePropertyName "hooks" -NotePropertyValue @{} }
                foreach ($hookType in $template.hooks.PSObject.Properties.Name) {
                    if (-not $existing.hooks.$hookType) {
                        $existing.hooks | Add-Member -NotePropertyName $hookType -NotePropertyValue @()
                    }
                    $template.hooks.$hookType | ForEach-Object { $existing.hooks.$hookType += $_ }
                }
            }
            if ($template.permissions -and $template.permissions.allow) {
                if (-not $existing.permissions) {
                    $existing | Add-Member -NotePropertyName "permissions" -NotePropertyValue @{ allow = @() }
                }
                if (-not $existing.permissions.allow) {
                    $existing.permissions | Add-Member -NotePropertyName "allow" -NotePropertyValue @()
                }
                foreach ($perm in $template.permissions.allow) {
                    if ($existing.permissions.allow -notcontains $perm) { $existing.permissions.allow += $perm }
                }
            }
            if ($template.mcpServers) {
                if (-not $existing.mcpServers) {
                    $existing | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue @{}
                }
                foreach ($s in $template.mcpServers.PSObject.Properties.Name) {
                    if (-not $existing.mcpServers.$s) {
                        $existing.mcpServers | Add-Member -NotePropertyName $s -NotePropertyValue $template.mcpServers.$s
                    }
                }
            }
            if ($template.environment) {
                if (-not $existing.environment) {
                    $existing | Add-Member -NotePropertyName "environment" -NotePropertyValue @{}
                }
                foreach ($k in $template.environment.PSObject.Properties.Name) {
                    $existing.environment | Add-Member -NotePropertyName $k -NotePropertyValue $template.environment.$k -Force
                }
            }
            $existing.environment | Add-Member -NotePropertyName "ULTRA_COST_EFFECTIVE_LEVEL" -NotePropertyValue $Preset -Force
            $existing | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
            Write-Ok "settings.json merged"
        } catch {
            Write-Warn "Smart merge failed: $_"
            Write-Info "Please manually merge: $templateFile"
        }
    } else {
        Copy-Item $templateFile $settingsFile
        try {
            $s = Get-Content $settingsFile -Raw | ConvertFrom-Json
            if (-not $s.environment) { $s | Add-Member -NotePropertyName "environment" -NotePropertyValue @{} }
            $s.environment | Add-Member -NotePropertyName "ULTRA_COST_EFFECTIVE_LEVEL" -NotePropertyValue $Preset -Force
            $s | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
        } catch {}
        Write-Ok ".claude/settings.json created from template"
    }
} else {
    $patchFile = Join-Path $targetEngine "adapters" "qoder" "settings.patch.json"
    Write-Ok "Qoder patch: $patchFile"
    Write-Info "Merge this into your Qoder settings.json"
}

# ─── [4/4] 验证安装 ────────────────────────────

Write-Step 4 "Verifying installation..."

$coreFiles = @(
    "helpers/tokenforge.cjs",
    "helpers/context-interceptor.cjs",
    "helpers/workflow-integrator.cjs",
    "helpers/ultra-cost-effective-guard.cjs",
    "rules/interceptor-aop.md",
    "rules/workflow-compress.md"
)

$allOk = $true
foreach ($f in $coreFiles) {
    if (Test-Path (Join-Path $targetEngine $f)) { Write-Ok $f }
    else { Write-Fail "Missing: $f"; $allOk = $false }
}

# ─── Done ──────────────────────────────────────

Write-Host ""
if ($allOk) {
    Write-Host "  Install complete!" -ForegroundColor Green
} else {
    Write-Host "  Install complete with warnings" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    1. Restart Claude Code / Qoder" -ForegroundColor White
Write-Host "    2. Say 'token report' to see savings" -ForegroundColor White
Write-Host ""
Write-Host "  Uninstall: delete ultra-cost-effective/ and remove settings entries" -ForegroundColor Gray
Write-Host ""
