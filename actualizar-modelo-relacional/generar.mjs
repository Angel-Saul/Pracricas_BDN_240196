import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, basename, resolve, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { parseDump } from '../Practica03/visor-eer/src/parser.js';

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
function option(name) {
  const index = args.indexOf(name);
  return index < 0 ? undefined : args[index + 1];
}

const inputPath = option('--input');
const outputDirArg = option('--output-dir');
if (!inputPath || !outputDirArg) {
  console.error('Uso: node actualizar-modelo-relacional/generar.mjs --input <respaldo.sql> --output-dir <carpeta>');
  process.exit(2);
}

const input = resolve(inputPath);
const outputDir = resolve(outputDirArg);
const sql = readFileSync(input, 'utf8');
const model = parseDump(sql);
if (!model.tables.length) throw new Error('No se encontraron definiciones CREATE TABLE en el archivo seleccionado.');
mkdirSync(outputDir, { recursive: true });

const domains = ['identity', 'catalog', 'commerce', 'address', 'association', 'audit'];
const domainColumn = new Map(domains.map((domain, index) => [domain, index]));
const domainRows = new Map(domains.map(domain => [domain, 0]));
function domainOf(table) {
  if (table === 'tb_users' || table === 'tb_people') return 'identity';
  if (table === 'tb_logs') return 'audit';
  if (table.startsWith('tbc_') || table === 'tb_products') return 'catalog';
  if (table === 'tb_user_addresses' || table === 'tbd_address_components') return 'address';
  if (table.startsWith('tbd_')) return 'association';
  return 'commerce';
}

const entities = model.tables.map(table => {
  const tag = domainOf(table.name);
  const row = domainRows.get(tag);
  domainRows.set(tag, row + 1);
  const maxAttributeWidth = Math.max(0, ...table.columns.map(column => {
    const comment = column.comment ? ` · ${column.comment.replace(/^['"]|['"]$/g, '')}` : '';
    return Math.ceil(column.name.length * 6 + `${column.type}${comment}`.length * 5.7);
  }));
  return {
    id: table.name,
    label: table.name,
    sublabel: `${table.columns.length} columnas`,
    tag,
    row,
    col: domainColumn.get(tag),
    width: Math.max(340, 140 + maxAttributeWidth),
    attributes: table.columns.map(column => {
      const roles = [];
      if (column.primary) roles.push('pk');
      if (column.foreign) roles.push('fk');
      if (column.unique || table.indexes.some(index => index.type.startsWith('UNIQUE') && index.columns.length === 1 && index.columns[0] === column.name)) roles.push('uk');
      const foreignKey = model.relationships.find(relation => relation.source === table.name && relation.columns.includes(column.name));
      const targetColumn = foreignKey?.targetColumns[foreignKey.columns.indexOf(column.name)];
      const comment = column.comment ? ` · ${column.comment.replace(/^['"]|['"]$/g, '')}` : '';
      return {
        name: column.name,
        type: `${column.type}${comment}`,
        ...(roles.length ? { key: roles.length === 1 ? roles[0] : roles } : {}),
        ...(foreignKey ? { references: `${foreignKey.target}.${targetColumn}` } : {}),
      };
    }),
  };
});

const triggerPattern = /\bTRIGGER\s+`([^`]+)`\s+(BEFORE|AFTER)\s+(INSERT|UPDATE|DELETE)\s+ON\s+`([^`]+)`/gi;
const triggersByTable = new Map();
const triggerWrites = new Map();
for (const match of sql.matchAll(triggerPattern)) {
  const [, name, timing, event, table] = match;
  const triggerEnd = sql.indexOf('END */;;', match.index);
  const definition = sql.slice(match.index, triggerEnd < 0 ? match.index + 20000 : triggerEnd);
  const writes = [...definition.matchAll(/\b(?:INSERT\s+INTO|REPLACE\s+INTO|UPDATE|DELETE\s+FROM)\s+`([^`]+)`/gi)].map(write => write[1]);
  if (!triggersByTable.has(table)) triggersByTable.set(table, []);
  triggersByTable.get(table).push({ name, timing, event, writes: [...new Set(writes)] });
  for (const target of new Set(writes)) {
    const key = `${table}\u0000${target}`;
    if (!triggerWrites.has(key)) triggerWrites.set(key, { from: table, to: target, triggers: [] });
    triggerWrites.get(key).triggers.push(`${name} (${timing} ${event})`);
  }
}
const foreignKeyItems = model.relationships.map(relation =>
  `${relation.source}.${relation.columns.join('+')} → ${relation.target}.${relation.targetColumns.join('+')} · ${relation.name || 'FK'}${relation.onDelete ? ` · ON DELETE ${relation.onDelete}` : ''}${relation.onUpdate ? ` · ON UPDATE ${relation.onUpdate}` : ''}`,
);
const cards = [];
if (foreignKeyItems.length) cards.push({ dot: 'cyan', title: 'Claves foráneas del respaldo', items: foreignKeyItems });
if (triggersByTable.size) cards.push({
  dot: 'amber',
  title: `Triggers del respaldo (${[...triggersByTable.values()].reduce((sum, list) => sum + list.length, 0)})`,
  items: [...triggersByTable].map(([table, names]) => `${table}: ${names.map(trigger => `${trigger.name} (${trigger.timing} ${trigger.event})`).join('; ')}`),
});

const outputHtml = resolve(outputDir, 'modelo-relacional.html');
const explorerHtmlPath = outputHtml;
const candidatePath = resolve(outputDir, 'candidate.json');
const relativeOutput = relative(projectRoot, outputHtml).split(sep).join('/');
if (relativeOutput.startsWith('../')) throw new Error('La carpeta de salida debe estar dentro del proyecto.');
const candidate = {
  schema_version: 1,
  diagram_type: 'erd',
  meta: {
    title: `Modelo relacional · ${model.database}`,
    subtitle: `${model.tables.length} tablas físicas · ${model.relationships.length} claves foráneas · respaldo: ${basename(input)}`,
    locale: 'es',
    output: relativeOutput,
    quality_profile: 'standard',
    legend: {
      mode: 'all',
      entries: {
        pk: { label: 'Clave primaria' },
        fk: { label: 'Clave foránea' },
        uk: { label: 'Única' },
        one: { label: 'Uno' },
        many: { label: 'Muchos' },
      },
    },
  },
  layout: { mode: 'grid', gapX: 68, gapY: 36 },
  entities,
  ...(cards.length ? { cards } : {}),
};

writeFileSync(candidatePath, `${JSON.stringify(candidate, null, 2)}\n`, 'utf8');
writeFileSync(resolve(outputDir, 'origen.json'), `${JSON.stringify({
  archivo: basename(input),
  sha256: createHash('sha256').update(sql).digest('hex'),
  tablas: model.tables.length,
  columnasFisicas: model.tables.reduce((sum, table) => sum + table.columns.length, 0),
  clavesForaneas: model.relationships.length,
  triggers: [...triggersByTable.values()].reduce((sum, list) => sum + list.length, 0),
  advertencias: model.warnings,
}, null, 2)}\n`, 'utf8');

const explorerData = {
  database: model.database,
  tables: model.tables.map(table => ({
    id: table.name,
    domain: domainOf(table.name),
    fields: table.columns.map(column => {
      const relation = model.relationships.find(item => item.source === table.name && item.columns.includes(column.name));
      return {
        name: column.name,
        type: column.type,
        key: [column.primary && 'PK', column.foreign && 'FK', column.unique && 'UQ'].filter(Boolean),
        reference: relation ? `${relation.target}.${relation.targetColumns[relation.columns.indexOf(column.name)]}` : '',
      };
    }),
    triggers: triggersByTable.get(table.name) || [],
  })),
  foreignKeys: model.relationships.map((relation, index) => ({
    id: `fk-${index}`, from: relation.source, to: relation.target, kind: 'fk',
    label: `${relation.source}.${relation.columns.join('+')} → ${relation.target}.${relation.targetColumns.join('+')}`,
    detail: `${relation.name || 'Clave foránea'}${relation.onDelete ? ` · ON DELETE ${relation.onDelete}` : ''}${relation.onUpdate ? ` · ON UPDATE ${relation.onUpdate}` : ''}`,
  })),
  triggerWrites: [...triggerWrites.values()].map((relation, index) => ({
    id: `trigger-${index}`, from: relation.from, to: relation.to, kind: 'trigger',
    label: `${relation.triggers.length} trigger${relation.triggers.length === 1 ? '' : 's'}`,
    detail: relation.triggers.join('; '),
  })),
};
const explorerDataJson = JSON.stringify(explorerData).replaceAll('<', '\\u003c');
const explorerHtml = `<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Modelo relacional interactivo</title>
<style>
:root{color-scheme:dark;--bg:#0b1220;--panel:#121c2d;--text:#edf4ff;--muted:#a5b5ca;--line:#32445e;--fk:#54c4e8;--trigger:#ffb454;--active:#a4f0ce}*{box-sizing:border-box}body{margin:0;background:radial-gradient(ellipse at 15% 0%,#1b3350 0,transparent 42%),var(--bg);color:var(--text);font:14px/1.45 system-ui,"Segoe UI",sans-serif}header{padding:22px 26px 12px}h1{font-size:clamp(22px,3vw,32px);margin:0 0 5px}header p{color:var(--muted);margin:3px 0}.bar{display:flex;gap:10px;align-items:center;flex-wrap:wrap;padding:0 26px 14px}.bar input,.bar button{background:var(--panel);color:var(--text);border:1px solid var(--line);border-radius:9px;padding:9px 12px}.bar input{min-width:240px}.bar button{cursor:pointer}.legend{display:flex;gap:16px;color:var(--muted);margin-left:auto}.key{display:inline-block;width:18px;border-top:3px solid var(--fk);margin-right:6px;vertical-align:middle}.key.trigger{border-color:var(--trigger);border-top-style:dashed}.layout{display:grid;grid-template-columns:minmax(0,1fr) 360px;gap:14px;padding:0 16px 24px}.canvas,.details{background:var(--panel);border:1px solid var(--line);border-radius:14px;min-width:0}.canvas{overflow:auto;min-height:550px}.canvas svg{display:block;width:100%;min-width:1120px;height:auto}.details{padding:17px;position:sticky;top:12px;align-self:start;max-height:calc(100vh - 24px);overflow:auto}.node{cursor:pointer}.node rect{fill:#17263a;stroke:#54708d;stroke-width:1.5;rx:11}.node text{fill:var(--text);font-size:13px;font-weight:650}.node .sub{fill:var(--muted);font-size:11px;font-weight:400}.node:hover rect,.node:focus rect,.node.selected rect{stroke:var(--active);stroke-width:2.5;filter:drop-shadow(0 0 8px #69d6b566)}.node:focus{outline:none}.edge{fill:none;stroke-width:2;opacity:.34;transition:opacity .18s,stroke-width .18s}.edge.fk{stroke:var(--fk);marker-end:url(#arrow-fk)}.edge.trigger{stroke:var(--trigger);stroke-dasharray:7 5;marker-end:url(#arrow-trigger)}.edge.active{opacity:1;stroke-width:3.2}.edge.dim,.node.dim{opacity:.08}.pulse{fill:white;filter:drop-shadow(0 0 5px #fff);pointer-events:none}.domain{fill:#91a6c0;font-size:11px;font-weight:700;letter-spacing:2px;text-transform:uppercase}.hint,.minor{color:var(--muted)}.table-name{font-size:19px;margin:0 0 2px}.section{margin-top:17px}.section h3{font-size:11px;text-transform:uppercase;letter-spacing:.08em;color:var(--muted);margin:0 0 7px}.field{padding:7px 0;border-bottom:1px solid #28364a}.field strong{overflow-wrap:anywhere}.field span{display:block;color:var(--muted);overflow-wrap:anywhere;font-size:12px}.ref{color:#80d7f0!important}.flow{padding:7px 0;border-bottom:1px solid #28364a;overflow-wrap:anywhere}.flow small{display:block;color:var(--muted)}@media(max-width:1050px){.layout{grid-template-columns:1fr}.details{position:static;max-height:none}.legend{margin-left:0;width:100%}}@media(prefers-reduced-motion:reduce){*{transition:none!important}}
</style></head><body>
<header><h1>Modelo relacional · ${model.database}</h1><p>${model.tables.length} tablas · ${model.relationships.length} claves foráneas · ${[...triggersByTable.values()].reduce((n, list) => n + list.length, 0)} triggers</p><p>Selecciona una tabla: se resaltan sus relaciones y se anima el recorrido de las referencias y escrituras declaradas.</p></header>
<div class="bar"><input id="search" type="search" placeholder="Buscar tabla"><button id="clear" type="button">Mostrar todo</button><button id="motion" type="button">Pausar animación</button><div class="legend"><span><i class="key"></i>Referencia FK</span><span><i class="key trigger"></i>Escritura de trigger</span></div></div>
<main class="layout"><section class="canvas" aria-label="Mapa de relaciones"><svg id="map" role="img" aria-label="Flechas entre tablas"></svg></section><aside class="details" id="details"><p class="hint">Las flechas azules muestran la referencia desde la tabla que contiene la FK hacia la tabla referenciada. Las flechas ámbar muestran escrituras que aparecen en el cuerpo de un trigger. Una FK expresa una referencia, no que la fila se copie.</p></aside></main>
<script type="application/json" id="model-data">${explorerDataJson}</script><script>
(()=>{const d=JSON.parse(document.getElementById('model-data').textContent),svg=document.getElementById('map'),ns='http://www.w3.org/2000/svg',W=220,H=60,GX=34,GY=28,L=30,T=54,domains=['identity','catalog','commerce','address','association','audit'],counts={};domains.forEach(x=>counts[x]=0);d.tables.forEach(x=>counts[x.domain]=(counts[x.domain]||0)+1);const maxRows=Math.max(1,...Object.values(counts)),width=L*2+domains.length*W+(domains.length-1)*GX,height=T+maxRows*(H+GY)+26;svg.setAttribute('viewBox','0 0 '+width+' '+height);svg.setAttribute('preserveAspectRatio','xMinYMin meet');svg.innerHTML='<defs><marker id="arrow-fk" markerWidth="9" markerHeight="9" refX="8" refY="4.5" orient="auto"><path d="M0 0L9 4.5L0 9Z" fill="#54c4e8"/></marker><marker id="arrow-trigger" markerWidth="9" markerHeight="9" refX="8" refY="4.5" orient="auto"><path d="M0 0L9 4.5L0 9Z" fill="#ffb454"/></marker></defs><g id="edges"></g><g id="labels"></g><g id="nodes"></g><g id="pulses"></g>';const pmap=new Map(),nmap=new Map(),rows={};domains.forEach(x=>rows[x]=0);const labelLayer=svg.querySelector('#labels'),nodeLayer=svg.querySelector('#nodes');domains.forEach((name,i)=>{const x=svgEl('text');x.setAttribute('class','domain');x.setAttribute('x',L+i*(W+GX));x.setAttribute('y',25);x.textContent=name;labelLayer.append(x)});d.tables.forEach(t=>{const c=domains.indexOf(t.domain),r=rows[t.domain]++,x=L+c*(W+GX),y=T+r*(H+GY);t.pos={x:x,y:y,cx:x+W/2,cy:y+H/2};const g=svgEl('g');g.setAttribute('class','node');g.setAttribute('tabindex','0');g.setAttribute('role','button');g.setAttribute('aria-label',t.id+', '+t.fields.length+' columnas');g.dataset.table=t.id;const rect=svgEl('rect');rect.setAttribute('x',x);rect.setAttribute('y',y);rect.setAttribute('width',W);rect.setAttribute('height',H);const a=svgEl('text');a.setAttribute('x',x+11);a.setAttribute('y',y+24);a.textContent=t.id;const b=svgEl('text');b.setAttribute('class','sub');b.setAttribute('x',x+11);b.setAttribute('y',y+44);b.textContent=t.fields.length+' columnas · '+t.triggers.length+' triggers';g.append(rect,a,b);g.addEventListener('click',()=>select(t.id));g.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();select(t.id)}});nodeLayer.append(g);nmap.set(t.id,g)});function svgEl(tag){return document.createElementNS(ns,tag)}const edges=d.foreignKeys.concat(d.triggerWrites),edgeLayer=svg.querySelector('#edges');function route(e,i){const a=d.tables.find(x=>x.id===e.from).pos,b=d.tables.find(x=>x.id===e.to).pos;if(a===b)return 'M '+(a.cx+38)+' '+a.y+' C '+(a.cx+68)+' '+(a.y-48)+' '+(a.cx-68)+' '+(a.y-48)+' '+(a.cx-38)+' '+a.y;const dx=b.cx-a.cx,dy=b.cy-a.cy,k=Math.min((W/2-7)/Math.max(1,Math.abs(dx)),(H/2-7)/Math.max(1,Math.abs(dy))),sx=a.cx+dx*k,sy=a.cy+dy*k,ex=b.cx-dx*k,ey=b.cy-dy*k,len=Math.hypot(ex-sx,ey-sy)||1,bend=((i%5)-2)*12,cx=(sx+ex)/2-(ey-sy)/len*bend,cy=(sy+ey)/2+(ex-sx)/len*bend;return 'M '+sx+' '+sy+' Q '+cx+' '+cy+' '+ex+' '+ey}edges.forEach((e,i)=>{if(!nmap.has(e.from)||!nmap.has(e.to))return;const p=svgEl('path');p.setAttribute('id',e.id);p.setAttribute('d',route(e,i));p.setAttribute('class','edge '+e.kind);p.dataset.from=e.from;p.dataset.to=e.to;const title=svgEl('title');title.textContent=e.label+' · '+e.detail;p.append(title);edgeLayer.append(p);pmap.set(e.id,p)});function esc(x){return String(x).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))}function list(items,fmt){return items.length?items.map(fmt).join(''):'<p class="minor">Sin rutas declaradas.</p>'}function select(id){const t=d.tables.find(x=>x.id===id);if(!t)return;for(const [name,n] of nmap){const linked=edges.some(e=>(e.from===id&&e.to===name)||(e.to===id&&e.from===name));n.classList.toggle('selected',name===id);n.classList.toggle('dim',name!==id&&!linked)}const pulses=svg.querySelector('#pulses');pulses.replaceChildren();for(const [key,p] of pmap){const on=p.dataset.from===id||p.dataset.to===id;p.classList.toggle('active',on);p.classList.toggle('dim',!on);if(on){const dot=svgEl('circle');dot.setAttribute('r','5');dot.setAttribute('class','pulse');const motion=svgEl('animateMotion');motion.setAttribute('dur','1.7s');motion.setAttribute('repeatCount','indefinite');motion.setAttribute('rotate','auto');const path=svgEl('mpath');path.setAttribute('href','#'+key);motion.append(path);dot.append(motion);pulses.append(dot)}}const fkOut=d.foreignKeys.filter(e=>e.from===id),fkIn=d.foreignKeys.filter(e=>e.to===id),twOut=d.triggerWrites.filter(e=>e.from===id),twIn=d.triggerWrites.filter(e=>e.to===id);document.getElementById('details').innerHTML='<div class="domain">'+esc(t.domain)+'</div><h2 class="table-name">'+esc(t.id)+'</h2><p class="minor">'+t.fields.length+' columnas · '+t.triggers.length+' triggers</p><section class="section"><h3>Campos</h3>'+t.fields.map(f=>'<div class="field"><strong>'+esc(f.name)+(f.key.length?' <span style="color:var(--active)">['+esc(f.key.join(' · '))+']</span>':'')+'</strong><span>'+esc(f.type)+'</span>'+(f.reference?'<span class="ref">Referencia → '+esc(f.reference)+'</span>':'')+'</div>').join('')+'</section><section class="section"><h3>FK salientes ('+fkOut.length+')</h3>'+list(fkOut,e=>'<div class="flow">'+esc(e.from)+' → '+esc(e.to)+'<small>'+esc(e.label+' · '+e.detail)+'</small></div>')+'</section><section class="section"><h3>FK entrantes ('+fkIn.length+')</h3>'+list(fkIn,e=>'<div class="flow">'+esc(e.from)+' → '+esc(e.to)+'<small>'+esc(e.label+' · '+e.detail)+'</small></div>')+'</section><section class="section"><h3>Escrituras de trigger</h3>'+list(twOut,e=>'<div class="flow">'+esc(e.from)+' → '+esc(e.to)+'<small>'+esc(e.detail)+'</small></div>')+(twIn.length?'<h3>Recibe escrituras de trigger</h3>'+list(twIn,e=>'<div class="flow">'+esc(e.from)+' → '+esc(e.to)+'<small>'+esc(e.detail)+'</small></div>'):'')+'</section><section class="section"><h3>Triggers declarados</h3>'+list(t.triggers,x=>'<div class="flow">'+esc(x.name)+'<small>'+esc(x.timing+' '+x.event)+(x.writes.length?' · escribe en '+esc(x.writes.join(', ')):' · no se detectó escritura')+'</small></div>')+'</section>'}document.getElementById('clear').addEventListener('click',()=>{nmap.forEach(n=>n.classList.remove('selected','dim'));pmap.forEach(p=>p.classList.remove('active','dim'));svg.querySelector('#pulses').replaceChildren();document.getElementById('details').innerHTML='<p class="hint">Selecciona una tabla. Flechas azules: referencias FK desde la tabla hija hacia la referenciada. Flechas ámbar: escrituras detectadas en triggers.</p>'});document.getElementById('search').addEventListener('input',e=>{const q=e.target.value.toLowerCase();nmap.forEach((n,id)=>n.style.display=id.toLowerCase().includes(q)?'':'none')});document.getElementById('motion').addEventListener('click',e=>{if(svg.animationsPaused()){svg.unpauseAnimations();e.currentTarget.textContent='Pausar animación'}else{svg.pauseAnimations();e.currentTarget.textContent='Reanudar animación'}})})();
</script></body></html>`;
// Archify writes the single deliverable HTML below; the flow data is embedded into it afterward.

const home = process.env.USERPROFILE || process.env.HOME;
const archifyCli = process.env.ARCHIFY_CLI || resolve(home || projectRoot, '.agents', 'skills', 'archify', 'bin', 'archify.mjs');
const result = spawnSync(process.execPath, [archifyCli, 'finalize', 'erd', candidatePath, outputHtml, '--quality', 'standard', '--json'], {
  cwd: projectRoot,
  encoding: 'utf8',
  maxBuffer: 16 * 1024 * 1024,
});
if (result.error) console.warn(`No se pudo ejecutar Archify: ${result.error.message}`);
if (result.stderr) process.stderr.write(result.stderr);
if (result.status !== 0) {
  const summaryPath = resolve(outputDir, 'modelo-relacional.finalize-summary.json');
  const summary = existsSync(summaryPath) ? JSON.parse(readFileSync(summaryPath, 'utf8')) : null;
  const failedStage = summary?.failedStage || 'desconocido';
  if (failedStage === 'browser-check' && existsSync(outputHtml)
    && summary.gates?.validate === 'pass'
    && summary.gates?.deliver === 'pass'
    && summary.gates?.check === 'pass') {
    console.warn('Archify generó el HTML y pasó validate, deliver y check, pero browser-check encontró observaciones de legibilidad o ajuste de pantalla.');
    for (const diagnostic of summary.diagnostics || []) console.warn(`- ${diagnostic.message}`);
    console.log(`Modelo generado: ${outputHtml}`);
  } else {
    console.error(`Archify se detuvo en ${failedStage}.`);
    for (const diagnostic of summary?.diagnostics || []) console.error(`- ${diagnostic.message}`);
    console.error(`El candidato y el inventario quedaron en: ${outputDir}`);
    process.exit(result.status || 1);
  }
} else {
  console.log(result.stdout.trim());
}
console.log(`\nHTML de Archify: ${outputHtml}`);
if (!existsSync(outputHtml)) {
  throw new Error('Archify no entregó el HTML; revisa los diagnósticos anteriores.');
}

const flowEnhancement = `<script type="application/json" id="archify-flow-data">${explorerDataJson}</script>
<style id="archify-flow-style">
svg[data-erd-ui="cards"] .af-edge{fill:none;stroke-width:2.4;opacity:.24;pointer-events:none;transition:opacity .2s,stroke-width .2s}svg[data-erd-ui="cards"] .af-edge.fk{stroke:#38bdf8;marker-end:url(#af-arrow-fk)}svg[data-erd-ui="cards"] .af-edge.trigger{stroke:#fb923c;stroke-dasharray:7 5;marker-end:url(#af-arrow-trigger)}svg[data-erd-ui="cards"] .af-edge.af-dim{opacity:.035}svg[data-erd-ui="cards"] .af-edge.af-active{opacity:1;stroke-width:3.8;filter:drop-shadow(0 0 3px #fff6)}svg[data-erd-ui="cards"] .af-pulse{fill:#fff;stroke:#fff;filter:drop-shadow(0 0 5px #fff);pointer-events:none}svg[data-erd-ui="cards"] [data-node-id].af-dim{opacity:.2}svg[data-erd-ui="cards"] [data-node-id].af-selected .er-table{stroke:#a4f0ce;stroke-width:3;filter:drop-shadow(0 0 5px #69d6b566)}.af-flow-card .af-flow-note{font-size:12px;color:var(--text-muted,#a5b5ca);line-height:1.45}.af-flow-card li.af-flow-row{font-size:12px;padding:5px 0;border-top:1px solid var(--lane-stroke,#32445e);overflow-wrap:anywhere}.af-flow-card li.af-flow-row small{display:block;color:var(--text-muted,#a5b5ca)}
</style>
<script>
(()=>{const d=JSON.parse(document.getElementById('archify-flow-data').textContent),svg=document.querySelector('svg[data-erd-ui="cards"]');if(!svg)return;const ns='http://www.w3.org/2000/svg',nodes=new Map(),paths=new Map(),el=t=>document.createElementNS(ns,t);for(const t of d.tables){const g=[...svg.querySelectorAll('[data-node-id]')].find(n=>n.dataset.nodeId===t.id),r=g&&g.querySelector('.er-table');if(g&&r){const b=r.getBBox();nodes.set(t.id,{group:g,box:{x:b.x,y:b.y,w:b.width,h:b.height,cx:b.x+b.width/2,cy:b.y+b.height/2}})}}const defs=svg.querySelector('defs')||svg.insertBefore(el('defs'),svg.firstChild);for(const [id,color]of [['af-arrow-fk','#38bdf8'],['af-arrow-trigger','#fb923c']]){const m=el('marker'),p=el('path');m.id=id;m.setAttribute('markerWidth','9');m.setAttribute('markerHeight','9');m.setAttribute('refX','8');m.setAttribute('refY','4.5');m.setAttribute('orient','auto');p.setAttribute('d','M0 0L9 4.5L0 9Z');p.setAttribute('fill',color);m.append(p);defs.append(m)}const layer=el('g');layer.setAttribute('aria-label','Flechas de datos por FK y triggers');svg.insertBefore(layer,svg.querySelector('[data-node-id]')||null);const edges=d.foreignKeys.concat(d.triggerWrites);function route(e,i){const a=nodes.get(e.from)?.box,b=nodes.get(e.to)?.box;if(!a||!b)return '';if(e.from===e.to)return 'M '+(a.cx+34)+' '+a.y+' C '+(a.cx+82)+' '+(a.y-54)+' '+(a.cx-82)+' '+(a.y-54)+' '+(a.cx-34)+' '+a.y;const dx=b.cx-a.cx,dy=b.cy-a.cy,ang=Math.atan2(dy,dx),ca=Math.abs(Math.cos(ang)),sa=Math.abs(Math.sin(ang)),ra=Math.min((a.w/2-5)/Math.max(.001,ca),(a.h/2-5)/Math.max(.001,sa)),rb=Math.min((b.w/2-14)/Math.max(.001,ca),(b.h/2-14)/Math.max(.001,sa)),sx=a.cx+Math.cos(ang)*ra,sy=a.cy+Math.sin(ang)*ra,ex=b.cx-Math.cos(ang)*rb,ey=b.cy-Math.sin(ang)*rb,len=Math.hypot(ex-sx,ey-sy)||1,o=((i%5)-2)*13,cx=(sx+ex)/2-(ey-sy)/len*o,cy=(sy+ey)/2+(ex-sx)/len*o;return 'M '+sx+' '+sy+' Q '+cx+' '+cy+' '+ex+' '+ey}edges.forEach((e,i)=>{const p=el('path');p.id='af-flow-'+i;p.setAttribute('d',route(e,i));p.setAttribute('class','af-edge '+e.kind);p.dataset.from=e.from;p.dataset.to=e.to;const title=el('title');title.textContent=e.label+' · '+e.detail;p.append(title);layer.append(p);paths.set(p.id,p)});let cards=document.querySelector('.cards'),card;if(cards){card=document.createElement('section');card.className='card af-flow-card';card.innerHTML='<div class="card-header"><div class="card-dot emerald"></div><h3>Recorrido seleccionado</h3></div><p class="af-flow-note">Selecciona una tabla para resaltar y animar sus relaciones.</p><button type="button" class="af-flow-clear">Limpiar selección</button>';cards.append(card)}function pulse(path){const dot=el('circle'),anim=el('animateMotion'),ref=el('mpath');dot.setAttribute('r','5');dot.setAttribute('class','af-pulse');anim.setAttribute('dur','1.7s');anim.setAttribute('repeatCount','indefinite');anim.setAttribute('rotate','auto');ref.setAttribute('href','#'+path.id);anim.append(ref);dot.append(anim);layer.append(dot)}function select(id){if(!nodes.has(id))return;for(const [name,n]of nodes){const connected=edges.some(e=>(e.from===id&&e.to===name)||(e.to===id&&e.from===name));n.group.classList.toggle('af-selected',name===id);n.group.classList.toggle('af-dim',name!==id&&!connected)}layer.querySelectorAll('.af-pulse').forEach(x=>x.remove());for(const p of paths.values()){const active=p.dataset.from===id||p.dataset.to===id;p.classList.toggle('af-active',active);p.classList.toggle('af-dim',!active);if(active)pulse(p)}if(card){const fkOut=d.foreignKeys.filter(e=>e.from===id),fkIn=d.foreignKeys.filter(e=>e.to===id),twOut=d.triggerWrites.filter(e=>e.from===id),twIn=d.triggerWrites.filter(e=>e.to===id);card.querySelector('.af-flow-note').textContent='Tabla: '+id+'. Las FK indican referencias; los triggers muestran escrituras declaradas en el SQL.';let list=card.querySelector('ul');if(!list){list=document.createElement('ul');card.append(list)}list.replaceChildren();for(const [heading,items]of [['FK salientes',fkOut],['FK entrantes',fkIn],['Escrituras de trigger',twOut],['Recibe escrituras',twIn]]){if(!items.length)continue;const h=document.createElement('li');h.textContent=heading;h.style.fontWeight='700';list.append(h);for(const e of items){const li=document.createElement('li');li.className='af-flow-row';li.textContent=e.from+' → '+e.to+' · '+e.label;const small=document.createElement('small');small.textContent=e.detail;li.append(small);list.append(li)}}}}svg.addEventListener('click',e=>{const n=e.target.closest('[data-node-id]');if(n)select(n.dataset.nodeId)},true);card?.querySelector('.af-flow-clear').addEventListener('click',()=>{nodes.forEach(n=>n.group.classList.remove('af-selected','af-dim'));paths.forEach(p=>p.classList.remove('af-active','af-dim'));layer.querySelectorAll('.af-pulse').forEach(x=>x.remove());card.querySelector('.af-flow-note').textContent='Selecciona una tabla para resaltar y animar sus relaciones.'})})();
</script>`;
const archifyHtml = readFileSync(outputHtml, 'utf8');
if (!archifyHtml.includes('id="archify-flow-data"')) {
  const close = archifyHtml.lastIndexOf('</body>');
  if (close < 0) throw new Error('El HTML generado por Archify no contiene </body>.');
  writeFileSync(outputHtml, archifyHtml.slice(0, close) + flowEnhancement + '\n' + archifyHtml.slice(close), 'utf8');
}
console.log(`HTML de Archify con flechas y animación: ${outputHtml}`);
