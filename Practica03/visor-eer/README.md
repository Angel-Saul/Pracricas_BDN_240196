# Atlas EER

Explorador de solo lectura para el dump MySQL [`240196_13.10.26.sql`](../backups/240196_13.10.26.sql). No instala dependencias, no envia el dump a servicios externos y nunca ejecuta sentencias SQL contra una base. Si no encuentra el respaldo predeterminado, permite cargar un `.sql` local.

## Ejecutar

Requiere Node.js 18 o posterior. No necesita dependencias externas ni conexión a una instancia MySQL. Desde esta carpeta:

```bash
npm start
```

Abre <http://127.0.0.1:4173> y selecciona **Importar SQL** para elegir tu respaldo local. El visor analiza el esquema, cuenta las tuplas `INSERT` que pueda determinar con seguridad y genera el diccionario en CSV, JSON, HTML o informe Markdown desde la vista **Estadísticas**.

Abre <http://127.0.0.1:4173>. En PowerShell tambien puedes usar `npm.cmd start`.

## Pruebas

```bash
npm test
```

## Vistas

- **Diagrama EER:** tablas, vistas, columnas, PK/FK, índices, restricciones, triggers asociados con cada tabla y sus tablas afectadas detectadas, cardinalidad inferida, zoom, pan, arrastre y panel inspector.
- **Explorador de datos:** todas las columnas y filas que aparecen en `INSERT ... VALUES`, busqueda, ordenamiento, paginacion y modo virtualizado para recorrer todas las filas sin insertar miles de nodos DOM a la vez.
- **Simulador de transito:** cruza las claves FK sobre las filas extraidas, omite componentes NULL, muestra ejemplos reales y anima las coincidencias. La animacion es una representacion conceptual, no trafico o actividad real de MySQL. Admite rutas FK de varias tablas.
- **Estadisticas:** conteos por tabla y resumen de relaciones coincidentes.

## Alcance y limites

- Los conteos describen las filas incluidas en el respaldo, no los datos actuales de una instancia MySQL. Se cuentan tuplas `INSERT` explícitas mediante análisis estático de solo lectura; no se ejecuta SQL. Si hay operaciones como `REPLACE`, `UPDATE`, `DELETE`, `LOAD DATA` o formatos no reducibles con certeza, el conteo afectado se marca no disponible.
- Los triggers se extraen como definiciones estáticas (momento, evento, tabla asociada y tablas destino detectadas); nunca se ejecutan durante el análisis ni la exportación.
- El explorador de datos presenta las filas incluidas en el respaldo SQL; esos ejemplos no se usan como conteos actuales de la instancia.
- El parser compara los valores FK extraidos de forma exacta. Diferencias de collation MySQL, conversiones implicitas, triggers, cascadas u operaciones externas pueden cambiar la semantica de ejecucion; el visor no conecta ni ejecuta la base. El dato presentado es el que el archivo permite demostrar estaticamente.
- La cardinalidad 1:1 requiere unicidad en las columnas FK del lado hijo; 1:N se infiere en los demas casos validos. Una tabla puente con clave unica compuesta por sus FKs se clasifica como M:N. No se inventa opcionalidad de negocio.
- Las seis vistas de este dump tienen estructura temporal de columnas y una definicion final en comentarios de version MySQL; se muestran ambas fuentes del propio archivo.
- El parser esta enfocado en MySQL. `INSERT ... SELECT`, expresiones dinamicas y formatos externos no se muestran como valores exactos.
