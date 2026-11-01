import { readFile, readdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { LuauState } from 'luau-web';

const root = fileURLToPath(new URL('../', import.meta.url));
const state = await LuauState.createAsync({ print: (...args) => console.log(...args) });
try {
  const sources = {};
  for (const name of await readdir(path.join(root, 'src'))) {
    if (!name.endsWith('.luau')) continue;
    const source = await readFile(path.join(root, 'src', name), 'utf8');
    state.loadstring(source, name, true); // Compile every shipped script, including the UI.
    sources[name.replace('.luau', '')] = source;
  }
  const order = ['Ids', 'Properties', 'Scanner', 'Replacement', 'Controller'];
  const prelude = order.map(name => {
    const source = sources[name];
    if (!source) throw new Error(`Missing production module: ${name}`);
    return `local ${name} = (function()\n${source.replace(/require\(script\.Parent\.(\w+)\)/g, '$1')}\nend)()`;
  }).join('\n');
  const tests = await readFile(path.join(root, 'tests/core.spec.luau'), 'utf8');
  state.loadstring(await readFile(path.join(root, 'tests/studio.spec.luau'), 'utf8'), 'studio.spec', true);
  state.loadstring(await readFile(path.join(root, 'tests/ui.spec.luau'), 'utf8'), 'ui.spec', true);
  await state.loadstring(`${prelude}\n${tests}`, 'core.spec', true)();
} finally {
  state.destroy();
}
