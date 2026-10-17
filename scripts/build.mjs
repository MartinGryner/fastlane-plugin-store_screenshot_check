import { build } from '../vendor/validate-store-screenshots/node_modules/esbuild/lib/main.js';
import { copyFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
const root = new URL('../', import.meta.url);
await build({
  entryPoints: [fileURLToPath(new URL('scripts/validate.mjs', root))],
  bundle: true, platform: 'node', target: 'node22', format: 'cjs',
  outfile: fileURLToPath(new URL('lib/fastlane/plugin/store_screenshot_check/helper/validate.cjs', root)),
});
await copyFile(new URL('../vendor/validate-store-screenshots/THIRD_PARTY_LICENSES.txt', import.meta.url), new URL('THIRD_PARTY_LICENSES.txt', root));
