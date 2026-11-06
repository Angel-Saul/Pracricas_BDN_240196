# Informe de validación — Diccionario de datos MySQL

## Fuente

- Archivo: `C:\Users\PC-26\Pracricas_BDN_240196\Practica03\backups\240196_20.10.26.sql` (11,881,544 bytes).
- Base declarada: `db_test`.
- Versión indicada por comentario del respaldo: MySQL 8.0.36; no es consulta a instancia activa.
- Generado: 20 de octubre de 2026 a las 10:57 a.m. (America/Mexico_City).
- SHA-256 fuente: ff72e8bef213ebcc4253096386f20d8329a946564237bfa128d8e949dcc83387.

## Inventario detectado

- 19 tablas; 147 columnas físicas; 19 vistas con 133 columnas proyectadas. Total de definiciones de columnas: 280.
- 19 tablas con clave primaria; 25 claves foráneas y relaciones declaradas.
- 34 índices secundarios declarados; 16 son UNIQUE.
- 12 CHECK; 54 triggers; 1 procedimientos; 0 funciones; 0 eventos.
- Objetos programables encontrados por lectura estática. No se consultó servidor MySQL.

## Conteos del respaldo

| Tabla | Filas INSERT contadas | Estado |
|---|---:|---|
| `tb_buyer_orders` | 0 | exact |
| `tb_carts` | 0 | exact |
| `tb_logs` | 37259 | exact |
| `tb_payment_transactions` | 0 | exact |
| `tb_payments` | 0 | exact |
| `tb_products` | 15007 | exact |
| `tb_seller_orders` | 0 | exact |
| `tb_user_addresses` | 0 | exact |
| `tb_users` | 9 | exact |
| `tbb_orders` | 0 | exact |
| `tbc_categories` | 100 | exact |
| `tbc_payment_methods_types` | 0 | exact |
| `tbd_address_components` | 0 | exact |
| `tbd_carts_items` | 0 | exact |
| `tbd_order_items` | 0 | exact |
| `tbd_products_categories` | 22146 | exact |
| `tbd_products_users_providers` | 0 | exact |
| `tbd_user_payment_methods` | 0 | exact |
| `tbd_users_wishlist_products` | 0 | exact |

## Cobertura y límites

- Se documentaron 19 tablas con 147 campos físicos; total confirmado: 147.
- Se documentaron 19 vistas, 54 triggers, 1 procedimientos y 0 funciones.
- Relaciones: 25; 4 con cardinalidad pendiente de confirmar.
- Conteos exactos son suma de tuplas INSERT estáticamente contables; no describen datos actuales del servidor.
- Las vistas se documentan desde la definición final cuando estaba presente.
- Valores reales de filas, incluidos textos de auditoría, datos de contacto y referencias, fueron excluidos del HTML, CSV e informe.
- Objetos no analizados: no se identificaron eventos programados; tablas temporales: no identificadas; índices espaciales/funcionales: revisar definición SQL si aparecen en el anexo.
- Advertencias del parser: ninguna para conteos INSERT.
- Pendiente: confirmar reglas de negocio, significado de estados/medidas, obligatoriedad funcional y política institucional de sensibilidad con responsables del sistema.

## Validaciones ejecutadas

- Parseo local del dump con el parser MySQL existente en modo lectura.
- Comparación de total de campos documentados con el inventario detectado.
- Revisión de consistencia entre las relaciones, sus claves foráneas y el modelo.
- Integridad CSV: encabezados y número de filas comprobados después de escribir; compatibilidad UTF-8 con BOM y comillas dobles.
- HTML: documento autónomo con CSS/JS y datos embebidos; búsqueda y filtros implementados en cliente.
- Anexo SQL: generado solo con CREATE DATABASE / TABLE / VIEW / TRIGGER / PROCEDURE / FUNCTION / EVENT; no se incluyeron DML ni sentencias destructivas.
- Respaldo fuente: se leyó sin modificarlo; comparar SHA-256 con la suma mostrada para verificar identidad.

## Archivos

- HTML: `C:\Users\PC-26\Pracricas_BDN_240196\.archify\diccionario-mysql-db-test-20261020-1055\diccionario.html`
- CSV: `C:\Users\PC-26\Pracricas_BDN_240196\.archify\diccionario-mysql-db-test-20261020-1055\diccionario-campos.csv`
- Anexo SQL: `C:\Users\PC-26\Pracricas_BDN_240196\.archify\diccionario-mysql-db-test-20261020-1055\anexo-tecnico-mysql.sql`
- Informe: `C:\Users\PC-26\Pracricas_BDN_240196\.archify\diccionario-mysql-db-test-20261020-1055\informe-validacion.md`
- Diagrama Archify: se genera en la misma carpeta al pasar validación automatizada.