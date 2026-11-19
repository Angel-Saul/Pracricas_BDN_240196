-- Anexo técnico MySQL derivado del respaldo Practica03/backups/240196_20.10.26.sql
-- Fuente: C:\Users\PC-26\Pracricas_BDN_240196\Practica03\backups\240196_20.10.26.sql
-- Generado: 20 de octubre de 2026 a las 11:21 a.m. (America/Mexico_City)
-- No ejecutar como restauración: se excluyeron sentencias top-level de carga de filas, DROP, LOCK, sentencias de usuarios/permisos y valores reales de registros.
-- Los INSERT contenidos en cuerpos de triggers/procedimientos se conservan como parte de su lógica, no se ejecutaron.
-- DEFINER fue omitido para no reproducir cuentas del servidor. Wrappers /*!version ... */ se conservan cuando forman parte de vistas/triggers.
CREATE DATABASE  IF NOT EXISTS `db_test` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

-- Tabla: tb_buyer_orders
CREATE TABLE `tb_buyer_orders` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `seller_ID` int unsigned NOT NULL,
  `subtotal` decimal(12,2) NOT NULL DEFAULT '0.00',
  `shipping_cost` decimal(12,2) NOT NULL DEFAULT '0.00',
  `fulfillment_status` enum('Pending','Accepted','Preparing','Sent','Delivered','Canceled','Returned') NOT NULL DEFAULT 'Pending',
  `status` bit(1) NOT NULL DEFAULT b'1',
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  KEY `seller_ID` (`seller_ID`),
  CONSTRAINT `tb_buyer_orders_ibfk_1` FOREIGN KEY (`seller_ID`) REFERENCES `tb_users` (`ID`),
  CONSTRAINT `tb_buyer_orders_chk_1` CHECK ((`subtotal` >= 0)),
  CONSTRAINT `tb_buyer_orders_chk_2` CHECK ((`shipping_cost` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tb_carts
CREATE TABLE `tb_carts` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `user_ID` int unsigned NOT NULL,
  `status` bit(1) DEFAULT b'1',
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `uk_cart_user` (`user_ID`),
  CONSTRAINT `tb_carts_ibfk_1` FOREIGN KEY (`user_ID`) REFERENCES `tb_users` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tb_logs
CREATE TABLE `tb_logs` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `table_name` varchar(100) NOT NULL,
  `operation` enum('Create','Read','Update','Delete') NOT NULL,
  `db_user` varchar(80) NOT NULL,
  `description` text NOT NULL,
  `operation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `operation_status` bit(1) DEFAULT b'1',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=37260 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tb_payment_transactions
CREATE TABLE `tb_payment_transactions` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `payment_ID` int unsigned NOT NULL,
  `event_type` enum('Created','Authorized','Captured','Failed','Refunded','PartiallyRefunded') NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `event_reference` varchar(150) DEFAULT NULL,
  `remarks` text,
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  KEY `payment_ID` (`payment_ID`),
  CONSTRAINT `tb_payment_transactions_ibfk_1` FOREIGN KEY (`payment_ID`) REFERENCES `tb_payments` (`ID`),
  CONSTRAINT `tb_payment_transactions_chk_1` CHECK ((`amount` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tb_payments
CREATE TABLE `tb_payments` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `order_ID` int unsigned NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'MXN',
  `payment_method` enum('Card','SPEI','Transfer','Cash') NOT NULL,
  `provider` varchar(50) DEFAULT NULL,
  `provider_reference` varchar(150) DEFAULT NULL,
  `payment_status` enum('Pending','Authorized','Paid','Failed','Refunded','PartiallyRefunded') NOT NULL DEFAULT 'Pending',
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `paid_date` datetime DEFAULT NULL,
  `last_update` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `uk_payment_reference` (`provider`,`provider_reference`),
  KEY `order_ID` (`order_ID`),
  CONSTRAINT `tb_payments_ibfk_1` FOREIGN KEY (`order_ID`) REFERENCES `tbb_orders` (`ID`),
  CONSTRAINT `tb_payments_chk_1` CHECK ((`amount` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tb_products
CREATE TABLE `tb_products` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `SKU` varchar(50) NOT NULL,
  `name` varchar(250) NOT NULL,
  `description` text,
  `current_price` decimal(10,2) NOT NULL DEFAULT '0.00',
  `current_stock` int unsigned NOT NULL DEFAULT '0',
  `status` bit(1) DEFAULT b'1',
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `SKU` (`SKU`)
) ENGINE=InnoDB AUTO_INCREMENT=15009 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tb_seller_orders
CREATE TABLE `tb_seller_orders` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `order_ID` int unsigned NOT NULL,
  `seller_ID` int unsigned NOT NULL,
  `subtotal` decimal(12,2) NOT NULL DEFAULT '0.00',
  `shipping_cost` decimal(12,2) NOT NULL DEFAULT '0.00',
  `fulfillment_status` enum('Pending','Accepted','Preparing','Sent','Delivered','Canceled','Returned') NOT NULL DEFAULT 'Pending',
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `uk_order_seller` (`order_ID`,`seller_ID`),
  KEY `seller_ID` (`seller_ID`),
  CONSTRAINT `tb_seller_orders_ibfk_1` FOREIGN KEY (`order_ID`) REFERENCES `tbb_orders` (`ID`),
  CONSTRAINT `tb_seller_orders_ibfk_2` FOREIGN KEY (`seller_ID`) REFERENCES `tb_users` (`ID`),
  CONSTRAINT `tb_seller_orders_chk_1` CHECK ((`subtotal` >= 0)),
  CONSTRAINT `tb_seller_orders_chk_2` CHECK ((`shipping_cost` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tb_user_addresses
CREATE TABLE `tb_user_addresses` (
  `ID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_ID` int unsigned NOT NULL,
  `address_label` varchar(100) NOT NULL,
  `recipient_name` varchar(150) DEFAULT NULL,
  `recipient_phone` varchar(25) DEFAULT NULL,
  `delivery_instructions` varchar(500) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `status` bit(1) NOT NULL DEFAULT b'1',
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  KEY `idx_user_addresses` (`user_ID`),
  CONSTRAINT `fk_addresses_users` FOREIGN KEY (`user_ID`) REFERENCES `tb_users` (`ID`),
  CONSTRAINT `chk_coordinates` CHECK ((((`latitude` is null) and (`longitude` is null)) or ((`latitude` is not null) and (`longitude` is not null)))),
  CONSTRAINT `chk_latitude` CHECK ((`latitude` between -(90) and 90)),
  CONSTRAINT `chk_longitude` CHECK ((`longitude` between -(180) and 180))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tb_users
CREATE TABLE `tb_users` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(100) NOT NULL,
  `nick` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `last_login` datetime DEFAULT NULL,
  `status` bit(1) NOT NULL DEFAULT b'1',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `nick` (`nick`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tbb_orders
CREATE TABLE `tbb_orders` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `key` varchar(40) NOT NULL,
  `User_ID` int unsigned NOT NULL,
  `total_products` int NOT NULL,
  `total_cost` decimal(10,3) NOT NULL DEFAULT '0.000',
  `status_string` enum('Registered','Wishlist','Payed','Canceled','Delivered','Devolved','Attended','Sended') NOT NULL DEFAULT 'Registered',
  `status` bit(1) DEFAULT b'1',
  `creation_date` datetime NOT NULL,
  `last_update` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `fk_user_2_idx` (`User_ID`),
  CONSTRAINT `fk_user_2` FOREIGN KEY (`User_ID`) REFERENCES `tb_users` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tbc_categories
CREATE TABLE `tbc_categories` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(120) NOT NULL,
  `description` text,
  `sup_id_category` int unsigned DEFAULT NULL,
  `status` bit(1) NOT NULL DEFAULT b'1',
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `name` (`name`),
  KEY `fk_superior_category` (`sup_id_category`),
  CONSTRAINT `fk_superior_category` FOREIGN KEY (`sup_id_category`) REFERENCES `tbc_categories` (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=101 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tbc_payment_methods_types
CREATE TABLE `tbc_payment_methods_types` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) NOT NULL,
  `description` text NOT NULL,
  `status` bit(1) NOT NULL DEFAULT b'1',
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `code_UNIQUE` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tbd_address_components
CREATE TABLE `tbd_address_components` (
  `ID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `address_ID` bigint unsigned NOT NULL,
  `value` varchar(255) NOT NULL,
  `component_type` varchar(50) NOT NULL,
  `status` bit(1) NOT NULL DEFAULT b'1',
  `address_sup_ID` bigint unsigned DEFAULT NULL,
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `uk_address_component` (`address_ID`,`ID`),
  KEY `idx_address_parent` (`address_ID`,`address_sup_ID`),
  CONSTRAINT `fk_component_address` FOREIGN KEY (`address_ID`) REFERENCES `tb_user_addresses` (`ID`) ON DELETE RESTRICT,
  CONSTRAINT `fk_component_parent` FOREIGN KEY (`address_ID`, `address_sup_ID`) REFERENCES `tbd_address_components` (`address_ID`, `ID`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tbd_carts_items
CREATE TABLE `tbd_carts_items` (
  `cart_ID` int unsigned NOT NULL,
  `provider_ID` int unsigned NOT NULL,
  `product_ID` int unsigned NOT NULL,
  `quantity` int unsigned NOT NULL DEFAULT '1',
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cart_ID`,`provider_ID`,`product_ID`),
  KEY `provider_ID` (`provider_ID`),
  KEY `product_ID` (`product_ID`),
  CONSTRAINT `tbd_carts_items_ibfk_1` FOREIGN KEY (`cart_ID`) REFERENCES `tb_carts` (`ID`),
  CONSTRAINT `tbd_carts_items_ibfk_2` FOREIGN KEY (`provider_ID`) REFERENCES `tbd_products_users_providers` (`user_ID`),
  CONSTRAINT `tbd_carts_items_ibfk_3` FOREIGN KEY (`product_ID`) REFERENCES `tbd_products_users_providers` (`product_ID`),
  CONSTRAINT `chk_cart_quantity` CHECK ((`quantity` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tbd_order_items
CREATE TABLE `tbd_order_items` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `seller_order_ID` int unsigned NOT NULL,
  `product_ID` int unsigned NOT NULL,
  `provider_ID` int unsigned NOT NULL,
  `product_name` varchar(255) NOT NULL,
  `quantity` int unsigned NOT NULL,
  `unit_price` decimal(12,2) NOT NULL,
  `subtotal` decimal(12,2) GENERATED ALWAYS AS ((`quantity` * `unit_price`)) STORED,
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  KEY `seller_order_ID` (`seller_order_ID`),
  KEY `product_ID` (`product_ID`),
  KEY `provider_ID` (`provider_ID`),
  CONSTRAINT `tbd_order_items_ibfk_1` FOREIGN KEY (`seller_order_ID`) REFERENCES `tb_seller_orders` (`ID`),
  CONSTRAINT `tbd_order_items_ibfk_2` FOREIGN KEY (`product_ID`) REFERENCES `tbd_products_users_providers` (`product_ID`),
  CONSTRAINT `tbd_order_items_ibfk_3` FOREIGN KEY (`provider_ID`) REFERENCES `tbd_products_users_providers` (`user_ID`),
  CONSTRAINT `tbd_order_items_chk_1` CHECK ((`quantity` > 0)),
  CONSTRAINT `tbd_order_items_chk_2` CHECK ((`unit_price` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tbd_products_categories
CREATE TABLE `tbd_products_categories` (
  `category_ID` int unsigned NOT NULL,
  `product_ID` int unsigned NOT NULL,
  `status` bit(1) NOT NULL DEFAULT b'1',
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`category_ID`,`product_ID`),
  KEY `fk_product` (`product_ID`),
  CONSTRAINT `fk_category` FOREIGN KEY (`category_ID`) REFERENCES `tbc_categories` (`ID`),
  CONSTRAINT `fk_product` FOREIGN KEY (`product_ID`) REFERENCES `tb_products` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tbd_products_users_providers
CREATE TABLE `tbd_products_users_providers` (
  `user_ID` int unsigned NOT NULL,
  `product_ID` int unsigned NOT NULL,
  `type_ownership` enum('Owner','Reseller','Distributor') DEFAULT NULL,
  `status` bit(1) NOT NULL DEFAULT b'1',
  `avalaible_date` datetime NOT NULL,
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_ID`,`product_ID`),
  KEY `fk_products2` (`product_ID`),
  CONSTRAINT `fk_products2` FOREIGN KEY (`product_ID`) REFERENCES `tb_products` (`ID`),
  CONSTRAINT `fk_user1` FOREIGN KEY (`user_ID`) REFERENCES `tb_users` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tbd_user_payment_methods
CREATE TABLE `tbd_user_payment_methods` (
  `ID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_ID` int unsigned NOT NULL,
  `payment_method_type_ID` int unsigned NOT NULL,
  `provider` varchar(60) NOT NULL,
  `provider_method_ref` varchar(255) NOT NULL,
  `label` varchar(100) DEFAULT NULL,
  `last_four` char(4) DEFAULT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT '0',
  `status` bit(1) NOT NULL DEFAULT b'1',
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `uk_provider_method` (`provider`,`provider_method_ref`),
  KEY `user_ID` (`user_ID`),
  KEY `payment_method_type_ID` (`payment_method_type_ID`),
  CONSTRAINT `tbd_user_payment_methods_ibfk_1` FOREIGN KEY (`user_ID`) REFERENCES `tb_users` (`ID`),
  CONSTRAINT `tbd_user_payment_methods_ibfk_2` FOREIGN KEY (`payment_method_type_ID`) REFERENCES `tbc_payment_methods_types` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tbd_users_wishlist_products
CREATE TABLE `tbd_users_wishlist_products` (
  `user_ID` int unsigned NOT NULL,
  `product_ID` int unsigned NOT NULL,
  `status` bit(1) NOT NULL DEFAULT b'1',
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime NOT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_ID`,`product_ID`),
  KEY `fk_products3` (`product_ID`),
  CONSTRAINT `fk_products3` FOREIGN KEY (`product_ID`) REFERENCES `tb_products` (`ID`),
  CONSTRAINT `fk_user2` FOREIGN KEY (`user_ID`) REFERENCES `tb_users` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Vista: vw_total_products_by_category (definición final del dump)
/*!50001 VIEW `vw_total_products_by_category` AS with recursive `categoryhierarchy` as (select `tbc_categories`.`ID` AS `category_ID`,cast(`tbc_categories`.`name` as char(500) charset utf8mb4) AS `category_path`,1 AS `category_level` from `tbc_categories` where (`tbc_categories`.`sup_id_category` is null) union all select `c`.`ID` AS `category_ID`,concat(`h`.`category_path`,' -> ',`c`.`name`) AS `category_path`,(`h`.`category_level` + 1) AS `category_level` from (`tbc_categories` `c` join `categoryhierarchy` `h` on((`c`.`sup_id_category` = `h`.`category_ID`)))) select `ch`.`category_ID` AS `category_ID`,`ch`.`category_path` AS `category_path`,`ch`.`category_level` AS `category_level`,count(`pc`.`product_ID`) AS `total_products`,sum((case when (`pc`.`status` = 1) then 1 else 0 end)) AS `total_active_products`,sum((case when (`pc`.`status` = 0) then 1 else 0 end)) AS `total_inactive_products`,0 AS `total_uncategorized_products` from (`categoryhierarchy` `ch` left join `tbd_products_categories` `pc` on((`ch`.`category_ID` = `pc`.`category_ID`))) group by `ch`.`category_ID`,`ch`.`category_path`,`ch`.`category_level` union all select NULL AS `category_ID`,'Sin categoría' AS `category_path`,0 AS `category_level`,count(`p`.`ID`) AS `total_products`,sum((case when (`p`.`status` = 1) then 1 else 0 end)) AS `total_active_products`,sum((case when (`p`.`status` = 0) then 1 else 0 end)) AS `total_inactive_products`,count(`p`.`ID`) AS `total_uncategorized_products` from (`tb_products` `p` left join `tbd_products_categories` `pc` on((`p`.`ID` = `pc`.`product_ID`))) where (`pc`.`product_ID` is null) */

-- Vista: vw_trazabilidad_carritos (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_carritos` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_carts') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_categorias (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_categorias` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbc_categories') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_componentes_direccion (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_componentes_direccion` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbd_address_components') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_direcciones_usuario (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_direcciones_usuario` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_user_addresses') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_items_carrito (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_items_carrito` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbd_carts_items') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_items_orden (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_items_orden` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbd_order_items') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_metodos_pago_usuario (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_metodos_pago_usuario` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbd_user_payment_methods') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_ordenes (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_ordenes` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbb_orders') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_ordenes_de_compra (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_ordenes_de_compra` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_buyer_orders') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_ordenes_vendedor (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_ordenes_vendedor` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_seller_orders') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_pagos (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_pagos` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_payments') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_productos (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_productos` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_products') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_productos_categorias (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_productos_categorias` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbd_products_categories') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_products_users_providers (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_products_users_providers` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbd_products_users_providers') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_tipos_metodos_pago (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_tipos_metodos_pago` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbc_payment_methods_types') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_transacciones_pago (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_transacciones_pago` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_payment_transactions') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_usuarios (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_usuarios` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_users') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_wishlist (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_wishlist` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbd_users_wishlist_products') and (`tb_logs`.`operation_status` = 0x01)) */

-- Trigger: trg_buyer_orders_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_buyer_orders_after_insert` AFTER INSERT ON `tb_buyer_orders` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_buyer_orders',
        'Create',
        LEFT(USER(), 80),
        CONCAT('Orden de vendedor creado. ', 'ID: ', NEW.ID, '. Datos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'seller_ID', NEW.seller_ID,
                'subtotal', NEW.subtotal,
                'shipping_cost', NEW.shipping_cost,
                'fulfillment_status', NEW.fulfillment_status,
                'status', CAST(NEW.status AS UNSIGNED),
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_buyer_orders_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_buyer_orders_after_update` AFTER UPDATE ON `tb_buyer_orders` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_buyer_orders',
        'Update',
        LEFT(USER(), 80),
        CONCAT('Orden de vendedor actualizado. ', 'ID: ', NEW.ID, '. Valores anteriores: ', JSON_OBJECT(
                'ID', OLD.ID,
                'seller_ID', OLD.seller_ID,
                'subtotal', OLD.subtotal,
                'shipping_cost', OLD.shipping_cost,
                'fulfillment_status', OLD.fulfillment_status,
                'status', CAST(OLD.status AS UNSIGNED),
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            ), '. Valores nuevos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'seller_ID', NEW.seller_ID,
                'subtotal', NEW.subtotal,
                'shipping_cost', NEW.shipping_cost,
                'fulfillment_status', NEW.fulfillment_status,
                'status', CAST(NEW.status AS UNSIGNED),
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_buyer_orders_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_buyer_orders_after_delete` AFTER DELETE ON `tb_buyer_orders` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_buyer_orders',
        'Delete',
        LEFT(USER(), 80),
        CONCAT('Orden de vendedor eliminado. ', 'ID: ', OLD.ID, '. Datos eliminados: ', JSON_OBJECT(
                'ID', OLD.ID,
                'seller_ID', OLD.seller_ID,
                'subtotal', OLD.subtotal,
                'shipping_cost', OLD.shipping_cost,
                'fulfillment_status', OLD.fulfillment_status,
                'status', CAST(OLD.status AS UNSIGNED),
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_carts_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_carts_after_insert` AFTER INSERT ON `tb_carts` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_carts',
        'Create',
        LEFT(USER(), 80),
        CONCAT('Carrito creado. ', 'ID: ', NEW.ID, '. Datos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'user_ID', NEW.user_ID,
                'status', CAST(NEW.status AS UNSIGNED),
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_carts_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_carts_after_update` AFTER UPDATE ON `tb_carts` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_carts',
        'Update',
        LEFT(USER(), 80),
        CONCAT('Carrito actualizado. ', 'ID: ', NEW.ID, '. Valores anteriores: ', JSON_OBJECT(
                'ID', OLD.ID,
                'user_ID', OLD.user_ID,
                'status', CAST(OLD.status AS UNSIGNED),
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            ), '. Valores nuevos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'user_ID', NEW.user_ID,
                'status', CAST(NEW.status AS UNSIGNED),
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_carts_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_carts_after_delete` AFTER DELETE ON `tb_carts` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_carts',
        'Delete',
        LEFT(USER(), 80),
        CONCAT('Carrito eliminado. ', 'ID: ', OLD.ID, '. Datos eliminados: ', JSON_OBJECT(
                'ID', OLD.ID,
                'user_ID', OLD.user_ID,
                'status', CAST(OLD.status AS UNSIGNED),
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_payment_transactions_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_payment_transactions_after_insert` AFTER INSERT ON `tb_payment_transactions` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_payment_transactions',
        'Create',
        LEFT(USER(), 80),
        CONCAT('Transaccion de pago creado. ', 'ID: ', NEW.ID, '. Datos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'payment_ID', NEW.payment_ID,
                'event_type', NEW.event_type,
                'amount', NEW.amount,
                'event_reference', NEW.event_reference,
                'remarks', NEW.remarks,
                'creation_date', NEW.creation_date
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_payment_transactions_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_payment_transactions_after_update` AFTER UPDATE ON `tb_payment_transactions` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_payment_transactions',
        'Update',
        LEFT(USER(), 80),
        CONCAT('Transaccion de pago actualizado. ', 'ID: ', NEW.ID, '. Valores anteriores: ', JSON_OBJECT(
                'ID', OLD.ID,
                'payment_ID', OLD.payment_ID,
                'event_type', OLD.event_type,
                'amount', OLD.amount,
                'event_reference', OLD.event_reference,
                'remarks', OLD.remarks,
                'creation_date', OLD.creation_date
            ), '. Valores nuevos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'payment_ID', NEW.payment_ID,
                'event_type', NEW.event_type,
                'amount', NEW.amount,
                'event_reference', NEW.event_reference,
                'remarks', NEW.remarks,
                'creation_date', NEW.creation_date
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_payment_transactions_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_payment_transactions_after_delete` AFTER DELETE ON `tb_payment_transactions` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_payment_transactions',
        'Delete',
        LEFT(USER(), 80),
        CONCAT('Transaccion de pago eliminado. ', 'ID: ', OLD.ID, '. Datos eliminados: ', JSON_OBJECT(
                'ID', OLD.ID,
                'payment_ID', OLD.payment_ID,
                'event_type', OLD.event_type,
                'amount', OLD.amount,
                'event_reference', OLD.event_reference,
                'remarks', OLD.remarks,
                'creation_date', OLD.creation_date
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_payments_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_payments_after_insert` AFTER INSERT ON `tb_payments` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_payments',
        'Create',
        LEFT(USER(), 80),
        CONCAT('Pago creado. ', 'ID: ', NEW.ID, '. Datos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'order_ID', NEW.order_ID,
                'amount', NEW.amount,
                'currency', NEW.currency,
                'payment_method', NEW.payment_method,
                'provider', NEW.provider,
                'provider_reference', NEW.provider_reference,
                'payment_status', NEW.payment_status,
                'creation_date', NEW.creation_date,
                'paid_date', NEW.paid_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_payments_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_payments_after_update` AFTER UPDATE ON `tb_payments` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_payments',
        'Update',
        LEFT(USER(), 80),
        CONCAT('Pago actualizado. ', 'ID: ', NEW.ID, '. Valores anteriores: ', JSON_OBJECT(
                'ID', OLD.ID,
                'order_ID', OLD.order_ID,
                'amount', OLD.amount,
                'currency', OLD.currency,
                'payment_method', OLD.payment_method,
                'provider', OLD.provider,
                'provider_reference', OLD.provider_reference,
                'payment_status', OLD.payment_status,
                'creation_date', OLD.creation_date,
                'paid_date', OLD.paid_date,
                'last_update', OLD.last_update
            ), '. Valores nuevos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'order_ID', NEW.order_ID,
                'amount', NEW.amount,
                'currency', NEW.currency,
                'payment_method', NEW.payment_method,
                'provider', NEW.provider,
                'provider_reference', NEW.provider_reference,
                'payment_status', NEW.payment_status,
                'creation_date', NEW.creation_date,
                'paid_date', NEW.paid_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_payments_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_payments_after_delete` AFTER DELETE ON `tb_payments` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_payments',
        'Delete',
        LEFT(USER(), 80),
        CONCAT('Pago eliminado. ', 'ID: ', OLD.ID, '. Datos eliminados: ', JSON_OBJECT(
                'ID', OLD.ID,
                'order_ID', OLD.order_ID,
                'amount', OLD.amount,
                'currency', OLD.currency,
                'payment_method', OLD.payment_method,
                'provider', OLD.provider,
                'provider_reference', OLD.provider_reference,
                'payment_status', OLD.payment_status,
                'creation_date', OLD.creation_date,
                'paid_date', OLD.paid_date,
                'last_update', OLD.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_products_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_products_after_insert` AFTER INSERT ON `tb_products` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        operation_date,
        description,
        operation_status
    )
    VALUES (
        'tb_products',
        'Create',
        USER(),
        CURRENT_TIMESTAMP,
        CONCAT(
            'Producto creado. ID=', NEW.ID,
            ', SKU=', NEW.SKU,
            ', nombre=', NEW.name
        ),
        b'1'
    );
END */;;

-- Trigger: trg_products_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_products_after_update` AFTER UPDATE ON `tb_products` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        operation_date,
        description,
        operation_status
    )
    VALUES (
        'tb_products',
        'Update',
        USER(),
        CURRENT_TIMESTAMP,
        CONCAT(
            'Producto actualizado. ID=', NEW.ID,
            ', SKU=', NEW.SKU,
            ', nombre=', NEW.name
        ),
        b'1'
    );
END */;;

-- Trigger: trg_products_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_products_after_delete` AFTER DELETE ON `tb_products` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        operation_date,
        description,
        operation_status
    )
    VALUES (
        'tb_products',
        'Delete',
        USER(),
        CURRENT_TIMESTAMP,
        CONCAT(
            'Producto eliminado. ID=', OLD.ID,
            ', SKU=', OLD.SKU,
            ', nombre=', OLD.name
        ),
        b'1'
    );
END */;;

-- Trigger: trg_seller_orders_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_seller_orders_after_insert` AFTER INSERT ON `tb_seller_orders` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_seller_orders',
        'Create',
        LEFT(USER(), 80),
        CONCAT('Orden de vendedor (seller_orders) creado. ', 'ID: ', NEW.ID, '. Datos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'order_ID', NEW.order_ID,
                'seller_ID', NEW.seller_ID,
                'subtotal', NEW.subtotal,
                'shipping_cost', NEW.shipping_cost,
                'fulfillment_status', NEW.fulfillment_status,
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_seller_orders_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_seller_orders_after_update` AFTER UPDATE ON `tb_seller_orders` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_seller_orders',
        'Update',
        LEFT(USER(), 80),
        CONCAT('Orden de vendedor (seller_orders) actualizado. ', 'ID: ', NEW.ID, '. Valores anteriores: ', JSON_OBJECT(
                'ID', OLD.ID,
                'order_ID', OLD.order_ID,
                'seller_ID', OLD.seller_ID,
                'subtotal', OLD.subtotal,
                'shipping_cost', OLD.shipping_cost,
                'fulfillment_status', OLD.fulfillment_status,
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            ), '. Valores nuevos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'order_ID', NEW.order_ID,
                'seller_ID', NEW.seller_ID,
                'subtotal', NEW.subtotal,
                'shipping_cost', NEW.shipping_cost,
                'fulfillment_status', NEW.fulfillment_status,
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_seller_orders_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_seller_orders_after_delete` AFTER DELETE ON `tb_seller_orders` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_seller_orders',
        'Delete',
        LEFT(USER(), 80),
        CONCAT('Orden de vendedor (seller_orders) eliminado. ', 'ID: ', OLD.ID, '. Datos eliminados: ', JSON_OBJECT(
                'ID', OLD.ID,
                'order_ID', OLD.order_ID,
                'seller_ID', OLD.seller_ID,
                'subtotal', OLD.subtotal,
                'shipping_cost', OLD.shipping_cost,
                'fulfillment_status', OLD.fulfillment_status,
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_user_addresses_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_user_addresses_after_insert` AFTER INSERT ON `tb_user_addresses` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_user_addresses',
        'Create',
        LEFT(USER(), 80),
        CONCAT('Direccion de usuario creado. ', 'ID: ', NEW.ID, '. Datos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'user_ID', NEW.user_ID,
                'address_label', NEW.address_label,
                'recipient_name', NEW.recipient_name,
                'recipient_phone', NEW.recipient_phone,
                'delivery_instructions', NEW.delivery_instructions,
                'latitude', NEW.latitude,
                'longitude', NEW.longitude,
                'is_default', NEW.is_default,
                'status', CAST(NEW.status AS UNSIGNED),
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_user_addresses_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_user_addresses_after_update` AFTER UPDATE ON `tb_user_addresses` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_user_addresses',
        'Update',
        LEFT(USER(), 80),
        CONCAT('Direccion de usuario actualizado. ', 'ID: ', NEW.ID, '. Valores anteriores: ', JSON_OBJECT(
                'ID', OLD.ID,
                'user_ID', OLD.user_ID,
                'address_label', OLD.address_label,
                'recipient_name', OLD.recipient_name,
                'recipient_phone', OLD.recipient_phone,
                'delivery_instructions', OLD.delivery_instructions,
                'latitude', OLD.latitude,
                'longitude', OLD.longitude,
                'is_default', OLD.is_default,
                'status', CAST(OLD.status AS UNSIGNED),
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            ), '. Valores nuevos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'user_ID', NEW.user_ID,
                'address_label', NEW.address_label,
                'recipient_name', NEW.recipient_name,
                'recipient_phone', NEW.recipient_phone,
                'delivery_instructions', NEW.delivery_instructions,
                'latitude', NEW.latitude,
                'longitude', NEW.longitude,
                'is_default', NEW.is_default,
                'status', CAST(NEW.status AS UNSIGNED),
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_user_addresses_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_user_addresses_after_delete` AFTER DELETE ON `tb_user_addresses` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_user_addresses',
        'Delete',
        LEFT(USER(), 80),
        CONCAT('Direccion de usuario eliminado. ', 'ID: ', OLD.ID, '. Datos eliminados: ', JSON_OBJECT(
                'ID', OLD.ID,
                'user_ID', OLD.user_ID,
                'address_label', OLD.address_label,
                'recipient_name', OLD.recipient_name,
                'recipient_phone', OLD.recipient_phone,
                'delivery_instructions', OLD.delivery_instructions,
                'latitude', OLD.latitude,
                'longitude', OLD.longitude,
                'is_default', OLD.is_default,
                'status', CAST(OLD.status AS UNSIGNED),
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_users_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_users_after_insert` AFTER INSERT ON `tb_users` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_users',
        'Create',
        LEFT(USER(), 80),
        CONCAT('Usuario creado. ID=', NEW.ID, ', email=', NEW.email, ', nick=', NEW.nick),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_users_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_users_after_update` AFTER UPDATE ON `tb_users` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_users',
        'Update',
        LEFT(USER(), 80),
        CONCAT('Usuario actualizado. ID=', NEW.ID, ', email=', NEW.email, ', nick=', NEW.nick, ', estado antiguo=', CAST(OLD.status AS UNSIGNED), ', estado nuevo=', CAST(NEW.status AS UNSIGNED)),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_users_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_users_after_delete` AFTER DELETE ON `tb_users` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_users',
        'Delete',
        LEFT(USER(), 80),
        CONCAT('Usuario eliminado. ID=', OLD.ID, ', email=', OLD.email, ', nick=', OLD.nick),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbb_orders_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbb_orders_after_insert` AFTER INSERT ON `tbb_orders` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbb_orders',
        'Create',
        LEFT(USER(), 80),
        CONCAT('Orden de compra creado. ', 'ID: ', NEW.ID, '. Datos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'key', NEW.`key`,
                'User_ID', NEW.User_ID,
                'total_products', NEW.total_products,
                'total_cost', NEW.total_cost,
                'status_string', NEW.status_string,
                'status', CAST(NEW.status AS UNSIGNED),
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbb_orders_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbb_orders_after_update` AFTER UPDATE ON `tbb_orders` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbb_orders',
        'Update',
        LEFT(USER(), 80),
        CONCAT('Orden de compra actualizado. ', 'ID: ', NEW.ID, '. Valores anteriores: ', JSON_OBJECT(
                'ID', OLD.ID,
                'key', OLD.`key`,
                'User_ID', OLD.User_ID,
                'total_products', OLD.total_products,
                'total_cost', OLD.total_cost,
                'status_string', OLD.status_string,
                'status', CAST(OLD.status AS UNSIGNED),
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            ), '. Valores nuevos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'key', NEW.`key`,
                'User_ID', NEW.User_ID,
                'total_products', NEW.total_products,
                'total_cost', NEW.total_cost,
                'status_string', NEW.status_string,
                'status', CAST(NEW.status AS UNSIGNED),
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbb_orders_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbb_orders_after_delete` AFTER DELETE ON `tbb_orders` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbb_orders',
        'Delete',
        LEFT(USER(), 80),
        CONCAT('Orden de compra eliminado. ', 'ID: ', OLD.ID, '. Datos eliminados: ', JSON_OBJECT(
                'ID', OLD.ID,
                'key', OLD.`key`,
                'User_ID', OLD.User_ID,
                'total_products', OLD.total_products,
                'total_cost', OLD.total_cost,
                'status_string', OLD.status_string,
                'status', CAST(OLD.status AS UNSIGNED),
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbc_categories_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbc_categories_after_insert` AFTER INSERT ON `tbc_categories` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        operation_date,
        description,
        operation_status
    )
    VALUES (
        'tbc_categories',
        'Create',
        USER(),
        CURRENT_TIMESTAMP,
        CONCAT(
            'Categoría creada. ID=', NEW.ID,
            ', nombre=', NEW.name
        ),
        b'1'
    );
END */;;

-- Trigger: trg_tbc_categories_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbc_categories_after_update` AFTER UPDATE ON `tbc_categories` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        operation_date,
        description,
        operation_status
    )
    VALUES (
        'tbc_categories',
        'Update',
        USER(),
        CURRENT_TIMESTAMP,
        CONCAT(
            'Categoría actualizada. ID=', NEW.ID,
            ', nombre antiguo=', OLD.name, ', nombre nuevo=', NEW.name,
            ', estado antiguo=', OLD.status, ', estado nuevo=', NEW.status
        ),
        b'1'
    );
END */;;

-- Trigger: trg_tbc_categories_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbc_categories_after_delete` AFTER DELETE ON `tbc_categories` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        operation_date,
        description,
        operation_status
    )
    VALUES (
        'tbc_categories',
        'Delete',
        USER(),
        CURRENT_TIMESTAMP,
        CONCAT(
            'Categoría eliminada. ID=', OLD.ID,
            ', nombre=', OLD.name
        ),
        b'1'
    );
END */;;

-- Trigger: trg_tbc_payment_methods_types_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbc_payment_methods_types_after_insert` AFTER INSERT ON `tbc_payment_methods_types` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbc_payment_methods_types',
        'Create',
        LEFT(USER(), 80),
        CONCAT('Tipo de metodo de pago creado. ', 'ID: ', NEW.ID, '. Datos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'code', NEW.code,
                'description', NEW.description,
                'status', CAST(NEW.status AS UNSIGNED),
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbc_payment_methods_types_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbc_payment_methods_types_after_update` AFTER UPDATE ON `tbc_payment_methods_types` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbc_payment_methods_types',
        'Update',
        LEFT(USER(), 80),
        CONCAT('Tipo de metodo de pago actualizado. ', 'ID: ', NEW.ID, '. Valores anteriores: ', JSON_OBJECT(
                'ID', OLD.ID,
                'code', OLD.code,
                'description', OLD.description,
                'status', CAST(OLD.status AS UNSIGNED),
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            ), '. Valores nuevos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'code', NEW.code,
                'description', NEW.description,
                'status', CAST(NEW.status AS UNSIGNED),
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbc_payment_methods_types_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbc_payment_methods_types_after_delete` AFTER DELETE ON `tbc_payment_methods_types` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbc_payment_methods_types',
        'Delete',
        LEFT(USER(), 80),
        CONCAT('Tipo de metodo de pago eliminado. ', 'ID: ', OLD.ID, '. Datos eliminados: ', JSON_OBJECT(
                'ID', OLD.ID,
                'code', OLD.code,
                'description', OLD.description,
                'status', CAST(OLD.status AS UNSIGNED),
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_address_components_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_address_components_after_insert` AFTER INSERT ON `tbd_address_components` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_address_components',
        'Create',
        LEFT(USER(), 80),
        CONCAT('Componente de direccion creado. ', 'ID: ', NEW.ID, '. Datos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'address_ID', NEW.address_ID,
                'value', NEW.value,
                'component_type', NEW.component_type,
                'status', CAST(NEW.status AS UNSIGNED),
                'address_sup_ID', NEW.address_sup_ID,
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_address_components_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_address_components_after_update` AFTER UPDATE ON `tbd_address_components` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_address_components',
        'Update',
        LEFT(USER(), 80),
        CONCAT('Componente de direccion actualizado. ', 'ID: ', NEW.ID, '. Valores anteriores: ', JSON_OBJECT(
                'ID', OLD.ID,
                'address_ID', OLD.address_ID,
                'value', OLD.value,
                'component_type', OLD.component_type,
                'status', CAST(OLD.status AS UNSIGNED),
                'address_sup_ID', OLD.address_sup_ID,
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            ), '. Valores nuevos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'address_ID', NEW.address_ID,
                'value', NEW.value,
                'component_type', NEW.component_type,
                'status', CAST(NEW.status AS UNSIGNED),
                'address_sup_ID', NEW.address_sup_ID,
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_address_components_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_address_components_after_delete` AFTER DELETE ON `tbd_address_components` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_address_components',
        'Delete',
        LEFT(USER(), 80),
        CONCAT('Componente de direccion eliminado. ', 'ID: ', OLD.ID, '. Datos eliminados: ', JSON_OBJECT(
                'ID', OLD.ID,
                'address_ID', OLD.address_ID,
                'value', OLD.value,
                'component_type', OLD.component_type,
                'status', CAST(OLD.status AS UNSIGNED),
                'address_sup_ID', OLD.address_sup_ID,
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_carts_items_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_carts_items_after_insert` AFTER INSERT ON `tbd_carts_items` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_carts_items',
        'Create',
        LEFT(USER(), 80),
        CONCAT('Item de carrito creado. ', 'cart_ID: ', NEW.cart_ID, ', provider_ID: ', NEW.provider_ID, ', product_ID: ', NEW.product_ID, '. Datos: ', JSON_OBJECT(
                'cart_ID', NEW.cart_ID,
                'provider_ID', NEW.provider_ID,
                'product_ID', NEW.product_ID,
                'quantity', NEW.quantity,
                'creation_date', NEW.creation_date
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_carts_items_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_carts_items_after_update` AFTER UPDATE ON `tbd_carts_items` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_carts_items',
        'Update',
        LEFT(USER(), 80),
        CONCAT('Item de carrito actualizado. ', 'cart_ID: ', NEW.cart_ID, ', provider_ID: ', NEW.provider_ID, ', product_ID: ', NEW.product_ID, '. Valores anteriores: ', JSON_OBJECT(
                'cart_ID', OLD.cart_ID,
                'provider_ID', OLD.provider_ID,
                'product_ID', OLD.product_ID,
                'quantity', OLD.quantity,
                'creation_date', OLD.creation_date
            ), '. Valores nuevos: ', JSON_OBJECT(
                'cart_ID', NEW.cart_ID,
                'provider_ID', NEW.provider_ID,
                'product_ID', NEW.product_ID,
                'quantity', NEW.quantity,
                'creation_date', NEW.creation_date
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_carts_items_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_carts_items_after_delete` AFTER DELETE ON `tbd_carts_items` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_carts_items',
        'Delete',
        LEFT(USER(), 80),
        CONCAT('Item de carrito eliminado. ', 'cart_ID: ', OLD.cart_ID, ', provider_ID: ', OLD.provider_ID, ', product_ID: ', OLD.product_ID, '. Datos eliminados: ', JSON_OBJECT(
                'cart_ID', OLD.cart_ID,
                'provider_ID', OLD.provider_ID,
                'product_ID', OLD.product_ID,
                'quantity', OLD.quantity,
                'creation_date', OLD.creation_date
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_order_items_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_order_items_after_insert` AFTER INSERT ON `tbd_order_items` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_order_items',
        'Create',
        LEFT(USER(), 80),
        CONCAT('Item de orden creado. ', 'ID: ', NEW.ID, '. Datos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'seller_order_ID', NEW.seller_order_ID,
                'product_ID', NEW.product_ID,
                'provider_ID', NEW.provider_ID,
                'product_name', NEW.product_name,
                'quantity', NEW.quantity,
                'unit_price', NEW.unit_price,
                'subtotal', NEW.subtotal,
                'creation_date', NEW.creation_date
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_order_items_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_order_items_after_update` AFTER UPDATE ON `tbd_order_items` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_order_items',
        'Update',
        LEFT(USER(), 80),
        CONCAT('Item de orden actualizado. ', 'ID: ', NEW.ID, '. Valores anteriores: ', JSON_OBJECT(
                'ID', OLD.ID,
                'seller_order_ID', OLD.seller_order_ID,
                'product_ID', OLD.product_ID,
                'provider_ID', OLD.provider_ID,
                'product_name', OLD.product_name,
                'quantity', OLD.quantity,
                'unit_price', OLD.unit_price,
                'subtotal', OLD.subtotal,
                'creation_date', OLD.creation_date
            ), '. Valores nuevos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'seller_order_ID', NEW.seller_order_ID,
                'product_ID', NEW.product_ID,
                'provider_ID', NEW.provider_ID,
                'product_name', NEW.product_name,
                'quantity', NEW.quantity,
                'unit_price', NEW.unit_price,
                'subtotal', NEW.subtotal,
                'creation_date', NEW.creation_date
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_order_items_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_order_items_after_delete` AFTER DELETE ON `tbd_order_items` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_order_items',
        'Delete',
        LEFT(USER(), 80),
        CONCAT('Item de orden eliminado. ', 'ID: ', OLD.ID, '. Datos eliminados: ', JSON_OBJECT(
                'ID', OLD.ID,
                'seller_order_ID', OLD.seller_order_ID,
                'product_ID', OLD.product_ID,
                'provider_ID', OLD.provider_ID,
                'product_name', OLD.product_name,
                'quantity', OLD.quantity,
                'unit_price', OLD.unit_price,
                'subtotal', OLD.subtotal,
                'creation_date', OLD.creation_date
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_products_categories_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_products_categories_after_insert` AFTER INSERT ON `tbd_products_categories` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        operation_date,
        description,
        operation_status
    )
    VALUES (
        'tbd_products_categories',
        'Create',
        USER(),
        CURRENT_TIMESTAMP,
        CONCAT(
            'Asociación producto-categoría creada. category_ID=', NEW.category_ID,
            ', product_ID=', NEW.product_ID
        ),
        b'1'
    );
END */;;

-- Trigger: trg_tbd_products_categories_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_products_categories_after_update` AFTER UPDATE ON `tbd_products_categories` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        operation_date,
        description,
        operation_status
    )
    VALUES (
        'tbd_products_categories',
        'Update',
        USER(),
        CURRENT_TIMESTAMP,
        CONCAT(
            'Asociación producto-categoría actualizada. category_ID=', NEW.category_ID,
            ', product_ID=', NEW.product_ID,
            ', estado antiguo=', OLD.status, ', estado nuevo=', NEW.status
        ),
        b'1'
    );
END */;;

-- Trigger: trg_tbd_products_categories_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_products_categories_after_delete` AFTER DELETE ON `tbd_products_categories` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        operation_date,
        description,
        operation_status
    )
    VALUES (
        'tbd_products_categories',
        'Delete',
        USER(),
        CURRENT_TIMESTAMP,
        CONCAT(
            'Asociación producto-categoría eliminada. category_ID=', OLD.category_ID,
            ', product_ID=', OLD.product_ID
        ),
        b'1'
    );
END */;;

-- Trigger: trg_products_users_providers_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_products_users_providers_after_insert` AFTER INSERT ON `tbd_products_users_providers` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tbd_products_users_providers',
        'Create',
        USER(),
        CONCAT(
            'Relación producto-proveedor creada. user_ID=', NEW.user_ID,
            ', product_ID=', NEW.product_ID,
            ', type_ownership=', IFNULL(NEW.type_ownership, 'N/A')
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_products_users_providers_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_products_users_providers_after_update` AFTER UPDATE ON `tbd_products_users_providers` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tbd_products_users_providers',
        'Update',
        USER(),
        CONCAT(
            'Relación producto-proveedor actualizada. user_ID=', NEW.user_ID,
            ', product_ID=', NEW.product_ID,
            ', type_ownership=', IFNULL(NEW.type_ownership, 'N/A'),
            ', status=', NEW.status
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_products_users_providers_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_products_users_providers_after_delete` AFTER DELETE ON `tbd_products_users_providers` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (
        table_name,
        operation,
        db_user,
        description,
        operation_date,
        operation_status
    )
    VALUES (
        'tbd_products_users_providers',
        'Delete',
        USER(),
        CONCAT(
            'Relación producto-proveedor eliminada. user_ID=', OLD.user_ID,
            ', product_ID=', OLD.product_ID,
            ', type_ownership=', IFNULL(OLD.type_ownership, 'N/A')
        ),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_user_payment_methods_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_user_payment_methods_after_insert` AFTER INSERT ON `tbd_user_payment_methods` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_user_payment_methods',
        'Create',
        LEFT(USER(), 80),
        CONCAT('Metodo de pago de usuario creado. ', 'ID: ', NEW.ID, '. Datos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'user_ID', NEW.user_ID,
                'payment_method_type_ID', NEW.payment_method_type_ID,
                'provider', NEW.provider,
                'label', NEW.label,
                'last_four', NEW.last_four,
                'is_default', NEW.is_default,
                'status', CAST(NEW.status AS UNSIGNED),
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_user_payment_methods_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_user_payment_methods_after_update` AFTER UPDATE ON `tbd_user_payment_methods` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_user_payment_methods',
        'Update',
        LEFT(USER(), 80),
        CONCAT('Metodo de pago de usuario actualizado. ', 'ID: ', NEW.ID, '. Valores anteriores: ', JSON_OBJECT(
                'ID', OLD.ID,
                'user_ID', OLD.user_ID,
                'payment_method_type_ID', OLD.payment_method_type_ID,
                'provider', OLD.provider,
                'label', OLD.label,
                'last_four', OLD.last_four,
                'is_default', OLD.is_default,
                'status', CAST(OLD.status AS UNSIGNED),
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            ), '. Valores nuevos: ', JSON_OBJECT(
                'ID', NEW.ID,
                'user_ID', NEW.user_ID,
                'payment_method_type_ID', NEW.payment_method_type_ID,
                'provider', NEW.provider,
                'label', NEW.label,
                'last_four', NEW.last_four,
                'is_default', NEW.is_default,
                'status', CAST(NEW.status AS UNSIGNED),
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_user_payment_methods_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_user_payment_methods_after_delete` AFTER DELETE ON `tbd_user_payment_methods` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_user_payment_methods',
        'Delete',
        LEFT(USER(), 80),
        CONCAT('Metodo de pago de usuario eliminado. ', 'ID: ', OLD.ID, '. Datos eliminados: ', JSON_OBJECT(
                'ID', OLD.ID,
                'user_ID', OLD.user_ID,
                'payment_method_type_ID', OLD.payment_method_type_ID,
                'provider', OLD.provider,
                'label', OLD.label,
                'last_four', OLD.last_four,
                'is_default', OLD.is_default,
                'status', CAST(OLD.status AS UNSIGNED),
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_users_wishlist_products_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_users_wishlist_products_after_insert` AFTER INSERT ON `tbd_users_wishlist_products` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_users_wishlist_products',
        'Create',
        LEFT(USER(), 80),
        CONCAT('Producto en wishlist creado. ', 'user_ID: ', NEW.user_ID, ', product_ID: ', NEW.product_ID, '. Datos: ', JSON_OBJECT(
                'user_ID', NEW.user_ID,
                'product_ID', NEW.product_ID,
                'status', CAST(NEW.status AS UNSIGNED),
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_users_wishlist_products_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_users_wishlist_products_after_update` AFTER UPDATE ON `tbd_users_wishlist_products` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_users_wishlist_products',
        'Update',
        LEFT(USER(), 80),
        CONCAT('Producto en wishlist actualizado. ', 'user_ID: ', NEW.user_ID, ', product_ID: ', NEW.product_ID, '. Valores anteriores: ', JSON_OBJECT(
                'user_ID', OLD.user_ID,
                'product_ID', OLD.product_ID,
                'status', CAST(OLD.status AS UNSIGNED),
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            ), '. Valores nuevos: ', JSON_OBJECT(
                'user_ID', NEW.user_ID,
                'product_ID', NEW.product_ID,
                'status', CAST(NEW.status AS UNSIGNED),
                'creation_date', NEW.creation_date,
                'last_update', NEW.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_tbd_users_wishlist_products_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_tbd_users_wishlist_products_after_delete` AFTER DELETE ON `tbd_users_wishlist_products` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tbd_users_wishlist_products',
        'Delete',
        LEFT(USER(), 80),
        CONCAT('Producto en wishlist eliminado. ', 'user_ID: ', OLD.user_ID, ', product_ID: ', OLD.product_ID, '. Datos eliminados: ', JSON_OBJECT(
                'user_ID', OLD.user_ID,
                'product_ID', OLD.product_ID,
                'status', CAST(OLD.status AS UNSIGNED),
                'creation_date', OLD.creation_date,
                'last_update', OLD.last_update
            )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Procedimiento: sp_soft_delete_user
CREATE PROCEDURE `sp_soft_delete_user`(
    IN p_user_id INT UNSIGNED
)
    MODIFIES SQL DATA
BEGIN
    DECLARE v_db_user VARCHAR(32);
    DECLARE v_has_role INT DEFAULT 0;
    DECLARE v_exists INT DEFAULT 0;
    DECLARE v_status TINYINT DEFAULT NULL;
    DECLARE v_affected INT DEFAULT 0;

    -- 1. Identificar usuario de conexión
    SET v_db_user = SUBSTRING_INDEX(USER(), '@', 1);

    -- 2. Verificar roles autorizados asignados
    SELECT COUNT(*)
    INTO v_has_role
    FROM mysql.role_edges re
    WHERE re.TO_USER = v_db_user
      AND re.TO_HOST = '%'
      AND re.FROM_HOST = '%'
      AND re.FROM_USER IN (
          'superadmin',
          'admin',
          'support'
      );

    IF v_has_role = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Acceso denegado: rol no autorizado';
    END IF;

    -- 3. Validar identificador
    IF p_user_id IS NULL OR p_user_id = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'El identificador del usuario es inválido';
    END IF;

    -- 4. Comprobar existencia y estado
    SELECT COUNT(*), MAX(status + 0)
    INTO v_exists, v_status
    FROM tb_users
    WHERE ID = p_user_id;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'El usuario especificado no existe';
    END IF;

    -- 5. Comprobar estado actual
    IF v_status = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'El usuario ya se encuentra inactivo';
    END IF;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'El usuario tiene un estado inválido';
    END IF;

    -- 6. Eliminación lógica
    UPDATE tb_users
    SET status = b'0'
    WHERE ID = p_user_id
      AND status = b'1';

    SET v_affected = ROW_COUNT();

    IF v_affected <> 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'No se pudo desactivar el usuario';
    END IF;

    -- 7. Confirmación
    SELECT
        'Usuario desactivado correctamente' AS mensaje,
        p_user_id AS user_id,
        v_db_user AS ejecutado_por,
        'Inactivo' AS estado_actual,
        CURRENT_TIMESTAMP AS fecha_operacion;

END ;;
