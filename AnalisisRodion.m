%% Resumen de todos los datos
% Calcular.resumenRecorridosPorRuta(datosBuses)
%   datosBuses (requerido): estructura completa de datos.
Calcular.resumenRecorridosPorRuta(datosBuses);

%% Graficar histograma muestro
% Graficar.graficarHistogramaMuestreo(datosBuses)
%   datosBuses (requerido).
Graficar.graficarHistogramaMuestreo(datosBuses);

%% Ver ruta recorrido
% Graficar.rutaMapa(datosBuses, rutas, busID, fecha, indiceRuta, nombreRutaFiltro, mostrarNombresParadas)
%   datosBuses, rutas (requeridos).
%   busID (string, ej. "bus_4012"; opcional; [] = todos los buses).
%   fecha (string 'f_DD_MM_YYYY', ej. "f_03_07_2024"; opcional; [] = todas las fechas).
%   indiceRuta (num; opcional; [] = todas las rutas).
%   nombreRutaFiltro (string exacto; opcional; [] = sin filtro).
%   mostrarNombresParadas (logical; opcional; por defecto false).
Graficar.rutaMapa(datosBuses,rutas,"bus_4012" ,"f_03_07_2024", 1,[], true)

%% Ver velocidad mapa de calor
% Graficar.graficarVelocidadMapa(datosBuses, rutas, busID, fecha, indiceRuta, tipoVelocidad, mostrarParadas)
%   datosBuses, rutas, busID (string "bus_XXXX"), fecha ('f_DD_MM_YYYY'), indiceRuta (num) requeridos.
%   tipoVelocidad ('filtrada'/'cruda'/'ambas'; opcional; por defecto 'filtrada').
%   mostrarParadas (logical; opcional; por defecto false).
Graficar.graficarVelocidadMapa(datosBuses, rutas, "bus_4012", "f_10_07_2024", 8, 'ambas', false);

%% Ver velocidad
% Graficar.graficarVelocidadPorRutas(datosBuses, busID, fecha, indiceRuta, tipoVelocidad, mostrarParadas, paradasStruct)
%   datosBuses (requerido).
%   busID (string "bus_XXXX"; opcional; [] = todos los buses).
%   fecha (string 'f_DD_MM_YYYY'; opcional; [] = todas las fechas).
%   indiceRuta (num; opcional; [] = todas las rutas).
%   tipoVelocidad ('filtrada'/'cruda'/'ambas'; opcional; por defecto 'filtrada').
%   mostrarParadas (logical; opcional; por defecto false).
%   paradasStruct (opcional; [] si no aplica).
Graficar.graficarVelocidadPorRutas(datosBuses, "bus_4012", "f_10_07_2024", 8, 'ambas', false, rutas);

%% Ver aceleracion
% Graficar.graficarAceleracionPorRutas(datosBuses, busID, fecha, indiceRuta, nombreRutaFiltro, mostrarRectangulos)
%   datosBuses (requerido).
%   busID (string "bus_XXXX"; opcional; [] = todos los buses).
%   fecha (string 'f_DD_MM_YYYY'; opcional; [] = todas las fechas).
%   indiceRuta (num; opcional; [] = todas las rutas).
%   nombreRutaFiltro (string exacto; opcional; [] = sin filtro).
%   mostrarRectangulos (logical; opcional; por defecto false).
Graficar.graficarAceleracionPorRutas(datosBuses,"bus_4012" ,"f_03_07_2024", 1,[], true)

%% Ver curvas
% Graficar.graficarCurvas(datosBuses, busID, fecha, indiceRuta, nombreRutaFiltro)
%   datosBuses, busID (string "bus_XXXX"), fecha ('f_DD_MM_YYYY') requeridos.
%   indiceRuta (num; opcional; [] = todas las rutas).
%   nombreRutaFiltro (string exacto; opcional; [] = sin filtro).
% TODO: pasar a metros y graficar en funcion del riesgo curva
Graficar.graficarCurvas(datosBuses,"bus_4012" ,"f_03_07_2024", 1,[]);

%% ver segmentos
% Graficar.graficarSegmentos(datosBuses, busID, fecha, indiceRuta, nombreRutaFiltro, campoSegmento)
%   datosBuses, busID (string), fecha ('f_DD_MM_YYYY'), campoSegmento (string) requeridos.
%   indiceRuta (num; opcional; [] = todas las rutas).
%   nombreRutaFiltro (string exacto; opcional; [] = sin filtro).
Graficar.graficarSegmentos(datosBuses,"bus_4012" ,"f_03_07_2024", 1,[], 'promedioVelocidad');

%% Ver velocidad vs distancia
% Graficar.velocidadvsdistancia(datosBuses, busID, fecha, indiceRuta, usarP60, mostrarParadas, paradasStruct)
%   datosBuses, busID (string "bus_XXXX"), fecha ('f_DD_MM_YYYY') requeridos.
%   indiceRuta (num; opcional; [] = todas las rutas).
%   usarP60 (logical; opcional; por defecto false).
%   mostrarParadas (logical; opcional; por defecto false).
%   paradasStruct (opcional; [] si no aplica).
Graficar.velocidadvsdistancia(datosBuses, 'bus_4012', 'f_03_07_2024', 1, false, true, rutas);

%% Diagramas de barras segmentos y conductores
% Graficar.graficarBarrasSegmentos(datosBuses, nombreRuta, campo, horario, modo)
%   datosBuses, nombreRuta (string, ej. "L613"), campo (string) requeridos.
%   horario ('H','M','V','F','ambos'; opcional; por defecto 'ambos').
%   modo ('porSegmento' por defecto, 'porConductor'; opcional).
Graficar.graficarBarrasSegmentos(datosBuses, "L613", "promedioVelocidad", "H", "porSegmento");

%% Boxplot
% Graficar.graficarBoxplotSegmentos(datosBuses, nombreRuta, campo, horario, modo)
%   Parámetros igual que graficarBarrasSegmentos.
Graficar.graficarBoxplotSegmentos(datosBuses, "L613", "promedioVelocidad", "ambos", "porConductor");

%% Graficar distribcion gauseana
% Graficar.graficarDistribucionGenero(datosBuses, campo, generoFiltro, tipoDist)
%   datosBuses, campo (requeridos).
%   generoFiltro ('M','F',[] ambos; opcional).
%   tipoDist ('empirica' por defecto, 'normal'; opcional).
Graficar.graficarDistribucionGenero(datosBuses, "promedioVelocidad", [], 'empirica');

%% Velocidad promedio dia
% Graficar.graficarVelocidadPromedioDia(datosBuses, busID, fecha, rutaFiltro)
%   datosBuses (requerido).
%   busID (string "bus_XXXX"; opcional; [] = todos los buses).
%   fecha (string 'f_DD_MM_YYYY'; opcional; [] = todas las fechas).
%   rutaFiltro (string exacto; opcional; [] = sin filtro).
Graficar.graficarVelocidadPromedioDia(datosBuses, [], [], []);