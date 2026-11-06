# Informe de validación — Diccionario de datos MySQL

## Fuente

- Archivo: `C:\Users\PC-26\Pracricas_BDN_240196\Practica03\backups\240196_20.10.26.sql` (11,881,544 bytes).
- Base declarada: `db_test`.
- Versión indicada por comentario del respaldo: MySQL 8.0.36; no es consulta a instancia activa.
- Generado: 20 de octubre de 2026 a las 11:21 a.m. (America/Mexico_City).
- SHA-256 fuente: ff72e8bef213ebcc4253096386f20d8329a946564237bfa128d8e949dcc83387.

## Inventario detectado

- 19 tablas; 147 columnas físicas; 19 vistas con 133 columnas proyectadas. Total de definiciones de columnas: 280.
- 19 tablas con clave primaria; 25 claves foráneas y relaciones declaradas.
- 34 índices secundarios declarados; 16 son UNIQUE.
- 37 restricciones declaradas (25 claves foráneas + 12 CHECK); 12 CHECK; 54 triggers; 1 procedimiento; 0 funciones; 0 eventos.
- 1 columna generada; 0 tablas temporales; 0 dependencias entre vistas.
- Objetos programables encontrados por lectura estática. No se consultó servidor MySQL.

## Conteos del respaldo

| Tabla | Filas INSERT contadas | Estado |
|---|---:|---|
| `tb_buyer_orders` | 0 | Exacto |
| `tb_carts` | 0 | Exacto |
| `tb_logs` | 37,259 | Exacto |
| `tb_payment_transactions` | 0 | Exacto |
| `tb_payments` | 0 | Exacto |
| `tb_products` | 15,007 | Exacto |
| `tb_seller_orders` | 0 | Exacto |
| `tb_user_addresses` | 0 | Exacto |
| `tb_users` | 9 | Exacto |
| `tbb_orders` | 0 | Exacto |
| `tbc_categories` | 100 | Exacto |
| `tbc_payment_methods_types` | 0 | Exacto |
| `tbd_address_components` | 0 | Exacto |
| `tbd_carts_items` | 0 | Exacto |
| `tbd_order_items` | 0 | Exacto |
| `tbd_products_categories` | 22,146 | Exacto |
| `tbd_products_users_providers` | 0 | Exacto |
| `tbd_user_payment_methods` | 0 | Exacto |
| `tbd_users_wishlist_products` | 0 | Exacto |

## Cobertura y límites

- Se documentaron 19 tablas con 147 campos físicos; total confirmado: 147.
- Se documentaron 19 vistas con 133 columnas, 54 triggers, 1 procedimiento y 0 funciones.
- Relaciones: 25; 4 con cardinalidad pendiente de confirmar. Relaciones muchos a muchos inferidas por tabla asociativa: 7.
- Conteos exactos son suma de tuplas INSERT estáticamente contables; no describen datos actuales del servidor.
- Las vistas se documentan desde la definición final cuando estaba presente; se distingue proyección directa de expresión calculada.
- Valores reales de filas, incluidos textos de auditoría, datos de contacto y referencias, fueron excluidos del HTML, CSV e informe.
- No se identificaron eventos programados ni tablas temporales. Se encontró una columna generada: tbd_order_items.subtotal (STORED). El respaldo no declara funciones SQL. Dependencias de vista a vista: 0.
- Advertencias del parser: ninguna para conteos INSERT.
- Pendiente: confirmar reglas de negocio, significado de estados/medidas, obligatoriedad funcional y política institucional de sensibilidad con responsables del sistema.

## Validaciones ejecutadas

- Parseo local del dump con el parser MySQL existente en modo lectura.
- Comparación de todas las tablas, campos físicos, vistas y 25 relaciones del respaldo.
- Integridad CSV: UTF-8 con BOM; 280 filas de columnas (147 físicas + 133 de vistas), 31 columnas por fila y parseo rectangular.
- HTML: documento autónomo. JavaScript compila; búsqueda, filtros y fichas probados con DOM local; Edge headless renderizó 19 fichas de tablas y 221 detalles desplegables sin error de JavaScript.
- Diagrama integrado: conectores para las 25 FKs, incluidas las dos autorreferencias; la navegación de campos lleva a la ficha de su relación.
- Anexo SQL: incluye definiciones de objetos; no contiene sentencias DROP, LOCK, usuarios/permisos ni datos de filas. INSERT dentro de triggers/procedimientos se conserva solo como definición y no se ejecutó. DEFINER se omitió.
- Archify generó y validó la estructura de campos. Su browser-check ejecutó el render y marcó 5 errores de legibilidad porque la etiqueta contextual “PK” baja de 6px al escalar el mapa denso. El HTML principal mantiene un diagrama propio con relaciones completas.
- Respaldo fuente: no se modificó; su SHA-256 se registra para cotejo.

## Archivos

- HTML: `C:\Users\PC-26\Pracricas_BDN_240196\archify-diccionario-mysql-db-test-20261020-1055\diccionario.html`
- CSV: `C:\Users\PC-26\Pracricas_BDN_240196\archify-diccionario-mysql-db-test-20261020-1055\diccionario-campos.csv`
- Anexo SQL: `C:\Users\PC-26\Pracricas_BDN_240196\archify-diccionario-mysql-db-test-20261020-1055\anexo-tecnico-mysql.sql`
- Informe: `C:\Users\PC-26\Pracricas_BDN_240196\archify-diccionario-mysql-db-test-20261020-1055\informe-validacion.md`
- Diagrama Archify: `C:\Users\PC-26\Pracricas_BDN_240196\archify-diccionario-mysql-db-test-20261020-1055\modelo-relacional.html` (mapa de campos; las FK se enumeran en su ficha).