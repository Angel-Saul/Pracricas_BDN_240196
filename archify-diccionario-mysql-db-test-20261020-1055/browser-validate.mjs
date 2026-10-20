import { spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const browser = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const html = resolve('archify-diccionario-mysql-db-test-20261020-1055/diccionario.html');
const profile = mkdtempSync(join(tmpdir(), 'codex-dictionary-edge-'));
try {
  const run = spawnSync(browser, [
    '--headless','--no-sandbox','--disable-gpu','--disable-extensions','--disable-background-networking','--disable-sync','--no-first-run','--disable-default-apps',
    `--user-data-dir=${profile}`,'--virtual-time-budget=15000','--dump-dom',pathToFileURL(html).href,
  ], { encoding:'utf8', timeout:60000, maxBuffer:8*1024*1024, windowsHide:true });
  const dom = run.stdout || '';
  const renderedDom = dom.replace(/<script[\s\S]*?<\/script>/gi,'');
  const result = {
    exitCode:run.status,
    title:dom.match(/<title>([^<]*)<\/title>/i)?.[1]||'',
    tableCards:(renderedDom.match(/<article class="tablecard" id="t-/g)||[]).length,
    fieldCards:(renderedDom.match(/<details class="field"/g)||[]).length,
    relationPanels:(renderedDom.match(/class="relation"/g)||[]).length,
    hasSearch:renderedDom.includes('id="search"'),
    hasFilter:renderedDom.includes('id="nature"')&&renderedDom.includes('id="type"')&&renderedDom.includes('id="constraint"'),
    hasRelationLinks:renderedDom.includes('href="#r-'),
    hasError:/Uncaught|SyntaxError|ReferenceError/.test(dom),
    stderr:(run.stderr||'').slice(0,500),
  };
  console.log(JSON.stringify(result,null,2));
  if (run.error || run.status!==0 || result.tableCards!==19 || result.fieldCards<147 || !result.hasSearch || !result.hasFilter || !result.hasRelationLinks || result.hasError) process.exitCode=1;
} finally {
  rmSync(profile,{recursive:true,force:true});
}
