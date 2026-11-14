# Apache Iceberg

## Desafíos actuales de Datos

Las bases de datos tradicionales fueron diseñados para procesamiento transaccional no para satisfacer demandas analíticas. Esto dio lugar al surgimiento de los *Data Warehouses*: sistemas diseñados específicamente para ofrecer un alto rendimiento en la consulta de datos estructurados. Con el tiempo, en la medida que las organizaciones necesitaron almacenar y analizar más diversas formas de datos, los *Data Lakes* emergieron como una solución, permitiendo el almacenamiento de grandes cantidades de datos estructurados, semiestructurados y no estructurados a un menor costo. 

Sin embargo, a medida que los volúmenes de datos alcanzaron el rango de los petabytes, tanto los *data warehouses* como los *data lakes* comenzaron a mostrar sus limitaciones. Los almacenes de datos, si bien potentes, conllevaban elevados costes de almacenamiento y carecían de la flexibilidad necesaria para gestionar datos no estructurados. Por otro lado, los lagos de datos, aunque flexibles y escalables, presentaban problemas de rendimiento a la hora de ofrecer la velocidad y fiabilidad requeridas para el análisis en tiempo real.

El desafío: ¿cómo integrar lo mejor de ambos mundos, combinando la flexibilidad y escalabilidad de los data lakes con el rendimiento y la estructura de los data warehouses? Este reto dio lugar a la creación del *Data Lakehouse*, una arquitectura unificada diseñada para responder a las necesidades cambiantes de la gestión moderna de datos.

## La solución de los Data Lakehouse


## La propuesta de Apache Iceberg

[Apache Iceberg](https://iceberg.apache.org/) es un formato de tabla abierto diseñado para gestionar conjuntos de datos a gran escala dentro de Data Lakes, proporcionando la funcionalidad y desempeño de Data Warehouses tradicionales. 

Iceberg permite a las organizaciones consultar, gestionar y evolucionar sus datos de manera eficiente al introducir funcionalidades poderosas como:

- Transacciones ACID.
- Evolución de Schema.
- Time travel.
- Evolución de particiones.

Iceberg aprovecha una arquitectura basada en metadatos que permite una gestión de datos rápida y confiable. Esta arquitectura gira en torno a varios archivos clave de metadatos que realizan un seguimiento del estado del conjunto de datos, garantizando una gestión fluida de operaciones de consulta, actualización y eliminación de información.

<div style="text-align: center">
<img src="images/iceberg_catalogo.png" alt="Girl in a jacket" width="500" height="600"/>
</div>

