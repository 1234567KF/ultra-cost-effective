#!/usr/bin/env node
/**
 * token-watcher.cjs — 从 Claude Code 会话 JSONL 提取真实 Token 用量
 *
 * 零侵入：不修改 BASE_URL，不拦截 API。
 * 直接读取 Claude Code 写入的会话 transcript 文件。
 *
 * 用法:
 *   node token-watcher.cjs                    # 扫描当前会话并输出报告
 *   node token-watcher.cjs --watch             # 持续监视（每 30s 扫描一次）
 *   node token-watcher.cjs --session <path>    # 指定 JSONL 文件路径
 */

'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');

// ─── 项目根 + 会话定位 ───────────────────────

function resolveProjectRoot() {
  let dir = __dirname;
  for (let i = 0; i < 5; i++) {
    dir = path.dirname(dir);
    if (fs.existsSync(path.join(dir, 'ultra-cost-effective'))) return dir;
  }
  return process.cwd();
}

function findActiveSession() {
  const projectsDir = path.join(os.homedir(), '.claude', 'projects');
  if (!fs.existsSync(projectsDir)) return null;

  const dirs = fs.readdirSync(projectsDir, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => path.join(projectsDir, d.name));

  // 找最近的 JSONL
  let latest = null;
  let latestTime = 0;
  for (const dir of dirs) {
    try {
      const files = fs.readdirSync(dir).filter(f => f.endsWith('.jsonl'));
      for (const f of files) {
        const fp = path.join(dir, f);
        const stat = fs.statSync(fp);
        if (stat.mtimeMs > latestTime) {
          latestTime = stat.mtimeMs;
          latest = fp;
        }
      }
    } catch {}
  }

  return latest;
}

// ─── 解析 JSONL ──────────────────────────────

function parseJsonl(filePath, lastPosition = 0) {
  if (!fs.existsSync(filePath)) return { entries: [], lastPos: 0, newEntries: 0 };

  const stat = fs.statSync(filePath);
  if (stat.size <= lastPosition) return { entries: [], lastPos: lastPosition, newEntries: 0 };

  // 只读新增部分
  const fd = fs.openSync(filePath, 'r');
  const buf = Buffer.alloc(stat.size - lastPosition);
  fs.readSync(fd, buf, 0, buf.length, lastPosition);
  fs.closeSync(fd);

  const text = buf.toString('utf-8');
  const lines = text.split('\n').filter(l => l.trim());
  const entries = [];

  for (const line of lines) {
    try {
      const entry = JSON.parse(line);
      if (entry.message?.usage) {
        entries.push({
          time: entry.timestamp,
          model: entry.message.model || 'unknown',
          usage: entry.message.usage,
        });
      }
    } catch {}
  }

  return { entries, lastPos: stat.size, newEntries: entries.length };
}

// ─── 写入 tracker ─────────────────────────────

function writeTracker(entries) {
  const PROJECT_ROOT = resolveProjectRoot();
  const TRACKER_FILE = path.join(PROJECT_ROOT, '.ultra-cost-effective-tracker.json');

  let session;
  try {
    session = JSON.parse(fs.readFileSync(TRACKER_FILE, 'utf-8'));
  } catch {
    session = {
      sessionId: 'watcher_' + Date.now().toString(36),
      projectRoot: PROJECT_ROOT,
      startTime: Date.now(),
      totalCalls: 0,
      totalInputTokens: 0,
      totalOutputTokens: 0,
      totalCacheHitTokens: 0,
      totalCacheMissTokens: 0,
      modelStats: {},
      calls: [],
    };
  }

  for (const entry of entries) {
    const u = entry.usage;
    const input = u.input_tokens || 0;
    const output = u.output_tokens || 0;
    const cacheHit = u.cache_read_input_tokens || 0;
    const cacheMiss = input - cacheHit;
    const model = entry.model || 'unknown';

    session.totalCalls++;
    session.totalInputTokens += input;
    session.totalOutputTokens += output;
    session.totalCacheHitTokens += cacheHit;
    session.totalCacheMissTokens += Math.max(0, cacheMiss);

    if (!session.modelStats[model]) {
      session.modelStats[model] = { calls: 0, inputTokens: 0, outputTokens: 0, cacheHitTokens: 0 };
    }
    session.modelStats[model].calls++;
    session.modelStats[model].inputTokens += input;
    session.modelStats[model].outputTokens += output;
    session.modelStats[model].cacheHitTokens += cacheHit;

    session.calls.push({ time: entry.time, model, inputTokens: input, outputTokens: output, cacheHitTokens: cacheHit });
    if (session.calls.length > 200) session.calls.shift();
  }

  fs.writeFileSync(TRACKER_FILE, JSON.stringify(session, null, 2));
  return session;
}

// ─── 报告 ─────────────────────────────────────

function printReport(session) {
  const elapsed = Math.floor((Date.now() - session.startTime) / 1000);
  const h = Math.floor(elapsed / 3600);
  const m = Math.floor((elapsed % 3600) / 60);
  const total = session.totalInputTokens + session.totalOutputTokens;
  const hitRate = (session.totalCacheHitTokens + session.totalCacheMissTokens) > 0
    ? (session.totalCacheHitTokens / (session.totalCacheHitTokens + session.totalCacheMissTokens) * 100).toFixed(1)
    : '0.0';

  const lines = [
    '',
    '══════════════════════════════════════════════════',
    '  UltraCostEffective 真实 Token 报告 (JSONL Watcher)',
    '══════════════════════════════════════════════════', '',
    `运行时间: ${h}h ${m}m  |  LLM 调用: ${session.totalCalls}`, '',
    `输入 Token:   ${(session.totalInputTokens / 1000).toFixed(1)}K`,
    `输出 Token:   ${(session.totalOutputTokens / 1000).toFixed(1)}K`,
    `合计:         ${(total / 1000).toFixed(1)}K`, '',
    `KV Cache 命中: ${(session.totalCacheHitTokens / 1000).toFixed(1)}K  (${hitRate}%)`,
    `KV Cache 未命中: ${(session.totalCacheMissTokens / 1000).toFixed(1)}K`, '',
    '─── 模型 ───',
  ];

  for (const [model, stats] of Object.entries(session.modelStats)) {
    const si = stats.inputTokens || 0;
    const so = stats.outputTokens || 0;
    lines.push(`  ${model}: ${stats.calls} 次, ${(si/1000).toFixed(1)}K in, ${(so/1000).toFixed(1)}K out`);
  }

  lines.push('', '══════════════════════════════════════════════════');
  return lines.join('\n');
}

// ─── 主逻辑 ────────────────────────────────────

function main() {
  const args = process.argv.slice(2);

  let jsonlPath = args.includes('--session') ? args[args.indexOf('--session') + 1] : null;
  if (!jsonlPath) jsonlPath = findActiveSession();

  if (!jsonlPath) {
    console.log('未找到活跃的 Claude Code 会话。请指定 --session <path>');
    process.exit(1);
  }

  console.log(`📂 监视: ${jsonlPath}`);

  const { entries, newEntries } = parseJsonl(jsonlPath, 0);
  console.log(`📊 发现 ${entries.length} 条 LLM 调用记录`);

  if (entries.length > 0) {
    const session = writeTracker(entries);
    console.log(printReport(session));
  }

  if (args.includes('--watch') || args.includes('-w')) {
    let lastPos = fs.statSync(jsonlPath).size;
    console.log('👁 持续监视中（每 30s）...\n');
    setInterval(() => {
      const { entries: newOnes, lastPos: newPos } = parseJsonl(jsonlPath, lastPos);
      if (newOnes.length > 0) {
        const session = writeTracker(newOnes);
        const last = newOnes[newOnes.length - 1];
        const input = last.usage.input_tokens || 0;
        const output = last.usage.output_tokens || 0;
        const cache = last.usage.cache_read_input_tokens || 0;
        console.log(`  📊 +${newOnes.length} 调用 | ${input} in / ${output} out | cache: ${cache}`);
      }
      lastPos = newPos;
    }, 30000);
  }
}

main();
