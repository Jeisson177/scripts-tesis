datosBuses = ImportarDatos.importarTodosLosDatos('Datos');

%% Calculo de todos los tiempos para cada ruta

datosBuses = Calcular.tiemposRutas(datosBuses, rutas);

%% Muestra un resumen de los datos totales a procesar

Calcular.resumenRecorridosPorRuta(datosBuses)

%% calcula la velocidad por fecha
% Recomendado no usar, salvo para debug, procesa TODOS lo datos, cosume
% mucho tiempo y recursos
% datosBuses = Calcular.velocidadTotal(datosBuses, 'km/h', 'pendiente');

%% Calcular velocidad por ruta
% Calcula la velocidad, solo durante el tiempo de la ruta
datosBuses = Calcular.calcularVelocidadPorRutas(datosBuses);

%% Extrer datos sensor por ruta:
datosBuses = Calcular.extraerDatosSensorPorRutas(datosBuses);


%% Graficar
Graficar.graficarVelocidadPorRutas(datosBuses, "bus_4020", "f_15_04_2024")
Graficar.graficarVelocidadPorRutas(datosBuses, "bus_4020", "f_15_04_2024", 1)

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

datosBuses = Calculos.extraerP60(datosBuses);

%%

datosBuses = Calculos.extraerSegmentosDatos(datosBuses);

%%

datosBuses = Calculos.extraerEV1(datosBuses);

%%

datosBuses = Calculos.extraerEV19(datosBuses);

%%

