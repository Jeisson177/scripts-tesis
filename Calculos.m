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
            
            
            velocidad=Calculos.corregirV(velocidad,datos);
            
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

        function velocidadCorregida = corregirVelocidad(datos, umbral)
    % Calcular velocidad inicial en m/s
    velocidad = Calculos.calcularVelocidadMS(datos); % Suponemos que esta función devuelve km/h

    % Calcular aceleraciones corregidas usando la función previa
    aceleracion = Calculos.calcularAceleracionFiltrada(datos, umbral);

    % Asumimos que los datos contienen: tiempo, latitud, longitud
    tiempo = datos{:, 1};
    
    % Calcular la diferencia de tiempo en segundos
    diferenciaTiempo = seconds(diff(tiempo));
    
    % Preasignar espacio para la velocidad corregida
    n = length(velocidad);
    velocidadCorregida = zeros(n, 1);
    velocidadCorregida(1) = velocidad(1); % Iniciar con la primera velocidad calculada
    
    % Actualizar las velocidades basándose en la aceleración corregida
    for i = 2:n
        velocidadCorregida(i) = velocidadCorregida(i-1) + aceleracion(i-1) * diferenciaTiempo(i-1);
    end
    
    return;
end

%%

function velocidadCorregida = corregirVelocidad2(datos, aceleracionAjustada, umbral)
    % Asumimos que los datos contienen: tiempo, latitud, longitud
    tiempo = datos{:, 1};    % Extraer columna de tiempo
    
    % Calcular velocidad inicial en m/s
    velocidad = Calculos.calcularVelocidadKH(datos);
    velocidad = velocidad * 0.277778; % Convertir velocidad a m/s
    
    % Preasignar espacio para la velocidad corregida
    n = length(velocidad);
    velocidadCorregida = velocidad;
    
    % Usar aceleración ajustada para corregir la velocidad
    for i = 2:n
        % Ajustar la velocidad en base a la aceleración corregida y el tiempo transcurrido
        dt = seconds(tiempo(i) - tiempo(i-1));
        velocidadCorregida(i) = velocidadCorregida(i-1) + aceleracionAjustada(i-1) * dt;
        
        % Verificar si la velocidad ajustada supera un cierto umbral y corregir si es necesario
        if abs(velocidadCorregida(i)) > umbral
            % Aplicar una corrección. Podría ser una simple limitación al umbral o una regresión si fuera necesario
            velocidadCorregida(i) = sign(velocidadCorregida(i)) * umbral;
        end
    end

    return;
end

%%


function velocidadCorregida = corregirVelocidad3(datos, aceleracionAjustada, umbral, intervaloReinicio)
    tiempo = datos{:, 1};    
    velocidad = Calculos.calcularVelocidadMS(datos);
    velocidadCorregida = velocidad;
    n = length(velocidad);

    for i = 2:n
        dt = seconds(tiempo(i) - tiempo(i-1));
        if mod(i, intervaloReinicio) == 0
            velocidadCorregida(i) = velocidad(i); % Reinicio basado en medición directa
        else
            velocidadCorregida(i) = velocidadCorregida(i-1) + aceleracionAjustada(i-1) * dt;
        end
        
        if abs(velocidadCorregida(i)) > umbral
            velocidadCorregida(i) = sign(velocidadCorregida(i)) * umbral;
        end
    end

    return;
end



%%
        function velocidad=corregirV(velocidad,datos)
            aceleracion = Calculos.calcularAceleracion(Calculos.calcularVelocidadMS(datos),datos);
            for k=1:size(aceleracion)%corrección de velocidad
                try
                    if (abs(aceleracion(k))>2)%determina el limite de aceleración 
                        for b=k:size(aceleracion)
                            if(abs(aceleracion(b))<2)%busca el siguiente punto bueno
                                a=b;
                                break;
                            end
                        end
                        p=((velocidad(b)-velocidad(k-1))/(b-k));
                        z=0;
                        for b=k:a
                            velocidad(b)=(z*p)+velocidad(k-1);
                            z=z+1;
                        end
                        k=a;                
                    end
                catch
                    velocidad=velocidad;
                end
            end
            %[peaks, locs] = findpeaks(aceleracion);
            %picos_mayores_a_2 = peaks > 2;
            %peaks(picos_mayores_a_2);

            %if numel(locs) > 0
             %   velocidad=Calculos.corregirV(velocidad,datos);
            %end
        end


        %%

       
        function velocidadCorregida = corregirVelocidadFiltrada(datos, umbral)
    % Asumimos que los datos contienen: tiempo, latitud, longitud
    tiempo = datos{:, 1};    % Extraer columna de tiempo
    velocidad = Calculos.calcularVelocidadKH(datos); % Calcular velocidad en km/h
    velocidad = velocidad * 0.277778; % Convertir velocidad a m/s
    
    % Calcular la diferencia de tiempo en segundos
    diferenciaTiempo = seconds(diff(tiempo));
    
    % Preasignar espacio para la velocidad corregida
    n = length(velocidad);
    velocidadCorregida = velocidad;
    
    % Iterar sobre los puntos de velocidad
    puntoInicial = 1;
    while puntoInicial < n
        puntoFinal = puntoInicial + 1;
        
        % Buscar el siguiente punto final donde la pendiente esté por debajo del umbral
        while puntoFinal <= n && abs((velocidad(puntoFinal) - velocidad(puntoInicial)) / diferenciaTiempo(puntoFinal-1)) > umbral
            puntoFinal = puntoFinal + 1;
        end
        
        % Si se supera el umbral en el tramo, ajustar la velocidad entre los puntos inicial y final
        if puntoFinal <= n
            % Calcular la pendiente entre el punto inicial y final
            pendiente = (velocidad(puntoFinal) - velocidad(puntoInicial)) / diferenciaTiempo(puntoFinal-1);
            
            % Ajustar la velocidad entre los puntos inicial y final para que la pendiente esté por debajo del umbral
            for i = puntoInicial:puntoFinal-1
                velocidadCorregida(i) = velocidad(puntoInicial) + pendiente * diferenciaTiempo(i-puntoInicial);
            end
        end
        
        % Mover el punto inicial al siguiente punto final
        puntoInicial = puntoFinal;
    end
    
    return;
end

        %%


        function velocidadCorregida = corregirVelocidadPendiente(datos, umbral)
    tiempo = datos{:, 1};    
    velocidad = Calculos.calcularVelocidadMS(datos);
    n = length(velocidad);
    velocidadCorregida = velocidad;
    
    i = 1;
    while i < n - 1
        % Convertir los objetos duration a segundos
        dt = seconds(tiempo(i+1) - tiempo(i));
        
        % Calcular la pendiente entre dos puntos consecutivos
        pendiente = (velocidadCorregida(i+1) - velocidadCorregida(i)) / dt;
        
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
       function aceleracion = calcularAceleracion(velocidad, datos)
    % Asumiendo que las columnas son: tiempo, latitud, longitud
    tiempo = datos{:, 1};
    
    % Calcular la diferencia de tiempo en segundos
    diferenciaTiempo = seconds(diff(tiempo));
    
    % Preasignar espacio para la aceleración
    aceleracion = zeros(length(velocidad) - 1, 1);
    %velocidad=velocidad .* 0.277778;
    
    % Calcular la aceleración para cada punto
    for i = 1:length(aceleracion)
        cambioVelocidad = velocidad(i+1) - velocidad(i);
        if diferenciaTiempo(i) ~= 0
            aceleracion(i) = cambioVelocidad / diferenciaTiempo(i);  % Aceleración en metros/segundo^2
        else
            aceleracion(i) = NaN; % Manejar el caso de división por cero
        end
    end
       end

       %%

       % ccori

       

       %%

       function aceleracion = calcularAceleracion2(velocidad,datos)
    % Calcular la velocidad en m/s usando la función de velocidad modificada

    velocidad = Calculos.calcularVelocidadKH(datos);

    % Asumiendo que las columnas son: tiempo, latitud, longitud
    tiempo = datos{:, 1};

    % Calcular la diferencia de tiempo en segundos
    % Nota: Se calcula desde el segundo punto ya que la primera velocidad se calcula entre el primer y segundo punto
    diferenciaTiempo = seconds(diff(tiempo(2:end)));

    % Preasignando espacio para la aceleración
    % La longitud de la aceleración será una menos que la de la velocidad, ya que se calcula entre velocidades sucesivas
    aceleracion = zeros(length(velocidad) - 1, 1);

    % Calcular la aceleración para cada punto
    for i = 1:length(aceleracion)-1
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
     
        function distancia=CalcularDistancia(datos)
            distancia = zeros(size(datos,1),1);
            distancia(1)=0;
            for a = 2:length(distancia)-1
                distancia(a) = distancia(a-1)+gps_distance(datos.lat(a), datos.lon(a), datos.lat(a+1), datos.lon(a+1));
            end
        end
        
        function direction=detectardireccion(datos)
            lat=datos.lat;
            lon=datos.lon;
            direction = zeros(size(lat) - [1 0]);
            curva=Calculos.calcularCurvatura(datos);
            for i=1:length(lat)-2
                if curva(i)~= -1
                    direction(i)=direccion(lat(i:i+2),lon(i:i+2));
                else
                    direction(i)=0;
                end          
            end
        end
%%
        function velocidadm=maximaVelocidadCurva()
            distancia=Calculos.calcularCurvatura(datosCordenadasSensor);
            velocidad=Calculos.calcularVelocidadKH(datosCordenadasSensor);
            datossss=[distancia,velocidad(2:end)];
            datoF=datossss(datossss(:,1)<50,:);
            datoF=datoF(datoF(:,1)>0,:);
            velocidadm=max(datoF(:, 2));
        end



%%
function aceleracion = calcularAceleracionFiltrada(datos, umbral)
    % Asumimos que los datos contienen: tiempo, latitud, longitud
    % Y que los datos de velocidad ya están calculados o se pueden calcular

    tiempo = datos{:, 1};    % Extraer columna de tiempo
    velocidad = Calculos.calcularVelocidadKH(datos); % Calcular velocidad en km/h
    velocidad = velocidad * 0.277778; % Convertir velocidad a m/s
    
    % Calcular la diferencia de tiempo en segundos
    diferenciaTiempo = seconds(diff(tiempo));
    
    % Preasignar espacio para la aceleración
    n = length(velocidad) - 1;
    aceleracion = zeros(n, 1);
    
    % Calcular la aceleración inicial para cada punto
    for i = 1:n
        cambioVelocidad = velocidad(i+1) - velocidad(i);
        if diferenciaTiempo(i) ~= 0
            aceleracion(i) = cambioVelocidad / diferenciaTiempo(i);
        else
            aceleracion(i) = NaN; % Manejar el caso de división por cero
        end
    end

    % Filtrar y corregir aceleraciones que excedan el umbral
    i = 1;
    while i <= n
        if abs(aceleracion(i)) > umbral
            j = i;
            % Buscar el próximo valor dentro del umbral
            while j <= n && abs(aceleracion(j)) > umbral
                j = j + 1;
            end
            if j <= n
                % Aplicar regresión lineal para rellenar los valores entre i y j
                x = [i-1, j]; % Puntos para la regresión
                y = [aceleracion(i-1), aceleracion(j)]; % Valores de aceleración en esos puntos
                coef = polyfit(x, y, 1); % Coeficientes de la regresión lineal
                for k = i:j-1
                    aceleracion(k) = polyval(coef, k); % Evaluar la regresión en k
                end
            end
            i = j; % Continuar desde el nuevo punto dentro del umbral
        else
            i = i + 1;
        end
    end
    
    % Retornar el vector de aceleración filtrada y corregida
    return;
end

function tiempos = Ruta(datos, puntoInicioFinal, puntoRegreso, distanciaUmbral)
    % Esta función devuelve un array con los tiempos de salida, llegada al punto de regreso,
    % y regreso al punto de inicio para cada viaje.
    
    % Convertir las fechas en 'datos' a datetimes sin zona horaria para la comparación
    datos{:, 1} = datetime(datos{:, 1}, 'TimeZone', '');
    
    % Inicializar variables
    estadoViaje = 0;  % Estado del viaje: 0 = en recarga, 1 = hacia regreso, 2 = regreso a inicio
    tiempos = [];     % Inicializar una matriz para guardar los tiempos de cada viaje
    tiempoRecarga = minutes(1); % Tiempo mínimo de recarga antes de iniciar nueva ruta
    lastTime = datetime('0000-01-01', 'TimeZone', ''); % Inicializar la última hora registrada para comparaciones
    
    % Recorrer todos los datos
    for i = 1:height(datos)
        % Calcular la distancia al punto de inicio/final y al punto de regreso
        distInicioFinal = Calculos.geodist(datos.lat(i), datos.lon(i), puntoInicioFinal(1), puntoInicioFinal(2));
        distRegreso = Calculos.geodist(datos.lat(i), datos.lon(i), puntoRegreso(1), puntoRegreso(2));
        
        % Control de estados según la ubicación del bus
        switch estadoViaje
            case 0  % Bus en recarga
                if distInicioFinal < distanciaUmbral && (isempty(tiempos) || (datos{:, 1}(i) - lastTime > tiempoRecarga))
                    salidaIda = datos{:, 1}(i);
                    estadoViaje = 1;  % Cambiar al estado de viaje hacia el regreso
                end
                
            case 1  % Bus hacia punto de regreso
                if distRegreso < distanciaUmbral
                    llegadaIda = datos{:, 1}(i);
                    salidaVuelta = llegadaIda;
                    estadoViaje = 2;  % Cambiar al estado de regreso al inicio
                end
                
            case 2  % Bus regresando al inicio
                if distInicioFinal < distanciaUmbral
                    llegadaVuelta = datos{:, 1}(i);
                    tiempos = [tiempos; {salidaIda, llegadaIda, llegadaVuelta}];
                    lastTime = llegadaVuelta; % Actualizar la última hora registrada
                    estadoViaje = 0;  % Bus vuelve al estado de recarga
                end
        end
    end
    
    % Comprobar si el último viaje iniciado no ha sido cerrado correctamente
    if estadoViaje == 2
        llegadaVuelta = datos{:, 1}(end);
        tiempos = [tiempos; {salidaIda, llegadaIda, llegadaVuelta}];
    end
end


function d = geodist(lat1, lon1, lat2, lon2)
    % Función para calcular la distancia geodésica entre dos puntos
    R = 6371000; % Radio de la Tierra en metros
    phi1 = deg2rad(lat1);
    phi2 = deg2rad(lat2);
    deltaPhi = deg2rad(lat2 - lat1);
    deltaLambda = deg2rad(lon2 - lon1);
    a = sin(deltaPhi/2) * sin(deltaPhi/2) + cos(phi1) * cos(phi2) * sin(deltaLambda/2) * sin(deltaLambda/2);
    c = 2 * atan2(sqrt(a), sqrt(1-a));
    d = R * c;
end










    end
end
function dir=direccion(latitud,longitud)
    vecAB = [latitud(2:end) - latitud(1:end-1); longitud(2:end) - longitud(1:end-1)];
    vecBC = [latitud(3:end) - latitud(2:end-1); longitud(3:end) - longitud(2:end-1)];
    % Calcular el producto cruzado
    productoCruz= vecAB(1, :) .* vecBC(2, :) - vecAB(2, :) .* vecBC(1, :);
    % Si el producto cruzado es positivo, la curva es hacia la izquierda.
    % Si es negativo, la curva es hacia la derecha.
    % Si es cero, la curva es recta.
    dir=sign(sum(productoCruz));
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
%%
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


%%






