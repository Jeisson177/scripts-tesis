%% Resumen de todos los datos
Calcular.resumenRecorridosPorRuta(datosBuses);

%% Ver ruta día

%% Ver ruta recorrido
Graficar.rutaMapa(datosBuses,rutas,"bus_4012" ,"f_03_07_2024", 1,[], true)

%% Ver velocidad
Graficar.graficarVelocidadPorRutas(datosBuses, "bus_4012", "f_03_07_2024", 1, 'ambas')

%% Ver curvas
%TODO: pasar a metros y graficar en funcion del riesgo curva
Graficar.graficarCurvas(datosBuses,"bus_4012" ,"f_03_07_2024", 1,[]);

%% ver segmentos
Graficar.graficarSegmentos(datosBuses,"bus_4012" ,"f_03_07_2024", 1,[], 'promedioVelocidad');