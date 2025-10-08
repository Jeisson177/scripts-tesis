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
        
        function graficarVelocidadPorRutas(datosBuses, busID, fecha, indiceRuta, tipoVelocidad, mostrarParadas, paradasStruct)
    % Esta función grafica las velocidades para rutas de un bus en fechas dadas
    % y opcionalmente muestra las paradas en el tiempo.

    if nargin < 5 || isempty(tipoVelocidad)
        tipoVelocidad = 'filtrada'; % valor por defecto
    end
    if nargin < 6
        mostrarParadas = false;
    end

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
            datosSensorRuta = datosBuses.(busID).(fechaActual).datosSensorRuta{k, 2};
            tiempos = datosSensorRuta.time(2:end-1);

            switch tipoVelocidad
                case 'filtrada'
                    velocidad = velocidadRutas{k, 2};
                case 'original'
                    velocidad = velocidadRutas{k, 5};
                case 'ambas'
                    velFiltrada = velocidadRutas{k, 2};
                    velOriginal = velocidadRutas{k, 5};
                otherwise
                    error('Valor no válido para tipoVelocidad. Use "filtrada", "original" o "ambas".');
            end

            % Asegurar tamaños iguales
            % Asegurar tamaños iguales según el tipo de velocidad
switch tipoVelocidad
    case {'filtrada', 'original'}
        n = min(length(velocidad), length(tiempos));
        velocidad = velocidad(1:n);
        tiempos = tiempos(1:n);
    case 'ambas'
        n = min([length(velFiltrada), length(velOriginal), length(tiempos)]);
        velFiltrada = velFiltrada(1:n);
        velOriginal = velOriginal(1:n);
        tiempos = tiempos(1:n);
end


            % Crear figura
            figure; hold on;

            % Graficar velocidad
            switch tipoVelocidad
                case 'filtrada'
                    plot(tiempos, velocidad, 'b-', 'DisplayName', 'Filtrada');
                case 'original'
                    plot(tiempos, velocidad, 'r--', 'DisplayName', 'Original');
                case 'ambas'
                    plot(tiempos, velOriginal(1:n), 'r--', 'DisplayName', 'Original');
                    plot(tiempos, velFiltrada(1:n), 'b-', 'DisplayName', 'Filtrada');
            end

            % --- NUEVO BLOQUE: Mostrar paradas ---
            if mostrarParadas
                nombreRuta = string(datosBuses.(busID).(fechaActual).tiempoRuta.Ruta{k});
                idrutas = string({paradasStruct.idruta});
                idxParada = find(idrutas == nombreRuta, 1);

                if ~isempty(idxParada)
                    stops = paradasStruct(idxParada).stops;
                    if iscell(stops), stops = stops{1}; end

                    latBus = datosSensorRuta.lat;
                    lonBus = datosSensorRuta.lon;

                    for s = 1:height(stops)
                        % Calcular distancia mínima entre parada y trayecto
                        dists = arrayfun(@(i) Calculos.geodist(latBus(i), lonBus(i), ...
                                        stops.lat(s), stops.lon(s)), 1:numel(latBus));
                        [~, idxMin] = min(dists);

                        % Línea vertical en el tiempo correspondiente
                        xline(tiempos(idxMin), '--r', 'LineWidth', 1, ...
      'HandleVisibility', 'off');

                        % Etiqueta de parada
                        % Etiqueta de parada
if ismember('stop_name', stops.Properties.VariableNames)
    switch tipoVelocidad
    case {'filtrada', 'original'}
        yMax = max(velocidad);
    case 'ambas'
        yMax = max([max(velFiltrada), max(velOriginal)]);
end


    text(tiempos(idxMin), yMax, string(stops.stop_name(s)), ...
         'Rotation', 90, 'VerticalAlignment','bottom', 'FontSize',8);
end

                    end
                end
            end
            % -------------------------------------

            % Título y ejes
            ruta = strrep(velocidadRutas{k,3}, '_', '\_');
            fechaEsc = strrep(fechaActual, '_', '\_');
            busEsc = strrep(busID, '_', '\_');

            title(sprintf('Velocidad vs Tiempo - %s (Ruta %d) %s %s', ...
                ruta, k, busEsc, fechaEsc), 'Interpreter','none');
            xlabel('Tiempo');
            ylabel('Velocidad (m/s)');
            grid on;
            legend show;
            hold off;
        end
    end
end


        function graficarRutasPorBus(datosBuses, busID, fecha, indicesRuta)
    % Graficar las rutas (trayectorias GPS) de los segmentos para un bus y una fecha

    % Verificar bus
    if nargin < 2 || isempty(busID)
        buses = fieldnames(datosBuses);
        buses(strcmp(buses, 'info')) = [];
    else
        buses = {busID};
    end

    for i = 1:numel(buses)
        bus = buses{i};
        if ~isfield(datosBuses, bus)
            warning('El bus %s no está presente.', bus);
            continue;
        end

        % Seleccionar fechas
        if nargin < 3 || isempty(fecha)
            fechas = fieldnames(datosBuses.(bus));
        else
            fechas = {fecha};
        end

        for j = 1:numel(fechas)
            fechaActual = fechas{j};
            if ~isfield(datosBuses.(bus), fechaActual)
                warning('La fecha %s no está presente para el bus %s.', fechaActual, bus);
                continue;
            end

            if ~isfield(datosBuses.(bus).(fechaActual), 'datosSensorRuta')
                warning('No hay datos de sensor de ruta para %s - %s.', bus, fechaActual);
                continue;
            end
            datosSensorRuta = datosBuses.(bus).(fechaActual).datosSensorRuta;

            % Determinar cuáles rutas (segmentos) graficar
            if nargin < 4 || isempty(indicesRuta)
                indices = 1:size(datosSensorRuta,1);
            else
                indices = indicesRuta;
            end

            figure;
            hold on;
            legendEntries = {};
            colores = lines(length(indices));

            for k = indices
                sensorData = datosSensorRuta{k,2};
                if isempty(sensorData) || ~isfield(sensorData, 'lat') || ~isfield(sensorData, 'lon')
                    continue;
                end
                plot(sensorData.lon, sensorData.lat, '-', 'Color', colores(k,:), 'LineWidth', 1.5);
                if size(datosSensorRuta,2) >= 3 && ~isempty(datosSensorRuta{k,3})
                    leyenda = datosSensorRuta{k,3};
                else
                    leyenda = sprintf('Ruta %d', k);
                end
                legendEntries{end+1} = leyenda;
            end

            xlabel('Longitud');
            ylabel('Latitud');
            title(sprintf('Trayectorias de rutas - Bus %s - Fecha %s', strrep(bus,'_','\_'), strrep(fechaActual,'_','\_')));
            legend(legendEntries, 'Interpreter','none', 'Location', 'best');
            grid on;
            axis equal;
            hold off;
        end
    end
end

function graficarVelocidadPromedioDia(datosBuses, busID, fecha, nombreRutaFiltro)
    % Graficar la velocidad promedio a lo largo del día para una o varias rutas.
    %
    % Parámetros:
    % datosBuses        -> estructura con datos de buses
    % busID (opcional)  -> identificador del bus. Si se omite, usa todos
    % fecha (opcional)  -> fecha específica. Si se omite, usa todas las disponibles
    % nombreRutaFiltro (opcional) -> nombre de ruta específico. Si se omite, usa todas
    %
    % Ejemplo:
    % graficarVelocidadPromedioDia(datosBuses, "bus_4012", "f_03_07_2024", "P60A")

    % -----------------------------
    % Inicialización
    % -----------------------------
    if nargin < 2 || isempty(busID)
        listaBuses = fieldnames(datosBuses);
        listaBuses(strcmp(listaBuses, 'info')) = [];
    else
        if ~isfield(datosBuses, busID)
            error('El bus especificado no existe en los datos.');
        end
        listaBuses = {busID};
    end

    velocidadesTotales = [];
    horasTotales = [];

    % -----------------------------
    % Recorrer buses y fechas
    % -----------------------------
    for i = 1:numel(listaBuses)
        bus = listaBuses{i};
        fechas = fieldnames(datosBuses.(bus));

        if nargin >= 3 && ~isempty(fecha)
            if ~isfield(datosBuses.(bus), fecha)
                warning('La fecha %s no existe para el bus %s.', fecha, bus);
                continue;
            end
            fechas = {fecha};
        end

        for j = 1:numel(fechas)
            fechaActual = fechas{j};

            if ~isfield(datosBuses.(bus).(fechaActual), 'velocidadRuta')
                continue;
            end

            velocidadRuta = datosBuses.(bus).(fechaActual).velocidadRuta;
            datosSensorRuta = datosBuses.(bus).(fechaActual).datosSensorRuta;
            nombresRutas = datosBuses.(bus).(fechaActual).tiempoRuta.Ruta;

            for k = 1:size(velocidadRuta, 1)
                nombreRuta = string(strrep(nombresRutas{k}, '"',''));

                % Filtro opcional por ruta
                if nargin >= 4 && ~isempty(nombreRutaFiltro)
                    if nombreRuta ~= nombreRutaFiltro
                        continue;
                    end
                end

                % Validar existencia de datos
                if isempty(velocidadRuta{k,2}) || isempty(datosSensorRuta{k,2})
                    continue;
                end

                vel = velocidadRuta{k,2}; % Velocidad filtrada
                t = datosSensorRuta{k,2}.time;

                % Asegurar dimensiones consistentes
                n = min(numel(vel), numel(t));
                vel = vel(1:n);
                t = t(1:n);

                % Convertir tiempos a horas del día (0–24)
                horas = hour(t) + minute(t)/60 + second(t)/3600;

                % Filtrar valores no válidos
                mask = ~isnan(vel) & vel > 0 & horas >= 0 & horas <= 24;
                vel = vel(mask);
                horas = horas(mask);

                % Acumular
                velocidadesTotales = [velocidadesTotales; vel];
                horasTotales = [horasTotales; horas];
            end
        end
    end

    % -----------------------------
    % Verificar datos
    % -----------------------------
    if isempty(velocidadesTotales)
        warning('No se encontraron datos válidos para la velocidad.');
        return;
    end

    % -----------------------------
    % Agrupar por hora (promedio y desviación)
    % -----------------------------
    edges = 0:0.25:24; % cada 15 minutos
    [N,~,bin] = histcounts(horasTotales, edges);
    medias = accumarray(bin, velocidadesTotales, [numel(edges)-1, 1], @mean, NaN);
    desv = accumarray(bin, velocidadesTotales, [numel(edges)-1, 1], @std, NaN);
    centros = (edges(1:end-1) + edges(2:end))/2;

    % -----------------------------
    % Graficar
    % -----------------------------
figure; hold on;

% Filtrar valores válidos (sin NaN)
valid = ~isnan(medias) & ~isnan(desv);
centrosValid = centros(valid);
mediasValid = medias(valid);
desvValid = desv(valid);

% Graficar la banda de desviación estándar solo si hay datos válidos
if ~isempty(centrosValid)
    % Asegurar vectores fila del mismo tamaño
    x = [centrosValid(:)', fliplr(centrosValid(:)')];
    y = [ (mediasValid + desvValid)' , fliplr((mediasValid - desvValid)') ];

    % Verificar tamaños iguales antes de graficar
    if numel(x) == numel(y)
        fill(x, y, [0.8 0.9 1.0], 'EdgeColor', 'none', 'FaceAlpha', 0.4);
    else
        warning('Dimensiones inconsistentes entre x e y. No se graficó la banda de desviación.');
    end
end


% Graficar línea promedio
plot(centrosValid, mediasValid, 'b', 'LineWidth', 2);

xlabel('Hora del día');
ylabel('Velocidad promedio (m/s)');

% Título informativo
if exist('nombreRutaFiltro','var') && ~isempty(nombreRutaFiltro)
    titulo = sprintf('Velocidad promedio diaria (%s)', nombreRutaFiltro);
else
    titulo = 'Velocidad promedio diaria (todas las rutas)';
end
title(titulo, 'Interpreter', 'none');

grid on;
xlim([0 24]);
legend('Desviación estándar', 'Promedio', 'Location', 'best');
hold off;
end

function r = iff(cond, a, b)
    if cond, r = a; else, r = b; end
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

        function rutaMapa(datosBuses, paradasStruct, busID, fecha, indiceRuta, nombreRutaFiltro, mostrarNombresParadas)
    % Esta función grafica la ruta de un bus (o varios buses) en una fecha
    % y ruta específicas sobre un mapa con coordenadas geográficas.
    %
    % Parámetros:
    % datosBuses       -> estructura con datos de buses
    % paradasStruct    -> estructura con paradas
    % busID (opcional) -> identificador del bus
    % fecha (opcional) -> fecha específica
    % indiceRuta (opcional) -> índice de ruta
    % nombreRutaFiltro (opcional) -> nombre de ruta a filtrar

    % ---------------------------
    % Si no se pasa busID -> usar todos
    % ---------------------------

    if nargin < 7 || isempty(mostrarNombresParadas)
        mostrarNombresParadas = false; % por defecto no muestra
    end

    if nargin < 3 || isempty(busID)
        listaBuses = fieldnames(datosBuses);
    else
        if ~isfield(datosBuses, busID)
            error('El bus especificado no existe en los datos.');
        end
        listaBuses = {busID};
    end

    % ---------------------------
    % Recorremos los buses
    % ---------------------------
    for i = 1:numel(listaBuses)
        busIDactual = listaBuses{i};

        % Obtener fechas
        if nargin < 4 || isempty(fecha)
            fechas = fieldnames(datosBuses.(busIDactual));
        else
            if ~isfield(datosBuses.(busIDactual), fecha)
                warning('La fecha %s no existe para el bus %s.', fecha, busIDactual);
                continue;
            end
            fechas = {fecha};
        end

        for j = 1:numel(fechas)
            fechaActual = fechas{j};

            % Comprobar si existen datos de la ruta
            if isfield(datosBuses.(busIDactual).(fechaActual), 'datosSensorRuta')
                rutas = datosBuses.(busIDactual).(fechaActual).datosSensorRuta;
                nombresRutas = datosBuses.(busIDactual).(fechaActual).tiempoRuta.Ruta;
            else
                warning('No hay datos de ruta disponibles para %s (%s).', busIDactual, fechaActual);
                continue;
            end

            % Definir los índices de rutas
            if nargin < 5 || isempty(indiceRuta)
                indicesRutas = 1:size(rutas, 1);
            else
                if indiceRuta < 1 || indiceRuta > size(rutas, 1)
                    error('Índice de ruta no válido. Debe estar entre 1 y %d.', size(rutas, 1));
                end
                indicesRutas = indiceRuta;
            end

            for k = indicesRutas
                nombreRuta = strrep(nombresRutas{k}, '"',''); 
                nombreRuta = string(nombreRuta);

                inicioHora = datosBuses.(busIDactual).(fechaActual).tiempoRuta.Inicio_Ruta(k);
                finHora = datosBuses.(busIDactual).(fechaActual).tiempoRuta.Fin_Ruta(k);

                inicioHora = datestr(inicioHora, 'HH:MM');
                finHora = datestr(finHora, 'HH:MM');
                % ---------------------------
                % Filtrar por nombreRutaFiltro (si se da)
                % ---------------------------
                if nargin >= 6 && ~isempty(nombreRutaFiltro)
                    if nombreRuta ~= nombreRutaFiltro
                        continue; % saltar esta ruta
                    end
                end

                % Crear figura
                figure;
                geobasemap('streets-light'); hold on;

                % Obtener coordenadas
                latitudes = rutas{k, 2}.lat;
                longitudes = rutas{k, 2}.lon;

                if isempty(latitudes) || isempty(longitudes)
                    warning('No hay coordenadas para ruta %d en %s (%s).', k, busIDactual, fechaActual);
                    continue;
                end

                % Dibujar ruta
                geoplot(latitudes, longitudes, '-o', 'MarkerSize', 1, 'LineWidth', 0.5, 'Color', 'b');
                geoscatter(latitudes(1), longitudes(1), 100, 'g', 'filled'); % inicio
                geoscatter(latitudes(end), longitudes(end), 100, 'r', 'filled'); % fin

                % Buscar paradas
                idrutas = string({paradasStruct.idruta});  
                idxParada = find(idrutas == nombreRuta, 1);
                if ~isempty(idxParada)
                    stops = paradasStruct(idxParada).stops;
                    if iscell(stops), stops = stops{1}; end
                    if istable(stops) && all(ismember({'lat','lon'}, stops.Properties.VariableNames))
                        latStops = stops.lat;
                        lonStops = stops.lon;
                        geoscatter(latStops, lonStops, 80, 'm', 'filled', '^');
                        if mostrarNombresParadas && ismember('stop_name', stops.Properties.VariableNames)
                            for s = 1:height(stops)
                                text(latStops(s), lonStops(s), string(stops.stop_name(s)), ...
                                    'FontSize', 8, 'Color','k', 'HorizontalAlignment','left');
                            end
                        end
                    end
                end

                % Título
                title(sprintf('Ruta %s #%d del bus %s en %s %s - %s', ...
                    nombreRuta, k, busIDactual, fechaActual, inicioHora, finHora ), 'Interpreter', 'none');
                hold off;
            end
        end
    end
end


function graficarVelocidadMapa(datosBuses, paradasStruct, busID, fecha, indiceRuta, tipoVelocidad, mostrarNombresParadas)
% Graficar mapa de calor de la velocidad (no por segmentos)
% con opción de mostrar paradas sobre la ruta.
%
% datosBuses          -> estructura con datos de buses
% paradasStruct       -> estructura con paradas
% busID               -> identificador del bus
% fecha               -> fecha específica
% indiceRuta          -> índice de ruta (numérico)
% tipoVelocidad       -> 'filtrada', 'original' o 'ambas'
% mostrarNombresParadas -> true/false para mostrar nombres de paradas

    if nargin < 7 || isempty(mostrarNombresParadas)
        mostrarNombresParadas = false;
    end
    if nargin < 6 || isempty(tipoVelocidad)
        tipoVelocidad = 'filtrada';
    end

    % --- Verificaciones básicas ---
    if ~isfield(datosBuses, busID)
        error('El bus especificado no existe en los datos.');
    end
    if ~isfield(datosBuses.(busID), fecha)
        error('La fecha especificada no existe para el bus dado.');
    end

    % --- Extraer datos ---
    datosRuta     = datosBuses.(busID).(fecha).datosSensorRuta;
    velRuta       = datosBuses.(busID).(fecha).velocidadRuta;
    nombresRutas  = datosBuses.(busID).(fecha).tiempoRuta.Ruta;

    if indiceRuta < 1 || indiceRuta > size(velRuta,1)
        error('Índice de ruta fuera de rango.');
    end

    % --- Seleccionar datos de ruta ---
    datosSensor = datosRuta{indiceRuta,2};
    lat = datosSensor.lat(:);
    lon = datosSensor.lon(:);
    tiempos = datosSensor.time(:);

    switch tipoVelocidad
        case 'filtrada'
            velocidad = velRuta{indiceRuta,2};
        case 'original'
            velocidad = velRuta{indiceRuta,5};
        case 'ambas'
            velocidad = velRuta{indiceRuta,2};
            warning('Tipo "ambas": se graficará solo la velocidad filtrada en mapa.');
        otherwise
            error('tipoVelocidad no válido. Use "filtrada", "original" o "ambas".');
    end

    % --- Alinear longitudes ---
    n = min([numel(lat), numel(lon), numel(velocidad)]);
    lat = lat(1:n);
    lon = lon(1:n);
    velocidad = velocidad(1:n);

    % --- Crear figura geográfica ---
    figure;
    geobasemap('streets-light'); hold on;

    % --- Normalizar valores para color ---
    vmin = min(velocidad, [], 'omitnan');
    vmax = max(velocidad, [], 'omitnan');
    cmap = jet(256);
    cidx = round(1 + (velocidad - vmin) / (vmax - vmin) * 255);
    cidx = max(min(cidx,256),1);

    % --- Dibujar la ruta con mapa de calor ---
    h = geoscatter(lat, lon, 15, velocidad, 'filled');


    % --- Añadir colorbar ---
    colormap(jet);
    cb = colorbar;
    cb.Label.String = sprintf('Velocidad (%s)', tipoVelocidad);
    cb.Label.FontSize = 10;

    % Personalizar DataTip
h.DataTipTemplate.DataTipRows(1).Label = 'Latitud';
h.DataTipTemplate.DataTipRows(2).Label = 'Longitud';
h.DataTipTemplate.DataTipRows(3).Label = 'Velocidad (m/s)';

if istable(datosSensor) && ismember('time', datosSensor.Properties.VariableNames)
    % Convertir el datetime a cadena con formato HH:MM
    horasStr = string(datestr(datosSensor.time(1:numel(lat)), 'HH:MM:SS'));
    dtHora = dataTipTextRow('Hora', horasStr);
    h.DataTipTemplate.DataTipRows(end+1) = dtHora;
end

    % --- Añadir paradas ---
    nombreRuta = string(strrep(nombresRutas{indiceRuta}, '"',''));
    idrutas = string({paradasStruct.idruta});
    idxParada = find(idrutas == nombreRuta, 1);

    if ~isempty(idxParada)
        stops = paradasStruct(idxParada).stops;
        if iscell(stops), stops = stops{1}; end
        if istable(stops) && all(ismember({'lat','lon'}, stops.Properties.VariableNames))
            latStops = stops.lat;
            lonStops = stops.lon;

            % Paradas como triángulos magenta
            geoscatter(latStops, lonStops, 80, 'm', 'filled', '^');

            % Mostrar nombres si se pide
            if mostrarNombresParadas && ismember('stop_name', stops.Properties.VariableNames)
                for s = 1:height(stops)
                    text(latStops(s), lonStops(s), string(stops.stop_name(s)), ...
                         'FontSize', 8, 'Color','k', 'HorizontalAlignment','left');
                end
            end
        end
    end

    % --- Marcar inicio y fin de ruta ---
    geoscatter(lat(1), lon(1), 100, 'g', 'filled'); % inicio
    geoscatter(lat(end), lon(end), 100, 'r', 'filled'); % fin

    % --- Título ---
    title(sprintf('Mapa de calor de velocidad - Bus %s (%s) Ruta %s', ...
        busID, fecha, nombreRuta), 'Interpreter','none');

    hold off;
end



function graficarCurvas(datosBuses, busID, fecha, indiceRuta, nombreRutaFiltro)
    % Esta función grafica la ruta filtrada y las curvas detectadas
    % usando la información en datosBuses.trayectoriaFiltrada.
    %
    % Parámetros:
    % datosBuses       -> estructura con datos de buses
    % busID (opcional) -> identificador del bus
    % fecha (opcional) -> fecha específica
    % indiceRuta (opcional) -> índice de ruta
    % nombreRutaFiltro (opcional) -> nombre de ruta a filtrar

    % ---------------------------
    % Si no se pasa busID -> usar todos
    % ---------------------------
    if nargin < 2 || isempty(busID)
        listaBuses = fieldnames(datosBuses);
    else
        if ~isfield(datosBuses, busID)
            error('El bus especificado no existe en los datos.');
        end
        listaBuses = {busID};
    end

    for i = 1:numel(listaBuses)
        busIDactual = listaBuses{i};

        % Fechas
        if nargin < 3 || isempty(fecha)
            fechas = fieldnames(datosBuses.(busIDactual));
        else
            if ~isfield(datosBuses.(busIDactual), fecha)
                warning('La fecha %s no existe para el bus %s.', fecha, busIDactual);
                continue;
            end
            fechas = {fecha};
        end

        for j = 1:numel(fechas)
            fechaActual = fechas{j};

            if ~isfield(datosBuses.(busIDactual).(fechaActual), 'datosSensorRuta')
                warning('No hay datos de ruta disponibles para %s (%s).', busIDactual, fechaActual);
                continue;
            end

            rutas = datosBuses.(busIDactual).(fechaActual).datosSensorRuta;
            nombresRutas = datosBuses.(busIDactual).(fechaActual).tiempoRuta.Ruta;

            if nargin < 4 || isempty(indiceRuta)
                indicesRutas = 1:size(rutas,1);
            else
                if indiceRuta < 1 || indiceRuta > size(rutas,1)
                    error('Índice de ruta no válido.');
                end
                indicesRutas = indiceRuta;
            end

            for k = indicesRutas
                nombreRuta = strrep(nombresRutas{k}, '"','');
                nombreRuta = string(nombreRuta);

                if nargin >= 5 && ~isempty(nombreRutaFiltro)
                    if nombreRuta ~= nombreRutaFiltro
                        continue;
                    end
                end

                % Extraer trayectoria filtrada
                if k > numel(datosBuses.(busIDactual).(fechaActual).trayectoriaFiltrada)
                    warning('No hay trayectoria filtrada para la ruta %d', k);
                    continue;
                end
                tray = datosBuses.(busIDactual).(fechaActual).trayectoriaFiltrada(k);

                if isempty(tray.lat) || isempty(tray.lon)
                    warning('Trayectoria vacía en ruta %d', k);
                    continue;
                end

                % Crear figura
                figure;
                geobasemap('streets-light'); hold on;

                % Dibujar ruta base
                geoplot(tray.lat, tray.lon, '-b', 'LineWidth', 1);
                geoscatter(tray.lat(1), tray.lon(1), 100, 'g', 'filled'); % inicio
                geoscatter(tray.lat(end), tray.lon(end), 100, 'r', 'filled'); % fin

                % Dibujar curvas si existen
                if isfield(tray, 'curvas') && ~isempty(tray.curvas)
                    curvas = tray.curvas;
                    for c = 1:numel(curvas)
                        idx = curvas(c).idx;
                        geoplot(tray.lat(idx), tray.lon(idx), 'r-', 'LineWidth', 2);

                        % centro del círculo
                        [xc, yc, R] = deal(curvas(c).xc, curvas(c).yc, curvas(c).R);
                        theta = linspace(0, 2*pi, 200);
                        latCirc = yc + R*sin(theta); % ojo: depende si usaste lat/lon directo
                        lonCirc = xc + R*cos(theta);
                        geoplot(latCirc, lonCirc, 'g--', 'LineWidth', 1);
                    end
                end

                title(sprintf('Curvas detectadas - Ruta %s #%d (%s)', ...
                    nombreRuta, k, fechaActual), 'Interpreter','none');
                hold off;
            end
        end
    end
end

function graficarDistribucionGenero(datosBuses, campoMetricas, nombreRutaFiltro, tipoDistribucion)
    % Graficar la distribución de un campo (por género), ya sea:
    %   - "empirica"  -> usando ksdensity (densidad suavizada real)
    %   - "teorica"   -> usando media y desviación estándar (gaussiana ideal)
    %
    % Parámetros:
    % datosBuses -> estructura con los datos
    % campoMetricas -> nombre del campo (por ejemplo 'promedioVelocidad')
    % nombreRutaFiltro (opcional) -> nombre de la ruta (si se omite o [], usa todas)
    % tipoDistribucion (opcional) -> 'empirica' (por defecto) o 'teorica'

    if nargin < 3
        nombreRutaFiltro = [];
    end
    if nargin < 4 || isempty(tipoDistribucion)
        tipoDistribucion = "empirica"; % por defecto
    end

    valoresH = [];
    valoresM = [];

    buses = fieldnames(datosBuses);
    for i = 1:numel(buses)
        bus = buses{i};
        if strcmp(bus, 'info')
            continue;
        end

        fechas = fieldnames(datosBuses.(bus));
        for j = 1:numel(fechas)
            fecha = fechas{j};

            if ~isfield(datosBuses.(bus).(fecha), 'segmentos8')
                continue;
            end

            rutas = datosBuses.(bus).(fecha).tiempoRuta.Ruta;
            generos = datosBuses.(bus).(fecha).tiempoRuta.Genero_Conductor;
            segs = datosBuses.(bus).(fecha).segmentos8;

            for k = 1:numel(rutas)
                nombreRuta = strrep(rutas{k}, '"', '');
                nombreRuta = string(nombreRuta);

                % Filtrar por ruta si aplica
                if ~isempty(nombreRutaFiltro) && nombreRuta ~= nombreRutaFiltro
                    continue;
                end

                genero = string(generos{k});
                if isempty(segs{k}) || ~ismember(campoMetricas, segs{k}.Properties.VariableNames)
                    continue;
                end

                datos = segs{k}.(campoMetricas);
                datos = datos(~isnan(datos)); % eliminar NaN

                if genero == "H"
                    valoresH = [valoresH; datos];
                elseif genero == "M"
                    valoresM = [valoresM; datos];
                end
            end
        end
    end

    if isempty(valoresH) && isempty(valoresM)
        warning('No hay datos válidos para graficar la distribución.');
        return;
    end

    % -------------------------------
    % Gráfica
    % -------------------------------
    figure;
    hold on;

    switch lower(tipoDistribucion)
        case "empirica"
            % === Distribución empírica (ksdensity) ===
            if ~isempty(valoresH)
                [fH, xH] = ksdensity(valoresH);
                plot(xH, fH, 'b', 'LineWidth', 2, 'DisplayName', 'Hombres');
            end
            if ~isempty(valoresM)
                [fM, xM] = ksdensity(valoresM);
                plot(xM, fM, 'r', 'LineWidth', 2, 'DisplayName', 'Mujeres');
            end
            tituloTipo = 'Distribución Empírica (ksdensity)';

        case "teorica"
            % === Distribución teórica (media y desviación) ===
            if ~isempty(valoresH)
                muH = mean(valoresH);
                sigmaH = std(valoresH);
            end
            if ~isempty(valoresM)
                muM = mean(valoresM);
                sigmaM = std(valoresM);
            end

            % Eje común
            xMin = min([valoresH; valoresM]);
            xMax = max([valoresH; valoresM]);
            x = linspace(xMin, xMax, 300);

            % Gaussianas teóricas
            if ~isempty(valoresH)
                fH = (1/(sqrt(2*pi)*sigmaH)) * exp(-0.5*((x - muH)/sigmaH).^2);
                plot(x, fH, 'b', 'LineWidth', 2, 'DisplayName', ...
                    sprintf('Hombres (μ=%.2f, σ=%.2f)', muH, sigmaH));
                xline(muH, '--b');
            end
            if ~isempty(valoresM)
                fM = (1/(sqrt(2*pi)*sigmaM)) * exp(-0.5*((x - muM)/sigmaM).^2);
                plot(x, fM, 'r', 'LineWidth', 2, 'DisplayName', ...
                    sprintf('Mujeres (μ=%.2f, σ=%.2f)', muM, sigmaM));
                xline(muM, '--r');
            end
            tituloTipo = 'Distribución Normal Teórica (μ, σ)';

        otherwise
            error('tipoDistribucion debe ser "empirica" o "teorica".');
    end

    % -------------------------------
    % Estilo de la figura
    % -------------------------------
    xlabel(strrep(campoMetricas, '_', '\_'));
    ylabel('Densidad de probabilidad');
    if isempty(nombreRutaFiltro)
        tituloRuta = 'Todas las rutas';
    else
        tituloRuta = sprintf('Ruta %s', nombreRutaFiltro);
    end
    title(sprintf('%s de %s (%s)', tituloTipo, campoMetricas, tituloRuta), 'Interpreter', 'none');
    legend('show', 'Location', 'best');
    grid on;
    hold off;
end


function graficarHistogramaMuestreo(datosBuses)
    % Graficar histograma de la precisión del muestreo (deltaTiempo)
    % usando todos los datos disponibles en datosSensorRuta.
    %
    % Descarta valores NaN, negativos y mayores a 30 s.

    deltaT_todos = [];

    buses = fieldnames(datosBuses);
    for i = 1:numel(buses)
        bus = buses{i};
        if strcmp(bus, 'info')
            continue;
        end

        fechas = fieldnames(datosBuses.(bus));
        for j = 1:numel(fechas)
            fecha = fechas{j};

            if ~isfield(datosBuses.(bus).(fecha), 'datosSensorRuta')
                continue;
            end

            rutas = datosBuses.(bus).(fecha).datosSensorRuta;

            for k = 1:size(rutas, 1)
                if istable(rutas{k, 2}) && ismember('deltaTiempo', rutas{k, 2}.Properties.VariableNames)
                    dT = rutas{k, 2}.deltaTiempo;
                    % Quitar NaN, negativos y valores > 30 s
                    dT = dT(~isnan(dT) & dT > 0 & dT <= 30);
                    deltaT_todos = [deltaT_todos; dT];
                end
            end
        end
    end

    % Si no hay datos válidos, salir
    if isempty(deltaT_todos)
        warning('No se encontraron datos válidos de deltaTiempo.');
        return;
    end

    % Graficar histograma
    figure;
    histogram(deltaT_todos, 50, 'FaceColor', [0.2 0.4 0.7], 'EdgeColor', 'none');
    xlabel('Δt (s)');
    ylabel('Frecuencia');
    title('Histograma de precisión del muestreo (filtrado, Δt ≤ 30 s)');
    grid on;

    % Mostrar estadísticas básicas
    media = mean(deltaT_todos);
    desviacion = std(deltaT_todos);
    texto = sprintf('Media: %.3f s\nDesv.: %.3f s', media, desviacion);
    annotation('textbox', [0.65 0.7 0.3 0.15], 'String', texto, ...
        'FitBoxToText', 'on', 'BackgroundColor', 'w');
end


function graficarSegmentos(datosBuses, busID, fecha, indiceRuta, nombreRutaFiltro, campoHeatmap)
    % Graficar segmentos de recorridos sobre un mapa.
    %
    % Parámetros:
    % datosBuses        -> estructura con datos de buses
    % busID (opcional)  -> identificador del bus
    % fecha (opcional)  -> fecha específica
    % indiceRuta (opcional) -> índice de ruta
    % nombreRutaFiltro (opcional) -> nombre de ruta a filtrar
    % campoHeatmap (opcional) -> nombre de columna en la tabla de segmentos para usar como mapa de calor
    %
    % Si no se pasa campoHeatmap, se usan colores categóricos diferentes para cada segmento.

    if nargin < 2 || isempty(busID)
        listaBuses = fieldnames(datosBuses);
    else
        if ~isfield(datosBuses, busID)
            error('El bus especificado no existe en los datos.');
        end
        listaBuses = {busID};
    end

    for i = 1:numel(listaBuses)
        busIDactual = listaBuses{i};

        if nargin < 3 || isempty(fecha)
            fechas = fieldnames(datosBuses.(busIDactual));
        else
            if ~isfield(datosBuses.(busIDactual), fecha)
                warning('La fecha %s no existe para el bus %s.', fecha, busIDactual);
                continue;
            end
            fechas = {fecha};
        end

        for j = 1:numel(fechas)
            fechaActual = fechas{j};

            if ~isfield(datosBuses.(busIDactual).(fechaActual), 'segmentos')
                warning('No hay segmentos para %s (%s).', busIDactual, fechaActual);
                continue;
            end

            segs = datosBuses.(busIDactual).(fechaActual).segmentos;
            rutas = datosBuses.(busIDactual).(fechaActual).datosSensorRuta;
            nombresRutas = datosBuses.(busIDactual).(fechaActual).tiempoRuta.Ruta;

            if nargin < 4 || isempty(indiceRuta)
                indicesRutas = 1:numel(segs);
            else
                indicesRutas = indiceRuta;
            end

            for k = indicesRutas
                nombreRuta = strrep(nombresRutas{k}, '"','');
                nombreRuta = string(nombreRuta);

                if nargin >= 5 && ~isempty(nombreRutaFiltro)
                    if nombreRuta ~= nombreRutaFiltro
                        continue;
                    end
                end

                tablaSeg = segs{k};
                if isempty(tablaSeg)
                    warning('Segmentos vacíos en ruta %d', k);
                    continue;
                end

                % Crear figura
                figure;
                geobasemap('streets-light'); hold on;

                % Si se pasó campoHeatmap, obtener los valores
                usarHeatmap = (nargin >= 6 && ~isempty(campoHeatmap) ...
                    && ismember(campoHeatmap, tablaSeg.Properties.VariableNames));

                if usarHeatmap
                    valores = tablaSeg.(campoHeatmap);
                    cmap = parula(256);
                    vmin = min(valores, [], 'omitnan');
                    vmax = max(valores, [], 'omitnan');
                else
                    colores = lines(height(tablaSeg)); % colores categóricos
                end

                % Dibujar cada segmento
                for s = 1:height(tablaSeg)
                    tIni = tablaSeg.tiempoInicio(s);
                    tFin = tablaSeg.tiempoFin(s);

                    datosSensor = rutas{k,2};
                    idx = (datosSensor.time >= tIni & datosSensor.time <= tFin);

                    lat = datosSensor.lat(idx);
                    lon = datosSensor.lon(idx);

                    if usarHeatmap
                        val = valores(s);
                        if isnan(val)
                            c = [0.5 0.5 0.5]; % gris si no hay valor
                        else
                            ci = round(1 + (val - vmin) / (vmax - vmin) * 255);
                            ci = max(min(ci,256),1);
                            c = cmap(ci,:);
                        end
                    else
                        c = colores(s,:);
                    end

                    geoplot(lat, lon, '-', 'LineWidth', 2, 'Color', c);
                end

                % Añadir barra de color si es heatmap
                if usarHeatmap
                    colormap(cmap);
                    cb = colorbar;
                    cb.Label.String = campoHeatmap;
                end

                % Título
                title(sprintf('Segmentos - Ruta %s #%d del bus %s en %s', ...
                    nombreRuta, k, busIDactual, fechaActual), 'Interpreter','none');
                hold off;
            end
        end
    end
end



function graficarBarrasSegmentos(datosBuses, nombreRutaFiltro, campoMetricas, filtroGenero, modoAgrupacion)
    % Graficar diagramas de barras agrupados por segmento y conductor.
    %
    % Parámetros:
    % datosBuses          -> estructura completa con los datos
    % nombreRutaFiltro    -> nombre de la ruta a filtrar (string)
    % campoMetricas       -> nombre del campo en los segmentos a graficar (ej. 'promedioVelocidad')
    % filtroGenero (opcional) -> 'M', 'F' o 'ambos' (por defecto 'ambos')
    % modoAgrupacion (opcional) -> 'porSegmento' o 'porConductor' (por defecto 'porSegmento')
    %
    % Ejemplo:
    % graficarBarrasSegmentos(datosBuses, "P60A", "promedioVelocidad", "F", "porConductor")

    % -----------------------------
    % Parámetros por defecto
    % -----------------------------
    if nargin < 4 || isempty(filtroGenero)
        filtroGenero = "ambos";
    end
    if nargin < 5 || isempty(modoAgrupacion)
        modoAgrupacion = "porSegmento";
    end

    % -----------------------------
    % Recolectar datos
    % -----------------------------
    datosGraficos = table();
    buses = fieldnames(datosBuses);

    for i = 1:numel(buses)
        bus = buses{i};
        if strcmp(bus, 'info')
            continue;
        end

        fechas = fieldnames(datosBuses.(bus));
        for j = 1:numel(fechas)
            fecha = fechas{j};

            if ~isfield(datosBuses.(bus).(fecha), 'segmentos8')
                continue;
            end

            rutas = datosBuses.(bus).(fecha).tiempoRuta.Ruta;
            generos = datosBuses.(bus).(fecha).tiempoRuta.Genero_Conductor;
            ids = datosBuses.(bus).(fecha).tiempoRuta.Id;
            segs = datosBuses.(bus).(fecha).segmentos8;

            for k = 1:numel(rutas)
                nombreRuta = strrep(rutas{k}, '"','');
                nombreRuta = string(nombreRuta);

                % Filtro de ruta
                if nombreRuta ~= nombreRutaFiltro
                    continue;
                end

                % Filtro de género
                genero = string(generos{k});
                if filtroGenero ~= "ambos" && genero ~= filtroGenero
                    continue;
                end

                % Excluir conductores no registrados
                idConductor = ids(k);
                if isnumeric(idConductor)
                    if idConductor == 0, continue; end
                elseif ischar(idConductor) || isstring(idConductor)
                    if idConductor == "0" || idConductor == "Conductor no registrado", continue; end
                end

                % Validar estructura de datos
                if isempty(segs{k}) || ~ismember(campoMetricas, segs{k}.Properties.VariableNames)
                    continue;
                end

                % Añadir metadatos
                t = segs{k};
                t.Bus = repmat(string(bus), height(t), 1);
                t.Fecha = repmat(string(fecha), height(t), 1);
                t.Conductor = repmat(string(ids(k)), height(t), 1);
                t.Genero = repmat(genero, height(t), 1);
                t.Ruta = repmat(nombreRuta, height(t), 1);

                datosGraficos = [datosGraficos; t];
            end
        end
    end

    if isempty(datosGraficos)
        warning('No se encontraron datos para la ruta "%s" con el filtro especificado.', nombreRutaFiltro);
        return;
    end

    % -----------------------------
    % Calcular promedios por segmento y conductor
    % -----------------------------
    resumen = groupsummary(datosGraficos, {'nombresSegmentos','Conductor'}, 'mean', campoMetricas);

    % -----------------------------
    % Definir agrupación (eje X y subgrupos)
    % -----------------------------
    switch modoAgrupacion
        case "porSegmento"
            etiquetasX = unique(resumen.nombresSegmentos, 'stable');
            subgrupos = unique(resumen.Conductor, 'stable');
            xlabelX = 'Segmento';
            legendLabel = subgrupos;
            ejePrimario = "nombresSegmentos";
            ejeSecundario = "Conductor";

        case "porConductor"
            etiquetasX = unique(resumen.Conductor, 'stable');
            subgrupos = unique(resumen.nombresSegmentos, 'stable');
            xlabelX = 'Conductor';
            legendLabel = subgrupos;
            ejePrimario = "Conductor";
            ejeSecundario = "nombresSegmentos";

        otherwise
            error('Valor no válido para modoAgrupacion. Use "porSegmento" o "porConductor".');
    end

    % -----------------------------
    % Construir matriz de valores
    % -----------------------------
    matrizValores = NaN(numel(etiquetasX), numel(subgrupos));
    for s = 1:numel(etiquetasX)
        for c = 1:numel(subgrupos)
            mask = strcmp(resumen.(ejePrimario), etiquetasX(s)) & strcmp(resumen.(ejeSecundario), subgrupos(c));
            fila = resumen(mask, :);
            if ~isempty(fila)
                nombreVar = "mean_" + strtrim(campoMetricas);
                matrizValores(s,c) = fila{1, nombreVar};
            end
        end
    end

    % -----------------------------
    % Graficar
    % -----------------------------
    figure;
    bar(matrizValores, 'grouped');
    set(gca, 'XTickLabel', etiquetasX, 'XTickLabelRotation', 45);
    xlabel(xlabelX);
    ylabel(strrep(campoMetricas, '_', '\_'));
    legend(legendLabel, 'Location', 'bestoutside');
    title(sprintf('Comparación %s (%s - %s)', ...
        modoAgrupacion, nombreRutaFiltro, filtroGenero));
    grid on;
end


function graficarBoxplotSegmentos(datosBuses, nombreRutaFiltro, campoMetricas, filtroGenero, modoAgrupacion)
    % Graficar diagramas de cajas y bigotes agrupados solo por segmento o por conductor.
    %
    % Parámetros:
    % datosBuses          -> estructura completa con los datos
    % nombreRutaFiltro    -> nombre de la ruta a filtrar (string)
    % campoMetricas       -> nombre del campo en los segmentos (ej. 'promedioVelocidad')
    % filtroGenero (opcional) -> 'M', 'F' o 'ambos' (por defecto 'ambos')
    % modoAgrupacion (opcional) -> 'porSegmento' o 'porConductor' (por defecto 'porSegmento')
    %
    % Ejemplo:
    % graficarBoxplotSegmentos(datosBuses, "L613", "promedioVelocidad", "H", "porSegmento")

    if nargin < 4 || isempty(filtroGenero)
        filtroGenero = "ambos";
    end
    if nargin < 5 || isempty(modoAgrupacion)
        modoAgrupacion = "porSegmento";
    end

    % -----------------------------
    % Recolectar datos
    % -----------------------------
    datosGraficos = table();
    buses = fieldnames(datosBuses);

    for i = 1:numel(buses)
        bus = buses{i};
        if strcmp(bus, 'info')
            continue;
        end

        fechas = fieldnames(datosBuses.(bus));
        for j = 1:numel(fechas)
            fecha = fechas{j};

            if ~isfield(datosBuses.(bus).(fecha), 'segmentos8')
                continue;
            end

            rutas = datosBuses.(bus).(fecha).tiempoRuta.Ruta;
            generos = datosBuses.(bus).(fecha).tiempoRuta.Genero_Conductor;
            ids = datosBuses.(bus).(fecha).tiempoRuta.Id;
            segs = datosBuses.(bus).(fecha).segmentos8;

            for k = 1:numel(rutas)
                nombreRuta = strrep(rutas{k}, '"','');
                nombreRuta = string(nombreRuta);

                % Filtro de ruta
                if nombreRuta ~= nombreRutaFiltro
                    continue;
                end

                % Filtro de género
                genero = string(generos{k});
                if filtroGenero ~= "ambos" && genero ~= filtroGenero
                    continue;
                end

                % Excluir conductores no registrados
                idConductor = ids(k);
                if isnumeric(idConductor)
                    if idConductor == 0, continue; end
                elseif ischar(idConductor) || isstring(idConductor)
                    if idConductor == "0" || idConductor == "Conductor no registrado", continue; end
                end

                % Validar datos
                if isempty(segs{k}) || ~ismember(campoMetricas, segs{k}.Properties.VariableNames)
                    continue;
                end

                % Añadir metadatos
                t = segs{k};
                t.Bus = repmat(string(bus), height(t), 1);
                t.Fecha = repmat(string(fecha), height(t), 1);
                t.Conductor = repmat(string(ids(k)), height(t), 1);
                t.Genero = repmat(genero, height(t), 1);
                t.Ruta = repmat(nombreRuta, height(t), 1);

                datosGraficos = [datosGraficos; t];
            end
        end
    end

    if isempty(datosGraficos)
        warning('No se encontraron datos para la ruta "%s" con el filtro especificado.', nombreRutaFiltro);
        return;
    end

    % -----------------------------
    % Seleccionar agrupación única
    % -----------------------------
    switch modoAgrupacion
        case "porSegmento"
            grupo = datosGraficos.nombresSegmentos;
            xlabelTexto = 'Segmento';
        case "porConductor"
            grupo = datosGraficos.Conductor;
            xlabelTexto = 'Conductor';
        otherwise
            error('modoAgrupacion debe ser "porSegmento" o "porConductor".');
    end

    % -----------------------------
    % Extraer valores y graficar
    % -----------------------------
    valores = datosGraficos.(campoMetricas);

    figure;
    boxplot(valores, grupo, 'PlotStyle', 'traditional', 'Whisker', 1.5);
    ylabel(strrep(campoMetricas, '_', '\_'));
    xlabel(xlabelTexto);
    title(sprintf('Distribución de %s por %s (%s - %s)', ...
        campoMetricas, xlabelTexto, nombreRutaFiltro, filtroGenero));
    grid on;
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

function velocidadvsdistancia(datosBuses, busID, fecha, indiceRuta, usarP60, mostrarParadas, paradasStruct)

    % Verificar bus
    if ~isfield(datosBuses, busID)
        error('El bus especificado no existe en los datos.');
    end

    % Fechas
    if nargin < 3 || isempty(fecha)
        fechas = fieldnames(datosBuses.(busID));
    else
        if ~isfield(datosBuses.(busID), fecha)
            error('La fecha especificada no existe para el bus dado.');
        end
        fechas = {fecha};
    end

    for j = 1:numel(fechas)
        fechaActual = fechas{j};

        % Comprobar que existan datos
        if ~isfield(datosBuses.(busID).(fechaActual), 'velocidadRuta')
            warning('No hay datos de velocidad para %s.', fechaActual);
            continue;
        end

        rutas = datosBuses.(busID).(fechaActual).datosSensorRuta;
        velocidadRutas = datosBuses.(busID).(fechaActual).velocidadRuta;

        % Índices de ruta
        if nargin < 4 || isempty(indiceRuta)
            indicesRutas = 1:size(velocidadRutas, 1);
        else
            if indiceRuta < 1 || indiceRuta > size(velocidadRutas, 1)
                error('Índice de ruta no válido. Debe estar entre 1 y %d.', size(velocidadRutas, 1));
            end
            indicesRutas = indiceRuta;
        end

        for k = indicesRutas
            % Selección de datos según usarP60
            if usarP60
                % Caso P60
                distancias = (datosBuses.(busID).(fechaActual).segmentoP60{k}.kilometrosOdometro - ...
                              datosBuses.(busID).(fechaActual).segmentoP60{k}.kilometrosOdometro(1));
                velocidad = datosBuses.(busID).(fechaActual).segmentoP60{k}.velocidadVehiculo;
            else
                % Caso datosSensor
                datosSensorRuta = rutas{k,2};
                distancias = datosSensorRuta.distanciaAcum;   % usar distancia acumulada del sensor
                velocidad = velocidadRutas{k,2};

                % Asegurar longitudes iguales
                n = min(length(distancias), length(velocidad));
                distancias = distancias(1:n);
                velocidad = velocidad(1:n);
            end

            % Graficar
            figure; hold on;
            plot(distancias, velocidad, '-', 'LineWidth', 1.5);
            xlabel('Distancia (km)');
            ylabel('Velocidad (m/s)');
            grid on;

            % Marcar paradas con líneas verticales
            if mostrarParadas
                nombreRuta = string(datosBuses.(busID).(fechaActual).tiempoRuta.Ruta{k});
                idrutas = string({paradasStruct.idruta});
                idxParada = find(idrutas == nombreRuta, 1);

                if ~isempty(idxParada)
                    stops = paradasStruct(idxParada).stops;
                    if iscell(stops), stops = stops{1}; end

                    for s = 1:height(stops)
                        % Buscar punto más cercano del bus a la parada
                        latBus = datosSensorRuta.lat;
                        lonBus = datosSensorRuta.lon;
                        dists = arrayfun(@(i) Calculos.geodist(latBus(i), lonBus(i), ...
                                        stops.lat(s), stops.lon(s)), 1:numel(latBus));
                        [~, idxMin] = min(dists);

                        xline(distancias(idxMin), '--r'); % línea vertical
                        if ismember('stop_name', stops.Properties.VariableNames)
                            text(distancias(idxMin), max(velocidad), string(stops.stop_name(s)), ...
                                 'Rotation', 90, 'VerticalAlignment','bottom', 'FontSize',8);
                        end
                    end
                end
            end

            % Título
            title(sprintf('Velocidad vs distancia - Ruta %s (Índice %d) %s %s', ...
                nombreRuta, k, busID, fechaActual), 'Interpreter','none');
        end
    end
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