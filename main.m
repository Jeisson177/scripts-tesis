
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

%% Calcular indices aceleracion
datosBuses = Calcular.corregirAceleracionPorRutas(datosBuses);
%%
datosBuses = Calcular.corregirAceleracionPorRutasMax(datosBuses);
%% Aceleraciones por kilometro
datosBuses = Calcular.aceleracionesKilometroRutas(datosBuses);

%%
datosBuses = Calcular.velocidadVsDistancia(datosBuses);

%%
datosBuses = Calcular.tiempoEntrePuntos(datosBuses);
%%
datosBuses1 = Calcular.aproximarNivelBateriaPorRutas(datosBuses);
%%
datosBuses = Calcular.PorcentajesAceleracion(datosBuses);

%%
datosBuses = Calcular.ClasificarHorarioRuta(datosBuses);

%% Graficar----------------------------------------------------------------

Graficar.rutaMapa(datosBuses,"bus_4012" ,"f_03_07_2024")

%%
Graficar.rutaPorTiempo(datosBuses,"bus_4012" ,"f_10_07_2024", datetime(2024,7,10,14,25,0), datetime(2024,7,10,15,42,0), rutas(12).stops)

%%
Graficar.graficarVelocidadPorRutas(datosBuses, "bus_4012", "f_03_07_2024")

%%
Graficar.aceleracionPorRutas(datosBuses, "bus_4012", "f_03_07_2024")

%%
Graficar.graficarMagnitudesVsDuraciones(datosBuses, 'bus_4012', 'f_03_07_2024', 6);
%%
Graficar.HistogramasMagnitudesVsDuraciones(datosBuses, 'bus_4012', 'f_03_07_2024', 1);

%%
Graficar.velocidadvsdistancia(datosBuses, 'bus_4012', 'f_03_07_2024');

%% ---------------Funciones viejas--------------------------








%%

datosBuses = Calculos.calcularPorcentajeBateriaRutas(datosBuses);

%%
datosBuses = Calculos.calcularConsumoEnergiaRutas(datosBuses);


%%

function [lambda, alpha] = ajustarDecayModel(datos)
    % Esta función ajusta modelos de decaimiento exponencial y de ley de potencia
    % sobre los datos de aceleraciones/duraciones.

    % Filtrar valores no negativos y convertir a doble
    datos = datos(datos > 0);
    datos = double(datos); 

    % Crear histograma para obtener P(x)
    [freq, edges] = histcounts(datos, 'Normalization', 'probability');
    x = edges(1:end-1)';  

    % Eliminar ceros en la frecuencia para evitar log(0)
    valid = freq > 0;
    freq = freq(valid);
    x = x(valid);

    log_freq = log(freq);  
    p_exp = polyfit(x, log_freq, 1);  
    lambda = -p_exp(1);  

    log_x = log(x);
    p_pow = polyfit(log_x, log_freq, 1);  
    alpha = -p_pow(1);  

    % Mostrar resultados
    fprintf('Decay Exponencial: λ = %.4f\n', lambda);
    fprintf('Ley de Potencia: α = %.4f\n', alpha);
end

% [lambda_magnitud, alpha_magnitud] = ajustarDecayModel(datosBuses.bus_4012.f_03_07_2024.indicesAceleracionRuta{1, 1});


%%
function reconstruirDistribucion(datos, lambda, alpha)
    % Esta función reconstruye la distribución original usando los modelos de
    % decaimiento exponencial y de ley de potencia.

    % Filtrar valores no negativos y convertir a doble
    datos = datos(datos > 0);
    datos = double(datos);

    % Crear histograma original
    [freq, edges] = histcounts(datos, 'Normalization', 'probability');
    x = edges(1:end-1)';  % Centrar en los bordes del histograma

    % Eliminar ceros en la frecuencia
    valid = freq > 0;
    freq = freq(valid);
    x = x(valid);

    P_exp = exp(-lambda * x);
    P_exp = P_exp / sum(P_exp); % Normalizar

    P_pow = x.^(-alpha);
    P_pow = P_pow / sum(P_pow); % Normalizar

    figure;
    subplot(1,2,1);
    plot(x, freq, 'ko-', 'LineWidth', 1.5, 'DisplayName', 'Datos Originales');
    hold on;
    plot(x, P_exp, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Modelo Exponencial');
    xlabel('Valor de x');
    ylabel('Probabilidad');
    title('Ajuste Exponencial');
    legend;
    grid on;

    subplot(1,2,2);
    plot(x, freq, 'ko-', 'LineWidth', 1.5, 'DisplayName', 'Datos Originales');
    hold on;
    plot(x, P_pow, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Modelo de Ley de Potencia');
    xlabel('Valor de x');
    ylabel('Probabilidad');
    title('Ajuste de Ley de Potencia');
    legend;
    grid on;

    sgtitle('Comparación de Modelos con Datos Originales');
end

% reconstruirDistribucion(datosBuses.bus_4012.f_03_07_2024.indicesAceleracionRuta{1, 1}, 1.5092, 1.7141);