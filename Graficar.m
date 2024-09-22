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
                            
                            
                            if strcmp(datosBuses.bus_4012.f_03_07_2024.tiempoRuta.Sexo,"M") 
                                scatter3(aceleracionesKM,cantidad_aceleraciones,tiempos_positivos,'r');
                                hold on;
                                scatter3(frenadasKM,cantidad_frenadas,tiempos_negativos,'r');
                            elseif strcmp(datosBuses.bus_4012.f_03_07_2024.tiempoRuta.Sexo,"F") 
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
                            
                            if strcmp(datosBuses.bus_4012.f_03_07_2024.tiempoRuta.Sexo,"M") 
                                scatter3(aceleracionesKM,cantidad_aceleraciones,tiempos_positivos,'r');
                                hold on;
                                scatter3(frenadasKM,cantidad_frenadas,tiempos_negativos,'r');
                            elseif strcmp(datosBuses.bus_4012.f_03_07_2024.tiempoRuta.Sexo,"F") 
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
                    velocidades = velocidadRutas{k, 3}; % Velocidades calculadas
                    ruta = velocidadRutas{k, end}; % Nombre de la ruta

                    % Obtener los tiempos asociados a las velocidades
                    datosSensorRuta = datosBuses.(busID).(fechaActual).datosSensorRuta{k, 3}; % Datos del sensor para la ruta
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
                    velocidades = aceleracionRutas{k, 3}; % Velocidades calculadas
                    ruta = aceleracionRutas{k, end}; % Nombre de la ruta

                    % Obtener los tiempos asociados a las velocidades
                    datosSensorRuta = datosBuses.(busID).(fechaActual).datosSensorRuta{k, 3}; % Datos del sensor para la ruta
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


    end
end