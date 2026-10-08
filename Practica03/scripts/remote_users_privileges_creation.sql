-- 1. CREACION DE USUARIOS REMOTOS
CREATE USER IF NOT EXISTS 'angel.barrios'@'%' IDENTIFIED BY '240196'; -- super admin 
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123'; -- Profe
CREATE USER IF NOT EXISTS 'luis.cazarez'@'%' IDENTIFIED BY '240343'; -- suport 
CREATE USER IF NOT EXISTS 'jose.castillo'@'%' IDENTIFIED BY '240628'; -- segundo vendedor
CREATE USER IF NOT EXISTS 'jonhy.neri'@'%' IDENTIFIED BY '240598'; -- primer vendedor 
CREATE USER IF NOT EXISTS 'aylin.esteban'@'%' IDENTIFIED BY '240853'; -- usuario 
CREATE USER IF NOT EXISTS 'juan.reyes'@'%' IDENTIFIED BY '240148'; -- usuario  

-- 2. ASIGNACION DE PRIVILEGIOS DE SUPERUSUARIO
GRANT ALL PRIVILEGES ON *.* TO 'angel.barrios'@'%';

GRANT SELECT, INSERT, UPDATE, DELETE
ON db_test.*
TO 'jonhy.neri'@'%';


-- 3. CREACION DE ROLES PARA ECOMMERCE
CREATE ROLE IF NOT EXISTS 'superadmin';
CREATE ROLE IF NOT EXISTS 'admin';
CREATE ROLE IF NOT EXISTS 'seller';
CREATE ROLE IF NOT EXISTS 'buyer';
CREATE ROLE IF NOT EXISTS 'support';
CREATE ROLE IF NOT EXISTS 'common';
CREATE ROLE IF NOT EXISTS 'user_not_registered';

-- 4. ASIGNACION DE PRIVILEGIOS A LOS ROLES
GRANT ALL PRIVILEGES ON *.* TO 'superadmin';
-- ADMIN
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';
-- SUPPORT
GRANT SELECT, UPDATE ON db_test.tb_products to 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tb_users TO 'support';
GRANT SELECT, INSERT, UPDATE ON db_test.tbc_categories TO 'support';
GRANT SELECT, INSERT,  UPDATE ON db_test.tbd_products_categories TO 'support';
GRANT EXECUTE ON PROCEDURE db_test.sp_soft_delete_user TO 'support'@'%';
-- SELLER
GRANT SELECT, INSERT, UPDATE ON db_test.tb_products TO 'seller';
GRANT SELECT ON db_test.tbc_categories TO 'seller';

-- 5. ASIGNACION DE ROLES A LOS USUARIOS
GRANT 'superadmin' TO 'angel.barrios'@'%';
GRANT 'admin' TO 'marco.ramirez'@'%';
GRANT 'support' TO 'luis.cazarez'@'%';
GRANT 'seller' TO 'jose.castillo'@'%';
GRANT 'seller' TO 'aylin.esteban'@'%';

-- 6. ACTIVACION AUTOMATICA DE ROLES PARA TODOS LOS USUARIOS (CRITICO)
SET DEFAULT ROLE 'superadmin' TO 'angel.barrios'@'%';
SET DEFAULT ROLE 'admin'      TO 'marco.ramirez'@'%';
SET DEFAULT ROLE 'support'    TO 'luis.cazarez'@'%';
SET DEFAULT ROLE 'seller'     TO 'jose.castillo'@'%';
SET DEFAULT ROLE 'seller'     TO 'aylin.esteban'@'%';
-- 7. REFRESCAR PRIVILEGIOS
FLUSH PRIVILEGES;

-- MENSAJE DE CONFIRMACION
SELECT "Los usuarios y privilegios han sido creados correctamente" AS mensaje;