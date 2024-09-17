
%% Importar todos los datos

datosBuses = ImportarDatos.importarTodosLosDatos('Datos');
datosBuses = Calcular.tiemposRutas(datosBuses, rutas);
%% Importar una muestra de datos
clc
datosBuses = ImportarDatos.importarMuestra('Datos', 3);
datosBuses = Calcular.tiemposRutas(datosBuses, rutas);

%% Muestra un resumen de los datos totales a procesar

Calcular.resumenRecorridosPorRuta(datosBuses);

%% Calcular los kilometros por ruta
% Extrer datos sensor por ruta:
% Extraer datos P60
datosBuses = Calcular.extraerDatosSensorPorRutas(datosBuses);
datosBuses = Calculos.extraerP60(datosBuses);

%%
datosBuses = Calcular.calcularKilometroRutas(datosBuses);

%% Calcular velocidad por ruta
% Calcula la velocidad, solo durante el tiempo de la ruta
datosBuses = Calcular.calcularVelocidadPorRutas(datosBuses);

%% Calcular aceleracion por ruta
% Calcula la velocidad, solo durante el tiempo de la ruta
datosBuses = Calcular.AceleracionPorRutas(datosBuses);


%% Graficar
%Graficar.graficarVelocidadPorRutas(datosBuses, "bus_4020", "f_15_04_2024")
Graficar.graficarVelocidadPorRutas(datosBuses, "bus_4012", "f_04_07_2024", 1)

%% Aceleracion
Graficar.aceleracionPorRutas(datosBuses, "bus_4012", "f_03_07_2024", 1)


%% Generar conductores

datosBuses = Calcular.ConductoresTemplante(datosBuses);

%% Aceleracion

temp = Calcular.aceleracionPorCuadrosMaximosRutas(datosBuses);

%% 
datosBuses = Calcular.llenarIndicadoresAceleracion(datosBuses);

%% ---------------Funciones viejas--------------------------















%%
datosBuses = Calculos.aproximarNivelBateria(datosBuses);

%% calcula la velocidad

datosBuses = Calculos.calcularAceleracionRutas(datosBuses);

%%
datosBuses = Calculos.calcularAceleracionRutas2(datosBuses);

%%

datosBuses = Calculos.calcularPorcentajeBateriaRutas(datosBuses);

%%
datosBuses = Calculos.calcularConsumoEnergiaRutas(datosBuses);

%%

datosBuses = Calculos.calcularPicosAceleracionRutas(datosBuses);
%%

datosBuses = Calculos.calcularPosAceleracion(datosBuses);



%%

datosBuses = Calculos.extraerSegmentosDatos(datosBuses);

%%

datosBuses = Calculos.extraerEV1(datosBuses);

%%

datosBuses = Calculos.extraerEV19(datosBuses);

%%

