classdef Calculos
    methods (Static)
        %%
        function velocidad = calcularVelocidadKH(datos)
            % Asegurarse de que los datos son una tabla
            if ~istable(datos)
                error('La entrada debe ser una tabla.');
            end
            
            % Asumiendo que las columnas son: tiempo, latitud, longitud
            tiempo = datos{:, 1};
            lat = datos{:, 2};
            lon = datos{:, 3};
            
            % Calcular la diferencia de tiempo en segundos
            diferenciaTiempo = seconds(diff(tiempo));
            
            % Preallocating for speed
            velocidad = zeros(size(lat) - [1 0]);
            
            % Calcular la velocidad para cada punto
            for i = 1:length(lat)-1
                distancia = gps_distance(lat(i), lon(i), lat(i+1), lon(i+1));
                velocidad(i) = distancia / (diferenciaTiempo(i)*0.000277778);
            end
            
        end

        %%
        function velocidad = calcularVelocidadMS(datos)
    % Asegurarse de que los datos son una tabla
    if ~istable(datos)
        error('La entrada debe ser una tabla.');
    end
    
    % Asumiendo que las columnas son: tiempo, latitud, longitud
    tiempo = datos{:, 1};
    lat = datos{:, 2};
    lon = datos{:, 3};
    
    % Calcular la diferencia de tiempo en segundos
    diferenciaTiempo = seconds(diff(tiempo));
    
    % Preasignando espacio para la velocidad
    velocidad = zeros(size(lat) - [1 0]);
    
    % Calcular la velocidad para cada punto
    for i = 1:length(lat)-1
        distancia = gps_distance(lat(i), lon(i), lat(i+1), lon(i+1));  % La distancia se obtiene en kilómetros
        velocidad(i) = (distancia * 1000) / diferenciaTiempo(i);  % Convertir la distancia a metros y dividir por el tiempo en segundos
    end
end


        %%
        function aceleracion = calcularAceleracion(datos)
    % Calcular la velocidad en m/s usando la función de velocidad modificada
    velocidad = Calculos.calcularVelocidadMS(datos);
    
    % Asumiendo que las columnas son: tiempo, latitud, longitud
    tiempo = datos{:, 1};
    
    % Calcular la diferencia de tiempo en segundos
    % Nota: Se calcula desde el segundo punto ya que la primera velocidad se calcula entre el primer y segundo punto
    diferenciaTiempo = seconds(diff(tiempo(2:end)));
    
    % Preasignando espacio para la aceleración
    % La longitud de la aceleración será una menos que la de la velocidad, ya que se calcula entre velocidades sucesivas
    aceleracion = zeros(length(velocidad) - 1, 1);
    
    % Calcular la aceleración para cada punto
    for i = 1:length(velocidad)-1
        cambioVelocidad = velocidad(i+1) - velocidad(i);
        aceleracion(i) = cambioVelocidad / diferenciaTiempo(i);  % Aceleración en metros/segundo^2
    end
end
%%
        
        function curvatura = calcularCurvatura(datos)
            % Asegurarse de que los datos son una tabla
            if ~istable(datos)
                error('La entrada debe ser una tabla.');
            end
            
            % Asumiendo que las columnas son: tiempo, latitud, longitud
            lat = datos{:, 2};
            lon = datos{:, 3};
            
            % Preallocating for speed
            curvatura = zeros(size(lat) - [2 0]);  % La curvatura requiere al menos 3 puntos
            
            % Calcular la curvatura para cada conjunto de tres puntos
            for i = 1:length(lat)-2
    p1 = struct('lat', lat(i), 'lon', lon(i));
    p2 = struct('lat', lat(i+1), 'lon', lon(i+1));
    p3 = struct('lat', lat(i+2), 'lon', lon(i+2));
    
    curvatura(i) = determinarCurvatura3Puntos(p1, p2, p3);

    if (curvatura(i) > 100)
        curvatura(i) = -1;  % Ajustar el valor de la curvatura si es necesario
    end
            end
        end
        
        function aceleracion = calcularAceleracion2(datos)
                % Calcular la velocidad usando la función existente
            velocidad = Calculos.calcularVelocidad(datos);

            % Asumiendo que las columnas son: tiempo, latitud, longitud
            tiempo = datos{:, 1};
    
                     % Calcular la diferencia de tiempo en segundos
            diferenciaTiempo = seconds(diff(tiempo(2:end)));  % Se ajusta el tiempo a la longitud de 'velocidad'
    
             % Preallocando para la aceleración
            aceleracion = zeros(size(velocidad) - [1 0]);
    
             % Calcular la aceleración para cada punto
            for i = 1:length(velocidad)-1
                cambioVelocidad = velocidad(i+1) - velocidad(i);
                aceleracion(i) = cambioVelocidad / diferenciaTiempo(i);  % Aceleración en metros/segundo^2
            end
        end
    end
end

function radio = determinarCurvatura3Puntos(p1, p2, p3)
    % Determina la curvatura de una curva definida por tres puntos en un plano cartesiano.
    % :param p1: Coordenadas del primer punto (x, y).
    % :param p2: Coordenadas del segundo punto (x, y).
    % :param p3: Coordenadas del tercer punto (x, y).
    % :return: Radio de curvatura de la curva en metros.
    
    % Calcula las diferencias entre las coordenadas de los puntos adyacentes para obtener las pendientes de las líneas.
    %voy a tomar latitud y y longitud x
    a1 = p1.lat - p2.lat;
    b1 = p2.lon - p1.lon;
    a2 = p2.lat - p3.lat;
    b2 = p3.lon - p2.lon;
    
    % Calcula los puntos medios entre p1 y p2, y entre p2 y p3.
    punto_medio1 = [(p1.lon + p2.lon) / 2, (p1.lat + p2.lat) / 2];
    punto_medio2 = [(p2.lon + p3.lon) / 2, (p2.lat + p3.lat) / 2];
    
    % Construye un sistema de ecuaciones lineales con las pendientes calculadas anteriormente.
    ecu = [b1, -a1; b2, -a2];
    sol = [punto_medio1(1) * b1 - a1 * punto_medio1(2) ; punto_medio2(1) * b2 - a2 * punto_medio2(2)];
    
    %try
        % Intenta resolver el sistema de ecuaciones lineales para encontrar el punto de intersección.
        cordInter = linsolve(ecu, sol);
        % Calcula el radio del círculo que mejor se ajusta a los tres puntos dados.
        radio = sqrt(((cordInter(1) - p2.lon) ^ 2) + ((cordInter(2) - p2.lat) ^ 2)) * (111.32 * 1000);%radio en metros
    %catch
        % Si la solución del sistema de ecuaciones falla, establece el radio como -1.
        %radio = -1;
    %end
end

function d = gps_distance(lat1,lon1,lat2,lon2)
    % Distance in km between 2 gps coordinates in decimals
    dlat = deg2rad(lat1-lat2);
    dlon = deg2rad(lon1-lon2);
    lat1 = deg2rad(lat1); 
    lat2 = deg2rad(lat2);
    % lon1 = deg2rad(lon1); lon2 = deg2rad(lon2); 
    a = (sin(dlat/2).*sin(dlat/2)) + ((cos(lat1).*cos(lat2)).*(sin(dlon/2).*sin(dlon/2)));
    b = 2.*atan2(sqrt(a),sqrt(1-a));
    d = 6371*b; % Earth radius = 6371km o 6371000m
end


