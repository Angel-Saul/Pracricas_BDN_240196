# Práctica: Triggers y privilegios en MySQL

## Descripción

En esta práctica se realizaron modificaciones a la base de datos para mejorar el control y registro de las operaciones realizadas sobre la tabla de usuarios.

Los cambios principales fueron:

* Agregar una nueva columna a la tabla de usuarios.
* Agregar **3 triggers** para registrar las operaciones de actualización y eliminación, además del trigger de inserción.
* Registrar las operaciones realizadas en la tabla `tb_logs`.
* Dar privilegios de **INSERT, UPDATE y DELETE** al usuario correspondiente.

## Base de datos

La práctica se realizó utilizando la base de datos:

```sql
db_test
```

La tabla principal utilizada fue:

```sql
tb_users
```

Esta tabla contiene información de los usuarios como:

* `ID`
* `email`
* `nickname`
* `password`
* `creation_date`
* `last_update`
* `last_login`

## Tabla de logs

Para llevar un registro de las operaciones realizadas sobre los usuarios se utiliza la tabla:

```sql
tb_logs
```

Esta tabla almacena información como:

* Tabla donde se realizó la operación.
* Tipo de operación.
* Usuario que realizó la operación.
* Descripción de la operación.
* Fecha y hora.
* Estado de la operación.

La tabla utiliza los tipos de operación `Create`, `Read`, `Update` y `Delete`.

## Triggers

Se trabajó con triggers para registrar automáticamente las operaciones realizadas en `tb_users`.

### 1. AFTER INSERT

El trigger:

```sql
trg_users_after_insert
```

se ejecuta después de insertar un nuevo usuario.

Su función es registrar en `tb_logs` los datos del usuario creado, como su ID, correo electrónico y nickname.

### 2. AFTER UPDATE

El trigger:

```sql
trg_users_after_update
```

se ejecuta después de actualizar un usuario.

Este trigger registra la operación `Update` en `tb_logs`, almacenando información del usuario modificado y del usuario de la base de datos que realizó la operación.

### 3. AFTER DELETE

El trigger:

```sql
trg_users_after_delete
```

se ejecuta después de eliminar un usuario.

En este caso se utiliza la información de `OLD` para obtener los datos del usuario que fue eliminado y guardar el registro correspondiente en `tb_logs`.

## Privilegios

Finalmente, se asignaron privilegios al usuario de la izquierda para que pudiera realizar las siguientes operaciones sobre la base de datos:

```text
INSERT
UPDATE
DELETE
```

Esto permite que dicho usuario pueda insertar, modificar y eliminar registros de acuerdo con los permisos establecidos.

## Resultado

Con estas modificaciones, la base de datos cuenta con un sistema básico de auditoría mediante triggers.

Cada vez que se realiza una operación de inserción, actualización o eliminación sobre `tb_users`, se genera un registro en `tb_logs`, permitiendo identificar:

* Qué operación se realizó.
* Sobre qué tabla.
* Qué usuario realizó la operación.
* Qué registro fue afectado.
* Cuándo se realizó la operación.

En el respaldo de la base de datos se pueden observar registros de operaciones `Create`, `Update` y `Delete` realizadas sobre `tb_users`.
