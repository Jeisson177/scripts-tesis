classdef Calcular
    methods (Static)
        %hola


        %%
        function datosBuses = velocidadTotal(datosBuses, unidades, filtro)
            % Esta función calcula la velocidad total para los datos de sensores de cada bus en cada fecha.
            % La velocidad se puede calcular en kilómetros por hora (kph) o metros por segundo (mps).
            % Un filtro puede ser aplicado si se especifica.

            % Validar la entrada de unidades
            if nargin < 2 || isempty(unidades)
                unidades = 'm/s'; % valor por defecto
            end
            if nargin < 3
                filtro = 'sin_filtro'; % valor por defecto
            end

            % Almacenar la información general de unidades y filtro en la estructura principal
            datosBuses.info.velocidad.unidades = unidades;
            datosBuses.info.velocidad.filtro = filtro;

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

                    % Verificar si existen datos del sensor para la fecha actual
                    if isfield(datosBuses.(bus).(fecha), 'datosSensor')
                        datosSensor = datosBuses.(bus).(fecha).datosSensor;

                        if isempty(datosSensor)
                            continue;
                        end

                        % Calcular la velocidad total con el filtro especificado
                        velocidadTotal = Calcular.velocidadConFiltro(datosSensor, 'time', 'lat', 'lon', filtro);


                        % Convertir la velocidad según las unidades especificadas
                        try
                            if ~strcmp(unidades, 'm/s')
                                velocidadTotal = convvel(velocidadTotal, 'm/s', unidades);
                            end
                        catch
                            warning('No se pudo convertir la velocidad a las unidades especificadas: %s. Se dejará en m/s.', unidades);
                        end

                        % Almacenar los datos calculados de velocidad en la estructura de datos
                        datosBuses.(bus).(fecha).(['velocidadTotal_' strrep(unidades, '/', '_')]) = velocidadTotal;

                        % Mostrar mensaje de confirmación
                        disp(['Procesamiento completado para bus ' bus ' en la fecha ' fecha '.']);

                    end
                end
            end
        end

        %%

        function velocidad = velocidadSinFiltro(datos, etiquetaTiempo, etiquetaLatitud, etiquetaLongitud)
            % Asegurarse de que los datos son una tabla
            if ~istable(datos)
                error('La entrada debe ser una tabla.');
            end

            % Asumiendo que las columnas son: tiempo, latitud, longitud
            tiempo = datos.(etiquetaTiempo);
            lat = datos.(etiquetaLatitud);
            lon = datos.(etiquetaLongitud);

            % Calcular la diferencia de tiempo en segundos
            diferenciaTiempo = seconds(diff(tiempo));

            % Preasignando espacio para la velocidad
            velocidad = zeros(length(lat) - 1, 1);

            % Calcular la velocidad para cada punto
            for i = 1:length(lat) - 1
                % Calcular la distancia en metros usando la función distance de MATLAB
                distancia = distance(lat(i), lon(i), lat(i+1), lon(i+1), wgs84Ellipsoid('meters'));
                velocidad(i) = distancia / diferenciaTiempo(i); % Dividir la distancia en metros por el tiempo en segundos
            end
        end


        %%

        function velocidad = velocidadConFiltro(datos, etiquetaTiempo, etiquetaLatitud, etiquetaLongitud, filtro)
            switch filtro
                case 'pendiente'
                    velocidad = Calcular.corregirVelocidadPendiente(datos, 3);
                case 'sin_filtro'
                    velocidad = Calcular.velocidadSinFiltro(datos, etiquetaTiempo, etiquetaLatitud, etiquetaLongitud);
                otherwise
                    error('Filtro no reconocido: %s. Use "media_movil", "kalman", "pendiente", "sin_filtro" u otros filtros disponibles.', filtro);
            end
        end




        %%

        function velocidadCorregida = corregirVelocidadPendiente(datos, umbral)
            tiempo = datos.time;
            velocidad = Calculos.calcularVelocidadMS(datos);
            n = length(velocidad);
            velocidadCorregida = velocidad;

            i = 1;
            while i < n - 1
                % Convertir los objetos duration a segundos
                dt = seconds(tiempo(i+1) - tiempo(i));

                % Calcular la pendiente entre dos puntos consecutivos
                %%pendiente = (velocidadCorregida(i+1) - velocidadCorregida(i)) / dt;
                pendiente = (velocidad(i+1) - velocidad(i)) / dt;
                % Si la pendiente supera el umbral, encontrar un punto donde no lo haga
                if abs(pendiente) > umbral
                    j = i + 2; % Iniciar con el siguiente punto

                    while j < n && abs(pendiente) > umbral
                        % Convertir los objetos duration a segundos
                        dt = seconds(tiempo(j) - tiempo(j-1));

                        pendiente = (velocidadCorregida(j) - velocidadCorregida(j-1)) / dt;
                        j = j + 1;
                    end

                    % Si encontramos un punto donde la pendiente es menor al umbral
                    if abs(pendiente) <= umbral
                        % Interpolación lineal entre los puntos i y j
                        x = [tiempo(i); tiempo(j)];
                        y = [velocidadCorregida(i); velocidadCorregida(j)];
                        p = polyfit(seconds(x - x(1)), y, 1); % Coeficientes de la regresión lineal
                        t = tiempo(i+1:j-1);
                        velocidadCorregida(i+1:j-1) = polyval(p, seconds(t - x(1))); % Evaluar la regresión lineal

                        % Actualizar el punto inicial y continuar
                        i = j - 1;
                    else
                        % Si no encontramos un punto dentro del umbral, avanzamos al siguiente punto
                        i = i + 1;
                    end
                else
                    % Si la pendiente está dentro del umbral, avanzamos al siguiente punto
                    i = i + 1;
                end
            end

            % Retornar el vector de velocidad corregida
            return;
        end


        %%

        function datosBuses = tiemposRutas(datosBuses, rutas)
            % Esta función calcula todos los tiempos de ruta para los buses en los datos proporcionados
            % y almacena los resultados directamente en la estructura de entrada datosBuses.
            % Las rutas se pasan como un parámetro adicional.

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
                    datosSensor = datosBuses.(bus).(fecha).datosSensor;
                    if isfield(datosBuses, bus) && isfield(datosBuses.(bus), fecha) && isfield(datosBuses.(bus).(fecha), 'P20') ...
                            && istable(datosBuses.(bus).(fecha).P20) && ~isempty(datosBuses.(bus).(fecha).P20)
                        p20 = datosBuses.(bus).(fecha).P20;
                    else
                        warning('El campo P20 no existe para el bus %s en la fecha %s', bus, fecha);
                        continue
                    end

                    try
                    p20 = datosBuses.(bus).(fecha).P20;
                    p20 = sortrows(p20,"fechaHoraLecturaDato","ascend");
                    catch
                        2+2;
                    end

                    if isempty(datosSensor)
                        warning("No se encontraron los datos del telefono para " + bus +  " para el dia " + fecha)
                        continue;
                    end

                    if isempty(p20)
                        warning("No se encontraron los datos P60 " + bus +  " para el dia " + fecha)
                        continue;
                    end

                    % Inicializar el campo tiempoRuta como una tabla vacía con encabezados
                    headers = {'Inicio_Ruta', 'Fin_Ruta', 'Ruta'};
                    datosBuses.(bus).(fecha).tiempoRuta = cell2table(cell(0, 3), 'VariableNames', headers);  % Inicializar tabla vacía



                    for k = 1:numel(rutas)
                        ruta = rutas(k).idruta;

                        % Busca una ruta especifica y retorna todas las
                        % coincidencias
                        tiempoRutaTemp = Calcular.Ruta(p20, rutas(k).stops, 30, .4);

                        % Añadir el nombre de la ruta a cada fila de tiempoRutaTemp
                        nombreRuta = repmat({ruta}, size(tiempoRutaTemp, 1), 1);
                        tiempoRutaTemp = [tiempoRutaTemp, nombreRuta];

                        if isempty(tiempoRutaTemp)
                            continue
                        end
                        % Concatenar los resultados en el campo tiempoRuta
                        datosBuses.(bus).(fecha).tiempoRuta = [datosBuses.(bus).(fecha).tiempoRuta; tiempoRutaTemp];
                    end
                end
            end
        end


        %%
        function tiempos = Ruta(datosP20, paradas, distanciaUmbral, porcentajeMinimoParadas)
            % Esta función devuelve un array con los tiempos de salida, llegada al punto de regreso,
            % y regreso al punto de inicio para cada viaje.

            % Convertir las fechas en 'datosP20' a datetimes sin zona horaria para la comparación
            datosP20{:, 'fechaHoraLecturaDato'} = datetime(datosP20{:, 'fechaHoraLecturaDato'}, 'TimeZone', '');

            % Inicializar variables
            tiempos = [];  % Inicializar una matriz para guardar los tiempos de cada viaje
            estadoViaje = 0;  % 0 = fuera de la ruta, 1 = en la ruta
            paradasVisitadas = false(height(paradas), 1);  % Marcador para saber si se ha pasado por la parada
            ultimoStopSequence = 0;  % Inicializar el último `stop_sequence` visitado
            tiempoRecarga = minutes(1);  % Tiempo mínimo de recarga antes de iniciar una nueva ruta
            lastTime = datetime('0000-01-01', 'TimeZone', '');  % Inicializar la última hora registrada
            inicioRuta = datetime('0000-01-01', 'TimeZone', '');  % Inicializar tiempo de inicio de ruta
            porcentajeVisitadas = 0;

            % Recorrer todos los puntos de datos de p20
            for i = 1:height(datosP20)
                % Obtener la posición actual del bus
                latBus = datosP20.latitud(i);
                lonBus = datosP20.longitud(i);

                % Verificar la distancia a cada parada en orden de `stop_sequence`
                for j = 1:height(paradas)
                    latParada = paradas.lat(j);
                    lonParada = paradas.lon(j);
                    stopSequence = paradas.stop_sequence(j);  % Obtener el stop_sequence actual



                    % Calcular la distancia entre el bus y la parada actual
                    distParada = Calculos.geodist(latBus, lonBus, latParada, lonParada);

                    % Si la distancia es menor que el umbral, se marca como visitada
                    if distParada < distanciaUmbral

                        if porcentajeVisitadas == 0

                            inicioRuta = datosP20.fechaHoraLecturaDato(i);  % Guardar el tiempo de inicio
                        end
                        if ultimoStopSequence > (stopSequence)
                            estadoViaje = 0;
                            paradasVisitadas(:) = false;  % Reiniciar las paradas visitadas para el siguiente viaje
                            ultimoStopSequence = 0;  % Reiniciar el `stop_sequence` para el siguiente viaje

                            if porcentajeVisitadas >= porcentajeMinimoParadas
                                finRuta = datosP20.fechaHoraLecturaDato(i);  % Guardar el tiempo de fin
                                % Registrar el viaje
                                tiempos = [tiempos; {inicioRuta, finRuta}];
                                lastTime = finRuta;  % Actualizar la última hora registrada
                                % Reiniciar el estado del viaje y las paradas visitadas
                                estadoViaje = 0;
                                paradasVisitadas(:) = false;  % Reiniciar las paradas visitadas para el siguiente viaje
                                ultimoStopSequence = 0;  % Reiniciar el `stop_sequence` para el siguiente viaje
                            end

                            inicioRuta = datosP20.fechaHoraLecturaDato(i);  % Guardar el tiempo de inicio
                        end

                        paradasVisitadas(j) = true;  % Marcar la parada como visitada
                        ultimoStopSequence = stopSequence;  % Actualizar el último `stop_sequence` visitado
                    end
                end

                % Verificar si se ha pasado por el porcentaje mínimo de paradas
                porcentajeVisitadas = sum(paradasVisitadas) / height(paradas);

            end
        end



        %%


        function datosBuses = calcularVelocidadPorRutas(datosBuses)
            % Esta función calcula las velocidades para cada ruta de cada bus,
            % basándose en los tiempos de ruta y los datos del sensor.

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

                    % Asegurarse de que existen datos de ruta y datos del sensor para el bus
                    if isfield(datosBuses.(bus).(fecha), 'tiempoRuta') && isfield(datosBuses.(bus).(fecha), 'datosSensor')
                        tiempoRuta = datosBuses.(bus).(fecha).tiempoRuta;
                        datosSensor = datosBuses.(bus).(fecha).datosSensor;

                        % Inicializar el campo velocidadRuta como una celda vacía
                        if ~isfield(datosBuses.(bus).(fecha), 'velocidadRuta') || isempty(datosBuses.(bus).(fecha).velocidadRuta)
                            datosBuses.(bus).(fecha).velocidadRuta = {}; % Inicializar como celda vacía si no existe
                        end

                        % Calcular la velocidad para cada ruta completa (ida y vuelta)
                        for k = 1:size(tiempoRuta, 1)
                            ruta = tiempoRuta{k, end}; % El nombre de la ruta está en la última columna

                            % Trayecto de ida
                            inicioIda = tiempoRuta{k, 1};
                            finIda = tiempoRuta{k, 2};
                            datosIda = datosSensor(datosSensor{:, 'time'} >= inicioIda & datosSensor{:, 'time'} <= finIda, :);
                            velocidadIda = Calcular.velocidadConFiltro(datosIda, 'time', 'lat', 'lon', 'pendiente');

                            % Trayecto de vuelta
                            inicioVuelta = tiempoRuta{k, 2};
                            finVuelta = tiempoRuta{k, 3};
                            datosVuelta = datosSensor(datosSensor{:, 'time'} >= inicioVuelta & datosSensor{:, 'time'} <= finVuelta, :);
                            velocidadVuelta = Calcular.velocidadConFiltro(datosVuelta, 'time', 'lat', 'lon', 'pendiente');

                            % Guardar las velocidades para la ruta
                            tiempoVelocidad = {inicioIda, finVuelta, velocidadIda, velocidadVuelta, ruta};

                            % Concatenar los resultados en el campo velocidadRuta
                            datosBuses.(bus).(fecha).velocidadRuta = [datosBuses.(bus).(fecha).velocidadRuta; tiempoVelocidad];

                            % Mostrar mensaje de confirmación
                            disp(['Velocidades calculadas para la ruta ' ruta ' en el bus ' bus ' en la fecha ' fecha '.']);
                        end
                    else
                        warning("No se encontraron los datos necesarios para calcular las velocidades de las rutas en el bus " + bus + " para el día " + fecha)
                    end
                end
            end
        end

        %%

        function datosBuses = AceleracionPorRutas(datosBuses)
            % Esta función calcula las velocidades para cada ruta de cada bus,
            % basándose en los tiempos de ruta y los datos del sensor.

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

                    % Asegurarse de que existen datos de ruta y datos del sensor para el bus
                    if isfield(datosBuses.(bus).(fecha), 'tiempoRuta') && isfield(datosBuses.(bus).(fecha), 'datosSensor')
                        tiempoRuta = datosBuses.(bus).(fecha).tiempoRuta;
                        datosSensor = datosBuses.(bus).(fecha).datosSensor;

                        % Inicializar el campo velocidadRuta como una celda vacía
                        if ~isfield(datosBuses.(bus).(fecha), 'aceleracionRuta') || isempty(datosBuses.(bus).(fecha).aceleracionRuta)
                            datosBuses.(bus).(fecha).aceleracionRuta = {}; % Inicializar como celda vacía si no existe
                        end

                        % Calcular la velocidad para cada ruta completa (ida y vuelta)
                        for k = 1:size(tiempoRuta, 1)

                            ruta = tiempoRuta{k, end}; % El nombre de la ruta está en la última columna

                            % Trayecto de ida
                            inicioIda = tiempoRuta{k, 1};
                            velocidadIda = datosBuses.(bus).(fecha).velocidadRuta{k, 3};
                            tiempoIda = datosBuses.(bus).(fecha).datosSensorRuta{k, 3}.time;
                            aceleracionIda = Calcular.aceleracion(velocidadIda, tiempoIda);

                            % Trayecto de vuelta
                            finVuelta = tiempoRuta{k, 3};

                            velocidadVuelta = datosBuses.(bus).(fecha).velocidadRuta{k, 4};
                            tiempoVuelta = datosBuses.(bus).(fecha).datosSensorRuta{k, 4}.time;

                            aceleracionVuelta = Calcular.aceleracion(velocidadVuelta, tiempoVuelta);

                            % Guardar las velocidades para la ruta
                            tiempoAceleracion = {inicioIda, finVuelta, aceleracionIda, aceleracionVuelta, ruta};

                            % Concatenar los resultados en el campo velocidadRuta
                            datosBuses.(bus).(fecha).aceleracionRuta = [datosBuses.(bus).(fecha).aceleracionRuta; tiempoAceleracion];

                            % Mostrar mensaje de confirmación
                            disp(['Velocidades calculadas para la ruta ' ruta ' en el bus ' bus ' en la fecha ' fecha '.']);
                        end
                    else
                        warning("No se encontraron los datos necesarios para calcular las velocidades de las rutas en el bus " + bus + " para el día " + fecha)
                    end
                end
            end
        end

        function aceleracion = aceleracion(velocidades, fechas)
            % Función para calcular la aceleración a partir de fechas y velocidades
            % donde la longitud de 'velocidades' es una unidad menos que 'fechas'.

            % Calcular las diferencias de tiempo en segundos, excluyendo el último punto de tiempo
            dt = seconds(diff(fechas(1:end-1))); % Diferencias en tiempo, en segundos

            % Calcular las diferencias de velocidad
            dv = diff(velocidades); % En este caso, no es necesario usar 'diff' ya que ya hay un dato menos

            % Calcular la aceleración (dv/dt)
            aceleracion = dv ./ dt;
        end


        %%

        function resumenRutas = resumenRecorridosPorRuta(datosBuses)
            % Esta función recorre toda la estructura datosBuses y hace un resumen
            % del número de recorridos por cada ruta.

            % Inicializar un contenedor para contar los recorridos por ruta
            resumenRutas = containers.Map('KeyType', 'char', 'ValueType', 'double');  % Especificar tipos de clave y valor

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

                    % Verificar si hay campo tiempoRuta
                    if isfield(datosBuses.(bus).(fecha), 'tiempoRuta') && ~isempty(datosBuses.(bus).(fecha).tiempoRuta)
                        % Obtener la tabla de tiempoRuta
                        tiempoRuta = datosBuses.(bus).(fecha).tiempoRuta;

                        % Iterar sobre cada fila de tiempoRuta
                        for k = 1:size(tiempoRuta, 1)
                            ruta = char(tiempoRuta.Ruta{k});  % Asegurarse de que la ruta sea de tipo 'char'

                            % Incrementar el contador para la ruta actual
                            if isKey(resumenRutas, ruta)
                                resumenRutas(ruta) = resumenRutas(ruta) + 1;
                            else
                                resumenRutas(ruta) = 1;
                            end
                        end
                    end
                end
            end

            % Convertir el contenedor a una tabla para un resumen más claro
            rutas = keys(resumenRutas);
            numRecorridos = values(resumenRutas);

            resumenRutas = table(rutas', cell2mat(numRecorridos)', 'VariableNames', {'Ruta', 'NumeroRecorridos'});
        end



        %%
        function datosBuses = extraerDatosSensorPorRutas(datosBuses)



            % Esta función extrae los datos del sensor para las rutas de cada bus,
            % basándose en los tiempos de ruta.

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

                    % Asegurarse de que existen datos de ruta y datos del sensor para el bus
                    if isfield(datosBuses.(bus).(fecha), 'tiempoRuta') && isfield(datosBuses.(bus).(fecha), 'datosSensor')
                        tiempoRuta = datosBuses.(bus).(fecha).tiempoRuta;
                        datosSensor = datosBuses.(bus).(fecha).datosSensor;

                        % Inicializar el campo datosSensorRuta como una celda vacía
                        if ~isfield(datosBuses.(bus).(fecha), 'datosSensorRuta') || isempty(datosBuses.(bus).(fecha).datosSensorRuta)
                            datosBuses.(bus).(fecha).datosSensorRuta = {}; % Inicializar como celda vacía si no existe
                        end

                        % Extraer los datos del sensor para cada ruta completa (ida y vuelta)
                        for k = 1:size(tiempoRuta, 1)
                            ruta = tiempoRuta{k, end}; % El nombre de la ruta está en la última columna

                            % Trayecto de ida
                            inicioIda = tiempoRuta{k, 1};
                            finIda = tiempoRuta{k, 2};
                            datosIda = datosSensor(datosSensor{:, 'time'} >= inicioIda & datosSensor{:, 'time'} <= finIda, :);

                            % Trayecto de vuelta
                            inicioVuelta = tiempoRuta{k, 2};
                            finVuelta = tiempoRuta{k, 3};
                            datosVuelta = datosSensor(datosSensor{:, 'time'} >= inicioVuelta & datosSensor{:, 'time'} <= finVuelta, :);

                            % Almacenar los datos del sensor extraídos
                            tiempoDatosSensor = {inicioIda, finVuelta, datosIda, datosVuelta, ruta};

                            % Concatenar los resultados en el campo datosSensorRuta
                            datosBuses.(bus).(fecha).datosSensorRuta = [datosBuses.(bus).(fecha).datosSensorRuta; tiempoDatosSensor];

                            % Mostrar mensaje de confirmación
                            disp(['Datos del sensor extraídos para la ruta ' ruta ' en el bus ' bus ' en la fecha ' fecha '.']);
                        end
                    else
                        warning("No se encontraron los datos necesarios para extraer los datos del sensor de las rutas en el bus " + bus + " para el día " + fecha)
                    end
                end
            end
        end


        function datosBuses = iterarSobreBusesYFechas(datosBuses, funcionAplicar)
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


                    try
                        for k = 1:numel(datosBuses.(bus).(fecha).tiempoRuta(:, 1))
                            datosBuses.(bus).(fecha) = funcionAplicar(datosBuses.(bus).(fecha), k);  % Aplicar la función pasada como argumento

                        end
                    catch ME
                        fprintf('Error encontrado: %s\n', ME.message);
                    end

                end
            end
        end
        function datosBuses = calcularKilometroRutasWrapper(datosBuses, k)

            kilometrosOdometro = datosBuses.segmentoP60;
            tiemposRutas = datosBuses.tiempoRuta;

            if isempty(kilometrosOdometro) || isempty(tiemposRutas)
                return;
            end

            % Verificar si las columnas de "Kilometros_Ida" y "Kilometros_Vuelta" ya existen
            if ~ismember('Kilometros_Ida', tiemposRutas.Properties.VariableNames)
                % Agregar columnas vacías con encabezados 'Kilometros_Ida' y 'Kilometros_Vuelta'
                tiemposRutas.Kilometros_Ida = nan(height(tiemposRutas), 1);
                tiemposRutas.Kilometros_Vuelta = nan(height(tiemposRutas), 1);
                datosBuses.tiempoRuta = tiemposRutas; % Actualizar la tabla con las nuevas columnas
            end

            % Calcular y asignar los valores para las nuevas columnas
            try
                datosBuses.tiempoRuta{k, 'Kilometros_Ida'} = datosBuses.segmentoP60{k, 1}.kilometrosOdometro(end) - datosBuses.segmentoP60{k, 1}.kilometrosOdometro(1);
                datosBuses.tiempoRuta{k, 'Kilometros_Vuelta'} = datosBuses.segmentoP60{k, 2}.kilometrosOdometro(end) - datosBuses.segmentoP60{k, 2}.kilometrosOdometro(1);
            catch ME
                fprintf('Error encontrado: %s\n', ME.message);
            end
        end

        function datosBuses = calcularKilometroRutas(datosBuses)
            % Esta función iterará sobre los buses y las fechas para calcular los kilómetros recorridos
            % y agregar las columnas "Kilometros_Ida" y "Kilometros_Vuelta" a la tabla tiempoRuta.

            datosBuses = Calcular.iterarSobreBusesYFechas(datosBuses, @Calcular.calcularKilometroRutasWrapper);
        end



        function datosBuses = ConductoresTemplante(datosBuses)
            % Esta función agrega columnas vacías 'ID_Conductor' y 'Sexo' a la tabla tiempoRuta
            % para cada ruta utilizando la función iterarSobreBusesYFechas.

            % Usar la función iterarSobreBusesYFechas para aplicar el cambio
            datosBuses = Calcular.iterarSobreBusesYFechas(datosBuses, @Calcular.agregarColumnasConductor);
        end

        function datosFecha = agregarColumnasConductor(datosFecha, k)
            % Función auxiliar que agrega las columnas 'ID_Conductor' y 'Sexo' a la tabla tiempoRuta para cada ruta.

            % Verificar si la tabla tiempoRuta existe
            if isfield(datosFecha, 'tiempoRuta')
                % Obtener la tabla tiempoRuta
                tiempoRuta = datosFecha.tiempoRuta;

                % Verificar si las columnas 'ID_Conductor' y 'Sexo' ya existen
                if ~ismember('ID_Conductor', tiempoRuta.Properties.VariableNames)
                    % Agregar columna 'ID_Conductor' vacía (como NaN)
                    tiempoRuta.ID_Conductor = NaN(height(tiempoRuta), 1);  % Columna numérica vacía
                end
                if ~ismember('Sexo', tiempoRuta.Properties.VariableNames)
                    % Agregar columna 'Sexo' vacía (como cadenas vacías)
                    tiempoRuta.Sexo = repmat({''}, height(tiempoRuta), 1);  % Columna de celdas vacía
                end

                % Actualizar las celdas vacías de 'ID_Conductor' y 'Sexo' en la fila correspondiente 'k'
                tiempoRuta.ID_Conductor(k) = NaN;  % Deja la celda vacía (NaN)
                tiempoRuta.Sexo{k} = '';  % Deja la celda vacía (cadena vacía)

                % Actualizar la tabla tiempoRuta en datosFecha
                datosFecha.tiempoRuta = tiempoRuta;
            end
        end


        function [magnitudes_positivas, magnitudes_negativas, tiempos_positivos, tiempos_negativos] = aceleracionPorCuadrosMx(datos)
            % Aplicar el umbral de aceleración
            datos.Acc(abs(datos.Acc) <= 0.3) = 0;

            % Inicializar variables
            intervalo_inicio = 1;
            magnitudes_positivas = [];
            magnitudes_negativas = [];
            tiempos_positivos = [];
            tiempos_negativos = [];

            % Recorrer la señal para identificar intervalos positivos, negativos o 0
            while intervalo_inicio <= length(datos.Acc)
                if datos.Acc(intervalo_inicio) > 0
                    % Buscar el final del intervalo positivo
                    intervalo_fin = find(datos.Acc(intervalo_inicio:end) <= 0, 1) + intervalo_inicio - 2;
                    if isempty(intervalo_fin)
                        intervalo_fin = length(datos.Acc);
                    end
                    altura = max(datos.Acc(intervalo_inicio:intervalo_fin));

                    % Calcular la duración del intervalo
                    duracion = datos.Tiempo(intervalo_fin) - datos.Tiempo(intervalo_inicio);

                    % Guardar magnitud y duración en arreglos separados para intervalos positivos
                    magnitudes_positivas = [magnitudes_positivas; altura];
                    tiempos_positivos = [tiempos_positivos; duracion];

                elseif datos.Acc(intervalo_inicio) < 0
                    % Buscar el final del intervalo negativo
                    intervalo_fin = find(datos.Acc(intervalo_inicio:end) >= 0, 1) + intervalo_inicio - 2;
                    if isempty(intervalo_fin)
                        intervalo_fin = length(datos.Acc);
                    end
                    altura = min(datos.Acc(intervalo_inicio:intervalo_fin));

                    % Calcular la duración del intervalo
                    duracion = datos.Tiempo(intervalo_fin) - datos.Tiempo(intervalo_inicio);

                    % Guardar magnitud y duración en arreglos separados para intervalos negativos
                    magnitudes_negativas = [magnitudes_negativas; altura];
                    tiempos_negativos = [tiempos_negativos; duracion];

                else
                    % Para los valores de 0
                    intervalo_fin = find(datos.Acc(intervalo_inicio:end) ~= 0, 1) + intervalo_inicio - 2;
                    if isempty(intervalo_fin)
                        intervalo_fin = length(datos.Acc);
                    end
                end

                % Actualizar el inicio del siguiente intervalo
                intervalo_inicio = intervalo_fin + 1;
            end

            % Eliminar las últimas 2 muestras de los arreglos
            if length(magnitudes_positivas) > 2
                magnitudes_positivas(end-1:end) = [];
            end

            if length(magnitudes_negativas) > 2
                magnitudes_negativas(end-1:end) = [];
            end

            if length(tiempos_positivos) > 2
                tiempos_positivos(end-1:end) = [];
            end

            if length(tiempos_negativos) > 2
                tiempos_negativos(end-1:end) = [];
            end
        end

        function [tiempo_constante, valor_constante] = aceleracionPorCuadrosProm(datos) %se recbie una tabla con valores Acc y tiempo
            %por ejemplo datos = table(datosBuses.bus_4012.f_03_07_2024.datosSensor.time(6300:10842), datosBuses.bus_4012.f_03_07_2024.aceleracionRuta{1, 3}  , 'VariableNames', {'Tiempo', 'Acc'});
            datos.Acc(abs(datos.Acc)<=0.3)=0;
            % Inicializar variables
            intervalo_inicio = 1;
            tiempo_constante = [];
            valor_constante = [];

            % Recorrer la señal para identificar intervalos positivos, negativos o 0
            while intervalo_inicio <= length(datos.Acc)
                if datos.Acc(intervalo_inicio) > 0
                    % Buscar el final del intervalo positivo
                    intervalo_fin = find(datos.Acc(intervalo_inicio:end) <= 0, 1) + intervalo_inicio - 2;
                    if isempty(intervalo_fin)
                        intervalo_fin = length(datos.Acc);
                    end
                    altura = mean(datos.Acc(intervalo_inicio:intervalo_fin));

                elseif datos.Acc(intervalo_inicio) < 0
                    % Buscar el final del intervalo negativo
                    intervalo_fin = find(datos.Acc(intervalo_inicio:end) >= 0, 1) + intervalo_inicio - 2;
                    if isempty(intervalo_fin)
                        intervalo_fin = length(datos.Acc);
                    end
                    altura = mean(datos.Acc(intervalo_inicio:intervalo_fin));

                else
                    % Para los valores de 0
                    intervalo_fin = find(datos.Acc(intervalo_inicio:end) ~= 0, 1) + intervalo_inicio - 2;
                    if isempty(intervalo_fin)
                        intervalo_fin = length(datos.Acc);
                    end
                    altura = 0; % Asignar 0 cuando el valor es 0
                end

                % Crear la señal constante
                tiempo_constante = [tiempo_constante; datos.Tiempo(intervalo_inicio:intervalo_fin)];
                valor_constante = [valor_constante; repmat(altura, intervalo_fin - intervalo_inicio + 1, 1)];

                % Actualizar el inicio del siguiente intervalo
                intervalo_inicio = intervalo_fin + 1;
            end



        end

        function datosBuses = aceleracionPorCuadrosMaximosRutas(datosBuses)
            datosBuses = Calcular.iterarSobreBusesYFechas(datosBuses, @Calcular.aceleracionPorCuadrosMaximosWraper);
        end
        function datosBuses = aceleracionPorCuadrosMaximosWraper(datosBuses, k)
            print("Holas")
        end

        function datosBuses = aceleracionPorCuadrosPromedio(datosBuses)
            datosBuses = Calcular.iterarSobreBusesYFechas(datosBuses, @Calcular.calcularKilometroRutasWrapper);
        end

        function datosBuses = llenarIndicadoresAceleracion(datosBuses)
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
                        datosSensorRuta = datosBuses.(busName).(subfieldName).datosSensorRuta;  % Acceder a datosSensorRuta
                        numFilas = size(datosSensorRuta, 1);  % Asume que tiene filas como una tabla o matriz

                        for f = 1:numFilas
                            try
                                % Para la ida
                                tiempoIda = datosSensorRuta{f, 3}.time(3:end);
                                AccIda = datosBuses.(busName).(subfieldName).aceleracionRuta{f, 3};
                                datos = table(tiempoIda, AccIda, 'VariableNames', {'Tiempo', 'Acc'});

                                [magnitudes_positivas, magnitudes_negativas, tiempos_positivos, tiempos_negativos] = Calcular.aceleracionPorCuadrosMx(datos);

                                datosBuses.(busName).(subfieldName).tiempoRuta.magnitudes_positivasIda{f} = sum(magnitudes_positivas) / datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Ida(f);
                                datosBuses.(busName).(subfieldName).tiempoRuta.magnitudes_negativasIda{f} = sum(magnitudes_negativas) / datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Ida(f);
                                datosBuses.(busName).(subfieldName).tiempoRuta.cantidad_magnitudes{f} = length(magnitudes_negativas) / datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Ida(f);
                                datosBuses.(busName).(subfieldName).tiempoRuta.tiempos_positivosIda{f} = sum(seconds(tiempos_positivos)) / datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Ida(f);
                                datosBuses.(busName).(subfieldName).tiempoRuta.tiempos_negativosIda{f} = sum(seconds(tiempos_negativos)) / datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Ida(f);
                            catch
                                fprintf('Error procesando la ida para el bus %s en el subcampo %s, fila %d.\n', busName, subfieldName, f);
                            end

                            try
                                % Para la vuelta
                                tiempoVuelta = datosSensorRuta{f, 4}.time(3:end);
                                AccVuelta = datosBuses.(busName).(subfieldName).aceleracionRuta{f, 4};
                                datos = table(tiempoVuelta, AccVuelta, 'VariableNames', {'Tiempo', 'Acc'});

                                [magnitudes_positivas, magnitudes_negativas, tiempos_positivos, tiempos_negativos] = Calcular.aceleracionPorCuadrosMx(datos);

                                datosBuses.(busName).(subfieldName).tiempoRuta.magnitudes_positivasVuelta{f} = sum(magnitudes_positivas) / datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Vuelta(f);
                                datosBuses.(busName).(subfieldName).tiempoRuta.magnitudes_negativasVuelta{f} = sum(magnitudes_negativas) / datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Vuelta(f);
                                datosBuses.(busName).(subfieldName).tiempoRuta.cantidad_magnitudes{f} = length(magnitudes_negativas) / datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Vuelta(f);
                                datosBuses.(busName).(subfieldName).tiempoRuta.tiempos_positivosVuelta{f} = sum(seconds(tiempos_positivos)) / datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Vuelta(f);
                                datosBuses.(busName).(subfieldName).tiempoRuta.tiempos_negativosVuelta{f} = sum(seconds(tiempos_negativos)) / datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Vuelta(f);
                            catch
                                fprintf('Error procesando la vuelta para el bus %s en el subcampo %s, fila %d.\n', busName, subfieldName, f);
                            end
                        end
                    catch
                        fprintf('Error procesando el subcampo %s del bus %s.\n', subfieldName, busName);
                    end
                end
            end
        end



    end
end
