import { writeFile } from 'node:fs/promises';
import { setTimeout as delay } from 'node:timers/promises';

const [serviceUri, action, output, value] = process.argv.slice(2);
const socket = new WebSocket(serviceUri.replace(/^http/, 'ws').replace(/\/$/, '') + '/ws');
await new Promise((resolve, reject) => {
  socket.addEventListener('open', resolve, { once: true });
  socket.addEventListener('error', reject, { once: true });
});
let sequence = 0;
const pending = new Map();
socket.addEventListener('message', ({ data }) => {
  const message = JSON.parse(data);
  const request = pending.get(message.id);
  if (!request) return;
  pending.delete(message.id);
  if (message.error) request.reject(new Error(JSON.stringify(message.error)));
  else request.resolve(message.result);
});
function rpc(method, params = {}) {
  return new Promise((resolve, reject) => {
    const id = ++sequence;
    pending.set(id, { resolve, reject });
    socket.send(JSON.stringify({ jsonrpc: '2.0', id, method, params }));
  });
}
const vm = await rpc('getVM');
const isolateId = vm.isolates.find(isolate => isolate.name === 'main').id;
const command = (action, extra = {}) => rpc('ext.selfbox.profile', { isolateId, action, ...extra });
try {
  if (['scroll', 'long-scroll', 'fast-scroll', 'traced-scroll', 'traced-long-scroll', 'keyboard', 'typing', 'idle'].includes(action)) {
    await command('reset');
    await delay(1500);
    await rpc('setVMTimelineFlags', { recordedStreams: ['Dart', 'Embedder', 'GC'] });
    await rpc('clearVMTimeline');
    const started = await rpc('getVMTimelineMicros');
    await command('start');
    const segments = [];
    let sampling = true;
    const collect = async () => {
      while (sampling) {
        segments.push(await rpc('getVMTimeline'));
        await delay(2000);
      }
    };
    const collecting = action.startsWith('traced-') ? collect() : Promise.resolve();
    try {
      await command(action.replace(/^traced-/, ''));
    } finally {
      sampling = false;
      await collecting;
    }
    await delay(1200);
    const result = await command('stop');
    await writeFile(output, JSON.stringify(result));
    await writeFile(output.replace('.json', '.timeline.json'), JSON.stringify(await rpc('getVMTimeline')));
    if (segments.length) await writeFile(output.replace('.json', '.segments.json'), JSON.stringify(segments));
    if (action.startsWith('traced-')) {
      const ended = await rpc('getVMTimelineMicros');
      await writeFile(output.replace('.json', '.cpu.json'), JSON.stringify(await rpc('getCpuSamples', {
        isolateId,
        timeOriginMicros: started.timestamp,
        timeExtentMicros: ended.timestamp - started.timestamp,
      })));
    }
    const summary = { count: result.frames.length, refreshRate: result.refreshRate };
    for (const field of ['buildUs', 'rasterUs', 'totalUs']) {
      const values = result.frames.map(frame => frame[field]).sort((left, right) => left - right);
      summary[field] = {
        p50: values[Math.floor(values.length * 0.5)] / 1000,
        p90: values[Math.floor(values.length * 0.9)] / 1000,
        p99: values[Math.floor(values.length * 0.99)] / 1000,
        over16: values.filter(duration => duration > 16667).length,
      };
    }
    process.stdout.write(JSON.stringify(summary) + '\n');
  } else if (action === 'trace') {
    for (const method of ['profileWidgetBuilds', 'profileRenderObjectLayouts', 'profileRenderObjectPaints']) {
      await rpc('ext.flutter.' + method, { isolateId, enabled: value ?? 'true' });
    }
  } else {
    const result = await command(action, value ? { value } : {});
    if (output) await writeFile(output, JSON.stringify(result));
    process.stdout.write(JSON.stringify(output ? { saved: output } : result) + '\n');
  }
} finally {
  socket.close();
}
