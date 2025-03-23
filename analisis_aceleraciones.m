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

%% Funciones

function TABLA = superTabla(datosBuses)


    % Crear la tabla vacía con los nombres de columna adecuados
    TABLA = table([], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [],[], ...
    'VariableNames', {'Bus', 'Fecha', 'Recorrido', 'ID', 'Sexo', 'HoraInicio', 'HoraFin', ...
                      'AcelePorcen1', 'AcelePorcen2', 'MagPosMean', 'MagNegMean', 'DurPosMean', ...
                      'DurNegMean', 'MagPosMax', 'MagNegMax', 'DurPosMax', 'DurNegMax','Ruta'});



            % Obtener los campos de los buses
            buses = fieldnames(datosBuses);

            % Iterar sobre cada bus
            for i = 1:numel(buses)  
                bus = buses{i};

                % Saltar el campo 'info'
                if strcmp(bus, 'info')
                    continue;
                end

                % Obtener los campos de las fechas para el bus actual
                fechas = fieldnames(datosBuses.(bus));

                % Iterar sobre cada fecha
                for j = 1:numel(fechas)
                    fecha = fechas{j};
                    rutadato = datosBuses.(bus).(fecha);
                    


                    try
                        indicesAceleracion = rutadato.indicesAceleracionRuta;
                        for k = 1:numel(datosBuses.(bus).(fecha).tiempoRuta(:, 1))
                            % datosBuses.(bus).(fecha) = funcionAplicar(datosBuses.(bus).(fecha), k);  % Aplicar la función pasada como argumento

                            id = rutadato.tiempoRuta.Id(k);
                            sexo = rutadato.tiempoRuta.Genero_Conductor(k);
                            hora_inicio = rutadato.tiempoRuta.Inicio_Ruta(k);
                            hora_final = rutadato.tiempoRuta.Fin_Ruta(k);
                            ruta=rutadato.tiempoRuta.Ruta(k);
                            acelepercent1 = sum(datosBuses.(bus).(fecha).indicesAceleracionRuta{k, 1}>1)/sum(datosBuses.(bus).(fecha).indicesAceleracionRuta{k, 1}>0);
                            acelepercent2 = sum(datosBuses.(bus).(fecha).indicesAceleracionRuta{k, 1}>2)/sum(datosBuses.(bus).(fecha).indicesAceleracionRuta{k, 1}>0);


                            % Definir los datos de una nueva fila
                            nuevaFila = table(string(bus), string(fecha), k, id, string(sexo), hora_inicio, hora_final, acelepercent1, acelepercent2, ...
                                indicesAceleracion(1), indicesAceleracion(2), indicesAceleracion(3), indicesAceleracion(4), ...
                                indicesAceleracion(5), indicesAceleracion(6), indicesAceleracion(7), indicesAceleracion(8) , ruta, ...
                                'VariableNames', {'Bus', 'Fecha', 'Recorrido', 'ID', 'Sexo', 'HoraInicio', 'HoraFin', 'AcelePorcen1', 'AcelePorcen2', ...
                                'MagPosMean', 'MagNegMean', 'DurPosMean', ...
                      'DurNegMean', 'MagPosMax', 'MagNegMax', 'DurPosMax', 'DurNegMax','Ruta'});
                            
                            
                            % Agregar la nueva fila a la tabla
                            TABLA = [TABLA; nuevaFila];

                         
                        end
                    catch ME
                        fprintf('Error encontrado: %s\n', ME.message);
                    end

                end
            end
end


Tabla = superTabla(datosBuses);


%% sexo

diagonal
hombres=Tabla(Tabla.Sexo=="H",:);
mujeres=Tabla(Tabla.Sexo=="M",:);

%% horario
antes9am = Tabla(timeofday(Tabla.HoraInicio) < duration(9, 0, 0), :);
entre9y2 = Tabla(timeofday(Tabla.HoraInicio) >= duration(9, 0, 0) & timeofday(Tabla.HoraInicio) < duration(14, 0, 0), :);
entre2y7 = Tabla(timeofday(Tabla.HoraInicio) >= duration(14, 0, 0) & timeofday(Tabla.HoraInicio) < duration(19, 0, 0), :);
despues7pm = Tabla(timeofday(Tabla.HoraInicio) >= duration(19, 0, 0), :);
%% ruta

soloA617 = entre2y7(entre2y7.Ruta == "A617", :);
soloH617 = entre2y7(entre2y7.Ruta == "H617", :);
