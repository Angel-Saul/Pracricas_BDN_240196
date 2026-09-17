-- 1. CREACION DE USUARIOS REMOTOS
CREATE USER IF NOT EXISTS 'angel.barrios'@'%' IDENTIFIED BY '240196';
CREATE USER IF NOT EXISTS 'marco.ramirez'@'%' IDENTIFIED BY 'qwerty123';
CREATE USER IF NOT EXISTS 'luis.cazarez'@'%' IDENTIFIED BY '240343';
CREATE USER IF NOT EXISTS 'jose.castillo'@'%' IDENTIFIED BY '240628';

-- 2. ASIGNACION DE PRIVILEGIOS DE SUPERUSUARIO
GRANT ALL PRIVILEGES ON *.* TO 'angel.barrios'@'%' WITH GRANT OPTION;

-- 3. CREACION DE ROLES PARA ECOMMERCE
CREATE ROLE IF NOT EXISTS 'admin';
CREATE ROLE IF NOT EXISTS 'seller';
CREATE ROLE IF NOT EXISTS 'buyer';
CREATE ROLE IF NOT EXISTS 'common_user';
CREATE ROLE IF NOT EXISTS 'user_not_registered';
CREATE ROLE IF NOT EXISTS 'support';

-- 4. ASIGNACION DE PRIVILEGIOS A LOS ROLES
-- Role: admin
GRANT ALL PRIVILEGES ON db_test.* TO 'admin';

-- Role: support
GRANT SELECT, INSERT, UPDATE ON db_test.tb_users TO 'support';
GRANT SELECT ON db_test.tb_logs TO 'support';

-- Role: common_user / buyer (Ejemplo de lectura)
GRANT SELECT ON db_test.* TO 'common_user';

-- 5. ASIGNACION DE ROLES A LOS USUARIOS
GRANT 'admin' TO 'marco.ramirez'@'%';
GRANT 'support' TO 'luis.cazarez'@'%';
GRANT 'common_user' TO 'jose.castillo'@'%';

-- 6. ACTIVACION AUTOMATICA DE ROLES PARA TODOS LOS USUARIOS (CRITICO)
SET DEFAULT ROLE ALL TO 
  'marco.ramirez'@'%', 
  'luis.cazarez'@'%', 
  'jose.castillo'@'%';

-- 7. REFRESCAR PRIVILEGIOS
FLUSH PRIVILEGES;