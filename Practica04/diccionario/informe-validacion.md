# Informe de validación — Diccionario de datos MySQL

## Fuente

- Archivo: `C:\Users\chest\BDN\Pracricas_BDN_240196\Practica04\backups\240196_06.11.26.sql` (26,077,500 bytes).
- Base declarada: `db_test`.
- Cliente de respaldo: mysqldump 8.0.46. Versión indicada para el servidor: 26.7.0; ambas se leen de comentarios y no se verifican contra una instancia.
- Generado: 6 de noviembre de 2026 a las 1:02 a.m. (America/Mexico_City).
- SHA-256 fuente: 8326aeec4b5c49b485484618e17210ebca0d8e9326070a5f511e64549269d65f.

## Inventario detectado

- 27 tablas; 213 columnas físicas; 25 vistas con 195 columnas proyectadas. Total de definiciones de columnas: 408.
- 27 tablas con clave primaria; 30 claves foráneas y relaciones declaradas.
- 47 índices secundarios declarados; 22 son UNIQUE.
- 51 restricciones declaradas (30 claves foráneas + 21 CHECK); 21 CHECK; 78 triggers; 7 procedimientos; 15 funciones; 0 eventos.
- 1 columna generada; 0 tablas temporales; 0 dependencias entre vistas.
- Objetos programables encontrados por lectura estática. No se consultó servidor MySQL.

## Conteos del respaldo

- Tablas con conteo exacto: 27; estimado: 0; no disponible: 0.

| Tabla | Filas INSERT contadas | Estado |
|---|---:|---|
| `tb_buyer_orders` | 0 | Exacto |
| `tb_carts` | 1 | Exacto |
| `tb_logs` | 73,831 | Exacto |
| `tb_order_cancellations` | 0 | Exacto |
| `tb_payment_transactions` | 3 | Exacto |
| `tb_payments` | 1 | Exacto |
| `tb_people` | 10,231 | Exacto |
| `tb_products` | 15,007 | Exacto |
| `tb_refunds` | 0 | Exacto |
| `tb_seller_orders` | 1 | Exacto |
| `tb_shipments` | 1 | Exacto |
| `tb_user_addresses` | 1 | Exacto |
| `tb_users` | 10,240 | Exacto |
| `tbb_orders` | 1 | Exacto |
| `tbc_categories` | 100 | Exacto |
| `tbc_gen_email_domains` | 11 | Exacto |
| `tbc_gen_family_names` | 369 | Exacto |
| `tbc_gen_given_names` | 508 | Exacto |
| `tbc_gen_phone_area_codes` | 145 | Exacto |
| `tbc_payment_methods_types` | 1 | Exacto |
| `tbd_address_components` | 7 | Exacto |
| `tbd_carts_items` | 5 | Exacto |
| `tbd_order_items` | 5 | Exacto |
| `tbd_products_categories` | 22,146 | Exacto |
| `tbd_products_users_providers` | 14,971 | Exacto |
| `tbd_user_payment_methods` | 1 | Exacto |
| `tbd_users_wishlist_products` | 5 | Exacto |

## Cobertura y límites

- Se documentaron 27 tablas con 213 campos físicos; total confirmado: 213.
- Se documentaron 25 vistas con 195 columnas, 78 triggers, 7 procedimientos y 15 funciones.
- Relaciones: 30; 0 con cardinalidad pendiente de confirmar. Relaciones muchos a muchos inferidas por tabla asociativa: 7.
- Conteos exactos son suma de tuplas INSERT estáticamente contables; no describen datos actuales del servidor.
- Las vistas se documentan desde la definición final cuando estaba presente; se distingue proyección directa de expresión calculada.
- Valores reales de filas, incluidos textos de auditoría, datos de contacto y referencias, fueron excluidos del HTML, CSV e informe.
- Eventos: 0; tablas temporales: 0; columnas generadas: 1; dependencias de vista a vista: 0.
- Advertencias del parser: ninguna para conteos INSERT.
- Pendiente: confirmar reglas de negocio, significado de estados/medidas, obligatoriedad funcional y política institucional de sensibilidad con responsables del sistema.

## Validaciones ejecutadas

- Parseo local del dump con el parser MySQL existente en modo lectura.
- Comparación estructural: 27 tablas, 213 columnas físicas, 25 vistas, 195 columnas proyectadas y 30 relaciones.
- CSV generado en UTF-8 con BOM; 408 filas de datos y 39 columnas por fila.
- HTML generado como documento autónomo desde el respaldo. No se ejecutó una validación de navegador en esta generación.
- Diagrama integrado con conectores para 30 claves foráneas declaradas.
- Anexo SQL: incluye definiciones de objetos; no contiene sentencias DROP, LOCK, usuarios/permisos ni datos de filas. INSERT dentro de triggers/procedimientos se conserva solo como definición y no se ejecutó. DEFINER se omitió.
- Se generó una estructura JSON auxiliar de entidades a partir del esquema.
- Respaldo fuente: no se modificó; su SHA-256 se registra para cotejo.

## Archivos

- HTML: `C:\Users\chest\BDN\Pracricas_BDN_240196\diccionario.html`
- CSV: `C:\Users\chest\BDN\Pracricas_BDN_240196\diccionario-campos.csv`
- Anexo SQL: `C:\Users\chest\BDN\Pracricas_BDN_240196\anexo-tecnico-mysql.sql`
- Informe: `C:\Users\chest\BDN\Pracricas_BDN_240196\informe-validacion.md`
- Diagrama Archify: `C:\Users\chest\BDN\Pracricas_BDN_240196\modelo-relacional.html` (mapa de campos; las FK se enumeran en su ficha).