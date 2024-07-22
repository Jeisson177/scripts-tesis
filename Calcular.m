classdef Calcular
    methods (Static)



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
                case 'media_movil'
                    velocidad = Calcular.velocidadMediaMovil(datos, etiquetaTiempo, etiquetaLatitud, etiquetaLongitud);
                case 'kalman'
                    velocidad = Calcular.velocidadKalman(datos, etiquetaTiempo, etiquetaLatitud, etiquetaLongitud);
                case 'pendiente'
                    velocidad = Calcular.corregirVelocidadPendiente(datos, etiquetaTiempo, etiquetaLatitud, etiquetaLongitud, 3);
                case 'sin_filtro'
                    velocidad = Calcular.velocidadSinFiltro(datos, etiquetaTiempo, etiquetaLatitud, etiquetaLongitud);
                otherwise
                    error('Filtro no reconocido: %s. Use "media_movil", "kalman", "pendiente", "sin_filtro" u otros filtros disponibles.', filtro);
            end
        end


        %%
        function velocidadCorregida = corregirVelocidadPendiente(datos, etiquetaTiempo, etiquetaLatitud, etiquetaLongitud, umbral)
            tiempo = datos.(etiquetaTiempo);
            velocidad = Calcular.velocidadSinFiltro(datos, etiquetaTiempo, etiquetaLatitud, etiquetaLongitud);
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
                        dt = seconds(tiempo(j) - tiempo(i));

                        pendiente = (velocidadCorregida(j) - velocidadCorregida(i)) / dt;
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

        function datosBuses = calcularTiemposRutas(datosBuses, rutas)
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

                    if isempty(datosSensor)
                        continue;
                    end

                    % Inicializar el campo tiempoRuta como una celda vacía
                    datosBuses.(bus).(fecha).tiempoRuta = {};

                    % Iterar sobre cada ruta y calcular los tiempos de ruta
                    rutaNames = fieldnames(rutas);
                    for k = 1:numel(rutaNames)
                        ruta = rutaNames{k};
                        Ida = rutas.(ruta).Ida;
                        Vuelta = rutas.(ruta).Vuelta;

                        % Calcular los tiempos de ruta y almacenar en una celda temporal
                        tiempoRutaTemp = Calculos.Ruta(datosSensor, Ida, Vuelta, 20);

                        % Añadir el nombre de la ruta a cada fila de tiempoRutaTemp
                        nombreRuta = repmat({ruta}, size(tiempoRutaTemp, 1), 1);
                        tiempoRutaTemp = [tiempoRutaTemp, nombreRuta];

                        % Concatenar los resultados en el campo tiempoRuta
                        datosBuses.(bus).(fecha).tiempoRuta = [datosBuses.(bus).(fecha).tiempoRuta; tiempoRutaTemp];
                    end
                end
            end
        end

    end
end