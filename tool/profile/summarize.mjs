import { readFile } from 'node:fs/promises';

const paths = process.argv.slice(2);
const runs = await Promise.all(paths.map(async path => JSON.parse(await readFile(path, 'utf8'))));
const frames = runs.flatMap(run => run.frames);
const budgetUs = 1e6 / runs[0].refreshRate;
const percentile = (values, fraction) => values.length ? values[Math.min(values.length - 1, Math.floor(values.length * fraction))] / 1000 : null;
const result = {
  runs: paths.length,
  frames: frames.length,
  refreshRate: runs[0].refreshRate,
  overBudget: frames.filter(frame => Math.max(frame.buildUs, frame.rasterUs) > budgetUs).length,
};
for (const field of ['buildUs', 'rasterUs', 'totalUs']) {
  const values = frames.map(frame => frame[field]).sort((left, right) => left - right);
  result[field] = {
    p50Ms: percentile(values, 0.5),
    p90Ms: percentile(values, 0.9),
    p99Ms: percentile(values, 0.99),
    maxMs: values.length ? values.at(-1) / 1000 : null,
  };
}
process.stdout.write(JSON.stringify(result, null, 2) + '\n');
