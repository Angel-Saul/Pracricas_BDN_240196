-- =====================================================================
-- 06_caso_prueba_4.sql
-- CASO DE PRUEBA 4 — "Compra exitosa del mismo proveedor con entrega en
--                     el punto de recolección"
--
-- Secciones (cada una en SU conexión y en UNA sola pestaña/sesión):
--   A) app_web (o app_movil) · rol user_not_registered -> pasos 1 a 5
--   B) angel.barrios (superadmin) · "el sistema"       -> pasos 6 y 7
--   C) jose.castillo (seller)                          -> paso 8
--   D) angel.barrios (superadmin)                      -> verificación
--
-- Antes de empezar: 01_ajustes_db_test.sql y 03_ajustes_casos_2_a_5.sql.
-- Las secciones B a D localizan la orden solas: la última pagada con SPEI.
--
-- NOTA: el enunciado dice "un solo pago en efectivo", pero el método
-- registrado es SPEI. Aquí el pago se registra como 'SPEI' para que sea
-- coherente. Si tu profesor quiere 'Cash', cambia el valor de
-- @pay_method en el paso 5 (y 'SPEI' en las secciones B y D).
-- EJECUCIÓN: el archivo completo se puede correr de una sola vez con
--   mysql -u angel.barrios -p --port=40196 < 06_caso_prueba_4.sql
-- Las "secciones" indican qué usuario haría cada paso en un ambiente real
-- (usuario de la app, vendedor, sistema); aquí todas las ejecuta el superadmin.
-- =====================================================================


-- #####################################################################
-- SECCIÓN A — Conexión: app_web  (o app_movil)
-- #####################################################################
USE db_test;

SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

-- ---------------------------------------------------------------------
-- PASO 1. Usuario YA registrado + carrito de 3 productos del MISMO
--         proveedor, de 1 a 3 unidades cada uno.
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

-- Proveedor al azar con al menos 3 productos disponibles
-- (hoy solo existe uno: vendedor_demo, ID 10244)
SET @provider_id = (
    SELECT pr.user_ID
    FROM tbd_products_users_providers pr
    JOIN tb_products p ON p.ID = pr.product_ID
    WHERE pr.status = b'1' AND p.status = b'1' AND p.current_stock >= 3
    GROUP BY pr.user_ID
    HAVING COUNT(*) >= 3
    ORDER BY RAND()
    LIMIT 1);

INSERT INTO tb_carts (user_ID) VALUES (@user_id);
SET @cart_id = LAST_INSERT_ID();

INSERT INTO tbd_carts_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart_id, x.provider_ID, x.product_ID, 1 + FLOOR(RAND() * 3)
FROM (SELECT pr.user_ID AS provider_ID, p.ID AS product_ID
      FROM tbd_products_users_providers pr
      JOIN tb_products p ON p.ID = pr.product_ID
      WHERE pr.user_ID = @provider_id
        AND pr.status = b'1' AND p.status = b'1' AND p.current_stock >= 3
      ORDER BY RAND()
      LIMIT 3) x;

-- Evidencia: 3 productos, un solo proveedor
SELECT ci.provider_ID, ci.product_ID, p.name, ci.quantity, p.current_price,
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
-- PASO 3. Domicilio que NO es su hogar (casa de una amiga)
-- ---------------------------------------------------------------------
INSERT INTO tb_user_addresses
    (user_ID, address_label, recipient_name, recipient_phone, delivery_instructions, is_default)
VALUES
    (@user_id, 'Casa de Sofía', 'Sofía Ramírez Cruz', '+52 33 4455 6677',
     'Si no hay nadie, dejar en punto de recolección', 0);
SET @address_id = LAST_INSERT_ID();

INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'México', 'country', NULL);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Puebla', 'state', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Puebla', 'municipality', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'La Paz', 'neighborhood', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Av. Juárez', 'street', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, '1510', 'exterior_number', @c);
SET @c = LAST_INSERT_ID();
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, '72160', 'postal_code', @c);

UPDATE tbb_orders SET address_ID = @address_id WHERE ID = @order_id;

-- ---------------------------------------------------------------------
-- PASO 4. Método de pago: transferencia SPEI (cuenta simulada de 16 dígitos)
-- ---------------------------------------------------------------------
SET @card_number = CONCAT('7', LPAD(FLOOR(RAND() * 1000000000000000), 15, '0'));

INSERT INTO tbd_user_payment_methods
    (user_ID, payment_method_type_ID, provider, provider_method_ref, label, last_four, is_default)
VALUES
    (@user_id,
     (SELECT ID FROM tbc_payment_methods_types WHERE code = 'SPEI'),
     'BANCO_SIMULADO', @card_number, 'SPEI simulada', RIGHT(@card_number, 4), 1);
SET @payment_method_id = LAST_INSERT_ID();

SELECT @card_number AS cuenta_simulada_16_digitos, CHAR_LENGTH(@card_number) AS digitos;

-- ---------------------------------------------------------------------
-- PASO 5. UN solo pago por el total de la compra. Activa el rol "buyer".
-- ---------------------------------------------------------------------
-- (Todo se ejecuta como superadmin: aquí el usuario normalmente activaría el rol "buyer")
SELECT CURRENT_ROLE() AS roles_activos;

SET @pay_method = 'SPEI';        -- cámbialo a 'Cash' si te lo exigen
SELECT ROUND(total_cost, 2) INTO @amount FROM tbb_orders WHERE ID = @order_id;

INSERT INTO tb_payments
    (order_ID, user_payment_method_ID, amount, currency, payment_method,
     provider, provider_reference, payment_status)
VALUES
    (@order_id, @payment_method_id, @amount, 'MXN', @pay_method,
     'BANCO_SIMULADO', CONCAT('PAY-', @order_id, '-', UNIX_TIMESTAMP()), 'Pending');
SET @payment_id = LAST_INSERT_ID();

SELECT @user_id AS user_id, @order_id AS order_id, @payment_id AS payment_id, @amount AS monto;
-- Fin de la sección A. Puedes cerrar esta conexión.


-- #####################################################################
-- SECCIÓN B — Conexión: angel.barrios (superadmin) = "EL SISTEMA"
-- #####################################################################
USE db_test;

SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

SELECT pay.ID, pay.order_ID, pay.amount
  INTO @payment_id, @order_id, @amount
FROM tb_payments pay
WHERE pay.payment_method = 'SPEI' AND pay.payment_status = 'Pending'
ORDER BY pay.ID DESC
LIMIT 1;

SELECT @payment_id AS payment_id, @order_id AS order_id, @amount AS monto;
SET @seller_order_id = (SELECT ID FROM tb_seller_orders WHERE order_ID = @order_id LIMIT 1);

-- ---------------------------------------------------------------------
-- PASO 6. El sistema confirma el pago y marca la orden como atendida
-- ---------------------------------------------------------------------
START TRANSACTION;

INSERT INTO tb_payment_transactions (payment_ID, event_type, amount, event_reference, remarks)
VALUES
    (@payment_id, 'Created',    @amount, CONCAT('TX-CRE-',  @payment_id), 'Intención de pago SPEI registrada'),
    (@payment_id, 'Authorized', @amount, CONCAT('TX-AUTH-', @payment_id), 'Transferencia SPEI recibida y autorizada'),
    (@payment_id, 'Captured',   @amount, CONCAT('TX-CAP-',  @payment_id), 'Cargo capturado');

UPDATE tb_payments SET payment_status = 'Authorized' WHERE ID = @payment_id;
UPDATE tb_payments SET payment_status = 'Paid', paid_date = NOW() WHERE ID = @payment_id;
UPDATE tbb_orders  SET status_string = 'Payed', last_update = NOW() WHERE ID = @order_id;

UPDATE tbb_orders SET status_string = 'Attended', last_update = NOW() WHERE ID = @order_id;
UPDATE tb_seller_orders SET fulfillment_status = 'Accepted' WHERE order_ID = @order_id;

COMMIT;

-- ---------------------------------------------------------------------
-- PASO 7. El sistema realiza el envío
-- ---------------------------------------------------------------------
UPDATE tb_seller_orders SET fulfillment_status = 'Preparing' WHERE ID = @seller_order_id;

INSERT INTO tb_shipments
    (seller_order_ID, carrier, tracking_number, shipment_status,
     shipped_at, estimated_delivery, shipping_notes)
VALUES
    (@seller_order_id, 'Paquetería Simulada',
     CONCAT('TRK-', LPAD(@order_id, 6, '0'), '-', UNIX_TIMESTAMP()),
     'Shipped', NOW(), DATE_ADD(NOW(), INTERVAL 3 DAY),
     'Envío a domicilio "Casa de Sofía"');

UPDATE tb_seller_orders SET fulfillment_status = 'Sent' WHERE ID = @seller_order_id;
UPDATE tbb_orders SET status_string = 'Sended', last_update = NOW() WHERE ID = @order_id;

SELECT ID, `key`, status_string FROM tbb_orders WHERE ID = @order_id;
-- Fin de la sección B.


-- #####################################################################
-- SECCIÓN C — Conexión: jose.castillo (seller)
-- #####################################################################
USE db_test;

SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

SET @order_id = (SELECT order_ID FROM tb_payments
                 WHERE payment_method = 'SPEI' ORDER BY ID DESC LIMIT 1);
SET @seller_order_id = (SELECT ID FROM tb_seller_orders WHERE order_ID = @order_id LIMIT 1);
SET @shipment_id = (SELECT MAX(ID) FROM tb_shipments WHERE seller_order_ID = @seller_order_id);

-- ---------------------------------------------------------------------
-- PASO 8. Nadie recibe el pedido: el paquete pasa al punto de recolección
--         y el cliente lo recoge ahí.
-- ---------------------------------------------------------------------
-- 8a. En tránsito
UPDATE tb_shipments SET shipment_status = 'InTransit' WHERE ID = @shipment_id;

-- 8b. Intento de entrega fallido: no había quién recibiera
UPDATE tb_shipments
   SET shipment_status = 'Failed',
       shipping_notes = CONCAT(shipping_notes,
           ' | Intento de entrega fallido: no había quién recibiera. ',
           'Se deja en punto de recolección "Punto Pickup Centro Puebla".')
 WHERE ID = @shipment_id;

-- 8c. El cliente recoge el pedido en el punto de recolección
UPDATE tb_shipments
   SET shipment_status = 'Delivered',
       delivered_at = NOW(),
       shipping_notes = CONCAT(shipping_notes,
           ' | Recogido por el cliente en el punto de recolección.')
 WHERE ID = @shipment_id;

UPDATE tb_seller_orders SET fulfillment_status = 'Delivered' WHERE ID = @seller_order_id;
UPDATE tbb_orders SET status_string = 'Delivered', last_update = NOW() WHERE ID = @order_id;
-- Fin de la sección C.


-- #####################################################################
-- SECCIÓN D — Conexión: angel.barrios (superadmin)  ·  VERIFICACIÓN
-- #####################################################################
USE db_test;

SET @order_id = (SELECT order_ID FROM tb_payments
                 WHERE payment_method = 'SPEI' ORDER BY ID DESC LIMIT 1);

-- D1. Usuario y orden final
SELECT u.ID AS user_id, u.email, p.given_names, p.family_names,
       o.ID AS order_id, o.total_products, o.total_cost, o.status_string
FROM tbb_orders o
JOIN tb_users u  ON u.ID = o.User_ID
JOIN tb_people p ON p.user_ID = u.ID
WHERE o.ID = @order_id;

-- D2. 3 productos, un solo proveedor, cantidades de 1 a 3 (paso 1)
SELECT oi.provider_ID, oi.product_ID, oi.product_name, oi.quantity, oi.unit_price, oi.subtotal
FROM tbd_order_items oi JOIN tb_seller_orders so ON so.ID = oi.seller_order_ID
WHERE so.order_ID = @order_id;

SELECT COUNT(*) AS ordenes_de_vendedor, COUNT(DISTINCT seller_ID) AS proveedores
FROM tb_seller_orders WHERE order_ID = @order_id;

-- D3. Domicilio ligado (paso 3)
SELECT a.address_label, a.recipient_name, a.delivery_instructions
FROM tbb_orders o JOIN tb_user_addresses a ON a.ID = o.address_ID
WHERE o.ID = @order_id;

-- D4. Método SPEI y pago único (pasos 4 y 5)
SELECT pay.ID AS payment_id, pay.amount, pay.payment_method, pay.payment_status, pay.paid_date,
       pm.label, pm.last_four, pm.provider_method_ref AS cuenta_simulada,
       CHAR_LENGTH(pm.provider_method_ref) AS digitos, t.code AS tipo_metodo
FROM tb_payments pay
JOIN tbd_user_payment_methods pm ON pm.ID = pay.user_payment_method_ID
JOIN tbc_payment_methods_types t ON t.ID = pm.payment_method_type_ID
WHERE pay.order_ID = @order_id;

-- D5. Transacciones (paso 6)
SELECT t.ID, t.event_type, t.amount, t.event_reference, t.remarks
FROM tb_payment_transactions t JOIN tb_payments pay ON pay.ID = t.payment_ID
WHERE pay.order_ID = @order_id ORDER BY t.ID;

-- D6. Envío y recolección (pasos 7 y 8)
SELECT s.ID, s.carrier, s.tracking_number, s.shipment_status, s.shipped_at, s.delivered_at,
       so.fulfillment_status, s.shipping_notes
FROM tb_shipments s JOIN tb_seller_orders so ON so.ID = s.seller_order_ID
WHERE so.order_ID = @order_id;

-- D7. Bitácora: se ven los cambios Shipped -> InTransit -> Failed -> Delivered
SELECT ID, table_name, operation, db_user, operation_date
FROM tb_logs ORDER BY ID DESC LIMIT 60;
