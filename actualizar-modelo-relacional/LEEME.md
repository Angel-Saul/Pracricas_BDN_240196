# Generar un modelo relacional desde un respaldo

1. Haz doble clic en `Seleccionar respaldo.cmd`. Este lanzador abre el selector mediante un comando de PowerShell y no requiere cambiar la política de ejecución del equipo.
2. Elige el archivo `.sql` del respaldo de MySQL.
3. El modelo interactivo aparece en una carpeta nueva dentro de `salidas/` y se abre en el navegador.

Cada ejecución crea su propia carpeta con un solo HTML: `modelo-relacional.html`, generado con el visor y el diseño de Archify, más `candidate.json` y `origen.json` como archivos de apoyo. El HTML muestra flechas de claves foráneas y escrituras declaradas por triggers. Al seleccionar una tabla, resalta sus rutas y anima puntos en la dirección de las flechas; también muestra sus campos, referencias y triggers. La flecha FK representa una referencia entre filas, no una copia de datos. El inventario registra el nombre del respaldo, su SHA-256, el número de tablas, columnas, claves foráneas, triggers y advertencias del parser. No se ejecuta SQL ni se conecta a un servidor.

## Requisitos

- Node.js disponible como `node` en PowerShell.
- La carpeta `Practica03/visor-eer` del proyecto, que contiene el parser SQL.
- Archify instalado en `%USERPROFILE%\.agents\skills\archify\bin\archify.mjs`. Si está en otra ruta, define la variable `ARCHIFY_CLI` antes de ejecutar el selector.

El generador documenta las tablas, campos, claves y relaciones declarados en el respaldo. Los triggers se enumeran por tabla en una ficha del diagrama. Las vistas y rutinas SQL no forman parte del modelo relacional.
