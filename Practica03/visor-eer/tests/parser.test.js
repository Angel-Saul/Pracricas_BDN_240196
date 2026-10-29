import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { parseDump } from '../src/parser.js';

test('extrae referencias compuestas, nulabilidad, default e índices y cuenta filas multilínea',()=>{
  const sql=`CREATE TABLE \`parent\` (\`a\` int NOT NULL, \`b\` int NOT NULL, PRIMARY KEY (\`a\`,\`b\`));
  CREATE TABLE \`child\` (\`x\` int NOT NULL, \`y\` int NOT NULL, \`label\` varchar(8) DEFAULT 'a, b', UNIQUE KEY \`uq\` (\`x\`,\`y\`), CONSTRAINT \`fk_xy\` FOREIGN KEY (\`x\`, \`y\`) REFERENCES \`parent\` (\`a\`,\`b\`) ON DELETE CASCADE ON UPDATE RESTRICT);
  INSERT INTO \`child\` VALUES (1,2,'it''s, ok'),
    (3,4,'line\\'s value');`;
  const result=parseDump(sql), child=result.tables.find(t=>t.name==='child');
  assert.deepEqual(child.primaryKey,[]);assert.equal(child.columns.find(c=>c.name==='label').defaultValue,"'a, b'");assert.equal(child.columns.find(c=>c.name==='x').foreign,true);
  assert.equal(result.relationships[0].columns.length,2);assert.equal(result.relationships[0].targetColumns.length,2);assert.equal(result.relationships[0].onDelete,'CASCADE');assert.equal(result.relationships[0].cardinality,'1:1');assert.equal(result.counts.get('child').value,2);
});

test('no cuenta comentarios o escrituras dentro de procedimientos',()=>{
  const sql=`CREATE TABLE \`items\` (\`id\` int PRIMARY KEY);
  -- INSERT INTO items VALUES (90);
  INSERT INTO items VALUES (1),(2);
  DELIMITER ;;
  CREATE PROCEDURE \`change_items\`() BEGIN INSERT INTO items VALUES (3); UPDATE items SET id=4; END;;
  DELIMITER ;`;
  const result=parseDump(sql);assert.equal(result.counts.get('items').value,2);assert.equal(result.counts.get('items').status,'exact');
});

test('invalida el conteo ante cambios de filas ejecutables no reducibles',()=>{
  const sql=`CREATE TABLE items (id int PRIMARY KEY);
  INSERT INTO items VALUES (1),(2);
  UPDATE items SET id = 3 WHERE id = 2;`;
  const count=parseDump(sql).counts.get('items');assert.equal(count.status,'unknown');assert.equal(count.value,null);
});

test('marca cargas externas como conteo desconocido',()=>{
  const sql=`CREATE TABLE items (id int PRIMARY KEY);
  LOAD DATA LOCAL INFILE 'rows.csv' INTO TABLE items;`;
  const count=parseDump(sql).counts.get('items');assert.equal(count.status,'unknown');assert.equal(count.value,null);
});

test('extrae columnas clave inline, precision decimal y tablas IF NOT EXISTS',()=>{
  const result=parseDump(`CREATE TABLE IF NOT EXISTS sample (id int PRIMARY KEY, code varchar(12) UNIQUE, amount decimal(12,2) NOT NULL DEFAULT 1.25);`);
  const table=result.tables[0];assert.deepEqual(table.primaryKey,['id']);assert.equal(table.columns.find(c=>c.name==='amount').type,'decimal(12,2)');assert.equal(table.columns.find(c=>c.name==='amount').nullable,false);assert.equal(table.columns.find(c=>c.name==='amount').defaultValue,'1.25');assert.equal(table.columns.find(c=>c.name==='code').unique,true);
});

test('el respaldo del curso se analiza y sus conteos quedan derivados del dump',async()=>{
  const sql=await readFile(new URL('../../backups/240196_13.10.26.sql',import.meta.url),'utf8');
  const result=parseDump(sql);assert.equal(result.tables.length,14);assert.equal(result.views.length,6);assert.ok(result.statistics.columns>0);assert.ok(result.relationships.length>0);
  assert.ok(result.tables.every(t=>t.columns.length>0));assert.ok(result.relationships.every(r=>r.columns.length===r.targetColumns.length));
  assert.ok(result.views.every(view=>view.definitionState==='final'&&view.definition.includes('VIEW')));
  assert.equal(result.counts.get('tb_logs').value,37259);assert.equal(result.counts.get('tb_products').value,15007);assert.equal(result.counts.get('tbd_products_categories').value,22146);
  for(const [name,count] of result.counts)assert.equal(result.rows.get(name).length,count.value,`row parser count for ${name}`);
  assert.equal([...result.counts.values()].reduce((total,count)=>total+(count.value||0),0),74521);assert.ok([...result.counts.values()].every(count=>count.status==='exact'));
  assert.ok([...result.counts.values()].every(c=>c.status==='exact'||c.status==='unknown'));
});
