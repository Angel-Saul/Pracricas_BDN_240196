import { extractSchema } from './schemaExtractor.js';
import { countRecords, parseInsertedRows } from './recordCounter.js';

export function parseDump(sql) {
  const schema = extractSchema(sql);
  const counts = countRecords(sql, schema.tables.map(table => table.name));
  const rows = parseInsertedRows(sql, schema.tables);
  for (const table of schema.tables) {
    const count = counts.get(table.name);
    if (count?.status === 'exact' && rows.get(table.name).length !== count.value) {
      count.status = 'unknown';
      count.value = null;
      count.reason = 'El conteo de tuplas y las filas que se pudieron interpretar no coinciden.';
    }
  }
  const warnings = [...counts]
    .filter(([, count]) => count.status === 'unknown')
    .map(([name, count]) => `${name}: ${count.reason}`);
  const dangling = schema.relationships.filter(
    relation => !schema.tables.some(table => table.name === relation.target),
  );
  if (dangling.length) warnings.push(`${dangling.length} claves foraneas apuntan a tablas ausentes del dump.`);

  return {
    ...schema,
    counts,
    rows,
    statistics: {
      tables: schema.tables.length,
      views: schema.views.length,
      columns: schema.objects.reduce((total, object) => total + object.columns.length, 0),
      primaryKeys: schema.tables.filter(table => table.primaryKey.length).length,
      foreignKeys: schema.relationships.length,
      relationships: schema.relationships.length,
      indexes: schema.tables.reduce((total, table) => total + table.indexes.length, 0),
    },
    warnings,
  };
}
