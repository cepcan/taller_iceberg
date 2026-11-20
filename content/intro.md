# Apache Iceberg

## Desafíos actuales de Datos

El panorama actual de datos se caracteriza por el crecimiento exponencial de los volúmenes de datos, la diversificación de los tipos de estos y la creciente demanda de análisis en tiempo real.

Las bases de datos tradicionales fueron diseñados para procesamiento transaccional, no para satisfacer demandas analíticas. Esto dio lugar al surgimiento de los **Data Warehouses**: sistemas diseñados específicamente para ofrecer un alto rendimiento en la consulta de datos estructurados. Con el tiempo, en la medida que las organizaciones necesitaron almacenar y analizar más diversas formas de datos, los **Data Lakes** emergieron como una solución, permitiendo el almacenamiento de grandes cantidades de datos estructurados, semiestructurados y no estructurados a un menor costo. 

Sin embargo, a medida que los volúmenes de datos alcanzaron el rango de los petabytes, tanto los *data warehouses* como los *data lakes* comenzaron a mostrar sus limitaciones. Los data warehouses, si bien potentes, conllevaban elevados costes de almacenamiento y carecían de la flexibilidad necesaria para gestionar datos no estructurados. Por otro lado, los data lakes, aunque flexibles y escalables, presentaban problemas de rendimiento a la hora de ofrecer la velocidad y fiabilidad requeridas para el análisis en tiempo real.

<div style="text-align: center">
<img src="images/iceberg-tradiccional.png" alt="Girl in a jacket" width="900" height="600"/>
</div>


El desafío: ¿cómo integrar lo mejor de ambos mundos, combinando la flexibilidad y escalabilidad de los data lakes con el rendimiento y la estructura de los data warehouses? Este reto dio lugar a la creación del **Data Lakehouse**, una arquitectura unificada diseñada para responder a las necesidades cambiantes de la gestión moderna de datos.

## La solución de los Data Lakehouse


## Apache Iceberg

[Apache Iceberg](https://iceberg.apache.org/) es un formato de tabla abierto diseñado para gestionar conjuntos de datos a gran escala dentro de Data Lakes, proporcionando la funcionalidad y desempeño de Data Warehouses tradicionales. 

Iceberg permite a las organizaciones consultar, gestionar y evolucionar sus datos de manera eficiente al introducir funcionalidades poderosas como:

- Transacciones ACID.
- Evolución de Schema.
- Time travel.
- Evolución de particiones.

Iceberg aprovecha una arquitectura basada en metadatos que permite una gestión de datos rápida y confiable. Esta arquitectura gira en torno a varios archivos clave de metadatos que realizan un seguimiento del estado del conjunto de datos, garantizando una gestión fluida de operaciones de consulta, actualización y eliminación de información.

<div style="text-align: center">
<img src="images/iceberg-iceberg.png" alt="Girl in a jacket" width="900" height="700"/>
</div>

### Metadata File (`metadata.json`)

El archivo de metadatos, también conocido como `metadata.json` es el archivo central que administra el estado de las tablas. Pensemos el archivo como el cerebro de las tablas de iceberg, el cual vincula la estructura e historia del conjunto de datos. Cada tabla de Iceberg cuenta con un archivo de metadatos principal que registria información fundamental como:

#### **Table schema**

Estructura de la tabla como nombre de las columnas, tipos de los datos, así como los cambios que han ocurrido en el tiempo en el esquema de la tabla.

#### **Snapshots** 
El archivo de metadatos hace un seguimiento de todo el historial de versiones de las tablas (snapshots), permitiendo con ello *viajes en el tiempo* de modo que los usuarios puedan realizar consultas sobre la tabla tal como existía en momentos anteriores.

#### **Current Snapshot** 
Referencia al último snapshot el cual representa el estado actual de la tabla.

#### **Partitioning**
Detalles sobre cómo está particionada la tabla y la evolución de las particiones: cualquier cambio en la partición a lo largo del tiempo.

#### **Table properties**
Detalles de configuración como formato de archivos usado, configuración de compresión, y otras configuraciones de optimización.

El archivo de metadatos es actualizado con cada modificación a las tablas (al agregar o eliminar datos), garantizando que Iceberg mantenga una visión precisa y actualizada de todo el conjunto de datos.

### Manifiest List

El *manifest list* es el archivo de metadatos de más alto nivel el cual apunta a todos los *manifest file* asociados con una tabla. Se trata de un índice que Iceberg consulta al determinar qué manifest files debe examinar para una consulta u operación. Esta estructura permite a Iceberg gestionar de manera eficiente grandes conjuntos de datos, al analizar únicamente las secciones de datos pertinentes. 

El uso de este *indice* le permite a Iceberg rápidamente localizar los manifest files que contienen a los datos necesitados para una consulta particular. Esto ayuda a reducir la cantidad de datos leídos desde el almacenamiento, lo que se traduce en un mejor rendimiento de las consultas y menores costos de I/O, especialmente al trabajar con conjuntos de datos a escala de petabytes.

### Manifest Files

Cada *manifest file* contiene metadatos detallados acerca de un grupo de archivos de datos en el conjunto de datos. Estos registros almacenan información como:

#### **File paths**  

Ubicación actual de los archivos de datos en el sistema de almacenamiento (*i.e.*, almacenamiento de objetos o HDFS).

#### **Partition values**
La información de partición de cada archivo, lo que permite a Iceberg realizar la eliminación de particiones (partition pruning) —filtrando las particiones innecesarias para reducir el alcance de la consulta.

#### **File statistics**
Valores mínimos y máximos para cada columna, lo que permite la propagación de predicados (filtrado de filas antes de su lectura) para realizar consultas más eficientes.


Los manifest files con fundamentales para la capacidad de Iceberg de escalar en datasets extremadamente grandes, ya que permiten al sistema gestionar grupos de archivos de datos de una manera organizada y optimizada. Al almacenar los metadatos sobre los archivos de datos por separado, Iceberg también admite la evolución de las particiones: la capacidad de ajustar los esquemas de particionamiento a lo largo del tiempo sin necesidad de reescribir todo el conjunto de datos.

### Data Files

Los archivos de datos son el lugar físico donde se almacenan los registros propiamente dichos del conjunto de datos. Estos archivos son tipicamente formatos columnares como Apache Parquet, ORC, Avro, optimizados para consultas analíticas. Los archivos de datos contienen los datos *crudos* que se procesan durante las operaciones de lectura y escritura, y los manifest files hacen referencia a ellos.

Iceberg abstrae la complejidad de gestionar estos archivos, permitiendo a los usuarios interactuar con sus conjuntos de datos a través de interfaces de tabla de alto nivel. Cuando se añaden nuevos datos, Iceberg los escribe en nuevos archivos de datos y actualiza los metadatos asociados, garantizando que el estado más reciente de la tabla esté siempre accesible. Los archivos de datos constituyen las unidades de almacenamiento fundamentales que Iceberg gestiona mediante sus capas de metadatos, lo que posibilita realizar operaciones con los datos de manera eficiente.

