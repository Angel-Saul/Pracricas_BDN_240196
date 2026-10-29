import { readFileSync, statSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { parseDump } from '../Practica03/visor-eer/src/parser.js';

const dir = new URL('./', import.meta.url);
const file = name => new URL(name, dir);
const sql = readFileSync(new URL('../Practica03/backups/240196_20.10.26.sql', import.meta.url), 'utf8');
const model = parseDump(sql);
const docs = JSON.parse(readFileSync(file('dictionary.json'), 'utf8'));
const html = readFileSync(file('diccionario.html'), 'utf8');
const csvRaw = readFileSync(file('diccionario-campos.csv'));
const csv = csvRaw.toString('utf8').replace(/^\uFEFF/, '');
const annex = readFileSync(file('anexo-tecnico-mysql.sql'), 'utf8');
const report = readFileSync(file('informe-validacion.md'), 'utf8');

function parseCsv(text) {
  const records = []; let row = [], cell = '', quoted = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (quoted) {
      if (ch === '"' && text[i + 1] === '"') { cell += '"'; i++; }
      else if (ch === '"') quoted = false;
      else cell += ch;
    } else if (ch === '"') quoted = true;
    else if (ch === ',') { row.push(cell); cell = ''; }
    else if (ch === '\n') { row.push(cell.replace(/\r$/, '')); records.push(row); row = []; cell = ''; }
    else cell += ch;
  }
  if (cell || row.length) { row.push(cell.replace(/\r$/, '')); records.push(row); }
  return records;
}
const records = parseCsv(csv);
const script = html.match(/<script>([\s\S]*?)<\/script>/i)?.[1];
new Function('document', script);
class Element {
  value = ''; innerHTML = ''; textContent = ''; listeners = {}; onclick = null;
  insertAdjacentHTML(_position, markup) { this.innerHTML += markup; }
  addEventListener(event, callback) { this.listeners[event] = callback; }
  click() { this.onclick?.(); }
}
const selectors = ['#metrics','#rowcounts','#nature','#type','#origin','#class','#constraint','#search','#clear','#table-nav','#table-list','#erd','#relations-list','#objects','#glossary','#sqlnote'];
const elements = new Map(selectors.map(selector => [selector, new Element()]));
new Function('document', script)({ querySelector: selector => elements.get(selector) });
const occurrences = (value, regex) => [...value.matchAll(regex)].length;
const tableCards = () => occurrences(elements.get('#table-list').innerHTML, /<article class="tablecard"/g);
const fieldCards = () => occurrences(elements.get('#table-list').innerHTML, /<details class="field"/g);
const initialTables = tableCards(), initialFields = fieldCards(), diagramPathTags = occurrences(elements.get('#erd').innerHTML, /<path d=/g), diagramEdges = diagramPathTags - 1;
elements.get('#search').value = 'tb_products'; elements.get('#search').listeners.input(); const searchNarrows = tableCards() > 0 && tableCards() < 19;
elements.get('#search').value = ''; elements.get('#nature').value = 'Identificador'; elements.get('#nature').listeners.change(); const natureNarrows = fieldCards() > 0 && fieldCards() < 147;
elements.get('#nature').value = ''; elements.get('#nature').listeners.change(); elements.get('#constraint').value = 'fk'; elements.get('#constraint').listeners.change(); const fkFilterWorks = tableCards() > 0;
elements.get('#clear').click(); const clearRestores = tableCards() === 19;
const allTables = docs.tables.map(t => t.name).sort().join('|') === model.tables.map(t => t.name).sort().join('|');
const allFields = docs.tables.reduce((sum, t) => sum + t.fields.length, 0) === model.tables.reduce((sum, t) => sum + t.columns.length, 0);
const allRelations = docs.relationships.length === model.relationships.length;
const typeAndKeysMatch = docs.tables.every(t=>{const source=model.tables.find(x=>x.name===t.name);return !!source&&t.fields.every(f=>source.columns.find(c=>c.name===f.name)?.type===f.type)&&t.primaryKey.join('|')===source.primaryKey.join('|')});
const fkNamesMatch = docs.relationships.map(r=>r.name).sort().join('|')===model.relationships.map(r=>r.name).sort().join('|');
const csvColumns = records[0]?.length;
const csvValid = records.length === 1 + docs.summary.columns && csvColumns === 31 && records.every(record => record.length === csvColumns);
const objectCounts = {
  tables: occurrences(annex, /^CREATE TABLE /gm),
  views: occurrences(annex, /VIEW `/g),
  triggers: occurrences(annex, /TRIGGER `/g),
  procedures: occurrences(annex, / PROCEDURE `/g),
  dropStatements: occurrences(annex, /^\s*DROP /gmi),
  lockStatements: occurrences(annex, /^\s*LOCK TABLES/gmi),
};
const hash = createHash('sha256').update(sql).digest('hex');
const reportedHash = report.match(/SHA-256 fuente: ([a-f0-9]{64})/)?.[1];
const personalEmailPatternFound = /[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}/.test(html + '\n' + csv + '\n' + annex);
const results = {
  html: { bytes: Buffer.byteLength(html), scriptParses: true, tableCards: initialTables, fieldCards: initialFields, searchNarrows, natureNarrows, foreignKeyFilterWorks: fkFilterWorks, clearRestores, relationEdges: diagramEdges },
  csv: { dataRows: records.length - 1, columns: csvColumns, rowWidths:[...new Set(records.map(record=>record.length))], firstInvalidRow:records.findIndex(record=>record.length!==csvColumns), rectangular: csvValid, utf8Bom: csvRaw.subarray(0, 3).equals(Buffer.from([239, 187, 191])) },
  sqlAppendix: objectCounts,
  coverage: { allTables, allPhysicalColumns: allFields, allTypesAndPrimaryKeys: typeAndKeysMatch, allForeignKeyNames: fkNamesMatch, allRelationships: allRelations, personalEmailPatternFound },
  source: { sha256MatchesReport: hash === reportedHash, bytes: statSync(new URL('../Practica03/backups/240196_20.10.26.sql', import.meta.url)).size },
};
console.log(JSON.stringify(results, null, 2));
if (!results.html.scriptParses || initialTables !== 19 || initialFields !== 147 || !searchNarrows || !natureNarrows || !fkFilterWorks || !clearRestores || diagramEdges !== 25 || !csvValid || !allTables || !allFields || !typeAndKeysMatch || !fkNamesMatch || !allRelations || personalEmailPatternFound || hash !== reportedHash || objectCounts.tables !== 19 || objectCounts.views !== 19 || objectCounts.triggers !== 54 || objectCounts.procedures !== 1 || objectCounts.dropStatements || objectCounts.lockStatements) process.exitCode = 1;
