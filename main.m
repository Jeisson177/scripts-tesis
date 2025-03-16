
%% Cargar datos
Conductores = ImportarDatos.importarCSV("conductores_LaRolita.csv");
load Rutas.mat

%% Importar todos los datos
datosBuses = ImportarDatos.importarTodosLosDatos('Datos'); %#ok<NASGU>

%% Importar una muestra de datos
clc
datosBuses = ImportarDatos.importarMuestra('Datos', 3);
%% Segmenta la ruta, optiene en nombre de la ruta y tiempos
datosBuses = Calcular.tiemposRutas(datosBuses, rutas, Conductores);


%% Muestra un resumen de los datos totales a procesar

Calcular.resumenRecorridosPorRuta(datosBuses);

%% Calcular los kilometros por ruta
% Extrer datos sensor por ruta
% Extraer datos P60
datosBuses = Calcular.extraerDatosSensorPorRutas(datosBuses);

datosBuses = Calculos.extraerP60(datosBuses);

datosBuses = Calcular.calcularKilometroRutas(datosBuses);

%% Calcular velocidad por ruta
% Calcula la velocidad, solo durante el tiempo de la ruta
datosBuses = Calcular.calcularVelocidadPorRutas(datosBuses);

%% Calcular aceleracion por ruta
% Calcula la velocidad, solo durante el tiempo de la ruta
datosBuses = Calcular.AceleracionPorRutas(datosBuses);





%% Graficar----------------------------------------------------------------

Graficar.rutaMapa(datosBuses,"bus_4012" ,"f_10_07_2024", 2)

%%
Graficar.rutaPorTiempo(datosBuses,"bus_4012" ,"f_10_07_2024", datetime(2024,7,10,14,25,0), datetime(2024,7,10,15,42,0), rutas(12).stops)

%%
Graficar.graficarVelocidadPorRutas(datosBuses, "bus_4012", "f_03_07_2024")

%% Aceleracion
Graficar.aceleracionPorRutas(datosBuses, "bus_4012", "f_03_07_2024")

%% Aceleracion
datosBuses = Calcular.llenarIndicadoresAceleracion(datosBuses);

%%
datosBuses = Calcular.corregirAceleracionPorRutas(datosBuses);
datosBuses = Calcular.corregirAceleracionPorRutasMax(datosBuses);

%%
Graficar.graficarMagnitudesVsDuraciones(datosBuses, 'bus_4012', 'f_03_07_2024', 6);

%%
datosBuses1 = Calcular.aproximarNivelBateriaPorRutas(datosBuses);

%% ---------------Funciones viejas--------------------------








%%

datosBuses = Calculos.calcularPorcentajeBateriaRutas(datosBuses);

%%
datosBuses = Calculos.calcularConsumoEnergiaRutas(datosBuses);


%%

datosBuses = Calculos.extraerEV1(datosBuses);

%%

datosBuses = Calculos.extraerEV19(datosBuses);

%%

%% plotear indicadores aceleracion
Graficar.graficarIndicadoresAcc(datosBuses);
