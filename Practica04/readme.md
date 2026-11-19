# Práctica 04 — Procesos de Simulación de Compra

**Periodo:** septiembre–diciembre 2026 · **Matrícula:** 240196  
**Base de datos:** `db_test` (MySQL en el VPS) · **Puerto usado en los ejemplos:** `40196`

---

## Objetivo

Simular, directamente sobre la base de datos, el ciclo completo de compra de una plataforma de e-commerce: registro de usuarios, selección de productos, carrito, orden, domicilio, método de pago, pagos, transacciones bancarias, atención de la orden, envío, entrega y —según el caso— cancelaciones, reembolsos, devoluciones y reenvíos.

Cada caso se ejecuta con distintos **usuarios de conexión y roles**, de modo que la bitácora (`tb_logs`) registre quién realizó cada operación. Los datos personales y los números de cuenta usados son ficticios.

---

## Estructura de la carpeta

| Ruta | Contenido |
|---|---|
| `scripts/remote_users_privileges_creation.sql` | Creación de usuarios remotos, roles de e-commerce, privilegios por tabla, asignación de roles y roles predeterminados. |
| `scripts/02_caso_prueba_1.sql` | Caso 1. Compra exitosa con tarjeta de débito. |
| `scripts/03_ajustes_casos_2_a_5.sql` | Ajustes previos para los casos 2 a 5: nuevos tipos de método de pago, ampliación del `ENUM` de `tb_payments.payment_method` con `GiftCoupon` y privilegios adicionales. |
| `scripts/04_caso_prueba_2.sql` | Caso 2. Pago fraccionado, rechazo del último pago, reclamación y reenvío. |
| `scripts/05_caso_prueba_3.sql` | Caso 3. Cancelación parcial, ajuste de la orden y reembolso parcial. |
| `scripts/06_caso_prueba_4.sql` | Caso 4. Productos de un mismo proveedor y entrega en punto de recolección. |
| `scripts/07_caso_prueba_5.sql` | Caso 5. Compra fallida por falta de inventario y reasignación del cupón. |
| `scripts/generar-diccionario.mjs` | Generador del diccionario de datos a partir del respaldo SQL más reciente. |
| `scripts/diccionario-candidate.json` | Candidato estructural del modelo relacional generado desde el respaldo. |
| `backups/` | Respaldo de la base: `240196_28.10.26.sql`, `240196_06.11.26.sql` y `240196_19.11.26.sql` (el más reciente, usado como fuente del diccionario). |
| `diccionario/` | `dictionary.json`, `diccionario-campos.csv`, `anexo-tecnico-mysql.sql` e `informe-validacion.md`. |
| `../diccionario.html` | Diccionario de datos publicado en GitHub Pages. |

---

## Usuarios, conexiones y roles

El script `remote_users_privileges_creation.sql` define:

- **Usuarios remotos:** `angel.barrios` (superadmin), `marco.ramirez` (admin), `luis.cazarez` (support), `jose.castillo` y `aylin.esteban` (sellers), `jonhy.neri` y otros usuarios, además de `app_web` y `app_movil` (aplicación).
- **Roles:** `superadmin`, `admin`, `seller`, `buyer`, `support`, `common` y `user_not_registered`.
- Los usuarios de la aplicación arrancan con `user_not_registered` como rol predeterminado; el rol **`buyer` se activa explícitamente con `SET ROLE` al realizar el pago**.
- La simulación reparte las operaciones entre la aplicación (`app_web`/`app_movil`), "el sistema" (`angel.barrios`), el vendedor (`jose.castillo`) y el soporte, según corresponda.

---

## Casos de prueba

### Caso 1 — Compra exitosa, sin modificaciones

`scripts/02_caso_prueba_1.sql`

1. Un usuario **nuevo**, conectado como `app_web`/`app_movil` con `user_not_registered`, se registra con datos personales y de cuenta mediante `sp_register_person`.
2. Se verifican los ~10 000 productos disponibles y se eligen **5 al azar** con estatus activo y stock suficiente; quedan en la wishlist.
3. Se crea **1 carrito** y se agregan los 5 productos con cantidades distintas (1, 2, 3, 4 y 5).
4. Se genera la orden con `sp_create_order` (orden, orden por vendedor, artículos y descuento de stock).
5. Se registra el domicilio (etiqueta "Casa") con sus **componentes jerárquicos** y se liga a la orden.
6. Se da de alta una **tarjeta de débito simulada de 16 dígitos** en `tbd_user_payment_methods`.
7. Se registra un **pago único** y la conexión activa el rol `buyer`.
8. El sistema registra las transacciones (`Created`, `Authorized`, `Captured`), autoriza el pago y marca la orden como `Attended`.
9. El vendedor prepara y envía; el paquete se marca como entregado en casa.

**Resultado:** orden `Delivered`, pago `Paid`, envío `Delivered`.

---

### Caso 2 — Compra con detalles en el último pago, reclamación y reenvío

`scripts/04_caso_prueba_2.sql`

1. Un usuario **ya registrado** arma un carrito con **10 productos aleatorios**, cantidades entre 1 y 5, y crea la orden.
2. Registra como domicilio su **lugar de trabajo** (no su hogar).
3. Registra una **tarjeta de crédito simulada de 16 dígitos** y **6 pagos mensuales**; al pagar activa el rol `buyer`.
4. El sistema autoriza los **primeros 5 pagos** y rechaza el ** sexto por "límite excedido de crédito"** (`payment_status = Failed`), dejando evidencia en `tb_payment_transactions`.
5. La orden se marca como atendida y se genera la orden de compra del vendedor; el producto se envía y se entrega en el domicilio.
6. El usuario **reclama un producto dañado**: se registra la cancelación, se devuelve el producto (`Returned`) y se realiza un **reenvío en buenas condiciones** hasta la entrega final.

**Resultado:** orden `Delivered` tras el reenvío, reclamación `Completed`, pago 6 `Failed`.

---

### Caso 3 — Compra exitosa con cancelación parcial, ajuste y reembolso parcial

`scripts/05_caso_prueba_3.sql`

1. Usuario registrado: carrito de **3 productos de la misma categoría**, cantidades de 1 a 10, y orden de compra.
2. Domicilio de envío con etiqueta **"Casa Papas"**.
3. Método de pago: **tarjeta digital Spin** (cuenta simulada de 16 dígitos) vinculada a su tabla dependiente.
4. Se registra **un solo pago en efectivo** por el total y se activa el rol `buyer`.
5. El pago se autoriza, la orden queda `Attended`.
6. El usuario **cancela un producto**: se registra la cancelación, se elimina el artículo de la orden, se **devuelve el stock**, se ajustan subtotales y totales.
7. Se emite el **reembolso parcial** (`Processing` → `Completed`), el pago pasa a `PartiallyRefunded` y la cancelación a `Completed`.
8. Se realiza el envío y el pedido se entrega en "Casa Papas".

**Resultado:** orden `Delivered`, pago `PartiallyRefunded`, reembolso `Completed`.

---

### Caso 4 — Compra del mismo proveedor con entrega en punto de recolección

`scripts/06_caso_prueba_4.sql`

1. Usuario registrado: carrito de **3 productos del mismo proveedor**, 1 a 3 unidades, y orden de compra.
2. Domicilio de envío registrado (casa de un familiar).
3. Método de pago: **transferencia SPEI** con cuenta simulada de 16 dígitos; se registra el pago total y se activa `buyer`.
4. El sistema autoriza y marca la orden como atendida; el vendedor prepara y envía el pedido.
5. Como **no hay nadie para recibirlo**, el envío pasa por `InTransit` y queda en el **punto de recolección**, desde donde el cliente lo recoge.

**Resultado:** orden `Delivered` por recolección, envío entregado en punto de recolección.

> Nota del script: el enunciado menciona "un solo pago en efectivo", pero para mantener coherencia con el método registrado se usa `SPEI`. Si se requiere `Cash`, debe cambiarse `@pay_method` en el paso 5 y las referencias de las secciones siguientes.

---

### Caso 5 — Compra fallida por falta de inventario

`scripts/07_caso_prueba_5.sql`

1. Usuario registrado: carrito de **1 producto**, entre 1 y 5 unidades, y orden de compra.
2. Domicilio registrado (casa de un familiar) y método de pago: **cupón de regalo** (`GIFT_COUPON`), vinculado en `tbd_user_payment_methods`.
3. Al usar el cupón, su `status` pasa a `0` (usado).
4. El vendedor realiza el conteo físico y **reporta 0 existencias reales** del producto.
5. El sistema valida el inventario, rechaza la atención de la orden, registra la solicitud de cancelación y una transacción de pago fallida.
6. La orden y la orden del vendedor pasan a `Canceled`; se registra la cancelación como completada y el **cupón se reasigna** (vuelve a `status = 1`).

**Resultado:** orden `Canceled`, pago `Failed`, cupón disponible de nuevo. No se devuelve stock porque las unidades físicas no existían.

---

## Decisiones y observaciones

- `sp_create_order` no permite crear una orden si no hay stock suficiente en el carrito; por eso en el caso 5 la falta de inventario se provoca **después** de la orden, con el conteo físico del vendedor.
- El cupón de regalo **no es una tabla propia**: se modela como un método de pago más en `tbd_user_payment_methods`, con `status` para disponible/usado.
- Los números de cuenta de 16 dígitos se generan de forma aleatoria y solo se conserva la referencia simulada en la tabla dependiente; no se documentan datos sensibles reales.
- Los triggers de auditoría escriben en `tb_logs` el usuario de conexión (`db_user`), la tabla afectada, la operación y la fecha, lo que permite reconstruir quién ejecutó cada paso.
- El respaldo `backups/240196_19.11.26.sql` refleja los ajustes del caso 5 (opción `GiftCoupon` en el `ENUM` y nuevos tipos de pago), además de los conteos de filas actualizados.

---

## Orden sugerido de ejecución

1. `scripts/remote_users_privileges_creation.sql` — usuarios y roles (una sola vez).
2. Los ajustes previos a los que hacen referencia los encabezados de los scripts (`01_ajustes_db_test.sql`).
3. `scripts/02_caso_prueba_1.sql` — caso 1 (secciones A–D, cada una en su propia conexión).
4. `scripts/03_ajustes_casos_2_a_5.sql` — una vez, con `angel.barrios`.
5. `scripts/04_caso_prueba_2.sql`, `05_caso_prueba_3.sql`, `06_caso_prueba_4.sql` y `07_caso_prueba_5.sql` — en ese orden. Cada archivo puede ejecutarse completo como superadmin; las secciones indican qué usuario ejecutaría cada paso en un entorno real.
6. Cada script termina con consultas de verificación (orden, ítems, domicilio, pago, transacciones, envío y bitácora).

Para regenerar el diccionario después de cambiar de respaldo:

```bash
node Practica04/scripts/generar-diccionario.mjs
```

El generador toma la fuente indicada en `backupFile` dentro de `scripts/generar-diccionario.mjs` y actualiza `../diccionario.html` y los archivos de `diccionario/`.

---

## Enlaces

- [Diccionario de datos](https://angel-saul.github.io/Pracricas_BDN_240196/diccionario.html)
- [Modelo relacional](https://angel-saul.github.io/Pracricas_BDN_240196/Practica03/actualizar-modelo-relacional/salidas/240196_19.11.26-20261119-002131/modelo-relacional.html)

