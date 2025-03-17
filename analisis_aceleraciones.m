%% Gráfico de magnitudes vs duraciones de aceleraciones y desaceleraciones
figure
i = 8;
hold on, grid
scatter(datosBuses.bus_4012.f_03_07_2024.indicesAceleracionRuta{i, 3},datosBuses.bus_4012.f_03_07_2024.indicesAceleracionRuta{i, 1})
scatter(datosBuses.bus_4012.f_03_07_2024.indicesAceleracionRuta{i, 4},datosBuses.bus_4012.f_03_07_2024.indicesAceleracionRuta{i, 2})
scatter(datosBuses.bus_4012.f_03_07_2024.indicesAceleracionRuta{i, 7},datosBuses.bus_4012.f_03_07_2024.indicesAceleracionRuta{i, 5})
scatter(datosBuses.bus_4012.f_03_07_2024.indicesAceleracionRuta{i, 8},datosBuses.bus_4012.f_03_07_2024.indicesAceleracionRuta{i, 6})
legend("Aceleraciones positivas promedio", ...
       "Aceleraciones negativas promedio", ...
       "Aceleraciones positivas máximas", ...
       "Aceleraciones negativas mínimas", ...
       'Location', 'best');
%% Cálculo de aceleraciones y desaceleraciones por km
cellfun(@length,datosBuses.bus_4012.f_04_07_2024.indicesAceleracionRuta)./repmat(datosBuses.bus_4012.f_04_07_2024.tiempoRuta.Kilometros_Ida,1,8)



%% indicadores aceleración

%hacer un conteo de las aceleraciones por intervalo de tiempo, además de eso 
% sacar un promedio de cada una de ellas. (pensar si se pueden obviar las 
% que son muy bajas)

%sirve para comparar cada conductor si las aceleraciones que hace por un 
% tiempo considerable son mas agresivas que las de los demás, teniendo eso 
% se puede hacer un ranking y determinar cuales conducen mejor.

j = 1; % Conductor

% Extraer tiempos y aceleraciones
tiempos_seg = datosBuses.bus_4012.f_03_07_2024.indicesAceleracionRuta{j, 3}; % duration
aceleraciones = datosBuses.bus_4012.f_03_07_2024.indicesAceleracionRuta{j, 1}; % double

% Definir intervalos de tiempo
intervalo = seconds(1); % Intervalo de 1 segundo en formato duration
edges = (min(tiempos_seg):intervalo:max(tiempos_seg) + intervalo)'; % Bordes en duration

% Contar cuántas aceleraciones hay en cada intervalo
[N, ~, binIndex] = histcounts(tiempos_seg, edges); % binIndex indica a qué intervalo pertenece cada dato

% Inicializar vector de promedios con NaN para todos los intervalos
promedios = NaN(length(edges)-1, 1);

% Calcular promedio de aceleración para cada intervalo con datos
if any(binIndex) % Solo si hay datos en los bins
    valores_promedio = accumarray(binIndex(binIndex > 0), aceleraciones(binIndex > 0), [], @mean, NaN);
    idx_intervalos = unique(binIndex(binIndex > 0)); % Índices de intervalos con datos
    promedios(idx_intervalos) = valores_promedio; % Asignar valores solo a intervalos con datos
end

% Asegurar que todas las columnas tienen el mismo número de filas
if length(N) ~= length(promedios)
    error('Dimensiones de N (%d) y promedios (%d) no coinciden.', length(N), length(promedios));
end

% Crear una tabla con los resultados (asegurar que todas las variables sean columnas)
resultados = table(edges(1:end-1), N(:), promedios, ...
                   'VariableNames', {'TiempoInicio', 'ConteoAceleraciones', 'PromedioAceleracion'});

