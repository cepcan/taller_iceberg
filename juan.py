import marimo

__generated_with = "0.25.2"
app = marimo.App(width="medium")


@app.cell
def _():
    import marimo as mo

    return


@app.cell
def _():
    from pyiceberg.catalog.rest import RestCatalog
    import pandas as pd
    import pyarrow.parquet as pq
    import pyarrow as pa
    import polars as pl 

    from dotenv import load_dotenv
    import os
    load_dotenv()  # reads variables from a .env file and sets them in os.environ

    CATALOG_URL = "https://iceberg.cepcan.org/catalog"
    DEMO_WAREHOUSE = "cepcan"
    CLIENT_ID_SECRET = os.getenv("ICEBERGR_REST_CREDENTIAL")
    OAUTH2_SERVER_URI = os.getenv("ICEBERGR_REST_OAUTH2_SERVER_URI")
    SCOPE = os.getenv("ICEBERGR_REST_SCOPE")

    catalog = RestCatalog(
        name="cepcan",
        warehouse=DEMO_WAREHOUSE,
        uri=CATALOG_URL,
        credential=CLIENT_ID_SECRET,
        **{"oauth2-server-uri": OAUTH2_SERVER_URI, "scope": SCOPE}
    )
    return (catalog,)


@app.cell
def _(catalog):
    catalog.load_table(
        "pyiceberg_namespace.cdata"
    ).scan(
        "Municipio == '001 Abalá'"
    ).to_polars()
    return


if __name__ == "__main__":
    app.run()
