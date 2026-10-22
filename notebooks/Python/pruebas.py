import marimo

__generated_with = "0.25.2"
app = marimo.App(width="medium")


@app.cell
def _():
    import marimo as mo

    return (mo,)


@app.cell
def _():
    from pyiceberg.catalog.rest import RestCatalog
    import pandas as pd
    import pyarrow.parquet as pq
    import pyarrow as pa
    import polars as pl 


    CATALOG_URL = ""
    DEMO_WAREHOUSE = "cepcan"
    CLIENT_ID = "spark"
    CLIENT_SECRET = ""

    catalog = RestCatalog(
        name="cepcan",
        warehouse=DEMO_WAREHOUSE,
        uri=CATALOG_URL,
        credential=f"{CLIENT_ID}:{CLIENT_SECRET}",
        **{"oauth2-server-uri": "", "scope": "lakekeeper"}
    )
    return catalog, pa, pl


@app.cell
def _(catalog):
    catalog.load_table(
        "pyiceberg_namespace.cdata"
    ).scan(
        "Municipio == '001 Abalá'"
    ).to_polars()
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Carguemos datos del Atlas de Complejidad
    """)
    return


@app.cell
def _(pl):
    df = pl.read_parquet("datos/hs12_country_product_year_6.parquet")
    df
    return (df,)


@app.cell
def _(catalog, df, pa):
    # Write data
    test_namespace = ("atlas",)
    if test_namespace not in catalog.list_namespaces():
        catalog.create_namespace(test_namespace)

    write_table = ("atlas", "hs12_country_product_year_6")

    pa_atlas = pa.Table.from_pandas(df.to_pandas())

    if write_table in catalog.list_tables(namespace=test_namespace):
        catalog.drop_table(write_table)

    table_atlas = catalog.create_table(
        write_table,
        schema=pa_atlas.schema,
    )

    table_atlas.append(pa_atlas)
    return


@app.cell
def _(catalog):
    catalog.load_table("atlas.hs12_country_product_year_6").scan(
        "country_iso3_code == 'MEX'"
    ).to_polars()
    return


@app.cell
def _(catalog):
    juan = catalog.load_table("atlas.hs12_country_product_year_6").scan().to_polars()
    juan
    return


if __name__ == "__main__":
    app.run()
