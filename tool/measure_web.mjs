// Cold-loads the console in headless Chrome and reports what the browser
// downloaded, when Flutter drew its first frame, and any console errors.
//
//   node tool/measure_web.mjs https://publish.apprelease.store/ shot.png
//   LS='{"flutter.tour_seen_v2":"true"}' H=2000 node tool/measure_web.mjs http://127.0.0.1:8077/ tall.png
//
// Needs Google Chrome in /Applications and Node 22 or newer.
import { spawn } from 'node:child_process';
import { writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const url = process.argv[2];
const shot = process.argv[3];
const timeout = Number(process.argv[4] ?? 40000);
const port = 9333 + Math.floor(Math.random() * 500);
// LS='{"flutter.tour_seen_v2":"true"}' presets localStorage; H=2000 sets the height.
const preset = process.env.LS ?? '{}';
const height = process.env.H ?? '900';
const profile = mkdtempSync(join(tmpdir(), 'ar-measure-'));
const chrome = spawn(
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  ['--headless=new', `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`,
   '--no-first-run', '--no-default-browser-check', `--window-size=1440,${height}`,
   '--hide-scrollbars', 'about:blank'],
  { stdio: 'ignore' },
);

async function targets() {
  for (let i = 0; i < 100; i++) {
    try { return await (await fetch(`http://127.0.0.1:${port}/json/list`)).json(); }
    catch { await new Promise((r) => setTimeout(r, 150)); }
  }
  throw new Error('chrome did not start');
}
const page = (await targets()).find((t) => t.type === 'page');
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((r) => (ws.onopen = r));
let id = 0;
const pending = new Map();
const handlers = {};
ws.onmessage = (m) => {
  const d = JSON.parse(m.data);
  if (d.id) { pending.get(d.id)?.(d); pending.delete(d.id); }
  else handlers[d.method]?.(d.params);
};
const send = (method, params = {}) => new Promise((res) => {
  const i = ++id; pending.set(i, res); ws.send(JSON.stringify({ id: i, method, params }));
});

const responses = new Map();
const bytes = new Map();
const errors = [];
let loadAt = null;
handlers['Network.responseReceived'] = (p) => responses.set(p.requestId, { url: p.response.url, type: p.type });
handlers['Network.loadingFinished'] = (p) => bytes.set(p.requestId, p.encodedDataLength);
handlers['Page.loadEventFired'] = (p) => (loadAt = p.timestamp);
handlers['Runtime.consoleAPICalled'] = (p) => {
  if (p.type === 'error' || p.type === 'warning') errors.push(`${p.type}: ${p.args.map((a) => a.value ?? a.description ?? '').join(' ').slice(0, 200)}`);
};
handlers['Runtime.exceptionThrown'] = (p) => errors.push(`exception: ${(p.exceptionDetails.exception?.description ?? p.exceptionDetails.text).slice(0, 200)}`);

await send('Network.enable');
await send('Page.enable');
await send('Runtime.enable');
await send('Network.setCacheDisabled', { cacheDisabled: true });
await send('Page.addScriptToEvaluateOnNewDocument', {
  source: `for(const [k,v] of Object.entries(${preset}))localStorage.setItem(k,v);window.__ff=null;window.__t0=performance.timeOrigin;window.addEventListener('flutter-first-frame',()=>{window.__ff=performance.now()});`,
});
const start = Date.now();
await send('Page.navigate', { url });

let firstFrame = null;
while (Date.now() - start < timeout) {
  const r = await send('Runtime.evaluate', { expression: 'window.__ff', returnByValue: true });
  if (r.result?.result?.value) { firstFrame = r.result.result.value; break; }
  await new Promise((res) => setTimeout(res, 100));
}
// Let the first screen settle (data arrives after the frame).
await new Promise((res) => setTimeout(res, 2500));
const navStart = (await send('Runtime.evaluate', { expression: 'performance.timing.navigationStart', returnByValue: true })).result.result.value;
const loadMs = loadAt ? Math.round(loadAt * 1000 - navStart) : null;

if (shot) {
  const img = await send('Page.captureScreenshot', { format: 'png' });
  writeFileSync(shot, Buffer.from(img.result.data, 'base64'));
}

const rows = [...responses].map(([rid, r]) => ({ ...r, bytes: bytes.get(rid) ?? 0 }));
const total = rows.reduce((s, r) => s + r.bytes, 0);
const byType = {};
for (const r of rows) byType[r.type] = (byType[r.type] ?? 0) + r.bytes;
console.log(`url: ${url}`);
console.log(`requests: ${rows.length}   wire bytes: ${(total / 1024).toFixed(0)} KB`);
console.log(`load event: ${loadMs} ms   flutter first frame: ${firstFrame ? Math.round(firstFrame) + ' ms' : 'never'}`);
console.log('by type: ' + Object.entries(byType).sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k}=${(v / 1024).toFixed(0)}KB`).join('  '));
console.log('largest:');
for (const r of rows.sort((a, b) => b.bytes - a.bytes).slice(0, 10)) console.log(`  ${(r.bytes / 1024).toFixed(0).padStart(6)} KB  ${r.url.replace(/^https?:\/\/[^/]+/, '')}`);
if (errors.length) { console.log('console:'); for (const e of errors.slice(0, 12)) console.log('  ' + e); }
ws.close();
chrome.kill();
