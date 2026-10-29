-- Anexo técnico MySQL derivado del respaldo Practica03/backups/240196_27.10.26.sql
-- Fuente: C:\Users\ti_la\Pracricas_BDN_240196\Practica03\backups\240196_27.10.26.sql
-- Generado: 27 de octubre de 2026 a las 10:58 a.m. (America/Mexico_City)
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
) ENGINE=InnoDB AUTO_INCREMENT=58805 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tb_order_cancellations
CREATE TABLE `tb_order_cancellations` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `order_ID` int unsigned NOT NULL,
  `requested_by` int unsigned DEFAULT NULL,
  `reason` varchar(500) NOT NULL,
  `cancellation_status` enum('Requested','Approved','Rejected','Completed') NOT NULL DEFAULT 'Requested',
  `refund_required` bit(1) NOT NULL DEFAULT b'0',
  `resolution_notes` varchar(500) DEFAULT NULL,
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  KEY `idx_order_cancellations_order` (`order_ID`),
  KEY `idx_order_cancellations_requested_by` (`requested_by`),
  CONSTRAINT `fk_order_cancellations_order` FOREIGN KEY (`order_ID`) REFERENCES `tbb_orders` (`ID`),
  CONSTRAINT `fk_order_cancellations_user` FOREIGN KEY (`requested_by`) REFERENCES `tb_users` (`ID`),
  CONSTRAINT `chk_order_cancellation_reason` CHECK ((char_length(trim(`reason`)) > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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

-- Tabla: tb_people
CREATE TABLE `tb_people` (
  `person_ID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_ID` int unsigned DEFAULT NULL,
  `courtesy_title` varchar(20) DEFAULT NULL,
  `given_names` varchar(150) NOT NULL,
  `family_names` varchar(150) DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `gender` enum('Hombre','Mujer','Prefiero no decirlo') NOT NULL DEFAULT 'Prefiero no decirlo',
  `country_code` char(2) DEFAULT NULL,
  `phone` varchar(25) DEFAULT NULL,
  `status` bit(1) DEFAULT b'1',
  `creation_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`person_ID`),
  UNIQUE KEY `user_ID` (`user_ID`),
  CONSTRAINT `fk_people_users` FOREIGN KEY (`user_ID`) REFERENCES `tb_users` (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=10229 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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

-- Tabla: tb_refunds
CREATE TABLE `tb_refunds` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `payment_ID` int unsigned NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `refund_status` enum('Requested','Processing','Completed','Rejected','Failed') NOT NULL DEFAULT 'Requested',
  `reason` varchar(500) NOT NULL,
  `provider_reference` varchar(150) DEFAULT NULL,
  `requested_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `processed_at` datetime DEFAULT NULL,
  `last_update` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  KEY `idx_refunds_payment` (`payment_ID`),
  KEY `idx_refunds_status` (`refund_status`),
  CONSTRAINT `fk_refunds_payment` FOREIGN KEY (`payment_ID`) REFERENCES `tb_payments` (`ID`),
  CONSTRAINT `chk_refunds_amount` CHECK ((`amount` > 0)),
  CONSTRAINT `chk_refunds_reason` CHECK ((char_length(trim(`reason`)) > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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

-- Tabla: tb_shipments
CREATE TABLE `tb_shipments` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `seller_order_ID` int unsigned NOT NULL,
  `carrier` varchar(100) DEFAULT NULL,
  `tracking_number` varchar(150) DEFAULT NULL,
  `shipment_status` enum('Pending','LabelCreated','Shipped','InTransit','Delivered','Failed','Returned') NOT NULL DEFAULT 'Pending',
  `shipped_at` datetime DEFAULT NULL,
  `estimated_delivery` datetime DEFAULT NULL,
  `delivered_at` datetime DEFAULT NULL,
  `shipping_notes` varchar(500) DEFAULT NULL,
  `creation_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_update` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  KEY `idx_shipments_seller_order` (`seller_order_ID`),
  KEY `idx_shipments_tracking` (`tracking_number`),
  CONSTRAINT `fk_shipments_seller_order` FOREIGN KEY (`seller_order_ID`) REFERENCES `tb_seller_orders` (`ID`),
  CONSTRAINT `chk_shipments_dates` CHECK (((`delivered_at` is null) or (`shipped_at` is null) or (`delivered_at` >= `shipped_at`)))
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
) ENGINE=InnoDB AUTO_INCREMENT=10243 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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

-- Tabla: tbc_gen_email_domains
CREATE TABLE `tbc_gen_email_domains` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `country_code` char(2) NOT NULL,
  `domain` varchar(80) NOT NULL,
  `weight` smallint unsigned NOT NULL DEFAULT '1',
  `status` bit(1) NOT NULL DEFAULT b'1',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `uk_gen_domain` (`country_code`,`domain`),
  CONSTRAINT `chk_gen_domain_weight` CHECK ((`weight` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tbc_gen_family_names
CREATE TABLE `tbc_gen_family_names` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `country_code` char(2) NOT NULL,
  `name` varchar(60) NOT NULL,
  `weight` smallint unsigned NOT NULL DEFAULT '1',
  `status` bit(1) NOT NULL DEFAULT b'1',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `uk_gen_family` (`country_code`,`name`),
  CONSTRAINT `chk_gen_family_weight` CHECK ((`weight` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=370 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tbc_gen_given_names
CREATE TABLE `tbc_gen_given_names` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `country_code` char(2) NOT NULL,
  `gender` enum('Hombre','Mujer') NOT NULL,
  `name` varchar(60) NOT NULL,
  `birth_year_from` smallint unsigned NOT NULL COMMENT 'Primer año de nacimiento en que el nombre es común',
  `birth_year_to` smallint unsigned NOT NULL COMMENT 'Último año de nacimiento en que el nombre es común',
  `weight` smallint unsigned NOT NULL DEFAULT '1' COMMENT 'Frecuencia relativa',
  `status` bit(1) NOT NULL DEFAULT b'1',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `uk_gen_given` (`country_code`,`gender`,`name`,`birth_year_from`),
  KEY `idx_gen_given_lookup` (`country_code`,`gender`,`birth_year_from`,`birth_year_to`),
  CONSTRAINT `chk_gen_given_weight` CHECK ((`weight` > 0)),
  CONSTRAINT `chk_gen_given_years` CHECK ((`birth_year_from` <= `birth_year_to`))
) ENGINE=InnoDB AUTO_INCREMENT=509 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Tabla: tbc_gen_phone_area_codes
CREATE TABLE `tbc_gen_phone_area_codes` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `country_code` char(2) NOT NULL,
  `area_code` char(3) NOT NULL,
  `weight` smallint unsigned NOT NULL DEFAULT '1',
  `status` bit(1) NOT NULL DEFAULT b'1',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `uk_gen_area` (`country_code`,`area_code`),
  CONSTRAINT `chk_gen_area_weight` CHECK ((`weight` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=146 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

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
  KEY `idx_provider_product` (`provider_ID`,`product_ID`),
  CONSTRAINT `tbd_carts_items_ibfk_1` FOREIGN KEY (`cart_ID`) REFERENCES `tb_carts` (`ID`),
  CONSTRAINT `tbd_carts_items_ibfk_2` FOREIGN KEY (`provider_ID`, `product_ID`) REFERENCES `tbd_products_users_providers` (`user_ID`, `product_ID`),
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
  KEY `idx_provider_product` (`provider_ID`,`product_ID`),
  CONSTRAINT `tbd_order_items_ibfk_1` FOREIGN KEY (`seller_order_ID`) REFERENCES `tb_seller_orders` (`ID`),
  CONSTRAINT `tbd_order_items_ibfk_2` FOREIGN KEY (`provider_ID`, `product_ID`) REFERENCES `tbd_products_users_providers` (`user_ID`, `product_ID`),
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

-- Vista: vw_trazabilidad_cancelaciones (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_cancelaciones` AS select `c`.`ID` AS `cancellation_ID`,`c`.`order_ID` AS `order_ID`,`o`.`key` AS `order_key`,`o`.`User_ID` AS `buyer_user_ID`,`c`.`requested_by` AS `requested_by`,`c`.`reason` AS `reason`,`c`.`cancellation_status` AS `cancellation_status`,`c`.`refund_required` AS `refund_required`,`c`.`resolution_notes` AS `resolution_notes`,`c`.`creation_date` AS `creation_date`,`c`.`last_update` AS `last_update` from (`tb_order_cancellations` `c` join `tbb_orders` `o` on((`o`.`ID` = `c`.`order_ID`))) */

-- Vista: vw_trazabilidad_carritos (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_carritos` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_carts') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_categorias (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_categorias` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbc_categories') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_componentes_direccion (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_componentes_direccion` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbd_address_components') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_direcciones_usuario (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_direcciones_usuario` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_user_addresses') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_envios (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_envios` AS select `s`.`ID` AS `shipment_ID`,`s`.`seller_order_ID` AS `seller_order_ID`,`so`.`order_ID` AS `order_ID`,`o`.`key` AS `order_key`,`so`.`seller_ID` AS `seller_ID`,`s`.`carrier` AS `carrier`,`s`.`tracking_number` AS `tracking_number`,`s`.`shipment_status` AS `shipment_status`,`s`.`shipped_at` AS `shipped_at`,`s`.`estimated_delivery` AS `estimated_delivery`,`s`.`delivered_at` AS `delivered_at`,`s`.`shipping_notes` AS `shipping_notes`,`s`.`creation_date` AS `creation_date`,`s`.`last_update` AS `last_update` from ((`tb_shipments` `s` join `tb_seller_orders` `so` on((`so`.`ID` = `s`.`seller_order_ID`))) join `tbb_orders` `o` on((`o`.`ID` = `so`.`order_ID`))) */

-- Vista: vw_trazabilidad_items_carrito (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_items_carrito` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbd_carts_items') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_items_orden (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_items_orden` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbd_order_items') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_metodos_pago_usuario (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_metodos_pago_usuario` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbd_user_payment_methods') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_nuevas_tablas (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_nuevas_tablas` AS select `l`.`ID` AS `log_ID`,`l`.`table_name` AS `table_name`,`l`.`operation` AS `operation`,`l`.`db_user` AS `db_user`,`l`.`description` AS `description`,`l`.`operation_date` AS `operation_date`,`l`.`operation_status` AS `operation_status` from `tb_logs` `l` where (`l`.`table_name` in ('tb_order_cancellations','tb_shipments','tb_refunds')) */

-- Vista: vw_trazabilidad_ordenes (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_ordenes` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbb_orders') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_ordenes_de_compra (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_ordenes_de_compra` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_buyer_orders') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_ordenes_vendedor (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_ordenes_vendedor` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_seller_orders') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_pagos (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_pagos` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_payments') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_personas (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_personas` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_people') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_productos (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_productos` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_products') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_productos_categorias (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_productos_categorias` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbd_products_categories') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_products_users_providers (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_products_users_providers` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbd_products_users_providers') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_reembolsos (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_reembolsos` AS select `r`.`ID` AS `refund_ID`,`r`.`payment_ID` AS `payment_ID`,`p`.`order_ID` AS `order_ID`,`o`.`key` AS `order_key`,`o`.`User_ID` AS `buyer_user_ID`,`r`.`amount` AS `refund_amount`,`p`.`amount` AS `original_payment_amount`,`p`.`currency` AS `currency`,`p`.`payment_status` AS `payment_status`,`r`.`refund_status` AS `refund_status`,`r`.`reason` AS `reason`,`r`.`provider_reference` AS `provider_reference`,`r`.`requested_at` AS `requested_at`,`r`.`processed_at` AS `processed_at`,`r`.`last_update` AS `last_update` from ((`tb_refunds` `r` join `tb_payments` `p` on((`p`.`ID` = `r`.`payment_ID`))) join `tbb_orders` `o` on((`o`.`ID` = `p`.`order_ID`))) */

-- Vista: vw_trazabilidad_tipos_metodos_pago (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_tipos_metodos_pago` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tbc_payment_methods_types') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_transacciones_pago (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_transacciones_pago` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_payment_transactions') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_usuarios (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_usuarios` AS select `tb_logs`.`ID` AS `ID`,`tb_logs`.`table_name` AS `table_name`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_users') and (`tb_logs`.`operation_status` = 0x01)) */

-- Vista: vw_trazabilidad_usuarios_pares (definición final del dump)
/*!50001 VIEW `vw_trazabilidad_usuarios_pares` AS select `tb_logs`.`ID` AS `log_ID`,`tb_logs`.`table_name` AS `table_name`,cast(regexp_replace(regexp_substr(`tb_logs`.`description`,'ID[=: ]*[0-9]+'),'[^0-9]','') as unsigned) AS `usuario_ID`,`tb_logs`.`operation` AS `operation`,`tb_logs`.`db_user` AS `db_user`,`tb_logs`.`description` AS `description`,`tb_logs`.`operation_date` AS `operation_date`,`tb_logs`.`operation_status` AS `operation_status` from `tb_logs` where ((`tb_logs`.`table_name` = 'tb_users') and (regexp_substr(`tb_logs`.`description`,'ID[=: ]*[0-9]+') is not null) and ((cast(regexp_replace(regexp_substr(`tb_logs`.`description`,'ID[=: ]*[0-9]+'),'[^0-9]','') as unsigned) % 2) = 0)) */

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

-- Trigger: trg_order_cancellations_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_order_cancellations_after_insert` AFTER INSERT ON `tb_order_cancellations` FOR EACH ROW BEGIN
  INSERT INTO `tb_logs` (`table_name`,`operation`,`db_user`,`description`,`operation_date`,`operation_status`)
  VALUES ('tb_order_cancellations','Create',LEFT(USER(),80),
    CONCAT('Nueva solicitud de cancelación. Datos: ', JSON_OBJECT(
      'ID',NEW.ID,'order_ID',NEW.order_ID,'requested_by',NEW.requested_by,
      'cancellation_status',NEW.cancellation_status,'refund_required',NEW.refund_required,
      'creation_date',NEW.creation_date)), CURRENT_TIMESTAMP, b'1');
END */;;

-- Trigger: trg_order_cancellations_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_order_cancellations_after_update` AFTER UPDATE ON `tb_order_cancellations` FOR EACH ROW BEGIN
  INSERT INTO `tb_logs` (`table_name`,`operation`,`db_user`,`description`,`operation_date`,`operation_status`)
  VALUES ('tb_order_cancellations','Update',LEFT(USER(),80),
    CONCAT('Solicitud de cancelación actualizada. Antes: ', JSON_OBJECT(
      'ID',OLD.ID,'order_ID',OLD.order_ID,'cancellation_status',OLD.cancellation_status,
      'refund_required',OLD.refund_required), ' Después: ', JSON_OBJECT(
      'ID',NEW.ID,'order_ID',NEW.order_ID,'cancellation_status',NEW.cancellation_status,
      'refund_required',NEW.refund_required)), CURRENT_TIMESTAMP, b'1');
END */;;

-- Trigger: trg_order_cancellations_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_order_cancellations_after_delete` AFTER DELETE ON `tb_order_cancellations` FOR EACH ROW BEGIN
  INSERT INTO `tb_logs` (`table_name`,`operation`,`db_user`,`description`,`operation_date`,`operation_status`)
  VALUES ('tb_order_cancellations','Delete',LEFT(USER(),80),
    CONCAT('Solicitud de cancelación eliminada. Datos: ', JSON_OBJECT(
      'ID',OLD.ID,'order_ID',OLD.order_ID,'cancellation_status',OLD.cancellation_status,
      'refund_required',OLD.refund_required)), CURRENT_TIMESTAMP, b'1');
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

-- Trigger: trg_people_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_people_after_insert` AFTER INSERT ON `tb_people` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_people',
        'Create',
        LEFT(USER(), 80),
        CONCAT('Persona creada. ', 'ID: ', NEW.person_ID, '. Datos: ', JSON_OBJECT(
            'person_ID', NEW.person_ID,
            'user_ID', NEW.user_ID,
            'courtesy_title', NEW.courtesy_title,
            'given_names', NEW.given_names,
            'family_names', NEW.family_names,
            'birth_date', NEW.birth_date,
            'gender', NEW.gender,
            'country_code', NEW.country_code,
            'phone', NEW.phone,
            'status', CAST(NEW.status AS UNSIGNED),
            'creation_date', NEW.creation_date,
            'last_update', NEW.last_update
        )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_people_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_people_after_update` AFTER UPDATE ON `tb_people` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_people',
        'Update',
        LEFT(USER(), 80),
        CONCAT('Persona actualizada. ', 'ID: ', NEW.person_ID, '. Valores anteriores: ', JSON_OBJECT(
            'person_ID', OLD.person_ID,
            'user_ID', OLD.user_ID,
            'courtesy_title', OLD.courtesy_title,
            'given_names', OLD.given_names,
            'family_names', OLD.family_names,
            'birth_date', OLD.birth_date,
            'gender', OLD.gender,
            'country_code', OLD.country_code,
            'phone', OLD.phone,
            'status', CAST(OLD.status AS UNSIGNED),
            'creation_date', OLD.creation_date,
            'last_update', OLD.last_update
        ), '. Valores nuevos: ', JSON_OBJECT(
            'person_ID', NEW.person_ID,
            'user_ID', NEW.user_ID,
            'courtesy_title', NEW.courtesy_title,
            'given_names', NEW.given_names,
            'family_names', NEW.family_names,
            'birth_date', NEW.birth_date,
            'gender', NEW.gender,
            'country_code', NEW.country_code,
            'phone', NEW.phone,
            'status', CAST(NEW.status AS UNSIGNED),
            'creation_date', NEW.creation_date,
            'last_update', NEW.last_update
        )),
        CURRENT_TIMESTAMP,
        b'1'
    );
END */;;

-- Trigger: trg_people_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_people_after_delete` AFTER DELETE ON `tb_people` FOR EACH ROW BEGIN
    INSERT INTO tb_logs (table_name, operation, db_user, description, operation_date, operation_status)
    VALUES (
        'tb_people',
        'Delete',
        LEFT(USER(), 80),
        CONCAT('Persona eliminada. ', 'ID: ', OLD.person_ID, '. Datos eliminados: ', JSON_OBJECT(
            'person_ID', OLD.person_ID,
            'user_ID', OLD.user_ID,
            'courtesy_title', OLD.courtesy_title,
            'given_names', OLD.given_names,
            'family_names', OLD.family_names,
            'birth_date', OLD.birth_date,
            'gender', OLD.gender,
            'country_code', OLD.country_code,
            'phone', OLD.phone,
            'status', CAST(OLD.status AS UNSIGNED),
            'creation_date', OLD.creation_date,
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

-- Trigger: trg_refunds_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_refunds_after_insert` AFTER INSERT ON `tb_refunds` FOR EACH ROW BEGIN
  INSERT INTO `tb_logs` (`table_name`,`operation`,`db_user`,`description`,`operation_date`,`operation_status`)
  VALUES ('tb_refunds','Create',LEFT(USER(),80),
    CONCAT('Nuevo reembolso registrado. Datos: ', JSON_OBJECT(
      'ID',NEW.ID,'payment_ID',NEW.payment_ID,'amount',NEW.amount,
      'refund_status',NEW.refund_status,'provider_reference',NEW.provider_reference,
      'requested_at',NEW.requested_at)), CURRENT_TIMESTAMP, b'1');
END */;;

-- Trigger: trg_refunds_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_refunds_after_update` AFTER UPDATE ON `tb_refunds` FOR EACH ROW BEGIN
  INSERT INTO `tb_logs` (`table_name`,`operation`,`db_user`,`description`,`operation_date`,`operation_status`)
  VALUES ('tb_refunds','Update',LEFT(USER(),80),
    CONCAT('Reembolso actualizado. Antes: ', JSON_OBJECT(
      'ID',OLD.ID,'payment_ID',OLD.payment_ID,'amount',OLD.amount,'refund_status',OLD.refund_status),
      ' Después: ', JSON_OBJECT(
      'ID',NEW.ID,'payment_ID',NEW.payment_ID,'amount',NEW.amount,'refund_status',NEW.refund_status)),
      CURRENT_TIMESTAMP, b'1');
END */;;

-- Trigger: trg_refunds_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_refunds_after_delete` AFTER DELETE ON `tb_refunds` FOR EACH ROW BEGIN
  INSERT INTO `tb_logs` (`table_name`,`operation`,`db_user`,`description`,`operation_date`,`operation_status`)
  VALUES ('tb_refunds','Delete',LEFT(USER(),80),
    CONCAT('Reembolso eliminado. Datos: ', JSON_OBJECT(
      'ID',OLD.ID,'payment_ID',OLD.payment_ID,'amount',OLD.amount,'refund_status',OLD.refund_status)),
      CURRENT_TIMESTAMP, b'1');
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

-- Trigger: trg_shipments_after_insert
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_shipments_after_insert` AFTER INSERT ON `tb_shipments` FOR EACH ROW BEGIN
  INSERT INTO `tb_logs` (`table_name`,`operation`,`db_user`,`description`,`operation_date`,`operation_status`)
  VALUES ('tb_shipments','Create',LEFT(USER(),80),
    CONCAT('Nuevo registro de envío. Datos: ', JSON_OBJECT(
      'ID',NEW.ID,'seller_order_ID',NEW.seller_order_ID,'carrier',NEW.carrier,
      'tracking_number',NEW.tracking_number,'shipment_status',NEW.shipment_status,
      'creation_date',NEW.creation_date)), CURRENT_TIMESTAMP, b'1');
END */;;

-- Trigger: trg_shipments_after_update
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_shipments_after_update` AFTER UPDATE ON `tb_shipments` FOR EACH ROW BEGIN
  INSERT INTO `tb_logs` (`table_name`,`operation`,`db_user`,`description`,`operation_date`,`operation_status`)
  VALUES ('tb_shipments','Update',LEFT(USER(),80),
    CONCAT('Registro de envío actualizado. Antes: ', JSON_OBJECT(
      'ID',OLD.ID,'seller_order_ID',OLD.seller_order_ID,'shipment_status',OLD.shipment_status,
      'tracking_number',OLD.tracking_number), ' Después: ', JSON_OBJECT(
      'ID',NEW.ID,'seller_order_ID',NEW.seller_order_ID,'shipment_status',NEW.shipment_status,
      'tracking_number',NEW.tracking_number)), CURRENT_TIMESTAMP, b'1');
END */;;

-- Trigger: trg_shipments_after_delete
/*!50003 CREATE*/ /*!50003 TRIGGER `trg_shipments_after_delete` AFTER DELETE ON `tb_shipments` FOR EACH ROW BEGIN
  INSERT INTO `tb_logs` (`table_name`,`operation`,`db_user`,`description`,`operation_date`,`operation_status`)
  VALUES ('tb_shipments','Delete',LEFT(USER(),80),
    CONCAT('Registro de envío eliminado. Datos: ', JSON_OBJECT(
      'ID',OLD.ID,'seller_order_ID',OLD.seller_order_ID,'shipment_status',OLD.shipment_status,
      'tracking_number',OLD.tracking_number)), CURRENT_TIMESTAMP, b'1');
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

-- Procedimiento: sp_generate_users
CREATE PROCEDURE `sp_generate_users`(
    IN  p_total           INT,
    IN  p_country_code    CHAR(2),
    IN  p_min_age         INT,
    IN  p_max_age         INT,
    IN  p_pct_inactive    DECIMAL(5,2),
    OUT p_first_user_id   INT UNSIGNED,
    OUT p_last_user_id    INT UNSIGNED
)
    MODIFIES SQL DATA
BEGIN
    -- Parámetros de simulación (ajustables aquí, en un solo lugar)
    DECLARE c_plain_password   VARCHAR(100) DEFAULT 'Test@1234';
    DECLARE c_pct_female       DECIMAL(5,2) DEFAULT 50.00;
    DECLARE c_pct_undisclosed  DECIMAL(5,2) DEFAULT 2.00;
    DECLARE c_pct_never_login  DECIMAL(5,2) DEFAULT 7.00;
    DECLARE c_signup_window_d  INT          DEFAULT 730;   -- altas en los últimos 2 años

    DECLARE v_started          DATETIME;
    DECLARE v_now              DATETIME;
    DECLARE v_window_start     DATETIME;
    DECLARE v_password_hash    VARCHAR(255);
    DECLARE v_i                INT DEFAULT 0;
    DECLARE v_inactive_left    INT;
    DECLARE v_is_inactive      TINYINT;

    DECLARE v_gender           VARCHAR(30);
    DECLARE v_birth_date       DATE;
    DECLARE v_age              INT;
    DECLARE v_given            VARCHAR(60);
    DECLARE v_family           VARCHAR(60);
    DECLARE v_title            VARCHAR(20);
    DECLARE v_phone            VARCHAR(25);
    DECLARE v_email            VARCHAR(100);
    DECLARE v_nick             VARCHAR(50);
    DECLARE v_created_at       DATETIME;
    DECLARE v_deactivated_at   DATETIME;
    DECLARE v_login_until      DATETIME;
    DECLARE v_last_login       DATETIME;
    DECLARE v_user_id          INT UNSIGNED;
    DECLARE v_person_id        BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- 1. Autorización y validación (el código de país se normaliza a mayúsculas)
    SET p_country_code = UPPER(TRIM(p_country_code));

    IF fn_gen_is_authorized() = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Acceso denegado: rol no autorizado';
    END IF;

    CALL sp_gen_validate_params(p_total, p_country_code, p_min_age, p_max_age, p_pct_inactive);

    -- 2. Preparación
    SET v_started        = NOW();
    SET v_now            = NOW();
    SET v_window_start   = DATE_SUB(v_now, INTERVAL c_signup_window_d DAY);
    SET v_password_hash  = fn_gen_hash_password(c_plain_password);
    SET v_inactive_left  = ROUND(p_total * p_pct_inactive / 100);

    START TRANSACTION;

    -- 3. Generación
    WHILE v_i < p_total DO

        -- Cuota exacta con orden aleatorio: la probabilidad de que este usuario
        -- sea baja = bajas pendientes / usuarios pendientes (muestreo sin reemplazo)
        SET v_is_inactive = (v_inactive_left > 0
                             AND RAND() < v_inactive_left / (p_total - v_i));

        -- Datos personales coherentes entre sí
        SET v_gender     = fn_gen_pick_gender(c_pct_female, c_pct_undisclosed);
        SET v_birth_date = fn_gen_birth_date(p_min_age, p_max_age);
        SET v_age        = TIMESTAMPDIFF(YEAR, v_birth_date, CURRENT_DATE);
        SET v_given      = fn_gen_pick_given_name(p_country_code, v_gender, YEAR(v_birth_date));
        SET v_family     = fn_gen_pick_family_name(p_country_code);
        SET v_title      = fn_gen_courtesy_title(v_gender, v_age);
        SET v_phone      = fn_gen_phone(p_country_code);

        -- Cuenta: correo y nick únicos
        SET v_email = fn_gen_unique_email(v_given, v_family, YEAR(v_birth_date), p_country_code);
        SET v_nick  = fn_gen_unique_nick(v_given, v_family, YEAR(v_birth_date));

        -- Línea de tiempo coherente: alta (nunca antes de cumplir 18) <= último login <= baja <= hoy
        SET v_created_at = fn_gen_random_datetime(
            LEAST(GREATEST(CAST(DATE_ADD(v_birth_date, INTERVAL 18 YEAR) AS DATETIME), v_window_start), v_now),
            v_now
        );

        SET v_deactivated_at = NULL;
        SET v_login_until    = v_now;
        IF v_is_inactive = 1 THEN
            SET v_deactivated_at = fn_gen_random_datetime(
                LEAST(DATE_ADD(v_created_at, INTERVAL 1 DAY), v_now),
                v_now
            );
            SET v_login_until = v_deactivated_at;
        END IF;

        SET v_last_login = NULL;
        IF fn_gen_chance(c_pct_never_login) = 0 THEN
            SET v_last_login = fn_gen_random_datetime(v_created_at, v_login_until);
        END IF;

        -- Persistencia (a través de las rutinas abstractas)
        CALL sp_gen_insert_user_with_person(
            v_email, v_nick, v_password_hash, v_created_at, v_last_login,
            v_title, v_given, v_family, v_birth_date, v_gender,
            p_country_code, v_phone,
            v_user_id, v_person_id
        );

        IF v_is_inactive = 1 THEN
            CALL sp_gen_deactivate_user(v_user_id, v_deactivated_at);
            SET v_inactive_left = v_inactive_left - 1;
        END IF;

        IF v_i = 0 THEN
            SET p_first_user_id = v_user_id;
        END IF;
        SET p_last_user_id = v_user_id;

        SET v_i = v_i + 1;
    END WHILE;

    COMMIT;

    -- 4. Resumen
    SELECT
        'Generación completada'                                   AS mensaje,
        p_total                                                   AS usuarios_solicitados,
        COUNT(*)                                                  AS usuarios_creados,
        SUM(u.status = b'1')                                      AS activos,
        SUM(u.status = b'0')                                      AS dados_de_baja,
        ROUND(100 * SUM(u.status = b'1') / COUNT(*), 2)           AS pct_activos,
        ROUND(100 * SUM(u.status = b'0') / COUNT(*), 2)           AS pct_baja,
        MIN(TIMESTAMPDIFF(YEAR, p.birth_date, CURRENT_DATE))      AS edad_minima,
        MAX(TIMESTAMPDIFF(YEAR, p.birth_date, CURRENT_DATE))      AS edad_maxima,
        MIN(u.ID)                                                 AS primer_user_id,
        MAX(u.ID)                                                 AS ultimo_user_id,
        c_plain_password                                          AS password_de_prueba,
        TIMESTAMPDIFF(SECOND, v_started, NOW())                   AS segundos
    FROM tb_users u
    JOIN tb_people p ON p.user_ID = u.ID
    WHERE u.ID BETWEEN p_first_user_id AND p_last_user_id;
END ;;

-- Procedimiento: sp_gen_deactivate_user
CREATE PROCEDURE `sp_gen_deactivate_user`(
    IN p_user_id        INT UNSIGNED,
    IN p_deactivated_at DATETIME
)
    MODIFIES SQL DATA
BEGIN
    UPDATE tb_users
    SET status      = b'0',
        last_update = p_deactivated_at
    WHERE ID = p_user_id
      AND status = b'1';

    IF ROW_COUNT() <> 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se pudo dar de baja al usuario generado';
    END IF;
END ;;

-- Procedimiento: sp_gen_insert_user_with_person
CREATE PROCEDURE `sp_gen_insert_user_with_person`(
    IN  p_email          VARCHAR(100),
    IN  p_nick           VARCHAR(50),
    IN  p_password_hash  VARCHAR(255),
    IN  p_created_at     DATETIME,
    IN  p_last_login     DATETIME,
    IN  p_courtesy_title VARCHAR(20),
    IN  p_given_names    VARCHAR(150),
    IN  p_family_names   VARCHAR(150),
    IN  p_birth_date     DATE,
    IN  p_gender         VARCHAR(30),
    IN  p_country_code   CHAR(2),
    IN  p_phone          VARCHAR(25),
    OUT p_user_id        INT UNSIGNED,
    OUT p_person_id      BIGINT UNSIGNED
)
    MODIFIES SQL DATA
BEGIN
    INSERT INTO tb_users (email, nick, password, creation_date, last_login, status)
    VALUES (p_email, p_nick, p_password_hash, p_created_at, p_last_login, b'1');

    SET p_user_id = LAST_INSERT_ID();

    INSERT INTO tb_people (
        user_ID, courtesy_title, given_names, family_names, birth_date,
        gender, country_code, phone, status, creation_date, last_update
    )
    VALUES (
        p_user_id, p_courtesy_title, p_given_names, p_family_names, p_birth_date,
        p_gender, p_country_code, p_phone, b'1', p_created_at, p_created_at
    );

    SET p_person_id = LAST_INSERT_ID();
END ;;

-- Procedimiento: sp_gen_validate_params
CREATE PROCEDURE `sp_gen_validate_params`(
    IN p_total        INT,
    IN p_country_code CHAR(2),
    IN p_min_age      INT,
    IN p_max_age      INT,
    IN p_pct_inactive DECIMAL(5,2)
)
    READS SQL DATA
BEGIN
    DECLARE v_given_count  INT DEFAULT 0;
    DECLARE v_family_count INT DEFAULT 0;

    IF p_total IS NULL OR p_total < 1 OR p_total > 100000 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'p_total debe estar entre 1 y 100000';
    END IF;

    IF p_country_code IS NULL OR p_country_code NOT REGEXP '^[A-Z]{2}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'p_country_code debe ser un código ISO de 2 letras en mayúsculas';
    END IF;

    SELECT COUNT(*) INTO v_given_count
    FROM tbc_gen_given_names
    WHERE country_code = p_country_code AND status = b'1';

    SELECT COUNT(*) INTO v_family_count
    FROM tbc_gen_family_names
    WHERE country_code = p_country_code AND status = b'1';

    IF v_given_count = 0 OR v_family_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No hay catálogos de nombres/apellidos para ese país (tbc_gen_*)';
    END IF;

    IF p_min_age IS NULL OR p_max_age IS NULL
       OR p_min_age < 18 OR p_max_age > 100 OR p_min_age > p_max_age THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Rango de edad inválido: se requiere 18 <= p_min_age <= p_max_age <= 100';
    END IF;

    IF p_pct_inactive IS NULL OR p_pct_inactive < 0 OR p_pct_inactive > 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'p_pct_inactive debe estar entre 0 y 100';
    END IF;
END ;;

-- Procedimiento: sp_register_person
CREATE PROCEDURE `sp_register_person`(
    IN p_email          VARCHAR(100),
    IN p_nick           VARCHAR(50),
    IN p_password       VARCHAR(100),
    IN p_courtesy_title VARCHAR(20),
    IN p_given_names    VARCHAR(150),
    IN p_family_names   VARCHAR(150),
    IN p_birth_date     DATE,
    IN p_gender         VARCHAR(30),
    IN p_country_code   VARCHAR(50),
    IN p_phone          VARCHAR(25)
)
    MODIFIES SQL DATA
BEGIN
    DECLARE v_db_user   VARCHAR(32);
    DECLARE v_has_role  INT DEFAULT 0;
    DECLARE v_count     INT DEFAULT 0;
    DECLARE v_user_id   INT UNSIGNED;
    DECLARE v_person_id BIGINT UNSIGNED;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El correo o el nick ya se encuentran registrados';
    END;

    -- 1. Identificar usuario de conexión
    SET v_db_user = SUBSTRING_INDEX(USER(), '@', 1);

    -- 2. Verificar roles autorizados
    SELECT COUNT(*)
    INTO v_has_role
    FROM mysql.role_edges re
    WHERE re.TO_USER = v_db_user
      AND re.TO_HOST = '%'
      AND re.FROM_HOST = '%'
      AND re.FROM_USER IN (
          'superadmin',
          'admin',
          'support',
          'user_not_registered'
      );

    IF v_has_role = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Acceso denegado: rol no autorizado';
    END IF;

    -- 3. Normalizar entradas
    SET p_email          = LOWER(TRIM(p_email));
    SET p_nick           = TRIM(p_nick);
    SET p_given_names    = TRIM(p_given_names);
    SET p_family_names   = NULLIF(TRIM(p_family_names), '');
    SET p_courtesy_title = NULLIF(TRIM(p_courtesy_title), '');
    SET p_gender         = COALESCE(NULLIF(TRIM(p_gender), ''), 'Prefiero no decirlo');
    SET p_country_code   = NULLIF(UPPER(TRIM(p_country_code)), '');
    SET p_phone          = NULLIF(TRIM(p_phone), '');

    -- 4. Validar datos de la cuenta
    IF p_email IS NULL OR p_email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El correo electrónico es inválido';
    END IF;

    IF p_nick IS NULL OR CHAR_LENGTH(p_nick) < 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El nick debe tener al menos 3 caracteres';
    END IF;

    IF p_password IS NULL OR CHAR_LENGTH(p_password) < 8 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La contraseña debe tener al menos 8 caracteres';
    END IF;

    -- 5. Validar datos personales
    IF p_given_names IS NULL OR p_given_names = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El nombre es obligatorio';
    END IF;

    IF p_birth_date IS NOT NULL
       AND (p_birth_date > CURRENT_DATE OR p_birth_date < '1900-01-01') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de nacimiento es inválida';
    END IF;

    IF p_gender NOT IN ('Hombre', 'Mujer', 'Prefiero no decirlo') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El género debe ser Hombre, Mujer o Prefiero no decirlo';
    END IF;

    IF p_country_code IS NOT NULL AND p_country_code NOT REGEXP '^[A-Z]{2}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El código de país debe tener 2 letras (ISO)';
    END IF;

    IF p_phone IS NOT NULL AND p_phone NOT REGEXP '^[0-9+() -]{7,25}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El teléfono es inválido';
    END IF;

    -- 6. Comprobar duplicados
    SELECT COUNT(*) INTO v_count FROM tb_users WHERE email = p_email;
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El correo electrónico ya se encuentra registrado';
    END IF;

    SELECT COUNT(*) INTO v_count FROM tb_users WHERE nick = p_nick;
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El nick ya se encuentra en uso';
    END IF;

    -- 7. Registro atómico: usuario + persona (contraseña cifrada con MD5)
    START TRANSACTION;

    INSERT INTO tb_users (email, nick, password)
    VALUES (p_email, p_nick, MD5(p_password));

    SET v_user_id = LAST_INSERT_ID();

    INSERT INTO tb_people (
        user_ID, courtesy_title, given_names, family_names,
        birth_date, gender, country_code, phone
    )
    VALUES (
        v_user_id, p_courtesy_title, p_given_names, p_family_names,
        p_birth_date, p_gender, p_country_code, p_phone
    );

    SET v_person_id = LAST_INSERT_ID();

    COMMIT;

    -- 8. Confirmación
    SELECT
        'Usuario y persona registrados correctamente' AS mensaje,
        v_user_id AS user_id,
        v_person_id AS person_id,
        p_email AS email,
        p_nick AS nick,
        v_db_user AS ejecutado_por,
        CURRENT_TIMESTAMP AS fecha_operacion;
END ;;

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

-- Función: fn_gen_birth_date
CREATE FUNCTION `fn_gen_birth_date`(p_min_age INT, p_max_age INT) RETURNS date
    NO SQL
    COMMENT 'Fecha de nacimiento aleatoria cuya edad actual está entre p_min_age y p_max_age (inclusive)'
BEGIN
    DECLARE v_youngest DATE;   -- cumple p_min_age hoy
    DECLARE v_oldest   DATE;   -- cumple p_max_age+1 mañana

    SET v_youngest = DATE_SUB(CURRENT_DATE, INTERVAL p_min_age YEAR);
    SET v_oldest   = DATE_ADD(DATE_SUB(CURRENT_DATE, INTERVAL (p_max_age + 1) YEAR), INTERVAL 1 DAY);

    RETURN DATE_ADD(v_oldest, INTERVAL FLOOR(RAND() * (DATEDIFF(v_youngest, v_oldest) + 1)) DAY);
END ;;

-- Función: fn_gen_chance
CREATE FUNCTION `fn_gen_chance`(p_percent DECIMAL(5,2)) RETURNS tinyint
    NO SQL
    COMMENT 'Devuelve 1 con probabilidad p_percent %, 0 en otro caso'
BEGIN
    RETURN RAND() * 100 < p_percent;
END ;;

-- Función: fn_gen_courtesy_title
CREATE FUNCTION `fn_gen_courtesy_title`(p_gender VARCHAR(30), p_age INT) RETURNS varchar(20) CHARSET utf8mb4
    NO SQL
    COMMENT 'Título de cortesía (EE. UU.): solo ~30% de las personas lo registra'
BEGIN
    IF fn_gen_chance(30) = 0 OR p_gender NOT IN ('Hombre', 'Mujer') THEN
        RETURN NULL;
    END IF;

    IF p_age >= 30 AND fn_gen_chance(8) = 1 THEN
        RETURN 'Dr.';
    END IF;

    IF p_gender = 'Hombre' THEN
        RETURN 'Mr.';
    END IF;

    -- Mujer: "Mrs." solo es verosímil en adultas de mayor edad
    IF p_age >= 28 AND fn_gen_chance(45) = 1 THEN
        RETURN 'Mrs.';
    END IF;
    RETURN 'Ms.';
END ;;

-- Función: fn_gen_handle_candidate
CREATE FUNCTION `fn_gen_handle_candidate`(
    p_given      VARCHAR(60),
    p_family     VARCHAR(60),
    p_birth_year INT,
    p_attempt    INT
) RETURNS varchar(45) CHARSET utf8mb4
    NO SQL
    COMMENT 'Candidato de identificador (parte local del correo o nick) con estilos variados'
BEGIN
    DECLARE v_first VARCHAR(60);
    DECLARE v_last  VARCHAR(60);
    DECLARE v_local VARCHAR(120);
    DECLARE v_style INT;

    SET v_first = fn_gen_slug(p_given);
    SET v_last  = fn_gen_slug(p_family);
    SET v_style = fn_gen_rand_int(1, 7);   -- se sortea una sola vez

    SET v_local = CASE v_style
        WHEN 1 THEN CONCAT(v_first, '.', v_last)
        WHEN 2 THEN CONCAT(v_first, v_last)
        WHEN 3 THEN CONCAT(v_first, '_', v_last)
        WHEN 4 THEN CONCAT(LEFT(v_first, 1), v_last)
        WHEN 5 THEN CONCAT(v_first, '.', v_last, RIGHT(p_birth_year, 2))
        WHEN 6 THEN CONCAT(v_first, v_last, fn_gen_rand_int(1, 99))
        ELSE        CONCAT(v_first, fn_gen_rand_int(1, 9999))
    END;

    -- Reintentos: se agrega un sufijo numérico para escapar de colisiones
    IF p_attempt > 0 THEN
        SET v_local = CONCAT(v_local, fn_gen_rand_int(1, 9999));
    END IF;

    RETURN LEFT(v_local, 45);
END ;;

-- Función: fn_gen_hash_password
CREATE FUNCTION `fn_gen_hash_password`(p_plain VARCHAR(100)) RETURNS varchar(255) CHARSET utf8mb4
    NO SQL
    DETERMINISTIC
    COMMENT 'Único punto donde se decide cómo se cifra la contraseña (hoy MD5, igual que sp_register_person)'
BEGIN
    RETURN MD5(p_plain);
END ;;

-- Función: fn_gen_is_authorized
CREATE FUNCTION `fn_gen_is_authorized`() RETURNS tinyint
    READS SQL DATA
    COMMENT 'Mismo esquema de roles que sp_register_person (superadmin/admin); root siempre puede'
BEGIN
    DECLARE v_db_user  VARCHAR(32);
    DECLARE v_has_role INT DEFAULT 0;

    SET v_db_user = SUBSTRING_INDEX(USER(), '@', 1);

    IF v_db_user = 'root' THEN
        RETURN 1;
    END IF;

    SELECT COUNT(*)
    INTO v_has_role
    FROM mysql.role_edges re
    WHERE re.TO_USER   = v_db_user
      AND re.TO_HOST   = '%'
      AND re.FROM_HOST = '%'
      AND re.FROM_USER IN ('superadmin', 'admin');

    RETURN v_has_role > 0;
END ;;

-- Función: fn_gen_phone
CREATE FUNCTION `fn_gen_phone`(p_country CHAR(2)) RETURNS varchar(25) CHARSET utf8mb4
    READS SQL DATA
    COMMENT 'Teléfono con formato NANP: (AAA) NXX-XXXX con lada real del catálogo'
BEGIN
    DECLARE v_area     CHAR(3);
    DECLARE v_exchange INT;

    SET v_area = (
        SELECT a.area_code
        FROM tbc_gen_phone_area_codes a
        WHERE a.country_code = p_country
          AND a.status       = b'1'
        ORDER BY -LOG(1 - RAND()) / a.weight
        LIMIT 1
    );

    IF v_area IS NULL THEN
        RETURN NULL;
    END IF;

    -- Central válida: primer dígito 2-9, sin N11 (211, 311...) y sin 555
    REPEAT
        SET v_exchange = fn_gen_rand_int(200, 999);
    UNTIL (v_exchange MOD 100) <> 11 AND v_exchange <> 555
    END REPEAT;

    RETURN CONCAT('(', v_area, ') ', v_exchange, '-', LPAD(fn_gen_rand_int(0, 9999), 4, '0'));
END ;;

-- Función: fn_gen_pick_family_name
CREATE FUNCTION `fn_gen_pick_family_name`(p_country CHAR(2)) RETURNS varchar(60) CHARSET utf8mb4
    READS SQL DATA
    COMMENT 'Apellido ponderado por frecuencia según el país'
BEGIN
    RETURN (
        SELECT f.name
        FROM tbc_gen_family_names f
        WHERE f.country_code = p_country
          AND f.status       = b'1'
        ORDER BY -LOG(1 - RAND()) / f.weight
        LIMIT 1
    );
END ;;

-- Función: fn_gen_pick_gender
CREATE FUNCTION `fn_gen_pick_gender`(p_pct_female DECIMAL(5,2), p_pct_undisclosed DECIMAL(5,2)) RETURNS varchar(30) CHARSET utf8mb4
    NO SQL
    COMMENT 'Hombre / Mujer / Prefiero no decirlo según los porcentajes indicados'
BEGIN
    IF fn_gen_chance(p_pct_undisclosed) = 1 THEN
        RETURN 'Prefiero no decirlo';
    END IF;
    IF fn_gen_chance(p_pct_female) = 1 THEN
        RETURN 'Mujer';
    END IF;
    RETURN 'Hombre';
END ;;

-- Función: fn_gen_pick_given_name
CREATE FUNCTION `fn_gen_pick_given_name`(p_country CHAR(2), p_gender VARCHAR(30), p_birth_year INT) RETURNS varchar(60) CHARSET utf8mb4
    READS SQL DATA
    COMMENT 'Nombre de pila ponderado por popularidad, acorde al país, género y generación'
BEGIN
    DECLARE v_gender VARCHAR(30);
    DECLARE v_name   VARCHAR(60);

    -- "Prefiero no decirlo" no restringe el nombre: se sortea el catálogo de cualquiera de los dos
    SET v_gender = p_gender;
    IF v_gender NOT IN ('Hombre', 'Mujer') THEN
        SET v_gender = IF(RAND() < 0.5, 'Hombre', 'Mujer');
    END IF;

    -- Muestreo ponderado: gana la fila con menor -ln(U)/peso (P = peso / suma de pesos)
    SET v_name = (
        SELECT n.name
        FROM tbc_gen_given_names n
        WHERE n.country_code = p_country
          AND n.gender       = v_gender
          AND n.status       = b'1'
          AND p_birth_year BETWEEN n.birth_year_from AND n.birth_year_to
        ORDER BY -LOG(1 - RAND()) / n.weight
        LIMIT 1
    );

    -- Respaldo: si ninguna generación cubre ese año, se ignora la generación
    IF v_name IS NULL THEN
        SET v_name = (
            SELECT n.name
            FROM tbc_gen_given_names n
            WHERE n.country_code = p_country
              AND n.gender       = v_gender
              AND n.status       = b'1'
            ORDER BY -LOG(1 - RAND()) / n.weight
            LIMIT 1
        );
    END IF;

    RETURN v_name;
END ;;

-- Función: fn_gen_random_datetime
CREATE FUNCTION `fn_gen_random_datetime`(p_from DATETIME, p_to DATETIME) RETURNS datetime
    NO SQL
    COMMENT 'Fecha-hora aleatoria uniforme entre p_from y p_to'
BEGIN
    IF p_to <= p_from THEN
        RETURN p_from;
    END IF;
    RETURN DATE_ADD(
        p_from,
        INTERVAL FLOOR(RAND() * (TIMESTAMPDIFF(SECOND, p_from, p_to) + 1)) SECOND
    );
END ;;

-- Función: fn_gen_rand_int
CREATE FUNCTION `fn_gen_rand_int`(p_min INT, p_max INT) RETURNS int
    NO SQL
    COMMENT 'Entero aleatorio uniforme en [p_min, p_max]'
BEGIN
    RETURN FLOOR(p_min + RAND() * (p_max - p_min + 1));
END ;;

-- Función: fn_gen_slug
CREATE FUNCTION `fn_gen_slug`(p_text VARCHAR(150)) RETURNS varchar(150) CHARSET utf8mb4
    NO SQL
    DETERMINISTIC
    COMMENT 'Minúsculas y solo letras/dígitos (O''Brien -> obrien)'
BEGIN
    RETURN LOWER(REGEXP_REPLACE(p_text, '[^A-Za-z0-9]', ''));
END ;;

-- Función: fn_gen_unique_email
CREATE FUNCTION `fn_gen_unique_email`(
    p_given      VARCHAR(60),
    p_family     VARCHAR(60),
    p_birth_year INT,
    p_country    CHAR(2)
) RETURNS varchar(100) CHARSET utf8mb4
    READS SQL DATA
    COMMENT 'Correo verosímil que no existe aún en tb_users'
BEGIN
    DECLARE v_domain VARCHAR(80);
    DECLARE v_email  VARCHAR(100);
    DECLARE v_try    INT DEFAULT 0;

    SET v_domain = (
        SELECT d.domain
        FROM tbc_gen_email_domains d
        WHERE d.country_code = p_country
          AND d.status       = b'1'
        ORDER BY -LOG(1 - RAND()) / d.weight
        LIMIT 1
    );

    IF v_domain IS NULL THEN
        SET v_domain = 'example.com';
    END IF;

    WHILE v_try < 25 DO
        SET v_email = CONCAT(fn_gen_handle_candidate(p_given, p_family, p_birth_year, v_try), '@', v_domain);

        IF NOT EXISTS (SELECT 1 FROM tb_users WHERE email = v_email) THEN
            RETURN v_email;
        END IF;
        SET v_try = v_try + 1;
    END WHILE;

    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No fue posible generar un correo único tras 25 intentos';
    RETURN NULL;
END ;;

-- Función: fn_gen_unique_nick
CREATE FUNCTION `fn_gen_unique_nick`(
    p_given      VARCHAR(60),
    p_family     VARCHAR(60),
    p_birth_year INT
) RETURNS varchar(50) CHARSET utf8mb4
    READS SQL DATA
    COMMENT 'Nick verosímil que no existe aún en tb_users'
BEGIN
    DECLARE v_nick VARCHAR(50);
    DECLARE v_try  INT DEFAULT 0;

    WHILE v_try < 25 DO
        SET v_nick = fn_gen_handle_candidate(p_given, p_family, p_birth_year, v_try);

        IF NOT EXISTS (SELECT 1 FROM tb_users WHERE nick = v_nick) THEN
            RETURN v_nick;
        END IF;
        SET v_try = v_try + 1;
    END WHILE;

    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'No fue posible generar un nick único tras 25 intentos';
    RETURN NULL;
END ;;
