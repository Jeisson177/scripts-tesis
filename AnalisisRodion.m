%% Resumen de todos los datos
Calcular.resumenRecorridosPorRuta(datosBuses);

%% Ver ruta día


%% Graficar histograma muestro
Graficar.graficarHistogramaMuestreo(datosBuses);

%% Ver ruta recorrido
Graficar.rutaMapa(datosBuses,rutas,"bus_4012" ,"f_03_07_2024", 1,[], true)

%% Ver velocidad mapa de calor
Graficar.graficarVelocidadMapa(datosBuses, rutas, "bus_4012", "f_03_07_2024", 1, 'filtrada', true);


%% Ver velocidad
Graficar.graficarVelocidadPorRutas(datosBuses, "bus_4012", "f_03_07_2024", 1, 'filtrada', true, rutas);

%% Ver aceleracion
Graficar.graficarAceleracionPorRutas(datosBuses,"bus_4012" ,"f_03_07_2024", 1,[])

%% Ver curvas
%TODO: pasar a metros y graficar en funcion del riesgo curva
Graficar.graficarCurvas(datosBuses,"bus_4012" ,"f_03_07_2024", 1,[]);

%% ver segmentos
Graficar.graficarSegmentos(datosBuses,"bus_4012" ,"f_03_07_2024", 1,[], 'promedioVelocidad');

%% Ver velocidad vs distancia
Graficar.velocidadvsdistancia(datosBuses, 'bus_4012', 'f_03_07_2024', 1, false, true, rutas);

%% Diagramas de barras segmentos y conductores
Graficar.graficarBarrasSegmentos(datosBuses, "L613", "promedioVelocidad", "H", "porSegmento");

%% Boxplot
Graficar.graficarBoxplotSegmentos(datosBuses, "L613", "promedioVelocidad", "ambos", "porConductor");

%% Graficar distribcion gauseana
Graficar.graficarDistribucionGenero(datosBuses, "promedioVelocidad", [], 'empirica');

%% Velocidad promedio dia
Graficar.graficarVelocidadPromedioDia(datosBuses, [], [], []);