import { readFileSync, writeFileSync } from 'node:fs';
import { parseDump } from '../../Practica03/visor-eer/src/parser.js';
const backup='Practica03/backups/240196_13.10.26.sql';
const sql=readFileSync(backup,'utf8'); const model=parseDump(sql); const head='718edc434fce128063cec7f48b2cb9679a55467c';
const groupOf=name=>{
 if(name==='tb_logs')return 'operations';
 if(['tb_users','tbd_products_users_providers'].includes(name))return 'identity';
 if(['tb_products','tbc_categories','tbd_products_categories'].includes(name))return 'catalog';
 return 'commerce';
};
const ids=new Map([...model.tables,...model.views].map(x=>[x.name,x.name.replace(/[^a-zA-Z0-9_-]/g,'_').replace(/^[^a-zA-Z]/,'t_')]));
const pos=new Map();
const identity=model.tables.filter(t=>groupOf(t.name)==='identity');identity.forEach((t,col)=>pos.set(t.name,{row:0,col,tag:'identity'}));
const catalog=model.tables.filter(t=>groupOf(t.name)==='catalog');catalog.forEach((t,col)=>pos.set(t.name,{row:1,col,tag:'catalog'}));
const commerce=[...model.tables.filter(t=>groupOf(t.name)==='commerce'),model.tables.find(t=>t.name==='tbd_wishlist_products')].filter(Boolean);commerce.forEach((t,i)=>pos.set(t.name,{row:2+Math.floor(i/4),col:i%4,tag:'commerce'}));
const operations=model.tables.filter(t=>groupOf(t.name)==='operations');operations.forEach((t,col)=>pos.set(t.name,{row:4,col,tag:'operations'}));
const views=model.views; views.forEach((v,i)=>pos.set(v.name,{row:5+Math.floor(i/3),col:i%3,tag:'views'}));
const sourceRange=(definition)=>{const at=sql.indexOf(definition); if(at<0)return {path:backup,label:'Definición SQL'};const line=sql.slice(0,at).split('\n').length;const end=sql.slice(0,at+definition.length).split('\n').length;return {path:backup,line,end_line:end,label:'Definición SQL'}};
const countFor=name=>model.counts.get(name);
const attr=(column,table)=>{
 const roles=[];if(column.primary)roles.push('pk');if(column.foreign)roles.push('fk');if(column.unique)roles.push('uk');
 const fk=model.relationships.find(r=>r.source===table.name&&r.columns.includes(column.name));
 const detail=column.comment?` · COMMENT ${column.comment}`:'';
 return {name:column.name,type:`${column.type}${detail}`,...(roles.length?{key:roles.length===1?roles[0]:roles}:{}),...(fk?{references:`${fk.target}.${fk.targetColumns[fk.columns.indexOf(column.name)]}`}:{})};
};
const entities=[...model.tables,...model.views].map(obj=>{
 const p=pos.get(obj.name);const count=countFor(obj.name);
 const sublabel=obj.kind==='table'?`${count?.status==='exact'?count.value.toLocaleString('es-MX'):'?'} filas del respaldo · ${obj.columns.length} columnas · ${obj.primaryKey.length?`PK ${obj.primaryKey.join('+')}`:'sin PK'}`:`Vista · ${obj.columns.length} columnas proyectadas · filas no contabilizadas`;
 const measuredWidth=Math.max(320,Math.ceil(obj.name.length*8.4+74),...obj.columns.map(c=>Math.ceil((c.name.length+c.type.length)*5.2+112)));return {id:ids.get(obj.name),label:obj.name,sublabel,tag:p.tag,row:p.row,col:p.col,width:measuredWidth,attributes:obj.columns.map(c=>attr(c,obj)),sources:[sourceRange(obj.definition)]};
});
const selfReferences=model.relationships.filter(r=>r.source===r.target).map(r=>`${r.source}: ${r.columns.join(' + ')} → ${r.target}.${r.targetColumns.join(' + ')}${r.name?` · ${r.name}`:''}${r.onDelete?` · ON DELETE ${r.onDelete}`:''}${r.onUpdate?` · ON UPDATE ${r.onUpdate}`:''}`);
const relationships=model.relationships.filter(r=>ids.has(r.source)&&ids.has(r.target)&&r.source!==r.target).map((r,i)=>{
 const cardinality=r.cardinality==='1:1'?['one','one']:r.cardinality==='M:N'?['many','many']:['many','one'];
 const rules=[r.onDelete?`ON DELETE ${r.onDelete}`:null,r.onUpdate?`ON UPDATE ${r.onUpdate}`:null].filter(Boolean).join(' · ');
 const composite=r.columns.length>1?`[${r.columns.join(' + ')}] → [${r.targetColumns.join(' + ')}]`:`${r.columns[0]} → ${r.targetColumns[0]}`;
 return {id:`fk_${i+1}`,from:ids.get(r.source),to:ids.get(r.target),label:`${composite}${r.name?` · ${r.name}`:''}${rules?` · ${rules}`:''}`,fromCardinality:cardinality[0],toCardinality:cardinality[1],...(r.cardinality==='M:N'?{}:{identifying:r.columns.every(c=>model.tables.find(t=>t.name===r.source)?.primaryKey.includes(c))})};
});
const counts=[...model.counts].map(([name,c])=>`${name}: ${c.status==='exact'?c.value.toLocaleString('es-MX'):`${c.status} (${c.reason})`}`).join(' · ');
const indexes=model.tables.flatMap(t=>t.indexes.map(idx=>`${t.name}.${idx.name||idx.type} (${idx.type}): ${idx.columns.join(', ')}`));
const constraints=model.tables.flatMap(t=>t.constraints.filter(c=>c.type!=='FOREIGN KEY').map(c=>`${t.name}${c.name?` · ${c.name}`:''} (${c.type}): ${c.definition}`));
const candidate={schema_version:1,diagram_type:'erd',meta:{title:`Modelo EER · ${model.database}`,locale:'es',output:'archify-erd-20261014-181555/db-test.html',quality_profile:'standard',repository:{url:'https://github.com/Angel-Saul/Pracricas_BDN_240196.git',revision:head,provider:'github',link_mode:'local-only'},legend:{mode:'all',entries:{pk:{label:'Clave primaria'},fk:{label:'Clave foránea'},uk:{label:'Única'},one:{label:'Uno'},many:{label:'Muchos'}}}},layout:{mode:'grid',gapX:58,gapY:34},entities,relationships,cards:[{dot:'cyan',title:'Respaldo y conteos',items:[`${model.statistics.tables} tablas · ${model.statistics.views} vistas · ${model.statistics.columns} columnas · ${model.statistics.foreignKeys} claves foráneas.`,`Total identificado: ${[...model.counts.values()].reduce((n,c)=>n+(c.status==='exact'?c.value:0),0).toLocaleString('es-MX')} filas en INSERT; todos los conteos de tabla son exactos según las sentencias del respaldo. No equivale a filas actuales de MySQL.`,...counts.split(' · ')]},{dot:'amber',title:'Índices y restricciones',items:[...indexes,...constraints,...selfReferences].slice(0,80)}]};
writeFileSync('.archify/erd-db-test-20261014-181555/candidate.json',JSON.stringify(candidate,null,2));
console.log(JSON.stringify({entities:entities.length,relationships:relationships.length,stats:model.statistics,rows:[...model.counts].map(([name,c])=>[name,c.value,c.status]),candidate:'.archify/erd-db-test-20261014-181555/candidate.json'}));
