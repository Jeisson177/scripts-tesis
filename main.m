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

%% Velocidad vs distancia
datosBuses = Calcular.velocidadVsDistancia(datosBuses);

%% Delta de tiempo en datos sensor
datosBuses = Calcular.tiempoEntrePuntos(datosBuses);

%%
datosBuses = Calcular.iterarSobreBusesYFechas(datosBuses, @ImportarDatos.OrdenarP60);

%% Interpola los valores discretos del nivel del bateria
datosBuses = Calcular.aproximarNivelBateriaPorRutas(datosBuses);

%% Calcula el consumo electrico kw/h
datosBuses = Calcular.ConsumoPorRuta(datosBuses, 280);

%% Riesgo curva 
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

Graficar.graficarRutasPorBus(datosBuses, 'bus_4012', 'f_03_07_2024');


%%
Graficar.aceleracionPorRutas(datosBuses, "bus_4012", "f_03_07_2024")

%%
Graficar.graficarMagnitudesVsDuraciones(datosBuses, 'bus_4012', 'f_03_07_2024', 6);
%%
Graficar.HistogramasMagnitudesVsDuraciones(datosBuses, 'bus_4012', 'f_03_07_2024', 1);

%%
Graficar.velocidadvsdistancia(datosBuses, 'bus_4012', 'f_03_07_2024');

%% ---------------Funciones viejas--------------------------





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