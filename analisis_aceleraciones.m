%% Gráfico de magnitudes vs duraciones de aceleraciones y desaceleraciones

figure
i = 6;
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
Tabla = superTabla(datosBuses);

function TABLA = superTabla(datosBuses)


    % Crear la tabla vacía con los nombres de columna adecuados
    TABLA = table([], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [],[],[],[],[],[],[], ...
    'VariableNames', {'Bus', 'Fecha', 'Recorrido', 'ID', 'Sexo', 'HoraInicio', 'HoraFin', ...
                      'AcelePorcen1', 'AcelePorcen2', 'MagPosMean', 'MagNegMean', 'DurPosMean', ...
                      'DurNegMean', 'MagPosMax', 'MagNegMax', 'DurPosMax', 'DurNegMax', 'HorarioRuta', 'KilometrosRuta', 'NombreRuta', 'Distancia', 'Tiempo', 'Velocidad'});



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
                            distancia = {rutadato.datosSensorRuta{k, 2}.distancia};
                            acelepercent1 = sum(datosBuses.(bus).(fecha).indicesAceleracionRuta{k, 1}>1)/sum(datosBuses.(bus).(fecha).indicesAceleracionRuta{k, 1}>0);
                            acelepercent2 = sum(datosBuses.(bus).(fecha).indicesAceleracionRuta{k, 1}>2)/sum(datosBuses.(bus).(fecha).indicesAceleracionRuta{k, 1}>0);
                            tiempo = {rutadato.datosSensorRuta{k,2}.deltaTiempo};
                            velocidad = rutadato.velocidadRuta(k,2);


                            % Definir los datos de una nueva fila
                            nuevaFila = table(string(bus), string(fecha), k, id, string(sexo), hora_inicio, hora_final, acelepercent1, acelepercent2, ...
                                indicesAceleracion(k,1), indicesAceleracion(k,2), indicesAceleracion(k,3), indicesAceleracion(k,4), ...
                                indicesAceleracion(k,5), indicesAceleracion(k,6), indicesAceleracion(k,7), indicesAceleracion(k,8) , string(rutadato.tiempoRuta.HorarioRuta(k)), ...
                                rutadato.tiempoRuta.Kilometros_Ida(k), rutadato.tiempoRuta.Ruta(k), distancia, tiempo, velocidad, ...
                                'VariableNames', {'Bus', 'Fecha', 'Recorrido', 'ID', 'Sexo', 'HoraInicio', 'HoraFin', 'AcelePorcen1', 'AcelePorcen2', ...
                                'MagPosMean', 'MagNegMean', 'DurPosMean', ...
                      'DurNegMean', 'MagPosMax', 'MagNegMax', 'DurPosMax', 'DurNegMax', 'HorarioRuta', 'KilometrosRuta', 'NombreRuta', 'Distancia', 'Tiempo', 'Velocidad'});


                            % Agregar la nueva fila a la tabla
                            TABLA = [TABLA; nuevaFila];


                        end
                    catch ME
                        fprintf('Error encontrado: %s\n', ME.message);
                    end

                end
            end
end


% Tabla = superTabla(datosBuses);

%%
% histogram(Tabla.AcelePorcen1, 20, 'FaceAlpha', 0.5, 'EdgeColor', 'none');  % 20 bins
% hold on
% solo_mujeres = Tabla.NombreRuta == 'A617';
% histogram(Tabla.AcelePorcen1(solo_mujeres), 20, 'FaceAlpha', 0.5, 'EdgeColor', 'none');
% %%
% %Tabla=Tabla(Tabla.ID>0)
% 
% % for i=1:length(Tabla.ID)
% %     Tabla.DurPosMax{i}=seconds(mean(Tabla.DurPosMax{i}));
% %     Tabla.DurNegMax{i} =seconds(mean(Tabla.DurNegMax{i}));
% % end
% 
% % Tabla.MagPosMax = cell2mat(Tabla.MagPosMax);  % Convierte {[0.9535]} a 0.9535
% % Tabla.DurPosMax = cell2mat(Tabla.DurPosMax);  % Convierte {[1.4789]} a 1.4789
% % 
% 
% %Tabla=Tabla(Tabla.KilometrosRuta>0,:);
% rutas = unique(Tabla.NombreRuta);
% figure;
% hold on;
% colores = lines(length(rutas));
% 
% for i = 1:length(rutas)
%     idx = strcmp(Tabla.NombreRuta, rutas{i});  % Comparación para celdas de texto
%     scatter(Tabla.DurPosMax(idx),Tabla.MagPosMax(idx),  10, ...
%            'MarkerFaceColor', colores(i,:), ...
%            'DisplayName', rutas{i});
% end
% xlabel('MagPosMax');
% ylabel('DurPosMax');
% title('Dispersión por NombreRuta');
% legend('Location', 'bestoutside');
% grid on;
% hold off;
% %%
% horarios = unique(Tabla.HorarioRuta);  % Cambio clave: Usar HorarioRuta
% colores = lines(length(horarios));
% 
% figure;
% hold on;
% 
% for i = 1:length(horarios)
%     idx = strcmp(Tabla.HorarioRuta, horarios{i});  % Comparación por HorarioRuta
%     scatter(Tabla.MagPosMax(idx), Tabla.DurPosMax(idx), 10, ...
%            'MarkerFaceColor', colores(i,:), ...
%            'DisplayName', horarios{i});  % Leyenda muestra horarios
% end
% 
% xlabel('MagPosMax');
% ylabel('DurPosMax');
% title('Dispersión por HorarioRuta');  % Título actualizado
% legend('Location', 'bestoutside');
% grid on;
% hold off;
% %%
% grupo1 = (startsWith(Tabla.NombreRuta, {'A', 'L', 'K'})) & (hour(Tabla.HoraInicio) < 8);
% grupo2 = (startsWith(Tabla.NombreRuta, 'H')) & (hour(Tabla.HoraInicio) >= 17);
% grupo3 = ~(grupo1 | grupo2);
% colores = zeros(height(Tabla), 3);  % Matriz de colores RGB
% colores(grupo1, :) = repmat([0.2 0.6 1], sum(grupo1), 1);    % Azul (buses A/L/K antes de 8am)
% colores(grupo2, :) = repmat([1 0.5 0], sum(grupo2), 1);      % Naranja (buses H después de 5pm)
% colores(grupo3, :) = repmat([0.5 0.5 0.5], sum(grupo3), 1);  % Gris (resto)
% figure;
% hold on;
% scatter(Tabla.meanMagPosMax(grupo1), Tabla.AcelePorcen1(grupo1), 30, colores(grupo1, :), 'filled', 'DisplayName', 'Buses A/L/K (mañana)');
% scatter(Tabla.meanMagPosMax(grupo2), Tabla.AcelePorcen1(grupo2), 30, colores(grupo2, :), 'filled', 'DisplayName', 'Buses H (tarde/noche)');
% scatter(Tabla.meanMagPosMax(grupo3), Tabla.AcelePorcen1(grupo3), 30, colores(grupo3, :), 'filled', 'DisplayName', 'Otros buses');
% 
% ylabel('MagPosMax');
% xlabel('DurPosMax');
% title('Dispersión por tipo de bus y horario');
% legend('Location', 'bestoutside');
% grid on;
% hold off;