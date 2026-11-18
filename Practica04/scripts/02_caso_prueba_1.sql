-- =====================================================================
-- 02_caso_prueba_1.sql
-- CASO DE PRUEBA 1 — Simulación de compra con tarjeta de débito
--
-- Se ejecuta en 4 secciones, cada una con SU conexión:
--   A) app_web (o app_movil)  · rol user_not_registered  -> pasos 1 a 8
--   B) angel.barrios (superadmin) · "el sistema"             -> pasos 9 y 10
--   C) jose.castillo (seller)                             -> paso 11
--   D) angel.barrios (superadmin)                              -> verificación
--
-- IMPORTANTE: cada sección debe correr completa y en UNA sola pestaña/sesión,
-- porque usa variables de sesión (@user_id, @cart_id, ...).
-- Antes de empezar, ejecuta 01_ajustes_db_test.sql.
-- =====================================================================


-- #####################################################################
-- SECCIÓN A — Conexión: app_web  (o app_movil)
-- #####################################################################
USE db_test;

SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
-- Esperado: app_web@%  /  `user_not_registered`@`%`


-- ---------------------------------------------------------------------
-- PASO 1. Registro de usuario nuevo (datos de cuenta + datos personales)
-- ---------------------------------------------------------------------
CALL sp_register_person(
    'cliente.prueba1@mail.com',   -- p_email
    'cliente_prueba1',            -- p_nick
    'Cliente1234',                -- p_password
    'Srita.',                     -- p_courtesy_title
    'María Fernanda',             -- p_given_names
    'López Hernández',            -- p_family_names
    '2000-05-14',                 -- p_birth_date
    'Mujer',                      -- p_gender
    'MX',                         -- p_country_code
    '+52 55 1234 5678'            -- p_phone
);

-- >>> Copia el valor de "user_id" que devolvió el procedimiento y ponlo aquí:
SET @user_id = 0;   -- <-- REEMPLAZA el 0 por el user_id del resultado anterior


-- ---------------------------------------------------------------------
-- PASO 2. Selección de 5 productos disponibles (verificando estatus)
--         De los ~10,000 disponibles se eligen 5 al azar con stock >= 5.
--         La selección queda guardada en la wishlist del usuario.
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS productos_disponibles
FROM tb_products p
JOIN tbd_products_users_providers pr ON pr.product_ID = p.ID
WHERE p.status = b'1' AND pr.status = b'1' AND p.current_stock > 0;

INSERT INTO tbd_users_wishlist_products (user_ID, product_ID, status, last_update)
SELECT @user_id, p.ID, b'1', NOW()
FROM tb_products p
JOIN tbd_products_users_providers pr ON pr.product_ID = p.ID
WHERE p.status = b'1' AND pr.status = b'1' AND p.current_stock >= 5
ORDER BY RAND()
LIMIT 5;

-- Evidencia: productos elegidos con su estatus y stock
SELECT p.ID, p.SKU, p.name, p.current_price, p.current_stock,
       p.status + 0 AS producto_activo, pr.status + 0 AS ofrecido_activo
FROM tbd_users_wishlist_products w
JOIN tb_products p ON p.ID = w.product_ID
JOIN tbd_products_users_providers pr ON pr.product_ID = p.ID
WHERE w.user_ID = @user_id;


-- ---------------------------------------------------------------------
-- PASO 3. Crear 1 carrito de compra
-- ---------------------------------------------------------------------
INSERT INTO tb_carts (user_ID) VALUES (@user_id);
SET @cart_id = LAST_INSERT_ID();


-- ---------------------------------------------------------------------
-- PASO 4. Agregar los 5 productos con cantidades distintas (1, 2, 3, 4, 5)
-- ---------------------------------------------------------------------
INSERT INTO tbd_carts_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart_id, pr.user_ID, w.product_ID,
       ROW_NUMBER() OVER (ORDER BY w.product_ID)
FROM tbd_users_wishlist_products w
JOIN tb_products p ON p.ID = w.product_ID
JOIN tbd_products_users_providers pr ON pr.product_ID = p.ID
WHERE w.user_ID = @user_id
  AND w.status = b'1'
  AND p.status = b'1'
  AND pr.status = b'1'
  AND p.current_stock >= 5;

-- Evidencia
SELECT ci.cart_ID, ci.product_ID, p.name, ci.quantity, p.current_price,
       ci.quantity * p.current_price AS subtotal
FROM tbd_carts_items ci
JOIN tb_products p ON p.ID = ci.product_ID
WHERE ci.cart_ID = @cart_id;


-- ---------------------------------------------------------------------
-- PASO 5. Realizar la orden de compra
--         (crea orden, orden por vendedor, items y descuenta stock)
-- ---------------------------------------------------------------------
CALL sp_create_order(@user_id, @order_id, @order_total);
SELECT @order_id AS order_id, @order_total AS total_orden;


-- ---------------------------------------------------------------------
-- PASO 6. Registrar el domicilio de envío y ligarlo a la orden
-- ---------------------------------------------------------------------
INSERT INTO tb_user_addresses
    (user_ID, address_label, recipient_name, recipient_phone, delivery_instructions, is_default)
VALUES
    (@user_id, 'Casa', 'María Fernanda López Hernández', '+52 55 1234 5678',
     'Entregar a la persona que recibe; llamar al llegar', 1);
SET @address_id = LAST_INSERT_ID();

-- Componentes jerárquicos del domicilio (cada uno depende del anterior)
INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'México', 'country', NULL);
SET @c = LAST_INSERT_ID();

INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Ciudad de México', 'state', @c);
SET @c = LAST_INSERT_ID();

INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Benito Juárez', 'municipality', @c);
SET @c = LAST_INSERT_ID();

INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Del Valle Centro', 'neighborhood', @c);
SET @c = LAST_INSERT_ID();

INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, 'Calle Ejemplo', 'street', @c);
SET @c = LAST_INSERT_ID();

INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, '123', 'exterior_number', @c);
SET @c = LAST_INSERT_ID();

INSERT INTO tbd_address_components (address_ID, value, component_type, address_sup_ID)
VALUES (@address_id, '03100', 'postal_code', @c);

-- Ligar domicilio -> orden
UPDATE tbb_orders SET address_ID = @address_id WHERE ID = @order_id;


-- ---------------------------------------------------------------------
-- PASO 7. Registrar método de pago: tarjeta de débito (cuenta simulada de 16 dígitos)
--         Es un número ficticio generado al azar. Se guarda en la tabla
--         dependiente tbd_user_payment_methods.
-- ---------------------------------------------------------------------
SET @card_number = CONCAT('4', LPAD(FLOOR(RAND() * 1000000000000000), 15, '0'));

INSERT INTO tbd_user_payment_methods
    (user_ID, payment_method_type_ID, provider, provider_method_ref, label, last_four, is_default)
VALUES
    (@user_id,
     (SELECT ID FROM tbc_payment_methods_types WHERE code = 'DEBIT_CARD'),
     'BANCO_SIMULADO',
     @card_number,
     'Débito simulada',
     RIGHT(@card_number, 4),
     1);
SET @payment_method_id = LAST_INSERT_ID();

SELECT @card_number AS cuenta_simulada_16_digitos, CHAR_LENGTH(@card_number) AS digitos;


-- ---------------------------------------------------------------------
-- PASO 8. Pago único. Al pagar, la conexión ACTIVA el rol "buyer".
-- ---------------------------------------------------------------------
SET ROLE 'user_not_registered', 'buyer';
SELECT CURRENT_ROLE() AS roles_activos;   -- Esperado: user_not_registered y buyer

SELECT total_cost INTO @amount FROM tbb_orders WHERE ID = @order_id;

INSERT INTO tb_payments
    (order_ID, user_payment_method_ID, amount, currency, payment_method,
     provider, provider_reference, payment_status)
VALUES
    (@order_id, @payment_method_id, @amount, 'MXN', 'Card',
     'BANCO_SIMULADO', CONCAT('PAY-', @order_id, '-', UNIX_TIMESTAMP()), 'Pending');
SET @payment_id = LAST_INSERT_ID();

SELECT @user_id AS user_id, @order_id AS order_id, @payment_id AS payment_id, @amount AS monto;
-- Fin de la sección A. Puedes cerrar esta conexión.


-- #####################################################################
-- SECCIÓN B — Conexión: angel.barrios (superadmin)  =  "EL SISTEMA"
-- #####################################################################
USE db_test;

SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

-- Toma el último pago pendiente (el que se creó en el paso 8)
SELECT ID, order_ID, amount
  INTO @payment_id, @order_id, @amount
FROM tb_payments
WHERE payment_status = 'Pending'
ORDER BY ID DESC
LIMIT 1;

SELECT @payment_id AS payment_id, @order_id AS order_id, @amount AS monto;


-- ---------------------------------------------------------------------
-- PASO 9. El sistema registra la transacción bancaria y la autoriza
-- ---------------------------------------------------------------------
START TRANSACTION;

INSERT INTO tb_payment_transactions
    (payment_ID, event_type, amount, event_reference, remarks)
VALUES
    (@payment_id, 'Created',    @amount, CONCAT('TX-CRE-',  @payment_id), 'Intención de pago registrada'),
    (@payment_id, 'Authorized', @amount, CONCAT('TX-AUTH-', @payment_id), 'Autorizada por el banco simulado'),
    (@payment_id, 'Captured',   @amount, CONCAT('TX-CAP-',  @payment_id), 'Cargo capturado');

UPDATE tb_payments SET payment_status = 'Authorized' WHERE ID = @payment_id;
UPDATE tb_payments SET payment_status = 'Paid', paid_date = NOW() WHERE ID = @payment_id;
UPDATE tbb_orders  SET status_string = 'Payed', last_update = NOW() WHERE ID = @order_id;

COMMIT;


-- ---------------------------------------------------------------------
-- PASO 10. El sistema procesa la orden y la marca como atendida
-- ---------------------------------------------------------------------
START TRANSACTION;

UPDATE tbb_orders
   SET status_string = 'Attended', last_update = NOW()
 WHERE ID = @order_id;

UPDATE tb_seller_orders
   SET fulfillment_status = 'Accepted'
 WHERE order_ID = @order_id;

COMMIT;

SELECT ID, `key`, status_string FROM tbb_orders WHERE ID = @order_id;
-- Fin de la sección B.


-- #####################################################################
-- SECCIÓN C — Conexión: jose.castillo (seller)
-- #####################################################################
USE db_test;

SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;

-- Toma la última orden atendida
SET @order_id = (SELECT ID FROM tbb_orders
                 WHERE status_string = 'Attended'
                 ORDER BY ID DESC LIMIT 1);
SET @seller_order_id = (SELECT ID FROM tb_seller_orders
                        WHERE order_ID = @order_id LIMIT 1);


-- ---------------------------------------------------------------------
-- PASO 11. Envío y entrega del producto en el domicilio
-- ---------------------------------------------------------------------

-- 11a. El vendedor prepara y envía
UPDATE tb_seller_orders SET fulfillment_status = 'Preparing' WHERE ID = @seller_order_id;

INSERT INTO tb_shipments
    (seller_order_ID, carrier, tracking_number, shipment_status,
     shipped_at, estimated_delivery, shipping_notes)
VALUES
    (@seller_order_id, 'Paquetería Simulada',
     CONCAT('TRK-', LPAD(@order_id, 6, '0'), '-', UNIX_TIMESTAMP()),
     'Shipped', NOW(), DATE_ADD(NOW(), INTERVAL 3 DAY),
     'Envío a domicilio registrado en la orden');
SET @shipment_id = LAST_INSERT_ID();

UPDATE tb_seller_orders SET fulfillment_status = 'Sent' WHERE ID = @seller_order_id;
UPDATE tbb_orders SET status_string = 'Sended', last_update = NOW() WHERE ID = @order_id;

-- 11b. El usuario recibe el producto en casa
UPDATE tb_shipments
   SET shipment_status = 'Delivered', delivered_at = NOW()
 WHERE ID = @shipment_id;

UPDATE tb_seller_orders SET fulfillment_status = 'Delivered' WHERE ID = @seller_order_id;
UPDATE tbb_orders SET status_string = 'Delivered', last_update = NOW() WHERE ID = @order_id;
-- Fin de la sección C.


-- #####################################################################
-- SECCIÓN D — Conexión: angel.barrios (superadmin)  ·  VERIFICACIÓN
-- #####################################################################
USE db_test;

SET @order_id = (SELECT MAX(ID) FROM tbb_orders WHERE status_string = 'Delivered');

-- D1. Usuario y persona (paso 1)
SELECT u.ID AS user_id, u.email, u.nick, p.person_ID, p.given_names, p.family_names
FROM tbb_orders o
JOIN tb_users u  ON u.ID = o.User_ID
JOIN tb_people p ON p.user_ID = u.ID
WHERE o.ID = @order_id;

-- D2. Orden, domicilio ligado y estado final (pasos 5, 6, 10, 11)
SELECT o.ID AS order_id, o.`key`, o.total_products, o.total_cost, o.status_string,
       a.address_label, a.recipient_name
FROM tbb_orders o
LEFT JOIN tb_user_addresses a ON a.ID = o.address_ID
WHERE o.ID = @order_id;

-- D3. Items de la orden con el stock restante (paso 5)
SELECT oi.product_ID, oi.product_name, oi.quantity, oi.unit_price, oi.subtotal,
       p.current_stock AS stock_actual
FROM tbd_order_items oi
JOIN tb_seller_orders so ON so.ID = oi.seller_order_ID
JOIN tb_products p ON p.ID = oi.product_ID
WHERE so.order_ID = @order_id;

-- D4. Domicilio completo en orden jerárquico (paso 6)
SELECT c.component_type, c.value
FROM tbd_address_components c
JOIN tbb_orders o ON o.address_ID = c.address_ID
WHERE o.ID = @order_id
ORDER BY c.ID;

-- D5. Tarjeta y pago ligados (pasos 7 y 8)
SELECT pay.ID AS payment_id, pay.amount, pay.payment_method, pay.payment_status, pay.paid_date,
       pm.label, pm.last_four, pm.provider_method_ref AS cuenta_simulada
FROM tb_payments pay
JOIN tbd_user_payment_methods pm ON pm.ID = pay.user_payment_method_ID
WHERE pay.order_ID = @order_id;

-- D6. Transacciones bancarias (paso 9)
SELECT t.ID, t.event_type, t.amount, t.event_reference, t.creation_date
FROM tb_payment_transactions t
JOIN tb_payments pay ON pay.ID = t.payment_ID
WHERE pay.order_ID = @order_id
ORDER BY t.ID;

-- D7. Envío y entrega (paso 11)
SELECT s.ID, s.carrier, s.tracking_number, s.shipment_status, s.shipped_at, s.delivered_at,
       so.fulfillment_status
FROM tb_shipments s
JOIN tb_seller_orders so ON so.ID = s.seller_order_ID
WHERE so.order_ID = @order_id;

-- D8. Bitácora: quién hizo cada operación
SELECT ID, table_name, operation, db_user, operation_date
FROM tb_logs
ORDER BY ID DESC
LIMIT 60;
