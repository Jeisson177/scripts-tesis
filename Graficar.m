classdef Graficar
    methods (Static)

        function graficarIndicadoresAcc(datosBuses)
            figure;
            % Obtener los nombres de los buses
            busesNames = fieldnames(datosBuses);

            % Recorrer cada bus en la estructura datosBuses
            for i = 1:length(busesNames)
                busName = busesNames{i};  % Nombre del bus actual
                busData = datosBuses.(busName);  % Acceder a los datos del bus actual

                % Obtener los nombres de los subcampos dentro de cada bus (por ejemplo: f_03_07_2024)
                subfields = fieldnames(busData);  % Subcampos dentro del bus

                % Recorrer los subcampos
                for j = 1:length(subfields)
                    subfieldName = subfields{j};  % Nombre del subcampo
                    try
                          
                        tiempoRuta = datosBuses.(busName).(subfieldName).tiempoRuta;  % Acceder a datosSensorRuta
                        numFilas = size(tiempoRuta, 1);  % Asume que tiene filas como una tabla o matriz

                        for f = 1:numFilas
                            %se toman aceleraciones como positivas y
                            %frenadas como negativas
                            aceleracionesKM=datosBuses.(busName).(subfieldName).tiempoRuta.aceleracionesKMIda{f};%positiva
                            frenadasKM=datosBuses.(busName).(subfieldName).tiempoRuta.frenadasKMIda{f};%negativa
                            cantidad_frenadas=-1*datosBuses.(busName).(subfieldName).tiempoRuta.cantidad_frenadasIda{f};%las cantidades son positivas pero se multiplica por -1
                            cantidad_aceleraciones=datosBuses.(busName).(subfieldName).tiempoRuta.cantidad_aceleracionesIda{f};
                            tiempos_positivos=datosBuses.(busName).(subfieldName).tiempoRuta.tiempos_positivosIda{f};
                            tiempos_negativos=-1*datosBuses.(busName).(subfieldName).tiempoRuta.tiempos_negativosIda{f};%los tiempos son positivos pero se multiplican por -1
                            
                            
                            if strcmp(datosBuses.(busName).(subfieldName).tiempoRuta.Sexo,'M') 
                                scatter3(aceleracionesKM,cantidad_aceleraciones,tiempos_positivos,'r');
                                hold on;
                                scatter3(frenadasKM,cantidad_frenadas,tiempos_negativos,'r');
                            elseif strcmp(datosBuses.(busName).(subfieldName).tiempoRuta.Sexo,'H') 
                                scatter3(aceleracionesKM,cantidad_aceleraciones,tiempos_positivos,'b');
                                hold on;
                                scatter3(frenadasKM,cantidad_frenadas,tiempos_negativos,'b');
                            else
                                scatter3(aceleracionesKM,cantidad_aceleraciones,tiempos_positivos,'g');
                                hold on;
                                scatter3(frenadasKM,cantidad_frenadas,tiempos_negativos,'g');
                            end    
                            aceleracionesKM=datosBuses.(busName).(subfieldName).tiempoRuta.aceleracionesKMVuelta{f};%positiva
                            frenadasKM=datosBuses.(busName).(subfieldName).tiempoRuta.frenadasKMVuelta{f};%negativa
                            cantidad_frenadas=-1*datosBuses.(busName).(subfieldName).tiempoRuta.cantidad_frenadasVuelta{f};%las cantidades son positivas pero se multiplica por -1
                            cantidad_aceleraciones=datosBuses.(busName).(subfieldName).tiempoRuta.cantidad_aceleracionesvuelta{f};
                            tiempos_positivos=datosBuses.(busName).(subfieldName).tiempoRuta.tiempos_positivosVuelta{f};
                            tiempos_negativos=-1*datosBuses.(busName).(subfieldName).tiempoRuta.tiempos_negativosVuelta{f};%los tiempos son positivos pero se multiplican por -1
                            
                            if strcmp(datosBuses.(busName).(subfieldName).tiempoRuta.Sexo,'M') 
                                scatter3(aceleracionesKM,cantidad_aceleraciones,tiempos_positivos,'r');
                                hold on;
                                scatter3(frenadasKM,cantidad_frenadas,tiempos_negativos,'r');
                            elseif strcmp(datosBuses(busName).(subfieldName).tiempoRuta.Sexo,'H') 
                                scatter3(aceleracionesKM,cantidad_aceleraciones,tiempos_positivos,'b');
                                hold on;
                                scatter3(frenadasKM,cantidad_frenadas,tiempos_negativos,'b');
                            else
                                scatter3(aceleracionesKM,cantidad_aceleraciones,tiempos_positivos,'g');
                                hold on;
                                scatter3(frenadasKM,cantidad_frenadas,tiempos_negativos,'g');
                            end
                            
                        end
                    catch
                        fprintf('Error procesando el subcampo %s del bus %s.\n', subfieldName, busName);
                    end
                end
            end
            % Añadir etiquetas a los ejes y título
            xlabel('cambios bruscos por KM');
            ylabel('Cantidad de cambios');
            zlabel('Tiempo (segundos)');
            title('Gráfico de aceleraciones y frenadas por Sexo');
        end
        
        function graficarVelocidadPorRutas(datosBuses, busID, fecha, indiceRuta)
            % Esta función grafica las velocidades para rutas de un bus en fechas dadas
            % usando los parámetros proporcionados, con manejo de omisiones.

            % Comprobar si el bus existe
            if ~isfield(datosBuses, busID)
                error('El bus especificado no existe en los datos.');
            end

            % Obtener todas las fechas si no se especifica una
            if nargin < 3 || isempty(fecha)
                fechas = fieldnames(datosBuses.(busID));
            else
                if ~isfield(datosBuses.(busID), fecha)
                    error('La fecha especificada no existe para el bus dado.');
                end
                fechas = {fecha};
            end

            % Iterar sobre las fechas
            for j = 1:numel(fechas)
                fechaActual = fechas{j};

                % Obtener los datos de velocidad para la fecha especificada
                if isfield(datosBuses.(busID).(fechaActual), 'velocidadRuta')
                    velocidadRutas = datosBuses.(busID).(fechaActual).velocidadRuta;
                else
                    warning('No hay datos de velocidad disponibles para la fecha %s.', fechaActual);
                    continue;
                end

                % Obtener todos los índices si no se especifica uno
                if nargin < 4 || isempty(indiceRuta)
                    indicesRutas = 1:size(velocidadRutas, 1);
                else
                    if indiceRuta < 1 || indiceRuta > size(velocidadRutas, 1)
                        error('Índice de ruta no válido. Debe estar entre 1 y %d.', size(velocidadRutas, 1));
                    end
                    indicesRutas = indiceRuta;
                end

                % Iterar sobre los índices de ruta
                for k = indicesRutas
                    % Obtener las velocidades y los datos del sensor para el índice de ruta especificado
                    velocidades = velocidadRutas{k, 2}; % Velocidades calculadas
                    ruta = velocidadRutas{k, 3}; % Nombre de la ruta

                    % Obtener los tiempos asociados a las velocidades
                    datosSensorRuta = datosBuses.(busID).(fechaActual).datosSensorRuta{k, 2}; % Datos del sensor para la ruta
                    tiempos = datosSensorRuta.time(2:end-1); % Usar los tiempos del sensor
                    velocidades = velocidades(1:end-1); % cambio porque estaba dando error con lo de arriba
                    % Graficar las velocidades
                    figure;
                    plot(tiempos, velocidades, '-'); % Usar solo '-' para una línea continua

                    % Ajustar el título de la gráfica para evitar subíndices
                    ruta = strrep(ruta, '_', '\_'); % Escapar guiones bajos
                    fechaActualEscapada = strrep(fechaActual, '_', '\_'); % Escapar guiones bajos
                    busIDEscapado = strrep(busID, '_', '\_'); % Escapar guiones bajos

                    % Crear el título usando sprintf para evitar problemas de formato
                    title(sprintf('Velocidades para la ruta %s (Índice: %d) en el bus %s en la fecha %s', ruta, k, busIDEscapado, fechaActualEscapada));
                    xlabel('Tiempo');
                    ylabel('Velocidad (m/s)');
                    grid on;
                end
            end
        end

        function aceleracionPorRutas(datosBuses, busID, fecha, indiceRuta)
            % Esta función grafica las velocidades para rutas de un bus en fechas dadas
            % usando los parámetros proporcionados, con manejo de omisiones.

            % Comprobar si el bus existe
            if ~isfield(datosBuses, busID)
                error('El bus especificado no existe en los datos.');
            end

            % Obtener todas las fechas si no se especifica una
            if nargin < 3 || isempty(fecha)
                fechas = fieldnames(datosBuses.(busID));
            else
                if ~isfield(datosBuses.(busID), fecha)
                    error('La fecha especificada no existe para el bus dado.');
                end
                fechas = {fecha};
            end

            % Iterar sobre las fechas
            for j = 1:numel(fechas)
                fechaActual = fechas{j};

                % Obtener los datos de velocidad para la fecha especificada
                if isfield(datosBuses.(busID).(fechaActual), 'velocidadRuta')
                    aceleracionRutas = datosBuses.(busID).(fechaActual).aceleracionRuta;
                else
                    warning('No hay datos de velocidad disponibles para la fecha %s.', fechaActual);
                    continue;
                end

                % Obtener todos los índices si no se especifica uno
                if nargin < 4 || isempty(indiceRuta)
                    indicesRutas = 1:size(aceleracionRutas, 1);
                else
                    if indiceRuta < 1 || indiceRuta > size(aceleracionRutas, 1)
                        error('Índice de ruta no válido. Debe estar entre 1 y %d.', size(aceleracionRutas, 1));
                    end
                    indicesRutas = indiceRuta;
                end

                % Iterar sobre los índices de ruta
                for k = indicesRutas
                    % Obtener las velocidades y los datos del sensor para el índice de ruta especificado
                    velocidades = aceleracionRutas{k, 2}; % Velocidades calculadas
                    ruta = aceleracionRutas{k, 3}; % Nombre de la ruta

                    % Obtener los tiempos asociados a las velocidades
                    datosSensorRuta = datosBuses.(busID).(fechaActual).datosSensorRuta{k, 2}; % Datos del sensor para la ruta
                    tiempos = datosSensorRuta.time(2:end-1); % Usar los tiempos del sensor

                    % Graficar las velocidades
                    figure;
                    plot(tiempos, velocidades, '-'); % Usar solo '-' para una línea continua

                    % Ajustar el título de la gráfica para evitar subíndices
                    ruta = strrep(ruta, '_', '\_'); % Escapar guiones bajos
                    fechaActualEscapada = strrep(fechaActual, '_', '\_'); % Escapar guiones bajos
                    busIDEscapado = strrep(busID, '_', '\_'); % Escapar guiones bajos

                    % Crear el título usando sprintf para evitar problemas de formato
                    title(sprintf('Velocidades para la ruta %s (Índice: %d) en el bus %s en la fecha %s', ruta, k, busIDEscapado, fechaActualEscapada));
                    xlabel('Tiempo');
                    ylabel('Velocidad (m/s)');
                    grid on;
                end
            end
        end

        function rutaMapa(datosBuses, busID, fecha, indiceRuta)
            % Esta función grafica la ruta de un bus en una fecha y ruta específicas
            % sobre un mapa con coordenadas geográficas.
        
            % Verificar si el bus existe
            if ~isfield(datosBuses, busID)
                error('El bus especificado no existe en los datos.');
            end
        
            % Obtener todas las fechas si no se especifica una
            if nargin < 3 || isempty(fecha)
                fechas = fieldnames(datosBuses.(busID));
            else
                if ~isfield(datosBuses.(busID), fecha)
                    error('La fecha especificada no existe para el bus dado.');
                end
                fechas = {fecha};
            end
        
            % Iterar sobre las fechas
            for j = 1:numel(fechas)
                fechaActual = fechas{j};
        
                % Comprobar si existen datos de la ruta
                if isfield(datosBuses.(busID).(fechaActual), 'datosSensorRuta')
                    rutas = datosBuses.(busID).(fechaActual).datosSensorRuta;
                else
                    warning('No hay datos de ruta disponibles para la fecha %s.', fechaActual);
                    continue;
                end
        
                % Obtener todos los índices si no se especifica uno
                if nargin < 4 || isempty(indiceRuta)
                    indicesRutas = 1:size(rutas, 1);
                else
                    if indiceRuta < 1 || indiceRuta > size(rutas, 1)
                        error('Índice de ruta no válido. Debe estar entre 1 y %d.', size(rutas, 1));
                    end
                    indicesRutas = indiceRuta;
                end
        
                % Iterar sobre los índices de ruta
                for k = indicesRutas
                    % Crear una nueva figura para cada ruta
                    figure;
        
                    % Configurar el mapa base
                    geobasemap('streets-light'); % Puedes cambiar a 'satellite', 'topographic', etc.
                    hold on;
        
                    % Obtener las coordenadas de la ruta
                    latitudes = rutas{k, 2}.lat;
                    longitudes = rutas{k, 2}.lon;
        
                    if isempty(latitudes) || isempty(longitudes)
                        warning('No hay datos de coordenadas para la ruta %d en la fecha %s.', k, fechaActual);
                        continue;
                    end
        
                    % Graficar la ruta en el mapa
                    geoplot(latitudes, longitudes, '-o', 'MarkerSize', 1, 'LineWidth', 0.5, 'Color', 'b');
        
                    % Marcar el punto de inicio y final
                    geoscatter(latitudes(1), longitudes(1), 100, 'g', 'filled'); % Inicio (verde)
                    geoscatter(latitudes(end), longitudes(end), 100, 'r', 'filled'); % Fin (rojo)
        
                    % Agregar título
                    title(sprintf('Ruta %d del bus %s en la fecha %s', k, busID, fechaActual), 'Interpreter', 'none');
        
                    hold off;
                end
            end
        end

        function rutaPorTiempo(datosBuses, busID, fecha, tiempoInicio, tiempoFin, paradas)
            % Graficar la ruta de un bus en un rango de tiempo específico y opcionalmente sus paradas.
            
            % Verificar si el bus existe
            if ~isfield(datosBuses, busID)
                error('El bus especificado no existe en los datos.');
            end
            
            % Verificar si la fecha existe
            if ~isfield(datosBuses.(busID), fecha)
                error('La fecha especificada no existe para el bus dado.');
            end
            
            % Obtener los datos de la ruta para la fecha especificada
            if isfield(datosBuses.(busID).(fecha), 'datosSensorRuta')
                rutaDatos = datosBuses.(busID).(fecha).datosSensor;
            else
                warning('No hay datos de ruta disponibles para la fecha %s.', fecha);
                return;
            end
        
            % Filtrar los datos dentro del rango de tiempo
            tiempos = rutaDatos.time;
            indicesFiltrados = (tiempos >= tiempoInicio) & (tiempos <= tiempoFin);
            
            if sum(indicesFiltrados) == 0
                warning('No hay datos disponibles en el rango de tiempo seleccionado.');
                return;
            end
        
            % Extraer coordenadas de la ruta filtrada
            latitudes = rutaDatos.lat(indicesFiltrados);
            longitudes = rutaDatos.lon(indicesFiltrados);
        
            % Crear figura para la ruta
            figure;
            geobasemap('streets-light');
            hold on;
        
            % Graficar la ruta del bus
            geoplot(latitudes, longitudes, '-o', 'MarkerSize', 3, 'LineWidth', 1, 'Color', 'b');
        
            % Marcar el inicio y el final de la ruta
            geoscatter(latitudes(1), longitudes(1), 100, 'g', 'filled'); % Inicio en verde
            geoscatter(latitudes(end), longitudes(end), 100, 'r', 'filled'); % Fin en rojo
        
            % Si se proporcionan paradas, graficarlas
            if nargin == 6 && ~isempty(paradas)
                geoscatter(paradas.lat, paradas.lon, 50, 'm', 'filled', 'Marker', 's'); % Paradas en magenta
                legend({'Ruta', 'Inicio', 'Fin', 'Paradas'}, 'Location', 'best');
            else
                legend({'Ruta', 'Inicio', 'Fin'}, 'Location', 'best');
            end
        
            % Configurar título
            title(sprintf('Ruta del bus %s el %s de %s a %s', busID, fecha, datestr(tiempoInicio), datestr(tiempoFin)), 'Interpreter', 'none');
        
            hold off;
        end

        function graficarMagnitudesVsDuraciones(datosBuses, busID, fecha, indiceRuta)
            % Esta función grafica las magnitudes vs. duraciones de aceleraciones y desaceleraciones
            % para una ruta específica de un bus en una fecha dada.
        
            % Comprobar si el bus existe
            if ~isfield(datosBuses, busID)
                error('El bus especificado no existe en los datos.');
            end
        
            % Comprobar si la fecha existe
            if ~isfield(datosBuses.(busID), fecha)
                error('La fecha especificada no existe para el bus dado.');
            end
        
            % Obtener los datos de aceleración
            if isfield(datosBuses.(busID).(fecha), 'indicesAceleracionRuta')
                indicesAceleracion = datosBuses.(busID).(fecha).indicesAceleracionRuta;
            else
                error('No hay datos de aceleración para la fecha %s.', fecha);
            end
        
            % Validar el índice de ruta
            if indiceRuta < 1 || indiceRuta > size(indicesAceleracion, 1)
                error('Índice de ruta no válido. Debe estar entre 1 y %d.', size(indicesAceleracion, 1));
            end
        
            % Extraer los datos de magnitudes y duraciones
            magnitudes = { ...
                indicesAceleracion{indiceRuta, 3}, ...
                indicesAceleracion{indiceRuta, 4}, ...
                indicesAceleracion{indiceRuta, 7}, ...
                indicesAceleracion{indiceRuta, 8} ...
            };
        
            duraciones = { ...
                indicesAceleracion{indiceRuta, 1}, ...
                indicesAceleracion{indiceRuta, 2}, ...
                indicesAceleracion{indiceRuta, 5}, ...
                indicesAceleracion{indiceRuta, 6} ...
            };
        
            % Crear la gráfica
            figure;
            hold on;
            grid on;
        
            colores = {'b', 'r', 'g', 'y'}; % Colores para diferenciar los datos
            etiquetas = {'Magnitud aceleración promedio', 'Magnitud desaceleración promedio', 'Magnitud aceleración max', 'Magnitud desaceleración max'};
        
            for i = 1:4
                scatter(magnitudes{i}, duraciones{i}, 'filled', 'MarkerEdgeColor', colores{i}, 'MarkerFaceColor', colores{i});
            end
        
            xlabel('Duración');
            ylabel('Magnitud');
            title(sprintf('Magnitudes vs Duraciones para el Bus %s en %s (Ruta %d)', strrep(busID, '_', '\_'), strrep(fecha, '_', '\_'), indiceRuta));
            legend(etiquetas);
            hold off;
        end

        function HistogramasMagnitudesVsDuraciones(datosBuses, busID, fecha, indiceRuta)
 % Esta función genera dos figuras con histogramas separados para:
    %   - Figura 1: Duraciones (Mean, Min, Max)
    %   - Figura 2: Magnitudes (Mean, Min, Max)

    % Verificar si el bus y la fecha existen
    if ~isfield(datosBuses, busID)
        error('El bus especificado no existe en los datos.');
    end
    if ~isfield(datosBuses.(busID), fecha)
        error('La fecha especificada no existe para el bus dado.');
    end

    % Obtener los datos de aceleración
    if isfield(datosBuses.(busID).(fecha), 'indicesAceleracionRuta')
        indicesAceleracion = datosBuses.(busID).(fecha).indicesAceleracionRuta;
    else
        error('No hay datos de aceleración para la fecha %s.', fecha);
    end

    % Validar el índice de ruta
    if indiceRuta < 1 || indiceRuta > size(indicesAceleracion, 1)
        error('Índice de ruta no válido. Debe estar entre 1 y %d.', size(indicesAceleracion, 1));
    end

    % Extraer y convertir datos de duraciones
    duraciones = { ...
        Graficar.convertirADouble(indicesAceleracion{indiceRuta, 1}), ... % Duración aceleración promedio
        Graficar.convertirADouble(indicesAceleracion{indiceRuta, 2}), ... % Duración desaceleración promedio
        Graficar.convertirADouble(indicesAceleracion{indiceRuta, 5}), ... % Duración aceleración máxima
        Graficar.convertirADouble(indicesAceleracion{indiceRuta, 6})  ... % Duración desaceleración máxima
    };

    % Extraer y convertir datos de magnitudes
    magnitudes = { ...
        Graficar.convertirADouble(indicesAceleracion{indiceRuta, 3}), ... % Magnitud aceleración promedio
        Graficar.convertirADouble(indicesAceleracion{indiceRuta, 4}), ... % Magnitud desaceleración promedio
        Graficar.convertirADouble(indicesAceleracion{indiceRuta, 7}), ... % Magnitud aceleración máxima
        Graficar.convertirADouble(indicesAceleracion{indiceRuta, 8})  ... % Magnitud desaceleración máxima
    };

    % Definir etiquetas para los gráficos
    titulos_duraciones = { ...
        'Duración (Aceleración Promedio)', ...
        'Duración (Desaceleración Promedio)', ...
        'Duración (Aceleración Máxima)', ...
        'Duración (Desaceleración Máxima)' ...
    };

    titulos_magnitudes = { ...
        'Magnitud (Aceleración Promedio)', ...
        'Magnitud (Desaceleración Promedio)', ...
        'Magnitud (Aceleración Máxima)', ...
        'Magnitud (Desaceleración Máxima)' ...
    };

    % ---- FIGURA 1: Histogramas de Duraciones ----
    figure;
    for i = 1:4
        subplot(2,2,i);
        histogram(duraciones{i}, 'FaceColor', 'b', 'EdgeColor', 'k'); % Histograma de duración
        xlabel('Segundos');
        ylabel('Frecuencia');
        title(titulos_duraciones{i});
        grid on;
    end
    sgtitle(sprintf('Histogramas de Duraciones para el Bus %s en %s (Ruta %d)', ...
        strrep(busID, '_', '\_'), strrep(fecha, '_', '\_'), indiceRuta));

    % ---- FIGURA 2: Histogramas de Magnitudes ----
    figure;
    for i = 1:4
        subplot(2,2,i);
        histogram(magnitudes{i}, 'FaceColor', 'r', 'EdgeColor', 'k'); % Histograma de magnitud
        xlabel('m/s²'); % Ajusta la unidad si es diferente
        ylabel('Frecuencia');
        title(titulos_magnitudes{i});
        grid on;
    end
    sgtitle(sprintf('Histogramas de Magnitudes para el Bus %s en %s (Ruta %d)', ...
        strrep(busID, '_', '\_'), strrep(fecha, '_', '\_'), indiceRuta));
end

%% ---- Función auxiliar para convertir a valores numéricos ----
function valoresNumericos = convertirADouble(datos)
    if iscell(datos) && ~isempty(datos)
        datos = datos{:}; % Extraer contenido de la celda si es necesario
    end
    if isa(datos, 'duration')
        valoresNumericos = seconds(datos); % Convertir duration a segundos
    elseif isa(datos, 'datetime')
        valoresNumericos = datenum(datos); % Convertir datetime a números seriales
    elseif isnumeric(datos)
        valoresNumericos = datos; % Si ya es numérico, dejarlo igual
    else
        error('Tipo de dato no reconocido: %s', class(datos));
    end
end

    end
end