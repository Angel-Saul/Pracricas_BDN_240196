import test from 'node:test';
import assert from 'node:assert/strict';
import { analyzeRelation, findRelationshipPath, buildRouteTransitions } from '../src/relationAnalyzer.js';

test('compara todos los componentes FK y excluye NULL de las coincidencias',()=>{
  const parentRows=[{a:'1',b:'A'},{a:'2',b:'B'}];
  const childRows=[{x:'1',y:'A'},{x:'1',y:null},{x:'9',y:'Z'}];
  const relation={source:'child',columns:['x','y'],target:'parent',targetColumns:['a','b']};
  const model={rows:new Map([['child',childRows],['parent',parentRows]]),counts:new Map([['child',{status:'exact'}],['parent',{status:'exact'}]])};
  const result=analyzeRelation(model,relation);assert.equal(result.matchedSourceRows,1);assert.equal(result.nullKeys,1);assert.equal(result.orphanRows,1);assert.equal(result.unmatchedTargetRows,1);assert.deepEqual(result.pairs[0].values,['1','A']);
});

test('construye una ruta de varias FK y tránsitos en ambos sentidos',()=>{
  const a={id:'1'},b={id:'1',parent:'1'},c={id:'1',parent:'1'};
  const model={rows:new Map([['a',[a]],['b',[b]],['c',[c]]])};
  const relationships=[{source:'b',columns:['parent'],target:'a',targetColumns:['id']},{source:'c',columns:['parent'],target:'b',targetColumns:['id']}];
  const path=findRelationshipPath(relationships,'a','c');assert.equal(path.length,2);assert.equal(path[0].forward,false);
  const analyses=new Map([[0,{pairs:[{sourceRow:b,targetRow:a,sourceIndex:0,targetIndex:0,values:['1'],targetValues:['1']}] }],[1,{pairs:[{sourceRow:c,targetRow:b,sourceIndex:0,targetIndex:0,values:['1'],targetValues:['1']}] }]]);
  const transitions=buildRouteTransitions(model,path,analyses);assert.deepEqual(transitions.map(step=>[step.fromTable,step.toTable]),[['a','b'],['b','c']]);
});

test('el dump real tiene pares coincidentes reales y filas con FK NULL separadas',async()=>{
  const {readFile}=await import('node:fs/promises');const {parseDump}=await import('../src/parser.js');
  const sql=await readFile(new URL('../../backups/240196_13.10.26.sql',import.meta.url),'utf8'),model=parseDump(sql);
  const relation=model.relationships.find(r=>r.source==='tbd_products_categories'&&r.target==='tb_products');
  const result=analyzeRelation(model,relation);assert.equal(result.sourceTotal,22146);assert.equal(result.matchedSourceRows,22146);assert.equal(result.nullKeys,0);assert.equal(result.orphanRows,0);
  const self=model.relationships.find(r=>r.source==='tbc_categories'&&r.target==='tbc_categories'),selfResult=analyzeRelation(model,self);assert.equal(selfResult.matchedSourceRows,88);assert.equal(selfResult.nullKeys,12);
  const empty=model.relationships.find(r=>r.source==='tb_carts'),emptyResult=analyzeRelation(model,empty);assert.equal(emptyResult.pairs.length,0);assert.equal(emptyResult.sourceTotal,0);
});
