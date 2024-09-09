%% llenar indicadores aceleración

busesNames = fieldnames(datosBuses);  % Obtiene los nombres de los buses

% Recorre cada bus en la estructura datosBuses
for i = 1:length(busesNames)
    busName = busesNames{i};  % Nombre del bus actual
    busData = datosBuses.(busName);  % Accede a los datos del bus actual
    
    % Obtén los nombres de los subcampos dentro de cada bus (por ejemplo: f_03_07_2024)
    subfields = fieldnames(busData);  % Subcampos dentro del bus
    
    % Recorre los subcampos
    for j = 1:length(subfields)
        subfieldName = subfields{j};  % Nombre del subcampo
        datosSensorRuta = datosBuses.(busName).(subfieldName).datosSensorRuta;  % Accede a datosSensorRuta
        numFilas = size(datosSensorRuta, 1);  % Asume que tiene filas como una tabla o matriz
        for f=1:numFilas
            tiempoIda=datosSensorRuta{f,3}.time(3:end);
            AccIda=datosBuses.(busName).(subfieldName).aceleracionRuta{f,3};
            datos = table(tiempoIda, AccIda  , 'VariableNames', {'Tiempo', 'Acc'});
            [magnitudes_positivas, magnitudes_negativas, tiempos_positivos, tiempos_negativos]=Calculos.aceleracionPorCuadrosMx(datos);
            datosBuses.(busName).(subfieldName).tiempoRuta.magnitudes_positivasIda{f}=sum(magnitudes_positivas)/datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Ida(f);
            datosBuses.(busName).(subfieldName).tiempoRuta.magnitudes_negativasIda{f}=sum(magnitudes_negativas)/datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Ida(f);
            datosBuses.(busName).(subfieldName).tiempoRuta.cantidad_magnitudes{f}=length(magnitudes_negativas)/datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Ida(f);
            
            datosBuses.(busName).(subfieldName).tiempoRuta.tiempos_positivosIda{f}=sum(seconds(tiempos_positivos))/datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Ida(f);
            datosBuses.(busName).(subfieldName).tiempoRuta.tiempos_negativosIda{f}=sum(seconds(tiempos_negativos))/datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Ida(f);
            
            tiempoIda=datosSensorRuta{f,4}.time(3:end);%vuelta
            AccIda=datosBuses.(busName).(subfieldName).aceleracionRuta{f,4};
            datos = table(tiempoIda, AccIda  , 'VariableNames', {'Tiempo', 'Acc'});
            [magnitudes_positivas, magnitudes_negativas, tiempos_positivos, tiempos_negativos]=Calculos.aceleracionPorCuadrosMx(datos);
            datosBuses.(busName).(subfieldName).tiempoRuta.magnitudes_positivasVuelta{f}=sum(magnitudes_positivas)/datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Vuelta(f);
            datosBuses.(busName).(subfieldName).tiempoRuta.magnitudes_negativasVuelta{f}=sum(magnitudes_negativas)/datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Vuelta(f);
            datosBuses.(busName).(subfieldName).tiempoRuta.cantidad_magnitudes{f}=length(magnitudes_negativas)/datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Vuelta(f);
            
            datosBuses.(busName).(subfieldName).tiempoRuta.tiempos_positivosVuelta{f}=sum(seconds(tiempos_positivos))/datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Vuelta(f);
            datosBuses.(busName).(subfieldName).tiempoRuta.tiempos_negativosVuelta{f}=sum(seconds(tiempos_negativos))/datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Vuelta;
            
        end
       
    end
end




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

