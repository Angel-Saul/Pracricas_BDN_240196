-- =====================================================================
-- 04_caso_prueba_2.sql
-- CASO DE PRUEBA 2 — "Compra con detalles en el último pago, con
--                     reclamación y reenvío"
--
-- Secciones (cada una en SU conexión y en UNA sola pestaña/sesión):
--   A) app_web (o app_movil) · rol user_not_registered -> pasos 1 a 5
--   B) angel.barrios (superadmin) · "el sistema"       -> pasos 6 y 7
--   C) jose.castillo (seller)                          -> paso 8
--   D) app_web (o app_movil) · activa "buyer"          -> paso 9
--   E) angel.barrios (superadmin) · "el sistema"       -> paso 10
--   F) angel.barrios (superadmin)                      -> verificación
--
-- Antes de empezar: 01_ajustes_db_test.sql y 03_ajustes_casos_2_a_5.sql.
-- Las secciones B a F localizan la orden solas: es la que tiene 6 pagos.
-- EJECUCIÓN: el archivo completo se puede correr de una sola vez con
--   mysql -u angel.barrios -p --port=40196 < 04_caso_prueba_2.sql
-- Las "secciones" indican qué usuario haría cada paso en un ambiente real
-- (usuario de la app, vendedor, sistema); aquí todas las ejecuta el superadmin.
-- =====================================================================


-- #####################################################################
-- SECCIÓN A — Conexión: app_web  (o app_movil)
-- #####################################################################
USE db_test;

SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

-- ---------------------------------------------------------------------
-- PASO 1. Usuario YA registrado (de los ~10k) + carrito de 10 productos
--         aleatorios con cantidades de 1 a 5.
--         tb_carts permite un solo carrito por usuario, así que se elige
--         un usuario que todavía no tenga carrito.
-- ---------------------------------------------------------------------
SET @user_id = (
    SELECT u.ID
    FROM tb_users u
    JOIN tb_people p ON p.user_ID = u.ID
    WHERE u.status = b'1'
      AND u.email NOT LIKE '%utxicotepec%'
      AND NOT EXISTS (SELECT 1 FROM tb_carts c WHERE c.user_ID = u.ID)
      AND NOT EXISTS (SELECT 1 FROM tbd_products_users_providers pr WHERE pr.user_ID = u.ID)
    ORDER BY RAND()
    LIMIT 1);

SELECT u.ID AS user_id, u.email, u.nick, p.given_names, p.family_names
FROM tb_users u JOIN tb_people p ON p.user_ID = u.ID
WHERE u.ID = @user_id;

INSERT INTO tb_carts (user_ID) VALUES (@user_id);
SET @cart_id = LAST_INSERT_ID();

INSERT INTO tbd_carts_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart_id, x.provider_ID, x.product_ID, 1 + FLOOR(RAND() * 5)
FROM (SELECT pr.user_ID AS provider_ID, p.ID AS product_ID
      FROM tb_products p
      JOIN tbd_products_users_providers pr ON pr.product_ID = p.ID
      WHERE p.status = b'1' AND pr.status = b'1' AND p.current_stock >= 5
      ORDER BY RAND()
      LIMIT 10) x;

-- Evidencia
SELECT ci.product_ID, p.name, ci.quantity, p.current_price,
       ci.quantity * p.current_price AS subtotal, p.current_stock
FROM tbd_carts_items ci
JOIN tb_products p ON p.ID = ci.product_ID
WHERE ci.cart_ID = @cart_id;

-- ---------------------------------------------------------------------
-- PASO 2. Orden de compra (crea orden, orden por vendedor, items, stock)
-- ---------------------------------------------------------------------
CALL sp_create_order(@user_id, @order_id, @order_total);
SELECT @order_id AS order_id, @order_total AS total_orden;

-- ---------------------------------------------------------------------
-- PASO 3. Domicilio de envío que NO es su hogar: su trabajo
-- ---------------------------------------------------------------------
INSERT INTO tb_user_addresses
    (user_ID, address_label, recipient_name, recipient_phone, delivery_instructions, is_default)
SELECT @user_id, 'Trabajo', CONCAT(p.given_names, ' ', COALESCE(p.family_names, '')), p.phone,
       'Entregar en recepción del edificio, horario de oficina 9:00 a 18:00', 0
FROM tb_people p WHERE p.user_ID = @user_id;
SET @address_id = LAST_INSERT_ID();

INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'México', 'country', NULL);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Nuevo León', 'state', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'San Pedro Garza García', 'municipality', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Del Valle', 'neighborhood', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Av. Vasconcelos', 'street', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, '400 Piso 5', 'exterior_number', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, '66220', 'postal_code', @c);

UPDATE tbb_orders SET address_ID = @address_id WHERE ID = @order_id;

-- ---------------------------------------------------------------------
-- PASO 4. Método de pago: tarjeta de CRÉDITO (cuenta simulada de 16 dígitos)
-- ---------------------------------------------------------------------
SET @card_number = CONCAT('5', LPAD(FLOOR(RAND() * 1000000000000000), 15, '0'));

INSERT INTO tbd_user_payment_methods
    (user_ID, payment_method_type_ID, provider, provider_method_ref, label, last_four, is_default)
VALUES
    (@user_id,
     (SELECT ID FROM tbc_payment_methods_types WHERE code = 'CREDIT_CARD'),
     'BANCO_SIMULADO', @card_number, 'Crédito simulada', RIGHT(@card_number, 4), 1);
SET @payment_method_id = LAST_INSERT_ID();

SELECT @card_number AS cuenta_simulada_16_digitos, CHAR_LENGTH(@card_number) AS digitos;

-- ---------------------------------------------------------------------
-- PASO 5. 6 pagos mensuales. Al pagar se ACTIVA el rol "buyer".
--         Los primeros 5 son iguales; el 6.º absorbe el redondeo.
-- ---------------------------------------------------------------------
-- (Todo se ejecuta como superadmin: aquí el usuario normalmente activaría el rol "buyer")
SELECT CURRENT_ROLE() AS roles_activos;

SELECT ROUND(total_cost, 2) INTO @amount FROM tbb_orders WHERE ID = @order_id;
SET @cuota = ROUND(@amount / 6, 2);

INSERT INTO tb_payments
    (order_ID, user_payment_method_ID, amount, currency, payment_method,
     provider, provider_reference, payment_status)
SELECT @order_id, @payment_method_id,
       IF(m.n < 6, @cuota, @amount - 5 * @cuota),
       'MXN', 'Card', 'BANCO_SIMULADO',
       CONCAT('PAY-', @order_id, '-M', m.n, '-', UNIX_TIMESTAMP()), 'Pending'
FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3
      UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6) m
ORDER BY m.n;

SELECT ID AS payment_id, order_ID, amount, provider_reference, payment_status
FROM tb_payments WHERE order_ID = @order_id ORDER BY ID;
-- Fin de la sección A. Puedes cerrar esta conexión.


-- #####################################################################
-- SECCIÓN B — Conexión: angel.barrios (superadmin) = "EL SISTEMA"
-- #####################################################################
USE db_test;

SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

-- La orden del caso 2 es la última que tiene 6 pagos
SET @order_id = (SELECT order_ID FROM tb_payments
                 GROUP BY order_ID HAVING COUNT(*) = 6
                 ORDER BY order_ID DESC LIMIT 1);
SET @last_payment_id = (SELECT MAX(ID) FROM tb_payments WHERE order_ID = @order_id);
SELECT @order_id AS order_id, @last_payment_id AS pago_6;

-- ---------------------------------------------------------------------
-- PASO 6. Transacciones bancarias: autoriza los pagos 1 a 5 y RECHAZA el 6.º
-- ---------------------------------------------------------------------
START TRANSACTION;

-- Pagos 1 a 5: Created -> Authorized -> Captured
INSERT INTO tb_payment_transactions (payment_ID, event_type, amount, event_reference, remarks)
SELECT q.ID, e.event_type, q.amount,
       CONCAT('TX-', e.tag, '-', q.ID),
       CONCAT(e.remark, ' (mensualidad ', q.rn, '/6)')
FROM (SELECT p.ID, p.amount, ROW_NUMBER() OVER (ORDER BY p.ID) AS rn
      FROM tb_payments p WHERE p.order_ID = @order_id) q
JOIN (SELECT 1 AS ord, 'Created' AS event_type, 'CRE' AS tag, 'Intención de pago registrada' AS remark
      UNION ALL SELECT 2, 'Authorized', 'AUTH', 'Autorizada por el banco simulado'
      UNION ALL SELECT 3, 'Captured',   'CAP',  'Cargo capturado') e
WHERE q.ID <> @last_payment_id
ORDER BY q.ID, e.ord;

UPDATE tb_payments SET payment_status = 'Authorized'
 WHERE order_ID = @order_id AND ID <> @last_payment_id;
UPDATE tb_payments SET payment_status = 'Paid', paid_date = NOW()
 WHERE order_ID = @order_id AND ID <> @last_payment_id;

-- Pago 6: se crea y el banco lo rechaza
INSERT INTO tb_payment_transactions (payment_ID, event_type, amount, event_reference, remarks)
SELECT ID, 'Created', amount, CONCAT('TX-CRE-', ID), 'Intención de pago registrada (mensualidad 6/6)'
FROM tb_payments WHERE ID = @last_payment_id;

INSERT INTO tb_payment_transactions (payment_ID, event_type, amount, event_reference, remarks)
SELECT ID, 'Failed', amount, CONCAT('TX-FAIL-', ID), 'Rechazado: límite excedido de crédito'
FROM tb_payments WHERE ID = @last_payment_id;

UPDATE tb_payments SET payment_status = 'Failed' WHERE ID = @last_payment_id;

-- Con la compra a meses aprobada la orden queda pagada
UPDATE tbb_orders SET status_string = 'Payed', last_update = NOW() WHERE ID = @order_id;

COMMIT;

-- ---------------------------------------------------------------------
-- PASO 7. El sistema procesa la orden y la marca como atendida
-- ---------------------------------------------------------------------
START TRANSACTION;

UPDATE tbb_orders SET status_string = 'Attended', last_update = NOW() WHERE ID = @order_id;
UPDATE tb_seller_orders SET fulfillment_status = 'Accepted' WHERE order_ID = @order_id;

-- Registro en tb_buyer_orders (esta tabla no tiene order_ID, así que no
-- queda ligada a la orden; se llena con los datos del vendedor de la orden)
INSERT INTO tb_buyer_orders (seller_ID, subtotal, shipping_cost, fulfillment_status)
SELECT so.seller_ID, so.subtotal, so.shipping_cost, 'Accepted'
FROM tb_seller_orders so
WHERE so.order_ID = @order_id
LIMIT 1;

COMMIT;

SELECT ID, `key`, status_string FROM tbb_orders WHERE ID = @order_id;
SELECT ID, seller_ID, subtotal, shipping_cost, fulfillment_status
FROM tb_buyer_orders ORDER BY ID DESC LIMIT 1;
-- Fin de la sección B.


-- #####################################################################
-- SECCIÓN C — Conexión: jose.castillo (seller)
-- #####################################################################
USE db_test;

SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

SET @order_id = (SELECT order_ID FROM tb_payments
                 GROUP BY order_ID HAVING COUNT(*) = 6
                 ORDER BY order_ID DESC LIMIT 1);
SET @seller_order_id = (SELECT ID FROM tb_seller_orders WHERE order_ID = @order_id LIMIT 1);

-- ---------------------------------------------------------------------
-- PASO 8. Envío y entrega del producto en el domicilio
-- ---------------------------------------------------------------------
UPDATE tb_seller_orders SET fulfillment_status = 'Preparing' WHERE ID = @seller_order_id;

INSERT INTO tb_shipments
    (seller_order_ID, carrier, tracking_number, shipment_status,
     shipped_at, estimated_delivery, shipping_notes)
VALUES
    (@seller_order_id, 'Paquetería Simulada',
     CONCAT('TRK-', LPAD(@order_id, 6, '0'), '-', UNIX_TIMESTAMP()),
     'Shipped', NOW(), DATE_ADD(NOW(), INTERVAL 3 DAY),
     'Envío a domicilio (trabajo) registrado en la orden');
SET @shipment_id = LAST_INSERT_ID();

UPDATE tb_seller_orders SET fulfillment_status = 'Sent' WHERE ID = @seller_order_id;
UPDATE tbb_orders SET status_string = 'Sended', last_update = NOW() WHERE ID = @order_id;

UPDATE tb_shipments SET shipment_status = 'Delivered', delivered_at = NOW() WHERE ID = @shipment_id;
UPDATE tb_seller_orders SET fulfillment_status = 'Delivered' WHERE ID = @seller_order_id;
UPDATE tbb_orders SET status_string = 'Delivered', last_update = NOW() WHERE ID = @order_id;
-- Fin de la sección C.


-- #####################################################################
-- SECCIÓN D — Conexión: app_web (o app_movil)  ·  RECLAMACIÓN
-- #####################################################################
USE db_test;

-- (Todo se ejecuta como superadmin: aquí el usuario normalmente activaría el rol "buyer")
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS roles_activos;

SET @order_id = (SELECT order_ID FROM tb_payments
                 GROUP BY order_ID HAVING COUNT(*) = 6
                 ORDER BY order_ID DESC LIMIT 1);
SET @user_id  = (SELECT User_ID FROM tbb_orders WHERE ID = @order_id);

-- ---------------------------------------------------------------------
-- PASO 9. El usuario reclama la devolución de UN producto que llegó dañado
--         (se toma el primer producto de la orden)
-- ---------------------------------------------------------------------
SELECT oi.product_ID, oi.product_name
  INTO @damaged_product_id, @damaged_product_name
FROM tbd_order_items oi
JOIN tb_seller_orders so ON so.ID = oi.seller_order_ID
WHERE so.order_ID = @order_id
ORDER BY oi.ID
LIMIT 1;

INSERT INTO tb_order_cancellations
    (order_ID, requested_by, reason, cancellation_status, refund_required)
VALUES
    (@order_id, @user_id,
     CONCAT('Reclamación: el producto ID ', @damaged_product_id, ' (', @damaged_product_name,
            ') llegó dañado. Se solicita devolución y reenvío en buenas condiciones.'),
     'Requested', 0);

SELECT ID, order_ID, reason, cancellation_status, refund_required
FROM tb_order_cancellations WHERE order_ID = @order_id;
-- Fin de la sección D.


-- #####################################################################
-- SECCIÓN E — Conexión: angel.barrios (superadmin) = "EL SISTEMA"
-- #####################################################################
USE db_test;

SET @order_id = (SELECT order_ID FROM tb_payments
                 GROUP BY order_ID HAVING COUNT(*) = 6
                 ORDER BY order_ID DESC LIMIT 1);
SET @seller_order_id = (SELECT ID FROM tb_seller_orders WHERE order_ID = @order_id LIMIT 1);
SET @cancellation_id = (SELECT MAX(ID) FROM tb_order_cancellations WHERE order_ID = @order_id);
SET @first_shipment_id = (SELECT MIN(ID) FROM tb_shipments WHERE seller_order_ID = @seller_order_id);
SET @damaged_product_id = (SELECT oi.product_ID FROM tbd_order_items oi
                           WHERE oi.seller_order_ID = @seller_order_id ORDER BY oi.ID LIMIT 1);

-- ---------------------------------------------------------------------
-- PASO 10. El sistema aprueba la reclamación, recibe el producto dañado
--          y hace el REENVÍO de una unidad en buenas condiciones
-- ---------------------------------------------------------------------
START TRANSACTION;

-- 10a. Reclamación aprobada; el envío original queda como devuelto
UPDATE tb_order_cancellations
   SET cancellation_status = 'Approved',
       resolution_notes = 'Producto dañado confirmado. Se aprueba reenvío sin reembolso.'
 WHERE ID = @cancellation_id;

UPDATE tb_shipments SET shipment_status = 'Returned',
       shipping_notes = CONCAT(COALESCE(shipping_notes, ''), ' | Devolución parcial: producto dañado')
 WHERE ID = @first_shipment_id;
UPDATE tb_seller_orders SET fulfillment_status = 'Returned' WHERE ID = @seller_order_id;
UPDATE tbb_orders SET status_string = 'Devolved', last_update = NOW() WHERE ID = @order_id;

-- 10b. Reenvío: sale 1 unidad nueva del inventario
UPDATE tb_products SET current_stock = current_stock - 1
 WHERE ID = @damaged_product_id AND current_stock > 0;

INSERT INTO tb_shipments
    (seller_order_ID, carrier, tracking_number, shipment_status,
     shipped_at, estimated_delivery, shipping_notes)
VALUES
    (@seller_order_id, 'Paquetería Simulada',
     CONCAT('RESHIP-', LPAD(@order_id, 6, '0'), '-', UNIX_TIMESTAMP()),
     'Shipped', NOW(), DATE_ADD(NOW(), INTERVAL 2 DAY),
     CONCAT('Reenvío del producto ID ', @damaged_product_id, ' en buenas condiciones'));
SET @reship_id = LAST_INSERT_ID();

UPDATE tb_seller_orders SET fulfillment_status = 'Sent' WHERE ID = @seller_order_id;
UPDATE tbb_orders SET status_string = 'Sended', last_update = NOW() WHERE ID = @order_id;

-- 10c. El usuario recibe el reenvío y se cierra la reclamación
UPDATE tb_shipments SET shipment_status = 'Delivered', delivered_at = NOW() WHERE ID = @reship_id;
UPDATE tb_seller_orders SET fulfillment_status = 'Delivered' WHERE ID = @seller_order_id;
UPDATE tbb_orders SET status_string = 'Delivered', last_update = NOW() WHERE ID = @order_id;
UPDATE tb_order_cancellations SET cancellation_status = 'Completed' WHERE ID = @cancellation_id;

COMMIT;
-- Fin de la sección E.


-- #####################################################################
-- SECCIÓN F — Conexión: angel.barrios (superadmin)  ·  VERIFICACIÓN
-- #####################################################################
USE db_test;

SET @order_id = (SELECT order_ID FROM tb_payments
                 GROUP BY order_ID HAVING COUNT(*) = 6
                 ORDER BY order_ID DESC LIMIT 1);

-- F1. Usuario y orden (pasos 1 y 2): 10 productos distintos, cantidades 1 a 5
SELECT u.ID AS user_id, u.email, p.given_names, p.family_names,
       o.ID AS order_id, o.total_products AS unidades, o.total_cost, o.status_string
FROM tbb_orders o
JOIN tb_users u  ON u.ID = o.User_ID
JOIN tb_people p ON p.user_ID = u.ID
WHERE o.ID = @order_id;

SELECT COUNT(*) AS productos_distintos, MIN(oi.quantity) AS cant_min, MAX(oi.quantity) AS cant_max
FROM tbd_order_items oi JOIN tb_seller_orders so ON so.ID = oi.seller_order_ID
WHERE so.order_ID = @order_id;

-- F2. Domicilio de trabajo ligado (paso 3)
SELECT a.address_label, a.recipient_name, a.is_default
FROM tbb_orders o JOIN tb_user_addresses a ON a.ID = o.address_ID
WHERE o.ID = @order_id;

SELECT c.component_type, c.value
FROM tbd_address_components c JOIN tbb_orders o ON o.address_ID = c.address_ID
WHERE o.ID = @order_id ORDER BY c.ID;

-- F3. Tarjeta de crédito (paso 4)
SELECT pm.label, pm.last_four, pm.provider_method_ref AS cuenta_simulada,
       CHAR_LENGTH(pm.provider_method_ref) AS digitos, t.code AS tipo
FROM tbd_user_payment_methods pm
JOIN tbc_payment_methods_types t ON t.ID = pm.payment_method_type_ID
WHERE pm.ID = (SELECT user_payment_method_ID FROM tb_payments WHERE order_ID = @order_id LIMIT 1);

-- F4. Los 6 pagos y su suma (pasos 5 y 6): 5 Paid + 1 Failed
SELECT pay.ID AS payment_id, pay.amount, pay.payment_status, pay.paid_date
FROM tb_payments pay WHERE pay.order_ID = @order_id ORDER BY pay.ID;

SELECT SUM(amount) AS suma_pagos, (SELECT ROUND(total_cost, 2) FROM tbb_orders WHERE ID = @order_id) AS total_orden
FROM tb_payments WHERE order_ID = @order_id;

SELECT t.payment_ID, t.event_type, t.amount, t.event_reference, t.remarks
FROM tb_payment_transactions t JOIN tb_payments pay ON pay.ID = t.payment_ID
WHERE pay.order_ID = @order_id ORDER BY t.ID;

-- F5. Envío original, reclamación y reenvío (pasos 8 a 10)
SELECT s.ID, s.tracking_number, s.shipment_status, s.shipped_at, s.delivered_at, s.shipping_notes
FROM tb_shipments s JOIN tb_seller_orders so ON so.ID = s.seller_order_ID
WHERE so.order_ID = @order_id ORDER BY s.ID;

SELECT ID, reason, cancellation_status, refund_required, resolution_notes
FROM tb_order_cancellations WHERE order_ID = @order_id;

SELECT o.status_string AS estado_orden, so.fulfillment_status AS estado_vendedor
FROM tbb_orders o JOIN tb_seller_orders so ON so.order_ID = o.ID
WHERE o.ID = @order_id;

-- F6. Registro en tb_buyer_orders (paso 7)
SELECT ID, seller_ID, subtotal, shipping_cost, fulfillment_status
FROM tb_buyer_orders ORDER BY ID DESC LIMIT 1;

-- F7. Bitácora
SELECT ID, table_name, operation, db_user, operation_date
FROM tb_logs ORDER BY ID DESC LIMIT 60;
