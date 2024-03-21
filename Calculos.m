classdef Calculos
    methods (Static)
        function velocidad = calcularVelocidad(datos)
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
                velocidad(i) = distancia / (diferenciaTiempo(i)*0.000277778);  % Velocidad en metros/segundo
            end
        end
        
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
                p1 = [lat(i), lon(i)];
                p2 = [lat(i+1), lon(i+1)];
                p3 = [lat(i+2), lon(i+2)];
                
                curvatura(i) = determinarCurvatura3Puntos(p1, p2, p3);
            end
        end
    end
end

function curvatura = determinarCurvatura3Puntos(p1, p2, p3)
    % Esta es una función auxiliar para calcular la curvatura dado tres puntos
    % Debes implementar este cálculo según tus necesidades específicas
    % Por ejemplo, puedes usar el radio de curvatura basado en el círculo osculador

    % Cálculo ficticio de curvatura como ejemplo
    curvatura = rand();  % Reemplazar con tu propio cálculo de curvatura
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

