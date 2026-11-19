-- =====================================================================
-- 03_ajustes_casos_2_a_5.sql
-- Ajustes previos para los casos de prueba 2, 3, 4 y 5
-- Ejecutar UNA VEZ con angel.barrios (superadmin). Es idempotente.
-- =====================================================================
USE db_test;

-- ---------------------------------------------------------------------
-- 1. Nuevos tipos de método de pago (solo existía DEBIT_CARD)
-- ---------------------------------------------------------------------
INSERT IGNORE INTO tbc_payment_methods_types (code, description) VALUES
    ('CREDIT_CARD', 'Tarjeta de crédito'),
    ('SPIN',        'Tarjeta digital Spin'),
    ('SPEI',        'Transferencia SPEI'),
    ('GIFT_COUPON', 'Cupón de regalo');

-- ---------------------------------------------------------------------
-- 2. tb_payments.payment_method no tenía opción para cupón de regalo
--    (solo se amplía el enum; no se crea ninguna tabla)
-- ---------------------------------------------------------------------
ALTER TABLE tb_payments
    MODIFY payment_method ENUM('Card','SPEI','Transfer','Cash','GiftCoupon') NOT NULL;

-- ---------------------------------------------------------------------
-- 3. Privilegios adicionales (los GRANT repetidos no hacen daño)
--    El usuario de conexión (app_web/app_movil) solo trae por defecto
--    user_not_registered; "buyer" se activa al pagar.
-- ---------------------------------------------------------------------
-- Usuario ya registrado que arma su compra (sin ver la contraseña)
GRANT SELECT (ID, email, nick, status) ON db_test.tb_users TO 'user_not_registered';
GRANT SELECT (user_ID, given_names, family_names, phone) ON db_test.tb_people TO 'user_not_registered';
GRANT SELECT, INSERT ON db_test.tb_carts TO 'user_not_registered';
GRANT SELECT, INSERT ON db_test.tbd_carts_items TO 'user_not_registered';
GRANT SELECT ON db_test.tb_products TO 'user_not_registered';
GRANT SELECT ON db_test.tbd_products_users_providers TO 'user_not_registered';
GRANT SELECT ON db_test.tbd_products_categories TO 'user_not_registered';
GRANT SELECT ON db_test.tbb_orders TO 'user_not_registered';
GRANT UPDATE (address_ID) ON db_test.tbb_orders TO 'user_not_registered';
GRANT SELECT ON db_test.tb_seller_orders TO 'user_not_registered';
GRANT SELECT ON db_test.tbd_order_items TO 'user_not_registered';
GRANT SELECT, INSERT ON db_test.tb_user_addresses TO 'user_not_registered';
GRANT SELECT, INSERT ON db_test.tbd_address_components TO 'user_not_registered';
GRANT SELECT ON db_test.tbc_payment_methods_types TO 'user_not_registered';
GRANT SELECT, INSERT ON db_test.tbd_user_payment_methods TO 'user_not_registered';

-- Crear la orden (si 01_ajustes ya lo otorgó, no pasa nada)
GRANT EXECUTE ON PROCEDURE db_test.sp_create_order TO 'user_not_registered';
GRANT EXECUTE ON PROCEDURE db_test.sp_create_order TO 'buyer';

-- Vendedor: confirmar envíos y reportar inventario físico
GRANT UPDATE ON db_test.tbb_orders TO 'seller';
GRANT SELECT ON db_test.tb_payments TO 'seller';
GRANT SELECT ON db_test.tb_user_addresses TO 'seller';
GRANT SELECT ON db_test.tbd_address_components TO 'seller';

FLUSH PRIVILEGES;
SELECT 'Ajustes de casos 2 a 5 aplicados' AS mensaje;
