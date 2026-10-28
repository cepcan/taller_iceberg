install.packages("dotenv")

Sys.setenv(ICEBERGR_CARGO_FEATURES = "s3")
install.packages("icebergr", 
                 type = "source", 
                 configure.args = c(ICEBERGR_CARGO_FEATURES = "s3"), 
                 configure.vars = c(ICEBERGR_CARGO_FEATURES = "s3"), 
                 INSTALL_opts= c("--preclean"), 
                 clean = TRUE
                 )


library(dotenv)
library(icebergr)

load_dot_env(".env")

catalog <- icebergr_catalog("rest", 
                            warehouse = "cepcan", 
                            uri = "https://iceberg.cepcan.org/catalog", 
                            storage = "s3"                            
                            )


icebergr_list_namespaces(catalog)
icebergr_list_tables(catalog, "pyiceberg_namespace")


tbl <- icebergr_table(catalog, "pyiceberg_namespace.cdata")

icebergr_schema(tbl)

juan = icebergr_collect(tbl)

library("duckdb")

# to start an in-memory database
con <- dbConnect(duckdb())

library(glue)

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

# retrieve the items again
res <- dbGetQuery(con, "SELECT * FROM cepcan.pyiceberg_namespace.cdata;")
res

# Writing to Iceberg
## Creamos un namespace con icebergr
icebergr_create_namespace(catalog, "prueba")

plain <- data.frame(
  i = 1L,
  d = 1.5,
  s = "text",
  b = TRUE,
  day = as.Date("2026-07-01"),
  ts = as.POSIXct("2026-07-01 09:00:00", tz = "UTC")
)

tbl <- icebergr_create_table(catalog, "prueba.plain", plain)
icebergr_schema(tbl)[, c("name", "type")]

dbWriteTable(con, "plain", plain)
res <- dbGetQuery(con, "SELECT * FROM plain")
print(res)

# Inserting Data
dbExecute(con, "
INSERT INTO cepcan.prueba.plain SELECT * FROM plain;
")


