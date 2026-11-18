-- =====================================================================
-- 05_caso_prueba_3.sql
-- CASO DE PRUEBA 3 — "Compra exitosa con cancelación parcial, ajuste
--                     y reembolso parcial"
--
-- Secciones (cada una en SU conexión y en UNA sola pestaña/sesión):
--   A) app_web (o app_movil) · rol user_not_registered -> pasos 1 a 5
--   B) angel.barrios (superadmin) · "el sistema"       -> paso 6
--   C) app_web (o app_movil) · activa "buyer"          -> paso 7
--   D) angel.barrios (superadmin) · "el sistema"       -> pasos 8 a 11
--   E) angel.barrios (superadmin)                      -> verificación
--
-- Antes de empezar: 01_ajustes_db_test.sql y 03_ajustes_casos_2_a_5.sql.
-- Las secciones B a E localizan la orden solas: es la última pagada con
-- 'Cash' cuyo método de pago es Spin.
-- =====================================================================


-- #####################################################################
-- SECCIÓN A — Conexión: app_web  (o app_movil)
-- #####################################################################
USE db_test;

SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

-- ---------------------------------------------------------------------
-- PASO 1. Usuario YA registrado + carrito de 3 productos de la MISMA
--         categoría, con cantidades de 1 a 10.
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

-- Categoría al azar que tenga al menos 3 productos disponibles (stock >= 10)
SET @category_id = (
    SELECT pc.category_ID
    FROM tbd_products_categories pc
    JOIN tb_products p ON p.ID = pc.product_ID
    JOIN tbd_products_users_providers pr ON pr.product_ID = p.ID
    WHERE pc.status = b'1' AND p.status = b'1' AND pr.status = b'1'
      AND p.current_stock >= 10
    GROUP BY pc.category_ID
    HAVING COUNT(*) >= 3
    ORDER BY RAND()
    LIMIT 1);

INSERT INTO tb_carts (user_ID) VALUES (@user_id);
SET @cart_id = LAST_INSERT_ID();

INSERT INTO tbd_carts_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart_id, x.provider_ID, x.product_ID, 1 + FLOOR(RAND() * 10)
FROM (SELECT pr.user_ID AS provider_ID, p.ID AS product_ID
      FROM tbd_products_categories pc
      JOIN tb_products p ON p.ID = pc.product_ID
      JOIN tbd_products_users_providers pr ON pr.product_ID = p.ID
      WHERE pc.category_ID = @category_id
        AND pc.status = b'1' AND p.status = b'1' AND pr.status = b'1'
        AND p.current_stock >= 10
      ORDER BY RAND()
      LIMIT 3) x;

-- Evidencia: 3 productos, misma categoría
SELECT @category_id AS categoria, ci.product_ID, p.name, ci.quantity, p.current_price,
       ci.quantity * p.current_price AS subtotal
FROM tbd_carts_items ci
JOIN tb_products p ON p.ID = ci.product_ID
WHERE ci.cart_ID = @cart_id;

-- ---------------------------------------------------------------------
-- PASO 2. Orden de compra
-- ---------------------------------------------------------------------
CALL sp_create_order(@user_id, @order_id, @order_total);
SELECT @order_id AS order_id, @order_total AS total_orden;

-- ---------------------------------------------------------------------
-- PASO 3. Domicilio que NO es su hogar: etiqueta "Casa Papas"
-- ---------------------------------------------------------------------
INSERT INTO tb_user_addresses
    (user_ID, address_label, recipient_name, recipient_phone, delivery_instructions, is_default)
VALUES
    (@user_id, 'Casa Papas', 'Familia (padres del cliente)', NULL,
     'Entregar a mamá o papá; casa de portón negro', 0);
SET @address_id = LAST_INSERT_ID();

INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'México', 'country', NULL);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Jalisco', 'state', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Zapopan', 'municipality', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Jardines Vallarta', 'neighborhood', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Calle Los Pinos', 'street', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, '88', 'exterior_number', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, '45027', 'postal_code', @c);

UPDATE tbb_orders SET address_ID = @address_id WHERE ID = @order_id;

-- ---------------------------------------------------------------------
-- PASO 4. Método de pago: tarjeta digital SPIN (cuenta simulada de 16 dígitos)
-- ---------------------------------------------------------------------
SET @card_number = CONCAT('6', LPAD(FLOOR(RAND() * 1000000000000000), 15, '0'));

INSERT INTO tbd_user_payment_methods
    (user_ID, payment_method_type_ID, provider, provider_method_ref, label, last_four, is_default)
VALUES
    (@user_id,
     (SELECT ID FROM tbc_payment_methods_types WHERE code = 'SPIN'),
     'SPIN', @card_number, 'Spin digital simulada', RIGHT(@card_number, 4), 1);
SET @payment_method_id = LAST_INSERT_ID();

SELECT @card_number AS cuenta_simulada_16_digitos, CHAR_LENGTH(@card_number) AS digitos;

-- ---------------------------------------------------------------------
-- PASO 5. UN solo pago EN EFECTIVO por el total de la compra
--         (depósito en efectivo a la cuenta Spin). Activa el rol "buyer".
-- ---------------------------------------------------------------------
SET ROLE 'user_not_registered', 'buyer';
SELECT CURRENT_ROLE() AS roles_activos;

SELECT ROUND(total_cost, 2) INTO @amount FROM tbb_orders WHERE ID = @order_id;

INSERT INTO tb_payments
    (order_ID, user_payment_method_ID, amount, currency, payment_method,
     provider, provider_reference, payment_status)
VALUES
    (@order_id, @payment_method_id, @amount, 'MXN', 'Cash',
     'SPIN', CONCAT('PAY-', @order_id, '-', UNIX_TIMESTAMP()), 'Pending');
SET @payment_id = LAST_INSERT_ID();

SELECT @user_id AS user_id, @order_id AS order_id, @payment_id AS payment_id, @amount AS monto;
-- Fin de la sección A. Puedes cerrar esta conexión.


-- #####################################################################
-- SECCIÓN B — Conexión: angel.barrios (superadmin) = "EL SISTEMA"
-- #####################################################################
USE db_test;

SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

-- Última orden pagada en efectivo con cuenta Spin, aún sin procesar
SELECT pay.ID, pay.order_ID, pay.amount
  INTO @payment_id, @order_id, @amount
FROM tb_payments pay
JOIN tbd_user_payment_methods pm ON pm.ID = pay.user_payment_method_ID
JOIN tbc_payment_methods_types t ON t.ID = pm.payment_method_type_ID
WHERE pay.payment_method = 'Cash' AND t.code = 'SPIN' AND pay.payment_status = 'Pending'
ORDER BY pay.ID DESC
LIMIT 1;

SELECT @payment_id AS payment_id, @order_id AS order_id, @amount AS monto;

-- ---------------------------------------------------------------------
-- PASO 6. El sistema confirma el pago y marca la orden como atendida
-- ---------------------------------------------------------------------
START TRANSACTION;

INSERT INTO tb_payment_transactions (payment_ID, event_type, amount, event_reference, remarks)
VALUES
    (@payment_id, 'Created',    @amount, CONCAT('TX-CRE-',  @payment_id), 'Intención de pago en efectivo registrada'),
    (@payment_id, 'Authorized', @amount, CONCAT('TX-AUTH-', @payment_id), 'Depósito en efectivo confirmado en cuenta Spin'),
    (@payment_id, 'Captured',   @amount, CONCAT('TX-CAP-',  @payment_id), 'Cargo capturado');

UPDATE tb_payments SET payment_status = 'Authorized' WHERE ID = @payment_id;
UPDATE tb_payments SET payment_status = 'Paid', paid_date = NOW() WHERE ID = @payment_id;
UPDATE tbb_orders  SET status_string = 'Payed', last_update = NOW() WHERE ID = @order_id;

UPDATE tbb_orders SET status_string = 'Attended', last_update = NOW() WHERE ID = @order_id;
UPDATE tb_seller_orders SET fulfillment_status = 'Accepted' WHERE order_ID = @order_id;

COMMIT;

SELECT ID, `key`, total_products, total_cost, status_string FROM tbb_orders WHERE ID = @order_id;
-- Fin de la sección B.


-- #####################################################################
-- SECCIÓN C — Conexión: app_web (o app_movil)  ·  CANCELACIÓN PARCIAL
-- #####################################################################
USE db_test;

SET ROLE 'user_not_registered', 'buyer';
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS roles_activos;

SET @order_id = (SELECT pay.order_ID
                 FROM tb_payments pay
                 JOIN tbd_user_payment_methods pm ON pm.ID = pay.user_payment_method_ID
                 JOIN tbc_payment_methods_types t ON t.ID = pm.payment_method_type_ID
                 WHERE pay.payment_method = 'Cash' AND t.code = 'SPIN'
                 ORDER BY pay.ID DESC LIMIT 1);
SET @user_id = (SELECT User_ID FROM tbb_orders WHERE ID = @order_id);

-- ---------------------------------------------------------------------
-- PASO 7. El usuario cancela UN producto del pedido (el último)
-- ---------------------------------------------------------------------
SELECT oi.ID, oi.product_ID, oi.product_name, oi.quantity, oi.subtotal
  INTO @item_id, @cancel_product_id, @cancel_product_name, @cancel_qty, @cancel_amount
FROM tbd_order_items oi
JOIN tb_seller_orders so ON so.ID = oi.seller_order_ID
WHERE so.order_ID = @order_id
ORDER BY oi.ID DESC
LIMIT 1;

INSERT INTO tb_order_cancellations
    (order_ID, requested_by, reason, cancellation_status, refund_required)
VALUES
    (@order_id, @user_id,
     CONCAT('Cancelación parcial: producto ID ', @cancel_product_id, ' (', @cancel_product_name,
            '), ', @cancel_qty, ' unidad(es), monto $', @cancel_amount, '. El cliente ya no lo necesita.'),
     'Requested', 1);

SELECT ID, order_ID, reason, cancellation_status, refund_required
FROM tb_order_cancellations WHERE order_ID = @order_id;
-- Fin de la sección C.


-- #####################################################################
-- SECCIÓN D — Conexión: angel.barrios (superadmin) = "EL SISTEMA"
-- #####################################################################
USE db_test;

SET @order_id = (SELECT pay.order_ID
                 FROM tb_payments pay
                 JOIN tbd_user_payment_methods pm ON pm.ID = pay.user_payment_method_ID
                 JOIN tbc_payment_methods_types t ON t.ID = pm.payment_method_type_ID
                 WHERE pay.payment_method = 'Cash' AND t.code = 'SPIN'
                 ORDER BY pay.ID DESC LIMIT 1);
SET @payment_id = (SELECT ID FROM tb_payments WHERE order_ID = @order_id LIMIT 1);
SET @seller_order_id = (SELECT ID FROM tb_seller_orders WHERE order_ID = @order_id LIMIT 1);
SET @cancellation_id = (SELECT MAX(ID) FROM tb_order_cancellations WHERE order_ID = @order_id);

-- Producto cancelado = el último item de la orden (el mismo del paso 7)
SELECT oi.ID, oi.product_ID, oi.quantity, oi.subtotal
  INTO @item_id, @cancel_product_id, @cancel_qty, @cancel_amount
FROM tbd_order_items oi
WHERE oi.seller_order_ID = @seller_order_id
ORDER BY oi.ID DESC
LIMIT 1;

SELECT @item_id AS item_cancelado, @cancel_product_id AS producto, @cancel_qty AS unidades, @cancel_amount AS monto;

-- ---------------------------------------------------------------------
-- PASO 8. El sistema ACTUALIZA la orden de compra:
--         quita el producto, regresa el stock y recalcula totales
-- ---------------------------------------------------------------------
START TRANSACTION;

UPDATE tb_order_cancellations
   SET cancellation_status = 'Approved',
       resolution_notes = 'Cancelación parcial aprobada. Se ajusta la orden y se reembolsa el producto.'
 WHERE ID = @cancellation_id;

DELETE FROM tbd_order_items WHERE ID = @item_id;

UPDATE tb_products SET current_stock = current_stock + @cancel_qty WHERE ID = @cancel_product_id;

UPDATE tb_seller_orders SET subtotal = subtotal - @cancel_amount WHERE ID = @seller_order_id;

UPDATE tbb_orders
   SET total_products = total_products - @cancel_qty,
       total_cost     = total_cost - @cancel_amount,
       last_update    = NOW()
 WHERE ID = @order_id;

COMMIT;

SELECT o.ID, o.total_products, o.total_cost, so.subtotal AS subtotal_vendedor
FROM tbb_orders o JOIN tb_seller_orders so ON so.order_ID = o.ID
WHERE o.ID = @order_id;

-- ---------------------------------------------------------------------
-- PASO 9. El sistema reembolsa el monto del producto cancelado
-- ---------------------------------------------------------------------
START TRANSACTION;

INSERT INTO tb_refunds (payment_ID, amount, refund_status, reason, provider_reference)
VALUES (@payment_id, @cancel_amount, 'Requested',
        'Reembolso parcial por cancelación de producto', CONCAT('REF-', @payment_id, '-', UNIX_TIMESTAMP()));
SET @refund_id = LAST_INSERT_ID();

UPDATE tb_refunds SET refund_status = 'Processing' WHERE ID = @refund_id;

INSERT INTO tb_payment_transactions (payment_ID, event_type, amount, event_reference, remarks)
VALUES (@payment_id, 'PartiallyRefunded', @cancel_amount, CONCAT('TX-REF-', @refund_id),
        'Reembolso parcial a la cuenta Spin del cliente');

UPDATE tb_refunds SET refund_status = 'Completed', processed_at = NOW() WHERE ID = @refund_id;
UPDATE tb_payments SET payment_status = 'PartiallyRefunded' WHERE ID = @payment_id;
UPDATE tb_order_cancellations SET cancellation_status = 'Completed' WHERE ID = @cancellation_id;

COMMIT;

-- ---------------------------------------------------------------------
-- PASO 10. El sistema realiza el envío
-- ---------------------------------------------------------------------
UPDATE tb_seller_orders SET fulfillment_status = 'Preparing' WHERE ID = @seller_order_id;

INSERT INTO tb_shipments
    (seller_order_ID, carrier, tracking_number, shipment_status,
     shipped_at, estimated_delivery, shipping_notes)
VALUES
    (@seller_order_id, 'Paquetería Simulada',
     CONCAT('TRK-', LPAD(@order_id, 6, '0'), '-', UNIX_TIMESTAMP()),
     'Shipped', NOW(), DATE_ADD(NOW(), INTERVAL 3 DAY),
     'Envío a "Casa Papas" con la orden ya ajustada');
SET @shipment_id = LAST_INSERT_ID();

UPDATE tb_seller_orders SET fulfillment_status = 'Sent' WHERE ID = @seller_order_id;
UPDATE tbb_orders SET status_string = 'Sended', last_update = NOW() WHERE ID = @order_id;

-- ---------------------------------------------------------------------
-- PASO 11. El cliente recibe el pedido en "Casa Papas"
-- ---------------------------------------------------------------------
UPDATE tb_shipments SET shipment_status = 'Delivered', delivered_at = NOW() WHERE ID = @shipment_id;
UPDATE tb_seller_orders SET fulfillment_status = 'Delivered' WHERE ID = @seller_order_id;
UPDATE tbb_orders SET status_string = 'Delivered', last_update = NOW() WHERE ID = @order_id;
-- Fin de la sección D.


-- #####################################################################
-- SECCIÓN E — Conexión: angel.barrios (superadmin)  ·  VERIFICACIÓN
-- #####################################################################
USE db_test;

SET @order_id = (SELECT pay.order_ID
                 FROM tb_payments pay
                 JOIN tbd_user_payment_methods pm ON pm.ID = pay.user_payment_method_ID
                 JOIN tbc_payment_methods_types t ON t.ID = pm.payment_method_type_ID
                 WHERE pay.payment_method = 'Cash' AND t.code = 'SPIN'
                 ORDER BY pay.ID DESC LIMIT 1);

-- E1. Usuario y orden final (el total ya no incluye el producto cancelado)
SELECT u.ID AS user_id, u.email, p.given_names, p.family_names,
       o.ID AS order_id, o.total_products, o.total_cost, o.status_string
FROM tbb_orders o
JOIN tb_users u  ON u.ID = o.User_ID
JOIN tb_people p ON p.user_ID = u.ID
WHERE o.ID = @order_id;

-- E2. Items que quedaron en la orden (2 de 3) y su categoría común
SELECT oi.product_ID, oi.product_name, oi.quantity, oi.unit_price, oi.subtotal,
       GROUP_CONCAT(DISTINCT pc.category_ID) AS categorias
FROM tbd_order_items oi
JOIN tb_seller_orders so ON so.ID = oi.seller_order_ID
LEFT JOIN tbd_products_categories pc ON pc.product_ID = oi.product_ID
WHERE so.order_ID = @order_id
GROUP BY oi.ID, oi.product_ID, oi.product_name, oi.quantity, oi.unit_price, oi.subtotal;

-- E3. Domicilio "Casa Papas" (paso 3)
SELECT a.address_label, a.recipient_name, a.is_default
FROM tbb_orders o JOIN tb_user_addresses a ON a.ID = o.address_ID
WHERE o.ID = @order_id;

-- E4. Método de pago Spin (paso 4) y pago único en efectivo (paso 5)
SELECT pay.ID AS payment_id, pay.amount AS monto_cobrado, pay.payment_method, pay.payment_status,
       pm.label, pm.last_four, pm.provider_method_ref AS cuenta_simulada,
       CHAR_LENGTH(pm.provider_method_ref) AS digitos, t.code AS tipo_metodo
FROM tb_payments pay
JOIN tbd_user_payment_methods pm ON pm.ID = pay.user_payment_method_ID
JOIN tbc_payment_methods_types t ON t.ID = pm.payment_method_type_ID
WHERE pay.order_ID = @order_id;

-- E5. Transacciones (pasos 6 y 9)
SELECT t.ID, t.event_type, t.amount, t.event_reference, t.remarks
FROM tb_payment_transactions t JOIN tb_payments pay ON pay.ID = t.payment_ID
WHERE pay.order_ID = @order_id ORDER BY t.ID;

-- E6. Cancelación parcial y reembolso (pasos 7 a 9)
SELECT c.ID, c.reason, c.cancellation_status, c.refund_required, c.resolution_notes
FROM tb_order_cancellations c WHERE c.order_ID = @order_id;

SELECT r.ID, r.amount AS monto_reembolsado, r.refund_status, r.reason, r.processed_at
FROM tb_refunds r JOIN tb_payments pay ON pay.ID = r.payment_ID
WHERE pay.order_ID = @order_id;

-- E7. Envío y entrega (pasos 10 y 11)
SELECT s.ID, s.carrier, s.tracking_number, s.shipment_status, s.shipped_at, s.delivered_at,
       so.fulfillment_status
FROM tb_shipments s JOIN tb_seller_orders so ON so.ID = s.seller_order_ID
WHERE so.order_ID = @order_id;

-- E8. Bitácora
SELECT ID, table_name, operation, db_user, operation_date
FROM tb_logs ORDER BY ID DESC LIMIT 60;
