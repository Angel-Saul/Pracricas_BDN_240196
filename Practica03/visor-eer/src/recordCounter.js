const identifier = '(?:`((?:``|[^`])+)`|([\\w$]+))(?:\\s*\\.\\s*(?:`((?:``|[^`])+)`|([\\w$]+)))?';
function hideSqlCommentsAndStrings(sql) {
  const chars=sql.split(''), n=sql.length; let state='', quote='', escape=false;
  for(let i=0;i<n;i++){
    const c=sql[i], next=sql[i+1];
    if(state==='line'){if(c==='\n')state='';else chars[i]=' ';continue}
    if(state==='block'){chars[i]=c==='\n'?'\n':' ';if(c==='*'&&next==='/'){chars[i+1]=' ';i++;state=''}continue}
    if(quote){if(quote==='`'){if(c==='`'&&next==='`'){i++;continue}if(c==='`')quote='';continue}chars[i]=c==='\n'?'\n':' ';if(escape){escape=false;continue}if(c==='\\'){escape=true;continue}if(c===quote){if(next===quote){chars[i+1]=' ';i++;continue}quote=''}continue}
    if(c==='-'&&next==='-'&&(sql[i+2]===' '||sql[i+2]==='\t'||sql[i+2]==='\n')){chars[i]=chars[i+1]=' ';i++;state='line';continue}
    if(c==='#'){chars[i]=' ';state='line';continue}
    if(c==='/'&&next==='*'){chars[i]=chars[i+1]=' ';i++;state='block';continue}
    if(c==='\''||c==='"'){quote=c;chars[i]=' ';continue}
    if(c==='`'){quote=c}
  }
  return chars.join('');
}
function skipRoutineBodies(masked) {
  const out=[...masked];
  // MySQL dump routines are delimited by a custom token (here `;;`); body statements
  // describe future behavior and are not executed while loading the dump.
  const re=/\bCREATE\s+(?:DEFINER\s*=\s*[^\s]+\s+)?(?:PROCEDURE|FUNCTION|TRIGGER|EVENT)\b[\s\S]*?\bEND\s*;;/gi;let m;
  while((m=re.exec(masked)))for(let i=m.index;i<re.lastIndex;i++)if(out[i]!=='\n')out[i]=' ';
  return out.join('');
}
function rowTuples(statement, start) {
  let count=0, depth=0, quote='',escape=false,started=false;
  for(let i=start;i<statement.length;i++){const c=statement[i];if(quote){if(escape){escape=false;continue}if(c==='\\'){escape=true;continue}if(c===quote){if(statement[i+1]===quote){i++;continue}quote=''}continue}if(c==='\''||c==='"'){quote=c;continue}if(c==='('){if(depth===0)count++;depth++;started=true}else if(c===')'){depth--;if(depth<0)return null}else if(c===';'&&depth===0)break}
  return started&&depth===0?count:null;
}
function splitValues(text){const values=[];let start=0,depth=0,quote='',escape=false;for(let i=0;i<text.length;i++){const c=text[i];if(quote){if(escape){escape=false;continue}if(c==='\\'){escape=true;continue}if(c===quote){if(text[i+1]===quote){i++;continue}quote=''}continue}if(c==="'"||c==='"'){quote=c;continue}if(c==='(')depth++;else if(c===')')depth--;else if(c===','&&depth===0){values.push(text.slice(start,i).trim());start=i+1}}values.push(text.slice(start).trim());return values}
function readTuple(text,start){let depth=0,quote='',escape=false;for(let i=start;i<text.length;i++){const c=text[i];if(quote){if(escape){escape=false;continue}if(c==='\\'){escape=true;continue}if(c===quote){if(text[i+1]===quote){i++;continue}quote=''}continue}if(c==="'"||c==='"'){quote=c;continue}if(c==='(')depth++;else if(c===')'&&--depth===0)return{i,body:text.slice(start+1,i)}}return null}
function decodeSqlValue(value){const raw=value.trim();if(/^NULL$/i.test(raw))return null;const literal=raw.match(/^(?:_binary\s+|_[\w]+\s+|[bB]\s*)(['"])([\s\S]*)\1$/);if(literal){const q=literal[1],inside=literal[2].replace(new RegExp(q+q,'g'),q);return inside.replace(/\\([0btnrZ\\'"%_])/g,(_,c)=>({0:'\0',b:'\b',t:'\t',n:'\n',r:'\r',Z:'\x1a'}[c]??c))}if(/^[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?$/.test(raw))return raw;return raw}
function unmaskRoutineRanges(sql){const masked=skipRoutineBodies(hideSqlCommentsAndStrings(sql));return masked}
export function parseInsertedRows(sql,tables){const masked=unmaskRoutineRanges(sql),rows=new Map(tables.map(table=>[table.name,[]]));const identifier='(?:`((?:``|[^`])+)`|([\\w$]+))(?:\\s*\\.\\s*(?:`((?:``|[^`])+)`|([\\w$]+)))?';const re=new RegExp(`\\bINSERT\\s+(?:(?:LOW_PRIORITY|DELAYED|HIGH_PRIORITY|IGNORE)\\s+)*INTO\\s+${identifier}`,'gi');let m;while((m=re.exec(masked))){const name=(m[3]||m[4]||m[1]||m[2]).replace(/``/g,'`'),table=tables.find(item=>item.name===name);if(!table)continue;const end=masked.indexOf(';',re.lastIndex),stop=end<0?masked.length:end;const segment=sql.slice(m.index,stop),maskedSegment=masked.slice(m.index,stop);const values=/\bVALUES\s*/i.exec(maskedSegment);if(!values)continue;const beforeValues=maskedSegment.slice(re.lastIndex-m.index,values.index);let columns=table.columns.map(column=>column.name);const open=beforeValues.indexOf('('),close=beforeValues.lastIndexOf(')');if(open>=0&&close>open)columns=beforeValues.slice(open+1,close).split(',').map(item=>item.trim().replace(/^`|`$/g,'').replace(/``/g,'`'));const start=values.index+values[0].length;let cursor=start;while(cursor<segment.length){while(/\s|,/.test(segment[cursor]||'')&&cursor<segment.length)cursor++;if(segment[cursor]!=='(')break;const tuple=readTuple(segment,cursor);if(!tuple)break;const vals=splitValues(tuple.body).map(decodeSqlValue),record=Object.create(null);columns.forEach((column,index)=>{record[column]=vals[index]??null});rows.get(name).push(record);cursor=tuple.i+1}}
  return rows}
export function countRecords(sql, tableNames) {
  const masked=skipRoutineBodies(hideSqlCommentsAndStrings(sql));
  const counts=new Map(tableNames.map(name=>[name,{value:0,status:'exact',reason:'Filas explícitas incluidas en sentencias INSERT del respaldo.',sourceStatements:0}]));
  const unknown=new Map(), statements=new Map();
  const commandRe=new RegExp(`\\b(INSERT\\s+(?:(?:LOW_PRIORITY|DELAYED|HIGH_PRIORITY|IGNORE)\\s+)*INTO|REPLACE\\s+(?:LOW_PRIORITY\\s+|DELAYED\\s+)?INTO|UPDATE|DELETE\\s+FROM)\\s+${identifier}`,'gi');let m;
  while((m=commandRe.exec(masked))){const operation=m[1].toUpperCase().replace(/\s+/g,' '),name=(m[4]||m[5]||m[2]||m[3]).replace(/``/g,'`');let end=masked.indexOf(';',commandRe.lastIndex);if(end<0)end=masked.length;const statement=sql.slice(m.index,end+1), maskedStatement=masked.slice(m.index,end+1);const isInsert=operation.startsWith('INSERT');
    if(isInsert){const values=/\bVALUES\s*/i.exec(maskedStatement);if(!values){unknown.set(name,'La sentencia INSERT no usa VALUES con tuplas contables.');continue}const n=rowTuples(statement,values.index+values[0].length);if(n===null){unknown.set(name,'No se pudieron delimitar con certeza las tuplas INSERT.');continue}const current=counts.get(name);if(current){current.value+=n;current.sourceStatements++}else counts.set(name,{value:n,status:'exact',reason:'Tabla insertada detectada en el respaldo.',sourceStatements:1});statements.set(name,(statements.get(name)||0)+1);
    } else { const reason=operation.startsWith('REPLACE')?'REPLACE puede sustituir filas existentes y requiere evaluar claves únicas.':operation==='UPDATE'?'El respaldo contiene una operación UPDATE ejecutable que puede cambiar datos.':operation.startsWith('DELETE')?'El respaldo contiene una operación DELETE ejecutable que puede cambiar datos.':'LOAD DATA necesita interpretar el archivo externo referenciado.';unknown.set(name,reason); }
  }
  const loadRe=/\bLOAD\s+DATA(?:\s+LOCAL)?\s+INFILE\b[\s\S]*?\bINTO\s+TABLE\s+(`((?:``|[^`])+)`|([\w$]+))/gi;
  while((m=loadRe.exec(masked))){const name=(m[2]||m[3]).replace(/``/g,'`');unknown.set(name,'LOAD DATA referencia un archivo externo que no se puede contar desde el dump.');}
  for(const [name,reason] of unknown){const item=counts.get(name);if(item){item.status='unknown';item.value=null;item.reason=reason}}
  return counts;
}
