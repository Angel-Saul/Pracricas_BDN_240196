/** @typedef {{name:string,type:string,nullable:boolean,defaultValue:string|null,autoIncrement:boolean,primary:boolean,foreign:boolean,unique:boolean,indexed:boolean,comment:string}} Column */
/** @typedef {{name:string,type:string,columns:string[],targetTable:string,targetColumns:string[],onDelete:string,onUpdate:string,definition:string}} ForeignKey */
/** @typedef {{name:string,kind:'table'|'view',columns:Column[],constraints:object[],indexes:object[],primaryKey:string[],definition:string}} SchemaObject */
/** @typedef {{value:number|null,status:'exact'|'unknown'|'estimated',reason:string,sourceStatements:number}} RecordCount */
