%posiciones curvasLcurvas
%se usan los metodos para saber donde empiezan y donde acaba cada curva
%Lcurvasida4020()
%LcurvasVuelta4020()
%Lcurvasida4104s2()
%LcurvasVuelta4104s2()
%Lcurvasida4020s2()
%LcurvasVuelta4020s2()
%Lcurvasida4104()
%LcurvasVuelta4104()



%% pruebas para ver curvas 
% faltan 4012 y 4025
%a617 h617 a601 h601 h613 L613 a618, falta   h618
curva4012=Calculos.riesgoCurva(datosBuses.bus_4012.f_03_07_2024.datosSensorRuta{5,2},datosBuses.bus_4012.f_03_07_2024.tiempoRuta.Inicio_Ruta(5), datosBuses.bus_4012.f_03_07_2024.tiempoRuta.Fin_Ruta(5));
%marcador=Calculos.LcurvasH617(datosBuses);


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
datosBuses = Calcular.aproximarNivelBateriaPorRutas(datosBuses);

%%
datosBuses = Calcular.ConsumoPorRuta(datosBuses, 280);

%%
datosBuses = Calcular.RiesgoCurvaTodasRutas(datosBuses);

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


%% Velocidad acum ruta
% Bins del 1% (100 tramos)
edges = linspace(0, 1, 101);
centros = edges(1:end-1) + 0.005;

rutas = unique(Tabla.NombreRuta);
resultado = struct();

for r = 1:numel(rutas)
    ruta_actual = rutas(r);
    
    idx = Tabla.NombreRuta == ruta_actual;
    velocidades_ruta = Tabla.Velocidad(idx);
    dist_norm_ruta = Tabla.distanciaAcumNorm(idx);

    suma = zeros(1, 100);
    conteo = zeros(1, 100);

    for i = 1:numel(velocidades_ruta)
        v = velocidades_ruta{i};
        d = dist_norm_ruta{i};
        
        % Validar consistencia
        if numel(d) ~= numel(v)+1
            continue  % o lanzar advertencia
        end
        
        d = d(1:end-1);  % emparejar con v

        for b = 1:100
            in_bin = d >= edges(b) & d < edges(b+1);
            valores = v(in_bin);
            suma(b) = suma(b) + sum(valores);
            conteo(b) = conteo(b) + numel(valores);
        end
    end

    promedio = suma ./ max(conteo, 1);  % evitar división por cero

    resultado(r).Ruta = ruta_actual;
    resultado(r).Progreso = centros;
    resultado(r).VelocidadMedia = promedio;
end


%%

function graficarCurvasVelocidad(resultado)
% GRAFICARCURVASVELOCIDAD Grafica las curvas promedio de velocidad normalizada por ruta
%
% Entrada:
%   resultado: estructura con campos:
%       - Ruta: nombre de la ruta (categorical o string)
%       - Progreso: vector de progreso normalizado [0–1]
%       - VelocidadMedia: vector de velocidad promedio correspondiente

    if nargin < 1 || isempty(resultado)
        error('Se debe proporcionar la estructura de resultados.');
    end

    figure; hold on; grid on;
    for i = 1:numel(resultado)
        plot(resultado(i).Progreso, resultado(i).VelocidadMedia, 'LineWidth', 1.5, ...
             'DisplayName', string(resultado(i).Ruta));
    end

    xlabel('Progreso normalizado de la ruta (0–1)');
    ylabel('Velocidad promedio');
    title('Curvas promedio de velocidad por ruta');
    legend('Location', 'best');
end

graficarCurvasVelocidad(resultado)