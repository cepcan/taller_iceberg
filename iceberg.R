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

load_dot_env("/Users/milo/Documents/egtp/CEPCAN/taller_iceberg/.env")

catalog <- icebergr_catalog("rest", 
                            warehouse = "cepcan", 
                            uri = "https://iceberg.cepcan.org/catalog", 
                            storage = "s3")


icebergr_list_namespaces(catalog)
icebergr_list_tables(catalog, "pyiceberg_namespace")


tbl <- icebergr_table(catalog, "pyiceberg_namespace.cdata")

icebergr_schema(tbl)

juan = icebergr_collect(tbl)


