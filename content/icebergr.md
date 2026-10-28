# [`icebergr`](https://cran.r-project.org/web/packages/icebergr/index.html): Read and Write 'Apache Iceberg' Tables

[`icebergr`](https://cran.r-project.org/web/packages/icebergr/index.html) es un cliente para Apache Iceberg. En lugar de usar un query engine como [DuckDB](https://duckdb.org/docs/2.0/clients/r) `iceberg` se comunica directamente con Iceberg mediante el servicio REST a los catálogos, logrando con ello poder consultar los namespaces y tablas registradas, leer los schemas y particiones de las tablas, scanear datos, consultar el historial de snapshot de las tablas, agregar nuevos datos, etc. 

[Apache Arrow](https://arrow.apache.org/) funciona como la capa de intercambio de datos, de manera que los resultados del escaneo llegan a R sin necesidad de un proceso de serialización adicional. 

`icebergr` está construido sobre [`iceberg-rust`](https://github.com/apache/iceberg-rust), la implementación en [Rust](https://rust-lang.org/es/) de Apache Iceberg, via [`extender`](https://extendr.rs/)

## Instalación

