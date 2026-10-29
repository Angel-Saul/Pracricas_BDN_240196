USE db_test;

/* 1. Cuantas tablas tenemos? */
-- En la práctica 3 agregamos 2 nuevas categorias y productos_categorias
SHOW TABLES;

/* 2. Cuantos triggers tenemos */
-- 12 Por cada tabla creada deberan estar 3 trigger para poder realizar la trazabilidad de bitacora
SHOW TRIGGERS FROM db_test;

/* 3. Contabilizar el total de registro en bitacora */
SELECT count(*) FROM tb_logs;

/* 4. Contabilizar el total de productos */
SELECT COUNT(*) FROM tb_products;

/* 4.1. */
SELECT inserted_by, roles, count(*)
FROM vw_trazabilidad_productos;

/* 5. Contabilizar las categorias */
SELECT COUNT(*) FROM tbc_categories;

/* 6. Verificar los movientos de categorias en la bitacora */
SELECT * FROM tb_logs WHERE table_name="tbc_categories";

/* 7. Trazabilidad de Categorias */
SELECT * FROM vw_trazabilidad_categorias;

/* 8. Contabilizar cuantos productos por categoria*/
SELECT *
FROM vw_total_products_by_category
ORDER BY category_id is null;

/* 9* Trazabilidad de Categorizaciones */
SELECT * FROM vw_trazabilidad_categorizacion_productos;

/* 10. Muestra los procedimientos de la base de datos  */
SHOW PROCEDURE STATUS WHERE Db = 'db_test';