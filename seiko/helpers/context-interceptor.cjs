#!/usr/bin/env node
/**
 * context-interceptor.cjs — Seiko AOP 上下文拦截器
 *
 * 将 Seiko 从工具级 Hook 提升为上下文级 AOP 拦截器。
 * 三层拦截确保"绝对前置起效"：
 *   1. Always-on Rule  → 系统提示注入上下文压缩指令
 *   2. PreToolUse Hook  → 工具输出压缩（已有，tokenforge-hook）
 *   3. Context Monitor  → 阈值驱动主动压缩（本文件）
 *
 * 核心职责:
 *   - 监控上下文大小（从 perf-tracker + session-memory 估算）
 *   - 生成三色灯健康报告（green/yellow/red）
 *   - 生成 LLM 上下文注入提示
 *   - Agent spawn 前生成压缩上下文摘要
 *
 * 用法:
 *   node context-interceptor.cjs check              # 三色灯检查
 *   node context-interceptor.cjs hint               # 生成 LLM 上下文提示
 *   node context-interceptor.cjs pre-agent-spawn    # Agent spawn 前检查
 *   node context-interceptor.cjs health             # 全文健康报告
 */

'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');

// ─── 配置 ──────────────────────────────────────

const TRACKER_FILE = path.join(os.tmpdir(), 'seiko-perf-tracker.json');
const MEMORY_FILE = path.join(os.tmpdir(), 'seiko-session-memory.json');

// 默认上下文窗口大小（DeepSeek: 128K tokens, 按需覆盖）
const DEFAULT_CONTEXT_WINDOW = 128000;

// 三色灯阈值
const GREEN_THRESHOLD = 0.60;   // <60% 窗口 → green
const YELLOW_THRESHOLD = 0.80;  // 60-80% 窗口 → yellow
                                 // >80% 窗口 → red

// 估算参数
const AVG_TOKENS_PER_CALL = 1200;    // 每次工具调用平均输出 tokens
const AVG_TOKENS_PER_TURN = 800;     // 每次对话轮次平均 LLM 响应 tokens
const SESSION_MEMORY_PER_RECORD = 200; // 每条 session-memory 记录占用的提示 tokens

// ─── 数据读取 ──────────────────────────────────

function loadTracker() {
  try {
    if (fs.existsSync(TRACKER_FILE)) {
      return JSON.parse(fs.readFileSync(TRACKER_FILE, 'utf-8'));
    }
  } catch {}
  return null;
}

function loadMemory() {
  try {
    if (fs.existsSync(MEMORY_FILE)) {
      return JSON.parse(fs.readFileSync(MEMORY_FILE, 'utf-8'));
    }
  } catch {}
  return null;
}

// ─── 上下文大小估算 ────────────────────────────

/**
 * 估算当前会话的上下文 token 数
 *
 * 计算方式:
 *   totalTokens = 工具输出累计 + LLM 响应累计 + session-memory 提示开销 + 系统提示估算
 */
function estimateContextSize() {
  const tracker = loadTracker();
  const memory = loadMemory();

  let estimatedTokens = 0;

  // 系统提示基础开销（约 3000-5000 tokens）
  estimatedTokens += 4000;

  if (tracker) {
    const totalCalls = tracker.totalCalls || 0;

    // 工具输出累计
    estimatedTokens += totalCalls * AVG_TOKENS_PER_CALL;

    // LLM 响应累计
    estimatedTokens += totalCalls * AVG_TOKENS_PER_TURN;

    // 会话时长额外膨胀系数（长会话一般有更多中间推理）
    if (tracker.startTime) {
      const durationMin = Math.floor((Date.now() - tracker.startTime) / 60000);
      if (durationMin > 30) {
        estimatedTokens += Math.floor(durationMin / 30) * 1000;
      }
    }
  }

  // session-memory 提示开销
  if (memory && memory.records) {
    estimatedTokens += memory.records.length * SESSION_MEMORY_PER_RECORD;
  }

  return estimatedTokens;
}

/**
 * 获取上下文窗口大小
 */
function getContextWindow() {
  const envVal = parseInt(process.env.SEIKO_CONTEXT_WINDOW);
  if (!isNaN(envVal) && envVal > 0) return envVal;
  return DEFAULT_CONTEXT_WINDOW;
}

// ─── 三色灯健康检测 ────────────────────────────

/**
 * 返回上下文健康状态
 * @returns {{ status: 'green'|'yellow'|'red', estimatedTokens: number,
 *             windowSize: number, ratio: number, calls: number, records: number,
 *             recommendation: string }}
 */
function getContextHealth() {
  const estimatedTokens = estimateContextSize();
  const windowSize = getContextWindow();
  const ratio = estimatedTokens / windowSize;

  let status, recommendation;

  if (ratio < GREEN_THRESHOLD) {
    status = 'green';
    recommendation = '上下文健康，无需压缩。Seiko 工具输出压缩正常运行中。';
  } else if (ratio < YELLOW_THRESHOLD) {
    status = 'yellow';
    recommendation = '上下文接近中度占用。建议：1) 使用 session-memory 索引替代重复工具输出；2) 如有 Agent spawn，传递压缩摘要。';
  } else {
    status = 'red';
    recommendation = '上下文高危。立即执行：1) 用 session-memory 索引替换所有工具输出引用；2) 请求 LLM 自压缩历史摘要；3) 仅传递必要上下文给子 Agent。';
  }

  const tracker = loadTracker();
  const memory = loadMemory();

  return {
    status,
    estimatedTokens,
    windowSize,
    ratio: (ratio * 100).toFixed(1),
    calls: tracker ? tracker.totalCalls || 0 : 0,
    records: memory ? (memory.records || []).length : 0,
    recommendation
  };
}

// ─── LLM 上下文提示生成 ────────────────────────

/**
 * 生成可注入到 LLM 系统提示中的压缩指导
 * @returns {string|null} 紧凑的提示文本，或 null（green 状态不需要）
 */
function generateContextHint() {
  const health = getContextHealth();

  if (health.status === 'green') return null;

  const memory = loadMemory();
  const tracker = loadTracker();

  let hint = '';

  if (health.status === 'yellow') {
    hint = `[Seiko上下文: 黄色 ${health.estimatedTokens}/${health.windowSize} tokens (${health.ratio}%)]`;
  } else {
    hint = `[Seiko上下文: 红色 ${health.estimatedTokens}/${health.windowSize} tokens (${health.ratio}%) ⚠ 即将超出窗口]`;
  }

  // 注入 session-memory 索引
  if (memory && memory.records && memory.records.length > 0) {
    const recentRecords = memory.records.slice(-8);
    hint += `\n[会话压缩索引: ${memory.records.length}条记录可用，下列内容已被压缩，需要时用 retrieve 命令取回原文，勿在上下文中重复原始输出]`;

    for (const r of recentRecords) {
      const age = Math.floor((Date.now() - r.ts) / 1000);
      const ageStr = age < 60 ? `${age}s前` : `${Math.floor(age / 60)}min前`;
      hint += `\n  · ${r.id.slice(0,16)} [${r.compressor}] ${r.type} ${(r.origSize/1024).toFixed(1)}KB → ${(r.compSize/1024).toFixed(1)}KB (${r.ratio}%) ${ageStr}`;
    }
  }

  // 建议操作
  hint += `\n[建议: ${health.recommendation}]`;

  return hint;
}

// ─── Agent Spawn 前提示 ─────────────────────────

/**
 * 在 Agent spawn 前生成压缩上下文指导
 * @returns {string|null} 指导文本
 */
function preAgentSpawnHint() {
  const health = getContextHealth();
  const memory = loadMemory();

  // 即使 green 状态也给出提示，因为 spawn agent 时上下文会复制

  let hint = '[Seiko AgentSpawnGuard]';
  hint += `\n当前上下文: ${health.status} (${health.estimatedTokens}/${health.windowSize} tokens, ${health.ratio}%)`;

  if (memory && memory.records && memory.records.length > 0) {
    const compressors = {};
    for (const r of memory.records) {
      compressors[r.compressor] = (compressors[r.compressor] || 0) + 1;
    }
    const compSummary = Object.entries(compressors)
      .map(([k, v]) => `${k}:${v}`)
      .join(', ');

    hint += `\n会话压缩记录: ${memory.records.length}条 (${compSummary})`;
    hint += `\n⚠ Agent spawn: 请传递压缩上下文摘要 + session-memory 索引引用，而非完整工具输出历史。`;
    hint += `\n   子 Agent 如需原文: 通过 headroom retrieve <id> 取回，非直接复制。`;
  } else {
    hint += `\n⚠ Agent spawn: 当前无压缩记录，Seiko 工具输出压缩正常运行。`;
  }

  // 红色状态追加紧急提示
  if (health.status === 'red') {
    hint += `\n🚨 上下文红色预警: 请先压缩主会话上下文再 spawn agent，否则子 agent 可能立即超出窗口。`;
  }

  return hint;
}

// ─── 命令行接口 ────────────────────────────────

function main() {
  const args = process.argv.slice(2);
  const cmd = args[0];

  if (cmd === 'check') {
    const health = getContextHealth();
    const icon = health.status === 'green' ? '🟢' : health.status === 'yellow' ? '🟡' : '🔴';
    console.log(`${icon} ${health.status.toUpperCase()}`);
    console.log(`  Tokens: ${health.estimatedTokens.toLocaleString()} / ${health.windowSize.toLocaleString()} (${health.ratio}%)`);
    console.log(`  Calls:  ${health.calls}`);
    console.log(`  Memory: ${health.records} records`);
    console.log(`  ${health.recommendation}`);
    // 输出 JSON 供脚本解析
    console.log(JSON.stringify(health));
    return;
  }

  if (cmd === 'hint') {
    const hint = generateContextHint();
    if (hint) {
      console.log(hint);
    } else {
      console.log('[Seiko: 上下文健康，无需提示]');
    }
    return;
  }

  if (cmd === 'pre-agent-spawn') {
    const hint = preAgentSpawnHint();
    console.log(hint);
    return;
  }

  if (cmd === 'health') {
    const health = getContextHealth();
    console.log('═══════════════════════════════════');
    console.log('  Seiko Context Interceptor');
    console.log('═══════════════════════════════════');
    console.log(`  状态:     ${health.status.toUpperCase()}`);
    console.log(`  Tokens:   ${health.estimatedTokens.toLocaleString()} / ${health.windowSize.toLocaleString()} (${health.ratio}%)`);
    console.log(`  调用数:   ${health.calls}`);
    console.log(`  记忆记录: ${health.records}`);
    console.log('');
    console.log(`  ${health.recommendation}`);
    console.log('');

    const hint = generateContextHint();
    if (hint) {
      console.log('─── LLM 上下文提示 ───');
      console.log(hint);
      console.log('');
    }

    console.log('─── Agent Spawn 提示 ───');
    console.log(preAgentSpawnHint());
    console.log('');
    console.log('═══════════════════════════════════');
    return;
  }

  // 默认: check
  const health = getContextHealth();
  const icon = health.status === 'green' ? '🟢' : health.status === 'yellow' ? '🟡' : '🔴';
  console.log(`${icon} Seiko Context: ${health.status} | ${health.estimatedTokens.toLocaleString()}/${health.windowSize.toLocaleString()} tokens (${health.ratio}%) | ${health.calls} calls | ${health.records} records`);
}

if (require.main === module) {
  main();
}

module.exports = {
  getContextHealth,
  generateContextHint,
  preAgentSpawnHint,
  estimateContextSize,
  getContextWindow
};
