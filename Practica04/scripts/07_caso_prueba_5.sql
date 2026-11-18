-- =====================================================================
-- 07_caso_prueba_5.sql
-- CASO DE PRUEBA 5 — "Compra fallida por falta de inventario"
--
-- Secciones (cada una en SU conexión y en UNA sola pestaña/sesión):
--   A) app_web (o app_movil) · rol user_not_registered -> pasos 1 a 4
--   B) jose.castillo (seller) · reporta que no hay existencia física
--   C) angel.barrios (superadmin) · "el sistema"       -> pasos 5 y 6
--   D) angel.barrios (superadmin)                      -> verificación
--
-- EL CUPÓN ES UN MÉTODO DE PAGO (no hay tabla de cupones):
-- vive en tbd_user_payment_methods con tipo GIFT_COUPON.
--   status = 1 -> cupón disponible
--   status = 0 -> cupón usado en una orden
-- Al cancelar la orden el cupón se "reasigna" devolviéndolo a status = 1.
--
-- Antes de empezar: 01_ajustes_db_test.sql y 03_ajustes_casos_2_a_5.sql.
--
-- CÓMO SE PROVOCA LA FALTA DE INVENTARIO:
-- sp_create_order rechaza el carrito si el stock no alcanza, así que la
-- orden solo puede existir si había stock al comprar. La falta aparece
-- después: el vendedor hace su conteo físico (sección C), reporta 0
-- existencias del producto y el sistema ya no puede surtir la orden.
-- Por eso al cancelar NO se regresa stock (esas unidades no existen).
-- =====================================================================


-- #####################################################################
-- SECCIÓN A — Conexión: app_web  (o app_movil)
-- #####################################################################
USE db_test;

SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

-- ---------------------------------------------------------------------
-- PASO 1. Usuario YA registrado + carrito de 1 producto, de 1 a 5 unidades
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
      LIMIT 1) x;

SELECT ci.provider_ID, ci.product_ID, p.name, ci.quantity, p.current_price,
       ci.quantity * p.current_price AS subtotal, p.current_stock AS stock_antes
FROM tbd_carts_items ci
JOIN tb_products p ON p.ID = ci.product_ID
WHERE ci.cart_ID = @cart_id;

-- ---------------------------------------------------------------------
-- PASO 2. Orden de compra
-- ---------------------------------------------------------------------
CALL sp_create_order(@user_id, @order_id, @order_total);
SELECT @order_id AS order_id, @order_total AS total_orden;

-- ---------------------------------------------------------------------
-- PASO 3. Domicilio que NO es su hogar (casa de un familiar)
-- ---------------------------------------------------------------------
INSERT INTO tb_user_addresses
    (user_ID, address_label, recipient_name, recipient_phone, delivery_instructions, is_default)
VALUES
    (@user_id, 'Casa de mi tía', 'Laura Pérez Soto', '+52 22 8899 1122',
     'Tocar el timbre dos veces', 0);
SET @address_id = LAST_INSERT_ID();

INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'México', 'country', NULL);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Veracruz', 'state', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Xalapa', 'municipality', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Centro', 'neighborhood', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Calle Enríquez', 'street', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, '45', 'exterior_number', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, '91000', 'postal_code', @c);

UPDATE tbb_orders SET address_ID = @address_id WHERE ID = @order_id;

-- ---------------------------------------------------------------------
-- PASO 4. Método de pago: CUPÓN DE REGALO.
--         El cupón se registra como método de pago del usuario (tipo
--         GIFT_COUPON) y se usa para pagar la orden: queda con status = 0
--         (usado). Activa el rol "buyer".
-- ---------------------------------------------------------------------
SET ROLE 'user_not_registered', 'buyer';
SELECT CURRENT_ROLE() AS roles_activos;

SET @coupon_code = CONCAT('GIFT-', UPPER(SUBSTRING(MD5(RAND()), 1, 8)));

INSERT INTO tbd_user_payment_methods
    (user_ID, payment_method_type_ID, provider, provider_method_ref, label, last_four, is_default, status)
VALUES
    (@user_id,
     (SELECT ID FROM tbc_payment_methods_types WHERE code = 'GIFT_COUPON'),
     'CUPONES_REGALO', @coupon_code, 'Cupón de regalo', RIGHT(@coupon_code, 4), 0, b'1');
SET @payment_method_id = LAST_INSERT_ID();

SELECT ROUND(total_cost, 2) INTO @amount FROM tbb_orders WHERE ID = @order_id;

INSERT INTO tb_payments
    (order_ID, user_payment_method_ID, amount, currency, payment_method,
     provider, provider_reference, payment_status)
VALUES
    (@order_id, @payment_method_id, @amount, 'MXN', 'GiftCoupon',
     'CUPONES_REGALO', CONCAT(@coupon_code, '-ORD', @order_id), 'Pending');
SET @payment_id = LAST_INSERT_ID();

-- El cupón queda usado por esta orden
UPDATE tbd_user_payment_methods SET status = b'0' WHERE ID = @payment_method_id;

SELECT pm.ID AS cupon_id, pm.provider_method_ref AS cupon, pm.status + 0 AS cupon_activo,
       @user_id AS user_id, @order_id AS order_id, @payment_id AS payment_id, @amount AS monto
FROM tbd_user_payment_methods pm WHERE pm.ID = @payment_method_id;
-- Fin de la sección A.


-- #####################################################################
-- SECCIÓN B — Conexión: jose.castillo (seller)  ·  CONTEO FÍSICO
-- #####################################################################
USE db_test;

SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

SET @order_id = (SELECT order_ID FROM tb_payments
                 WHERE payment_method = 'GiftCoupon' ORDER BY ID DESC LIMIT 1);

-- El vendedor hace conteo físico y reporta 0 existencias del producto vendido
UPDATE tb_products
   SET current_stock = 0
 WHERE ID IN (SELECT oi.product_ID
              FROM tbd_order_items oi
              JOIN tb_seller_orders so ON so.ID = oi.seller_order_ID
              WHERE so.order_ID = @order_id);

SELECT p.ID, p.name, p.current_stock AS existencia_fisica
FROM tb_products p
WHERE p.ID IN (SELECT oi.product_ID FROM tbd_order_items oi
               JOIN tb_seller_orders so ON so.ID = oi.seller_order_ID
               WHERE so.order_ID = @order_id);
-- Fin de la sección C.


-- #####################################################################
-- SECCIÓN C — Conexión: angel.barrios (superadmin) = "EL SISTEMA"
-- #####################################################################
USE db_test;

SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

SELECT pay.ID, pay.order_ID
  INTO @payment_id, @order_id
FROM tb_payments pay
WHERE pay.payment_method = 'GiftCoupon' AND pay.payment_status = 'Pending'
ORDER BY pay.ID DESC
LIMIT 1;

SET @seller_order_id = (SELECT ID FROM tb_seller_orders WHERE order_ID = @order_id LIMIT 1);
SET @user_id = (SELECT User_ID FROM tbb_orders WHERE ID = @order_id);
SET @amount  = (SELECT amount FROM tb_payments WHERE ID = @payment_id);

-- ---------------------------------------------------------------------
-- PASO 5. El sistema intenta atender la orden: valida inventario.
--         Faltan unidades -> la orden NO se atiende (queda en 'Registered').
-- ---------------------------------------------------------------------
SELECT oi.product_ID, oi.product_name, oi.quantity AS unidades_pedidas,
       p.current_stock AS existencia_fisica,
       IF(p.current_stock = 0, 'SIN INVENTARIO', 'OK') AS validacion
FROM tbd_order_items oi
JOIN tb_seller_orders so ON so.ID = oi.seller_order_ID
JOIN tb_products p ON p.ID = oi.product_ID
WHERE so.order_ID = @order_id;

START TRANSACTION;

INSERT INTO tb_order_cancellations
    (order_ID, requested_by, reason, cancellation_status, refund_required, resolution_notes)
VALUES
    (@order_id, NULL,
     'Orden no atendida por falta de inventario',
     'Requested', 0,
     'El conteo físico del vendedor reportó 0 existencias del producto ordenado.');
SET @cancellation_id = LAST_INSERT_ID();

-- El pago con cupón no se concreta
INSERT INTO tb_payment_transactions (payment_ID, event_type, amount, event_reference, remarks)
VALUES
    (@payment_id, 'Created', @amount, CONCAT('TX-CRE-',  @payment_id), 'Intención de pago con cupón registrada'),
    (@payment_id, 'Failed',  @amount, CONCAT('TX-FAIL-', @payment_id), 'No se concreta: orden sin inventario');

UPDATE tb_payments SET payment_status = 'Failed' WHERE ID = @payment_id;

COMMIT;

-- ---------------------------------------------------------------------
-- PASO 6. El sistema CANCELA la orden y REASIGNA el cupón utilizado
-- ---------------------------------------------------------------------
START TRANSACTION;

UPDATE tbb_orders SET status_string = 'Canceled', last_update = NOW() WHERE ID = @order_id;
UPDATE tb_seller_orders SET fulfillment_status = 'Canceled' WHERE ID = @seller_order_id;

UPDATE tb_order_cancellations
   SET cancellation_status = 'Completed',
       resolution_notes = CONCAT(resolution_notes, ' Orden cancelada y cupón devuelto al cliente.')
 WHERE ID = @cancellation_id;

-- Se REASIGNA el cupón utilizado: vuelve a estar disponible para el cliente
UPDATE tbd_user_payment_methods pm
JOIN tb_payments pay ON pay.user_payment_method_ID = pm.ID
   SET pm.status = b'1'
 WHERE pay.ID = @payment_id AND pm.user_ID = @user_id;

COMMIT;

SELECT ID, `key`, status_string FROM tbb_orders WHERE ID = @order_id;
-- Fin de la sección D.


-- #####################################################################
-- SECCIÓN D — Conexión: angel.barrios (superadmin)  ·  VERIFICACIÓN
-- #####################################################################
USE db_test;

SET @order_id = (SELECT order_ID FROM tb_payments
                 WHERE payment_method = 'GiftCoupon' ORDER BY ID DESC LIMIT 1);

-- D1. Usuario y orden cancelada
SELECT u.ID AS user_id, u.email, p.given_names, p.family_names,
       o.ID AS order_id, o.total_products, o.total_cost, o.status_string
FROM tbb_orders o
JOIN tb_users u  ON u.ID = o.User_ID
JOIN tb_people p ON p.user_ID = u.ID
WHERE o.ID = @order_id;

-- D2. Producto, cantidad y existencia (paso 1)
SELECT oi.provider_ID, oi.product_ID, oi.product_name, oi.quantity, p.current_stock AS existencia_actual
FROM tbd_order_items oi
JOIN tb_seller_orders so ON so.ID = oi.seller_order_ID
JOIN tb_products p ON p.ID = oi.product_ID
WHERE so.order_ID = @order_id;

-- D3. Domicilio (paso 3)
SELECT a.address_label, a.recipient_name
FROM tbb_orders o JOIN tb_user_addresses a ON a.ID = o.address_ID
WHERE o.ID = @order_id;

-- D4. Método cupón y pago fallido (paso 4)
SELECT pay.ID AS payment_id, pay.amount, pay.payment_method, pay.payment_status,
       pm.label, pm.provider_method_ref AS cupon, t.code AS tipo_metodo
FROM tb_payments pay
JOIN tbd_user_payment_methods pm ON pm.ID = pay.user_payment_method_ID
JOIN tbc_payment_methods_types t ON t.ID = pm.payment_method_type_ID
WHERE pay.order_ID = @order_id;

SELECT t.ID, t.event_type, t.amount, t.event_reference, t.remarks
FROM tb_payment_transactions t JOIN tb_payments pay ON pay.ID = t.payment_ID
WHERE pay.order_ID = @order_id ORDER BY t.ID;

-- D5. Orden no atendida y cancelada (pasos 5 y 6)
SELECT c.ID, c.reason, c.cancellation_status, c.resolution_notes
FROM tb_order_cancellations c WHERE c.order_ID = @order_id;

SELECT so.fulfillment_status FROM tb_seller_orders so WHERE so.order_ID = @order_id;

SELECT COUNT(*) AS envios_creados FROM tb_shipments s
JOIN tb_seller_orders so ON so.ID = s.seller_order_ID WHERE so.order_ID = @order_id;

-- D6. Cupón reasignado: vuelve a estar activo (status = 1) para el mismo usuario
SELECT pm.ID, pm.provider_method_ref AS cupon, pm.status + 0 AS cupon_activo, pm.user_ID
FROM tbd_user_payment_methods pm
JOIN tbc_payment_methods_types t ON t.ID = pm.payment_method_type_ID
WHERE t.code = 'GIFT_COUPON'
  AND pm.user_ID = (SELECT User_ID FROM tbb_orders WHERE ID = @order_id);

-- D7. Bitácora
SELECT ID, table_name, operation, db_user, operation_date
FROM tb_logs ORDER BY ID DESC LIMIT 60;
