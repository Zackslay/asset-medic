import { mkdir, readFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
const root = fileURLToPath(new URL('../', import.meta.url));
const { version } = JSON.parse(await readFile(new URL('../package.json', import.meta.url), 'utf8'));
await mkdir(new URL('../dist/', import.meta.url), { recursive: true });
const fixture = process.argv.includes('--fixture');
const output = fixture ? 'dist/AssetMedic-TestPlace.rbxlx' : `dist/AssetMedic-${version}.rbxmx`;
const result = spawnSync('rojo', ['build', fixture ? 'fixture.project.json' : 'default.project.json', '-o', output], {
  cwd: root, stdio: 'inherit', shell: false,
});
if (result.error) throw result.error;
process.exitCode = result.status ?? 1;
