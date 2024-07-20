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
                filtro = false; % valor por defecto
            end

            % Obtener los campos de los buses
            buses = fieldnames(datosBuses);

            % Iterar sobre cada bus
            for i = 1:numel(buses)
                bus = buses{i};

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

                        % Calcular la velocidad total con o sin filtro
                        if filtro
                            velocidadTotal = Calcular.velocidadConFiltro(datosSensor, 'time', 'lat', 'lon', filtro);
                        else
                            velocidadTotal = Calcular.velocidadSinFiltro(datosSensor, 'time', 'lat', 'lon');
                        end

                        % Convertir la velocidad según las unidades especificadas
                        try
                            velocidadTotal = convvel(velocidadTotal, 'm/s', unidades);
                        catch
                            warning('No se pudo convertir la velocidad a las unidades especificadas: %s.', unidades);
                            continue;
                        end

                        % Almacenar los datos calculados de velocidad en la estructura de datos
                        datosBuses.(bus).(fecha).velocidadTotal = velocidadTotal;
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

    end
end