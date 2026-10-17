import { readFileSync } from 'node:fs';
import { validateDirectory } from '../vendor/validate-store-screenshots/src/validate.mjs';
import { appleTargetIds } from '../vendor/validate-store-screenshots/node_modules/@grunersoftware/store-screenshot-specs/dist/index.js';
import specs from '../vendor/validate-store-screenshots/node_modules/@grunersoftware/store-screenshot-specs/dist/specs.json' with { type: 'json' };

async function main() {
  try {
    if (Number(process.versions.node.split('.')[0]) < 22) throw new Error('Node.js 22 or newer is required.');
    const request = JSON.parse(readFileSync(0, 'utf8'));
    for (const key of ['directory', 'workspace', 'target']) {
      if (typeof request[key] !== 'string' || !request[key].trim()) throw new Error(`${key} must be a non-empty string.`);
    }
    const supported = [...appleTargetIds, 'google-phone'];
    if (!supported.includes(request.target)) throw new Error(`Unsupported target. Choose ${supported.join(', ')}.`);
    for (const key of ['fail_on_error', 'fail_on_review']) {
      if (typeof request[key] !== 'boolean') throw new Error(`${key} must be a boolean.`);
    }
    const report = await validateDirectory(request.directory, request.target, request.workspace);
    process.stdout.write(JSON.stringify({ ...report, specsVersion: specs.packageVersion }) + '\n');
    process.exitCode = (request.fail_on_error && report.failures > 0) || (request.fail_on_review && report.reviews > 0) ? 1 : 0;
  } catch (error) {
    process.stdout.write(JSON.stringify({ error: error.message }) + '\n');
    process.exitCode = 2;
  }
}
main();
