# Atlas EER

Explorador de solo lectura para el dump MySQL [`240196_13.10.26.sql`](../backups/240196_13.10.26.sql). No instala dependencias, no envia el dump a servicios externos y nunca ejecuta sentencias SQL contra una base. Si no encuentra el respaldo predeterminado, permite cargar un `.sql` local.

## Ejecutar

Requiere Node.js 18 o posterior. Desde esta carpeta:

```bash
npm start
```

Abre <http://127.0.0.1:4173>. En PowerShell tambien puedes usar `npm.cmd start`.

## Pruebas

```bash
npm test
```

## Vistas

- **Diagrama EER:** tablas, vistas, columnas, PK/FK, indices, restricciones, cardinalidad inferida, zoom, pan, arrastre y panel inspector.
- **Explorador de datos:** todas las columnas y filas que aparecen en `INSERT ... VALUES`, busqueda, ordenamiento, paginacion y modo virtualizado para recorrer todas las filas sin insertar miles de nodos DOM a la vez.
- **Simulador de transito:** cruza las claves FK sobre las filas extraidas, omite componentes NULL, muestra ejemplos reales y anima las coincidencias. La animacion es una representacion conceptual, no trafico o actividad real de MySQL. Admite rutas FK de varias tablas.
- **Estadisticas:** conteos por tabla y resumen de relaciones coincidentes.

## Alcance y limites

- Los totales son filas incluidas en el respaldo, no conteos actuales de una instancia MySQL. Si el dump tiene INSERT no reducibles, `REPLACE`, cargas externas o cambios de filas que impiden un total seguro, el valor se marca desconocido. Se excluyen operaciones dentro de cuerpos de rutinas porque definirlas no las ejecuta.
- El parser compara los valores FK extraidos de forma exacta. Diferencias de collation MySQL, conversiones implicitas, triggers, cascadas u operaciones externas pueden cambiar la semantica de ejecucion; el visor no conecta ni ejecuta la base. El dato presentado es el que el archivo permite demostrar estaticamente.
- La cardinalidad 1:1 requiere unicidad en las columnas FK del lado hijo; 1:N se infiere en los demas casos validos. Una tabla puente con clave unica compuesta por sus FKs se clasifica como M:N. No se inventa opcionalidad de negocio.
- Las seis vistas de este dump tienen estructura temporal de columnas y una definicion final en comentarios de version MySQL; se muestran ambas fuentes del propio archivo.
- El parser esta enfocado en MySQL. `INSERT ... SELECT`, expresiones dinamicas y formatos externos no se muestran como valores exactos.
