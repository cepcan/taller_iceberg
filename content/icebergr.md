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


```R
library(duckdb)
library(glue)

# to start an in-memory database
con <- dbConnect(duckdb())


CLIENT_ID = Sys.getenv("CLIENT_ID")
CLIENT_SECRET = Sys.getenv("CLIENT_SECRET")
OAUTH2_SERVER_URI = Sys.getenv("ICEBERGR_REST_OAUTH2_SERVER_URI")
OAUTH2_SCOPE = Sys.getenv("ICEBERGR_REST_SCOPE")
ENDPOINT = "https://iceberg.cepcan.org/catalog"

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

consulta_catalogo = glue(configura_catalogo)


dbExecute(con, consulta_catalogo)
```