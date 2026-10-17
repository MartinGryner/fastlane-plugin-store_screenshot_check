import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtemp, mkdir, writeFile, symlink, rm, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pngjs from '../vendor/validate-store-screenshots/node_modules/pngjs/lib/png.js';
const { PNG } = pngjs;
const helper = fileURLToPath(new URL('../lib/fastlane/plugin/store_screenshot_check/helper/validate.cjs', import.meta.url));
const png = (w, h, alpha = false) => PNG.sync.write({ width: w, height: h, data: Buffer.alloc(w * h * 4, 255) }, { colorType: alpha ? 6 : 2 });

test('bundled validator accepts real Apple and Google sets and keeps review separate', async () => {
  const root = await mkdtemp(path.join(tmpdir(), 'fastlane-screenshot-'));
  const run = (extra = {}) => {
    const result = spawnSync(process.execPath, [helper], { encoding: 'utf8', input: JSON.stringify({ workspace: root, directory: 'apple space; literal', target: 'apple-iphone-69', fail_on_error: true, fail_on_review: false, ...extra }) });
    assert.equal(result.stderr, '');
    return { status: result.status, report: JSON.parse(result.stdout) };
  };
  try {
    for (const folder of ['apple space; literal', 'google', 'empty', 'duo']) await mkdir(path.join(root, folder));
    await writeFile(path.join(root, 'duo', 'outer.png'), png(1398, 2034));
    assert.equal(run({ directory: 'duo', target: 'apple-iphone-duo' }).status, 0);
    await writeFile(path.join(root, 'apple space; literal', '01.png'), png(1260, 2736));
    const good = run();
    assert.equal(good.status, 0);
    assert.equal(good.report.files, 1);
    assert.equal(good.report.specsVersion, '0.1.0');
    await writeFile(path.join(root, 'apple space; literal', '02.png'), png(320, 640));
    assert.equal(run().status, 1);
    assert.equal(run().report.failures, 1);
    assert.equal(run({ fail_on_error: false }).status, 0);
    await writeFile(path.join(root, 'google', '01.png'), png(1080, 1920));
    assert.equal(run({ directory: 'google', target: 'google-phone' }).report.reviews, 1);
    assert.equal(run({ directory: 'google', target: 'google-phone', fail_on_review: true }).status, 1);
    await writeFile(path.join(root, 'google', '02.png'), png(1080, 1920));
    assert.equal(run({ directory: 'google', target: 'google-phone', fail_on_review: true }).status, 0);
    await writeFile(path.join(root, 'google', '03.png'), png(1080, 1920, true));
    assert.equal(run({ directory: 'google', target: 'google-phone' }).report.failures, 1);
    await writeFile(path.join(root, 'google', '04.png'), Buffer.from('not a png'));
    const broken = run({ directory: 'google', target: 'google-phone' });
    assert.equal(broken.status, 1);
    assert.equal(broken.report.errors.length, 1);
    await symlink(path.join(root, 'google', '01.png'), path.join(root, 'google', 'link.png'));
    assert.equal(run({ directory: 'google', target: 'google-phone' }).report.errors.length, 2);
    for (const extra of [{directory:'empty'}, {directory:'missing'}, {directory:'..'}, {target:'microsoft-desktop'}, {target:'google-tablet'}, {fail_on_error:'false'}]) {
      const result = run({ fail_on_error: false, ...extra });
      assert.equal(result.status, 2);
      assert.equal(typeof result.report.error, 'string');
    }
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});

test('documentation lists precisely the supported shared targets and published installation', async () => {
  const { appleTargetIds } = await import('../vendor/validate-store-screenshots/node_modules/@grunersoftware/store-screenshot-specs/dist/index.js');
  const readme = await readFile(new URL('../README.md', import.meta.url), 'utf8');
  for (const target of [...appleTargetIds, 'google-phone']) assert.ok(readme.includes('`' + target + '`'));
  assert.match(readme, /Version 0\.1\.1 is published on RubyGems/);
  assert.match(readme, /fastlane add_plugin store_screenshot_check/);
  assert.match(readme, /fastlane-plugin-store_screenshot_check', '~> 0\.1\.1'/);
  assert.match(readme, /fastlane-plugin-store_screenshot_check/);
  assert.match(readme, /Node.js 22 or newer/);
  assert.match(readme, /24 megapixels/);
  assert.doesNotMatch(readme, /foldable-device upload slots/);
});
