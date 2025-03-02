# README - Clase Calcular

## Descripción
La clase `Calcular` es una clase en MATLAB con métodos estáticos que permiten el análisis y procesamiento de datos de sensores de autobuses. Esta clase está diseñada para calcular velocidades, aceleraciones y tiempos de rutas utilizando diversos filtros y técnicas.

## Contenido de la Clase
La clase `Calcular` contiene los siguientes métodos:

### 1. `velocidadTotal(datosBuses, unidades, filtro)`
Calcula la velocidad total para cada bus y fecha, permitiendo la conversión de unidades y aplicación de filtros.

### 2. `velocidadSinFiltro(datos, etiquetaTiempo, etiquetaLatitud, etiquetaLongitud)`
Calcula la velocidad sin aplicar filtros, utilizando los datos de latitud, longitud y tiempo.

### 3. `velocidadConFiltro(datos, etiquetaTiempo, etiquetaLatitud, etiquetaLongitud, filtro)`
Aplica diferentes filtros para el cálculo de la velocidad, como:
- Pendiente
- Sin filtro

### 4. `corregirVelocidadPendiente(datos, umbral)`
Corrige las velocidades aplicando un método basado en pendientes.

### 5. `tiemposRutas(datosBuses, rutas, conductores)`
Calcula los tiempos de las rutas para cada bus y fecha, asociando los datos con rutas y conductores.

### 6. `Ruta(datosP20, paradas, distanciaUmbral, porcentajeMinimoParadas)`
Determina los tiempos de inicio y fin de una ruta basada en paradas y distancias umbrales.

### 7. `calcularVelocidadPorRutas(datosBuses)`
Calcula las velocidades para cada ruta de cada bus.

### 8. `AceleracionPorRutas(datosBuses)`
Calcula la aceleración para cada ruta de cada bus.

### 9. `aceleracion(velocidades, fechas)`
Calcula la aceleración a partir de las diferencias de velocidad y tiempo.

### 10. `resumenRecorridosPorRuta(datosBuses)`
Genera un resumen del número de recorridos por ruta.

### 11. `extraerDatosSensorPorRutas(datosBuses)`
Extrae los datos del sensor de las rutas de cada bus.

### 12. `calcularKilometroRutas(datosBuses)`
Calcula la cantidad de kilómetros recorridos por cada ruta.

### 13. `ConductoresTemplante(datosBuses)`
Agrega las columnas 'ID_Conductor' y 'Sexo' a la tabla de tiempo de rutas.

### 14. `aceleracionPorCuadrosMx(datos)`
Aplica umbrales para identificar intervalos de aceleración positivos y negativos.

### 15. `aceleracionPorCuadrosProm(datos)`
Calcula la aceleración promedio en intervalos constantes.

### 16. `aceleracionPorCuadrosMaximosRutas(datosBuses)`
Calcula los valores máximos de aceleración en rutas.

### 17. `llenarIndicadoresAceleracion(datosBuses)`
Llena indicadores de aceleración y frenado para cada bus y ruta.

## Requisitos
- MATLAB
- Datos de buses estructurados con sensores y tiempos de rutas

## Uso
Esta clase se utiliza principalmente para procesar datos de movilidad de buses y extraer información clave como velocidad, aceleración y tiempos de rutas. Se recomienda llamar a los métodos en el orden adecuado para garantizar la correcta manipulación de los datos.

## Notas
- Se recomienda validar los datos antes de utilizarlos en los métodos.
- Algunos métodos dependen de funciones auxiliares como `Calculos.geodist` para calcular distancias geodésicas.
- Los resultados pueden depender del formato de los datos de entrada, por lo que se sugiere revisar la estructura antes de ejecutar los métodos.

# README - Clase Calculos

## Descripción
La clase `Calculos` en MATLAB proporciona funciones para procesar y analizar datos relacionados con rutas de autobuses, incluyendo cálculos de velocidad, aceleración, consumo de energía y más.

## Funcionalidades Principales
### 1. `calcularVelocidadMS(datos)`
Calcula la velocidad en metros por segundo a partir de los datos de sensores.

### 2. `aproximarNivelBateria(datosBuses)`
Ajusta el nivel de batería en función de los datos recopilados.

### 3. `calcularAceleracionRutas(datosBuses)`
Calcula la aceleración a partir de los datos de velocidad y tiempo.

### 4. `calcularPorcentajeBateriaRutas(datosBuses)`
Determina el porcentaje de batería utilizado en cada ruta.

### 5. `calcularConsumoEnergiaRutas(datosBuses)`
Calcula el consumo de energía para cada ruta basada en los datos de batería.

### 6. `calcularPicosAceleracionRutas(datosBuses)`
Identifica picos de aceleración en los datos de las rutas.

### 7. `calcularPosAceleracion(datosBuses)`
Determina la posición de los picos de aceleración en el tiempo.

### 8. `extraerSegmentosDatos(datosBuses)`
Extrae segmentos de datos relevantes para su análisis.

### 9. `extraerEV1(datosBuses)` y `extraerEV19(datosBuses)`
Funciones para extraer datos específicos de eventos en las rutas de los autobuses.

### 10. `geodist(lat1, lon1, lat2, lon2)`
Calcula la distancia geodésica entre dos puntos utilizando coordenadas de latitud y longitud.

## Uso
La clase `Calculos` es utilizada dentro de otros scripts y clases para el análisis y procesamiento de datos de transporte. Es recomendable llamar a sus métodos en un flujo ordenado para obtener resultados precisos.

## Requisitos
- MATLAB
- Datos estructurados de rutas y sensores de autobuses

## Notas
- Asegúrese de que los datos de entrada sean válidos antes de ejecutar los cálculos.
- Algunas funciones pueden requerir dependencias adicionales como librerías geodésicas.

Este archivo README proporciona una visión general de la clase `Calculos`. Para más detalles, consulte la documentación del código fuente o las referencias en el proyecto principal.

# README - Clase IA

## Descripción
La clase `IA` en MATLAB proporciona métodos para la clasificación y análisis de datos de rutas de autobuses utilizando algoritmos de aprendizaje automático. Implementa modelos de K-Nearest Neighbors (KNN) y K-Means para segmentación y predicción de patrones de conducción.

## Funcionalidades Principales

### 1. `clasificarKNNGeneral(Rutas)`
Entrena un modelo KNN para clasificar los datos de rutas según múltiples características, incluyendo:
- Riesgo de curva
- Consumo de energía
- Velocidad
- Aceleraciones y desaceleraciones

Este método aplica reducción de dimensionalidad con PCA y evalúa el rendimiento del modelo con precisión, sensibilidad y especificidad.

### 2. `clasificarSexoYGraficar(Rutas)`
Clasifica los datos en función del género del conductor utilizando KNN y genera gráficos de dispersión en los primeros componentes principales.

### 3. `clasificarSexoSinPCA(Rutas)`
Implementa KNN sin reducción de dimensionalidad para comparar el impacto del PCA en la precisión del modelo.

### 4. `clasificarKMeansSinPCA(Rutas)`
Aplica el algoritmo K-Means sobre los datos normalizados para segmentación sin PCA, agrupando las rutas en clusters.

### 5. `clasificarKMeansSinPCAComparar(Rutas)`
Compara los resultados de K-Means con etiquetas de género y horario, generando métricas de rendimiento y matrices de confusión.

### 6. `clasificarKMeansConPCA(Rutas)`
Aplica PCA antes de K-Means para reducir la dimensionalidad y mejorar la segmentación de los datos.

### 7. `prepararDatosPCA(Rutas)`
Extrae y normaliza los datos relevantes de las rutas, preparando la entrada para modelos de Machine Learning.

### 8. `analizarContribucionesPCA(Rutas)`
Analiza la contribución de cada característica en los componentes principales y visualiza su impacto en la variabilidad de los datos.

## Requisitos
- MATLAB
- Datos de rutas y sensores de autobuses estructurados en MATLAB
- Dependencias: funciones de normalización y reducción de dimensionalidad

## Uso
Los métodos de la clase `IA` permiten entrenar modelos supervisados y no supervisados para analizar el comportamiento de los conductores y las rutas de autobuses. Se recomienda probar las variantes con y sin PCA para optimizar la clasificación y segmentación.

## Notas
- Es importante validar los datos antes de usarlos en los modelos.
- La precisión de los modelos depende de la calidad de los datos de entrada.
- Se pueden ajustar los parámetros de KNN (cantidad de vecinos) y K-Means (número de clusters) para mejorar la segmentación.

# README - Clase StructRutas

## Descripción
La clase `StructRutas` en MATLAB maneja la estructura de datos de las rutas de autobuses. Permite almacenar, gestionar y recuperar información de rutas y paradas, integrando datos desde PostgreSQL para obtener ubicaciones precisas de las paradas.

## Funcionalidades Principales

### 1. **Definición de Rutas Manuales**
La clase contiene una estructura inicial con rutas predefinidas, cada una con coordenadas de ida y vuelta:
- `Ruta4020`
- `Ruta4104`
- `Ruta4104S2`
- `Ruta4020S2`

Cada ruta tiene coordenadas de latitud y longitud para los puntos de inicio y final.

### 2. **Conexión a Base de Datos PostgreSQL**
La clase establece una conexión con una base de datos PostgreSQL para recuperar información de rutas almacenadas. 
- Parámetros de conexión:
  - **Datasource:** PostgreSQLDataSource
  - **Usuario:** postgres
  - **Contraseña:** Se debe configurar de forma segura

### 3. **Consulta de Rutas Disponibles**
Ejecuta una consulta SQL para obtener las rutas disponibles en la base de datos:
```sql
SELECT DISTINCT idruta FROM P60;
```
Esto permite obtener todas las rutas únicas registradas en la base de datos.

### 4. **Búsqueda de Paradas con Coordenadas**
Para cada ruta identificada, se ejecuta la función `buscarParadasConCoordenadas(idruta)`, que obtiene las paradas asociadas a la ruta desde la base de datos.
- Se extraen las coordenadas (latitud, longitud) de las paradas.
- Se filtran rutas sin paradas registradas.

### 5. **Estructuración de Rutas con Paradas**
Se construye una estructura en MATLAB para almacenar las rutas y sus respectivas paradas, facilitando el acceso y procesamiento posterior.

## Uso
Esta clase se utiliza para recuperar y estructurar rutas de autobuses con paradas georreferenciadas. Puede emplearse en combinación con otras clases para cálculos de velocidad, tiempo de recorrido y análisis de datos de movilidad.

## Requisitos
- MATLAB
- PostgreSQL con la base de datos configurada
- Librerías de conexión a bases de datos en MATLAB

## Notas
- Se recomienda manejar las credenciales de la base de datos de forma segura.
- Si una ruta no tiene paradas registradas, no se incluirá en la estructura final.
- Se pueden extender las consultas SQL para incluir información adicional sobre las rutas y paradas.


# README - Clase Map

## Descripción
La clase `Map` en MATLAB permite visualizar datos de rutas de autobuses en mapas georreferenciados. Sus métodos facilitan la representación de rutas, velocidades, aceleraciones, direcciones y eventos anómalos en un mapa de MATLAB.

## Funcionalidades Principales

### 1. `Ruta(datos, fechaInicio, fechaFin, colorYlinea, titulo, leyenda, mapa)`
Dibuja la ruta recorrida en un mapa geográfico a partir de un conjunto de datos con coordenadas.

### 2. `Marcadores(datos, fechaInicio, fechaFin, mapa, colorMarcador, formaMarcador)`
Agrega marcadores en las posiciones registradas en el intervalo de fechas especificado.

### 3. `Velocidad(datos, fechaInicio, fechaFin, titulo, leyenda, mapa)`
Genera un mapa de calor de velocidad utilizando los datos de la ruta.

### 4. `graficarSegmentosEnMapa(datos, segmentos, titulo, mapa)`
Muestra segmentos de una ruta en colores diferentes según la distancia recorrida.

### 5. `VelocidadSTS(datos, fechaInicio, fechaFin, titulo, leyenda, mapa)`
Dibuja un mapa de calor de velocidad basándose en sensores de velocidad del vehículo.

### 6. `Curvatura(datos, fechaInicio, fechaFin, titulo, mapa)`
Calcula y visualiza la curvatura del recorrido a partir de los datos de posición.

### 7. `Direccion(datos, fechaInicio, fechaFin, mapa)`
Identifica y muestra cambios de dirección en la ruta utilizando coordenadas geográficas.

### 8. `AgregarEtiquetasAEventos(datos, mapa)`
Añade etiquetas en el mapa indicando eventos anómalos registrados en los datos.

### 9. `MarcadoresEspeciales(datos, fechaInicio, fechaFin, mapa, formaMarcador, puntosKm)`
Coloca marcadores especiales en puntos específicos de la ruta, basados en la distancia recorrida.

## Requisitos
- MATLAB
- Librerías de geolocalización y visualización de MATLAB
- Datos estructurados con información de coordenadas GPS

## Uso
Esta clase se utiliza para visualizar y analizar datos georreferenciados de rutas de autobuses. Es útil para representar trayectos, velocidades, direcciones y eventos en mapas interactivos.

## Notas
- Asegúrese de que los datos de entrada tengan la estructura adecuada con fechas y coordenadas geográficas.
- Los métodos permiten personalizar los gráficos con colores, leyendas y títulos.
- Algunos métodos dependen de la clase `Calculos` para realizar cálculos adicionales como velocidad y curvatura.

# README - Clase Graficar

## Descripción
La clase `Graficar` en MATLAB proporciona funciones para visualizar y analizar datos de rutas de autobuses. Permite graficar velocidades, aceleraciones e indicadores de conducción a partir de los datos recopilados.

## Funcionalidades Principales

### 1. `graficarIndicadoresAcc(datosBuses)`
Genera un gráfico 3D con indicadores de aceleraciones y frenadas por género del conductor. Se representan:
- Aceleraciones por kilómetro.
- Cantidad de frenadas y aceleraciones.
- Tiempo de aceleraciones y frenadas.

Los datos se visualizan con diferentes colores según el género del conductor.

### 2. `graficarVelocidadPorRutas(datosBuses, busID, fecha, indiceRuta)`
Genera gráficos de velocidad en función del tiempo para rutas específicas de un bus.
- Se puede especificar una fecha y un índice de ruta.
- Se validan las fechas y rutas antes de graficar.
- Se representan velocidades a lo largo del tiempo con etiquetas claras.

### 3. `aceleracionPorRutas(datosBuses, busID, fecha, indiceRuta)`
Similar a la función anterior, pero graficando la aceleración en lugar de la velocidad.
- Representa cambios en la aceleración durante el trayecto de una ruta.
- Se validan los datos y se ajustan títulos y etiquetas dinámicamente.

## Requisitos
- MATLAB
- Datos estructurados de buses con información de sensores.
- Dependencias de visualización en MATLAB.

## Uso
Esta clase es utilizada para analizar visualmente el comportamiento de los buses y sus conductores en función de la velocidad y aceleración en distintas rutas.

## Notas
- Es importante validar los datos antes de graficarlos para evitar errores.
- Se recomienda utilizar esta clase en conjunto con `Calcular` y `Map` para obtener información completa del comportamiento del bus.
- Algunas funciones permiten personalizar los gráficos con diferentes colores y estilos.

# README - Clase Graficas

## Descripción
La clase `Graficas` en MATLAB proporciona funciones para visualizar el comportamiento de los autobuses en términos de velocidad, aceleración, consumo de energía y otros indicadores clave. Permite generar gráficos en función del tiempo y la distancia para evaluar el rendimiento y la eficiencia de los vehículos.

## Funcionalidades Principales

### 1. `velocidadTiempo(datos, fechaInicio, fechaFin, metodoVelocidad, titulo, colorYlinea, leyenda, grafica)`
Genera un gráfico de velocidad en función del tiempo. Se puede calcular la velocidad usando diferentes métodos:
- `KH` (kilómetros por hora)
- `MS` (metros por segundo)
- `filtrar` (corrección de velocidad)

### 2. `aceleracionTiempo(datos, fechaInicio, fechaFin, metodoAceleracion, titulo, colorYlinea, leyenda, grafica)`
Genera un gráfico de aceleración en función del tiempo utilizando distintos métodos de cálculo:
- `normal` (aceleración estándar)
- `metodo2` (variación de cálculo)
- `filtrar` (suavizado de aceleración)
- `diff` (cálculo basado en diferencias)

### 3. `analizarAceleraciones(datos, fechaInicio, fechaFin)`
Analiza las aceleraciones y detecta picos de aceleraciones bruscas. Genera histogramas para visualizar la distribución de aceleraciones.

### 4. `DistanciavsEnergia(datosp60, fechaInicio, fechaFin, conductor, bus)`
Genera un gráfico que muestra la relación entre la distancia recorrida y el consumo de energía del autobús.

### 5. `riesgoVsCurva(datosCordenadasSensor, fechaInicio, fechaFin, tituloGeneral)`
Analiza los riesgos en curvas basándose en la velocidad y el radio de giro. Genera gráficos con el índice de riesgo, velocidad y radio de curva.

### 6. `TiempovsEnergia(datos, fechaInicio, fechaFin, grafica)`
Genera un gráfico del nivel de batería en función del tiempo.

### 7. `TiempovsEnergiaCorregida(datos, fechaInicio, fechaFin, grafica)`
Similar a la anterior, pero aplicando un filtro de suavizado a los datos de batería.

### 8. `Evento20(grafica)` y `Evento21(grafica)`
Visualiza eventos específicos de los datos recopilados.

### 9. `DistanciavsVelocidad(datos, datosCordenadasP20)`
Genera gráficos comparando la velocidad con la distancia recorrida en diferentes fuentes de datos (sensor de velocidad del celular y sistema STS).

### 10. `visualizarPercentilesVelocidad(datosVelocidad, percentiles)`
Genera gráficos de percentiles de velocidad para evaluar el comportamiento de los conductores o sesiones.

## Requisitos
- MATLAB
- Datos estructurados con información de velocidad, aceleración y consumo de energía.
- Dependencias: funciones de cálculo de `Calculos`.

## Uso
Los métodos de la clase `Graficas` permiten visualizar y analizar el rendimiento de los autobuses en distintos contextos. Se recomienda utilizarlos en conjunto con las clases `Calculos`, `Map` y `Graficar` para obtener información completa sobre el desempeño de los vehículos.

## Notas
- Se recomienda validar los datos antes de generar gráficos.
- Algunas funciones permiten personalizar colores y estilos de gráficos.
- Los gráficos pueden mostrar múltiples series de datos en una misma visualización.

# README - Clase ImportarDatos

## Descripción
La clase `ImportarDatos` en MATLAB está diseñada para manejar la importación y filtrado de datos de sensores de autobuses. Facilita la carga y procesamiento de archivos CSV y TXT, proporcionando herramientas para gestionar grandes volúmenes de información de rutas de transporte público.

## Funcionalidades Principales

### 1. `createImportOptions(numVariables, variableNames, variableTypes, dateVars, decimalVars, initLine)`
Genera opciones de importación para leer archivos de texto delimitados por comas, especificando nombres y tipos de variables.

### 2. `importData(folder, fileName, numVariables, variableNames, variableTypes, dateVars, decimalVars, initLine)`
Importa datos desde un archivo CSV o TXT, aplicando configuraciones de formato y filtrado.

### 3. `Sensor(nombreCarpeta)`
Carga datos de sensores de archivos `.txt` dentro de una carpeta específica y los concatena en una única tabla.

### 4. `P20(carpeta)` y `P60(carpeta)`
Importan datos de los archivos `P20.csv` y `P60.csv`, respectivamente, los cuales contienen información de sensores de velocidad, aceleración y consumo de energía.

### 5. `filtrarDatosPorFechas(datos, fechaInicio, fechaFin)`
Filtra datos en un rango de fechas específico.

### 6. `EventoX(carpeta)` (X = 1, 2, 6, 7, 8, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21)
Carga datos de eventos específicos registrados en archivos CSV, como cambios en la ocupación, alertas de frenado, consumo de energía, entre otros.

### 7. `AlarmaX(carpeta)` (X = 1, 2, 3, 5, 8, 9, 10)
Importa datos de alarmas generadas por sensores de los autobuses.

### 8. `Evento19Coordenadas(datos)`
Filtra datos del evento 19 y organiza la información en tablas separadas según el código de comportamiento anómalo detectado.

### 9. `getFolderList(baseFolder)`
Obtiene una lista de subcarpetas dentro de un directorio especificado.

### 10. `importarTodosLosDatos(basePath, busesDatos)`
Carga y estructura datos de todos los sensores disponibles en la carpeta de base, organizándolos por bus y fecha.

### 11. `importarMuestra(basePath, numero, busesDatos)`
Carga datos de una cantidad limitada de carpetas para pruebas o análisis rápido.

### 12. `agregarCodigoConductor(datosBuses)`
Agrega información del conductor a la estructura de datos de los autobuses.

### 13. `importarCSV(filename)`
Carga archivos CSV generales y convierte sus fechas al formato `datetime`.

### 14. `reorganizarDatosBuses(datosBuses)`
Reorganiza los datos de los buses en función de la fecha y las rutas de ida y vuelta.

### 15. `reorganizarDatosRutas(datosBuses)`
Reestructura los datos organizándolos por rutas en lugar de por buses, facilitando su análisis por trayecto.

### 16. `clasificarHoras(datos)`
Clasifica los datos en horarios de **hora pico**, **hora valle** y **flujo libre**, según las horas de operación del sistema de transporte.

### 17. `compareTables(tabla1, tabla2)`
Compara dos tablas y muestra las diferencias entre sus contenidos.

## Requisitos
- MATLAB
- Archivos de datos CSV y TXT con información de sensores
- Dependencias de `readtable`, `datetime`, y `dir`

## Uso
Esta clase facilita la importación y organización de grandes volúmenes de datos de sensores de autobuses. Se recomienda usar `importarTodosLosDatos` para procesar toda la información y `filtrarDatosPorFechas` para extraer datos específicos.

## Notas
- Asegúrese de que los archivos CSV y TXT sigan la estructura esperada antes de importarlos.
- Algunas funciones generan advertencias en caso de errores de lectura o formatos incorrectos.
- Puede personalizar los métodos de importación para incluir más variables o formatos según sea necesario.


