# [`icebergr`](https://cran.r-project.org/web/packages/icebergr/index.html): Read and Write 'Apache Iceberg' Tables

[`icebergr`](https://cran.r-project.org/web/packages/icebergr/index.html) es un cliente para Apache Iceberg. En lugar de usar un query engine como [DuckDB](https://duckdb.org/docs/2.0/clients/r) `iceberg` se comunica directamente con Iceberg mediante el servicio REST a los catálogos, logrando con ello poder consultar los namespaces y tablas registradas, leer los schemas y particiones de las tablas, scanear datos, consultar el historial de snapshot de las tablas, agregar nuevos datos, etc. 

[Apache Arrow](https://arrow.apache.org/) funciona como la capa de intercambio de datos, de manera que los resultados del escaneo llegan a R sin necesidad de un proceso de serialización adicional. 

`icebergr` está construido sobre [`iceberg-rust`](https://github.com/apache/iceberg-rust), la implementación en [Rust](https://rust-lang.org/es/) de Apache Iceberg, via [`extender`](https://extendr.rs/)

## Instalación

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

Cargamos catálogos : 

```R
library(dotenv)
library(icebergr)

load_dot_env(".env")

catalog <- icebergr_catalog("rest", 
                            warehouse = "cepcan", 
                            uri = "https://iceberg.cepcan.org/catalog", 
                            storage = "s3"                            
                            )


icebergr_list_namespaces(catalog)
```

## Configuramos cliente de DuckDB

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