# [`icebergr`](https://cran.r-project.org/web/packages/icebergr/index.html): Read and Write 'Apache Iceberg' Tables

[`icebergr`](https://cran.r-project.org/web/packages/icebergr/index.html) es un cliente para Apache Iceberg. En lugar de usar un query engine como [DuckDB](https://duckdb.org/docs/2.0/clients/r) `iceberg` se comunica directamente con Iceberg mediante el servicio REST a los catálogos, logrando con ello poder consultar los namespaces y tablas registradas, leer los schemas y particiones de las tablas, scanear datos, consultar el historial de snapshot de las tablas, agregar nuevos datos, etc. 

[Apache Arrow](https://arrow.apache.org/) funciona como la capa de intercambio de datos, de manera que los resultados del escaneo llegan a R sin necesidad de un proceso de serialización adicional. 

`icebergr` está construido sobre [`iceberg-rust`](https://github.com/apache/iceberg-rust), la implementación en [Rust](https://rust-lang.org/es/) de Apache Iceberg, via [`extender`](https://extendr.rs/)

## Instalación

Los catálogos REST de Iceberg entregan tablas que se encuentran almacenadas en S3 (AWS, GCS, u otro sistema de almacenamiento de objetos open-source como RustFS o MinIO). En consecuencia, necesitamos agregar el argumento adicional `s3` para agregar la característica al realizar la compilación del código fuente del programa con [`Cargo`](https://doc.rust-lang.org/cargo/):


!!! note "**_IMPORTANTE:_**"
    En Windows es necesario contar con la instalación previa de [RTools](https://cran.r-project.org/bin/windows/Rtools/) para el Toolchains de la construcción y compilación del paquete.


```R
Sys.setenv(ICEBERGR_CARGO_FEATURES = "s3")

install.packages("icebergr", 
                 type = "source", 
                 configure.args = c(ICEBERGR_CARGO_FEATURES = "s3"), 
                 configure.vars = c(ICEBERGR_CARGO_FEATURES = "s3"), 
                 INSTALL_opts= c("--preclean"), 
                 clean = TRUE
                 )
```

## Carga de catálogos

`icebergr` lee las credenciales desde variables de entorno. **_NO_** permite pasar las credenciales como argumentos. La siguiente tabla presenta las variables de entorno que pueden utilizarse de acuerdo a la implementación de Iceberg.

<style scoped>
table {
  font-size: 8px;
}
</style>


|             Variable            |   Iceberg property   |             Used for             | 
|:-------------------------------:|:--------------------:|:--------------------------------:|
| `ICEBERGR_REST_TOKEN`             | `token`                | Bearer token for a REST catalog  |
| `ICEBERGR_REST_CREDENTIAL`        | `credential`           | OAuth2 client credential         |
| `ICEBERGR_REST_OAUTH2_SERVER_URI` | `oauth2-server-uri`    | OAuth2 token endpoint            |
| `ICEBERGR_REST_SCOPE`             | `scope`                | OAuth2 scope                     |
| `ICEBERGR_S3_ACCESS_KEY_ID`       | `s3.access-key-id`     | Object storage access key        |
| `ICEBERGR_S3_SECRET_ACCESS_KEY`   | `s3.secret-access-key` | Object storage secret            |
| `ICEBERGR_S3_SESSION_TOKEN`       | `s3.session-token`     | Temporary session token          |
| `ICEBERGR_S3_REGION`              | `s3.region`            | Object storage region            |
| `ICEBERGR_S3_ENDPOINT`            | `s3.endpoint`          | Custom or S3-compatible endpoint |


Lakekeeper accede a la ubicación donde el Warehouse almacena los datos mediante las credenciales definidas en el perfil de almacenamiento, dando acceso para consultar las tablas almacenadas en el Warehouse. Las credenciales y el perfil de almacenamiento son definidas cuando el Warehouse es creado. Lakekeeper valida las credenciales y las almacena. En consecuencia, los clientes no necesitan declarar las credenciales de almaccenamiento.

La usuaria sólo debe definir tres variables de ambiente que nos da acceso al catálogo mediante las credenciales de usuario [OAuth2](https://oauth.net/2/):

- `ICEBERGR_REST_CREDENTIAL`
- `ICEBERGR_REST_OAUTH2_SERVER_URI`
- `ICEBERGR_REST_SCOPE`

Se sugiere definir las variables en el archivo `~/.Renviron` o bien usar el paquete [`dotenv`](https://cran.r-project.org/web/packages/dotenv/index.html) para cargar las variables desde un archivo `.env`.

Nos conectamos al catálogo: 

```R
library(dotenv)
library(icebergr)

load_dot_env(".env")

catalog <- icebergr_catalog("rest", 
                            warehouse = "cepcan", 
                            uri = "https://iceberg.cepcan.org/catalog", 
                            storage = "s3"                            
                            )

```

Una vez creada la conexión al catálogo, podemos consultar los namespace:

```R
icebergr_list_namespaces(catalog)
```

La siguiente instrucción lista las tablas en un namespace:

```R
icebergr_list_tables(catalog, "atlas")
```

La instrucción `icebergr_table` inicia una conexión a una tabla de Iceberg. La función regresa un

```R
tbl <- icebergr_table(catalog, "atlas")
```

Podemos consultar el schema de la tabla con la siguiente instrucción:

```R
icebergr_schema(tbl)
```

La función permite agregar el snapshot de la tabla, el cual refiere a la versión de la tabla en algún momento de su historia.
Para consultar el historial de snapshot, usamos la instrucción `icebergr_snapshots`: 

```R
icebergr_snapshots(tbl)
```

### Lectura de tablas con `icebergr`

Para leer una tabla, necesitamos usar dos funciones: `icebergr_scan` y `icebergr_collect`. La función `icebergr_scan` **describe** una operación de descarga.  La función `icebergr_scan` **ejecuta** o **materializa** las ejecuciones de lectura de `icebergr_scan`.

```R
# A scan, materialised
icebergr_collect(
   icebergr_scan(
      tbl, filter = id > 1000, 
      select = c("id", "amount")
   )
)
# A whole table, materialised
icebergr_collect(tbl)
```

!!! warning "Error al reiniciar acceso a metadatos en el almacenamiento de datos"
    Hay un bug de `icebergr` al acceder a los metadatos del Warehouse. Aún no tengo claro el error. Mi sospecha es la siguiente : no se limpia el caché de la conexión y la sesión de usuario se mantiene activa, de manera que, para evitar el acceso compartido al recurso, se bloquea la conexión al almacenamiento.

    Por tal motivo, mientras resolvemos el bug, la lectura y escritura de tablas se realizará mediante el cliente de DuckDB. 

## Configuración del cliente de [DuckDB](https://duckdb.org/)

La instalación del cliente de DuckDB de R la realizamos con la siguiente instrucción:

```R
install.packages("duckdb")
```

DuckDB ofrece también un cliente de `dplyr` mediante el paquete  `duckplyr`. Instalamos `duckplyr` con la instrucción:

```R
install.packages("duckplyr")
```

La documentación de `duckplyr` se encuentra en el sitio [duckplyr.tidyverse.org](https://duckplyr.tidyverse.org/)

El manual de referencia del cliente de R de Duckdb se encuentra en el sitio [r.duckdb.org](https://r.duckdb.org/)

Para usar DuckDB, primero debemos crear un objeto que represente al archivo de la base de datos. Usaremos el caso default `:memory:` el cual creará una base de datos en memoria.

```R
library(duckdb)

# to start an in-memory database
con <- dbConnect(duckdb())
```

## Iceberg Extension en DuckDB

La extensión de Iceberg en DuckDB implementa el soporte para el formato de tabla de Apache Iceberg. Hay dos formas de trabajar con Iceberg en DuckDB: 

- *Tablas Individuales* las cuales son leídas directamente del storage al leer los metadatos de la tabla. No se requiere catálogo y es read-only.
- *Tablas administradas por catálogo* que son accesidas mediante la conexión de un catálogo REST de Iceberg, otorgando las funcionalidades completas, incluida operaciones de escritura.

### Instalación y carga de la extensión
La instrucción y carga de la extensión de Iceberg en Duckdb se realiza con la siguiente instrucción : 

```sql
INSTALL AND LOAD iceberg;
```

Las instrucciones de DuckDB se pueden ejecutar con el cliente de R de DuckDB mediante la función `dbExecute` la cual es una interfaz del paquete [DBI](https://cran.r-project.org/package=DBI) el cual establece una interfaz de comunicación entre R y un sistema de administración de bases de datos relacionales. 

La función `dbExecute` está pensado para consultas en las que no se esperan resultados, como `CREATE TABLE`, `UPDATE`, etc. Mientras que la función `dbGetQuery()` está pensado para utilizarse en consultas que generan resultados (p. ej., `SELECT`).

De manera que la instalación y carga de la extensión de Iceberg puede realizarse desde R con la instrucción: 

```R
dbExecute(con, "INSTALL iceberg; LOAD iceberg;")
```

### Conexión a Tablas administradas por catálogo

Para el acceso completo de operaciones de lectura y escritura es necesario conectarse a un catálogo REST de Iceberg.

La mayoría de los catálogos se autentican mediante OAuth2; almacena las credenciales en un secreto y vincula el catálogo con `ATTACH ... (TYPE iceberg, ...)`:

```sql
CREATE SECRET iceberg_secret (
    TYPE iceberg,
    CLIENT_ID 'admin',
    CLIENT_SECRET 'password',
    OAUTH2_SERVER_URI 'https://catalog.example.com/v1/oauth/tokens'
);

ATTACH 'warehouse' AS my_catalog (
    TYPE iceberg,
    SECRET iceberg_secret,
    URI 'https://catalog.example.com'
);
```

La conexión al catálogo del centro se realizaría de la siguiente manera desde R:

```R
## Cargamos variables de entorno
CLIENT_ID = Sys.getenv("CLIENT_ID")
CLIENT_SECRET = Sys.getenv("CLIENT_SECRET")
OAUTH2_SERVER_URI = Sys.getenv("ICEBERGR_REST_OAUTH2_SERVER_URI")
OAUTH2_SCOPE = Sys.getenv("ICEBERGR_REST_SCOPE")
ENDPOINT = "https://iceberg.cepcan.org/catalog"

## Definimos template para sustituir los valores de las variables de entorno
configura_catalogo <- "
INSTALL iceberg; 
LOAD iceberg;

CREATE SECRET iceberg_secret (
             TYPE iceberg,
             CLIENT_ID '{CLIENT_ID}',
             CLIENT_SECRET '{CLIENT_SECRET}',
             OAUTH2_SERVER_URI '{OAUTH2_SERVER_URI}',
             OAUTH2_SCOPE '{OAUTH2_SCOPE}'     
    );

LOAD httpfs;
ATTACH 'cepcan' AS cepcan (
   TYPE iceberg,
   SECRET iceberg_secret, -- pass a specific secret name to prevent ambiguity
   ENDPOINT '{ENDPOINT}'
);
"

## Formateamos el template 
consulta_catalogo = glue(configura_catalogo)

## Ejecutamos la instrucción
dbExecute(con, consulta_catalogo)
```

### Lectura de tablas con Duckdb

Para leer una tabla en Duckdb usamos la función `dbGetQuery()` para ejecutar una consulta que genera un resultado. Realizamos la misma consulta que hicimos con `icebergr`:

```R
dbGetQuery(con, "SELECT * FROM cepcan.atlas.cdata;")
```

!!! note 
    Nótese que usamos el prefijo `cepcan` para acceder posteriormente al namespace `atlas`. Esto se debe a que nos vinculamos a Iceberg con el alias `cepcan` con la instrucción `ATTACH 'cepcan' AS cepcan`. 


## Escritura

Para la escritura de tablas usaremos `icebergr` y el cliente de DuckDB. Usaremos `icebergr` para la administración de tareas en el catálogo y DuckDB para la carga de tablas al storage.

### Creación de namespaces

Para crear un nuevo namespace donde subiremos una tabla, usamos la instrucción:

```R
icebergr_create_namespace(catalog, "prueba")
```

Como es de esperarse, podemos subir tablas a namespaces ya existentes.


### Creación de la tabla
La función `icebergr_create_table()` toma un data frame como argumento, pero **solo para leer su esquema**: no se realiza ninguna operación de escritura.

La nueva tabla está vacía, sin ningún registro de snapshot:

```R
template <- data.frame(
  id = integer(),
  item = character(),
  amount = double(),
  day = as.Date(character())
)

orders <- icebergr_create_table(catalog, "prueba.orders", template)
show(orders)
```

Una tabla Iceberg sin confirmaciones (commits) constituye un estado válido: un esquema sin datos, que es precisamente lo que se obtiene en este caso. La escritura de filas vienen después.

### Concatenación de datos (appending)

Para la concatenación de datos usaremos DuckDB. 

En primer lugar, crearemos un dataframe con el mismo esquema que el registrado el cual ya contiene datos: 

```R
template_datos <- data.frame(
  id = 1:3,
  item = c("mug", "kettle", "mug"),
  amount = c(9.5, 42, 9.5),
  day = as.Date("2026-07-01") + 0:2
)
```

Posteriormente usaremos la función `dbWriteTable()` para escribir el data frame de R en DuckDB. Esta función crea una tabla en DuckDB con el contenido del data frame. 

En este caso, escribiremos el data frame `template_datos` en DuckDB con el nombre `orders`:

```R
dbWriteTable(con, "orders", template_datos)
```

Verificamos que la tabla `orders` existe en DuckDB con la instrucción:

```R
dbGetQuery(con, "SELECT * FROM orders")
```

Por último, escribimos los datos de la tabla `orders` a la tabla vacía `orders` en el namespace `prueba`:

```R
dbExecute(con, "
INSERT INTO cepcan.prueba.orders SELECT * FROM orders;
")
```

Verificamos que los datos fueron escritps con la instrucción:

```R
dbGetQuery(con, "
SELECT * FROM cepcan.prueba.orders;
")
```