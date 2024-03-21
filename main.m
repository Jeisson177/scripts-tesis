datosSensor = ImportarDatos.Sensor();
datosCordenadasSensor = ImportarDatos.SensorCordenadas(datosSensor);
velocidadSensor = Calculos.calcularVelocidad(datosCordenadasSensor);
%%
datosP20 = ImportarDatos.P20();
datosCordenadasP20 = ImportarDatos.P20Cordenadas(datosP20);

mymap = Map.FiltrarYMostrarRuta(datosCordenadasP20, '2024-02-14 07:30:00.434', '2024-02-14 07:59:00.434');
%%
datosEventos = ImportarDatos.Evento1();
datosEventosCord = ImportarDatos.Evento1Coordenadas(datosEventos);
mymap = Map.FiltrarYAgregarMarcadores(datosEventosCord, '2024-02-14 07:30:00.434', '2024-02-14 07:59:00.434', mymap);
 
%%

mymap = Map.FiltrarYDibujarVelocidad(datosCordenadasSensor, '2024-02-15 08:45:00.434', '2024-02-15 08:49:00.434');

%%
datos = datosSensor;
% Especifica el número de filas y columnas para los subplots
num_filas = ceil(sqrt(numel(datos)));  % Calcula el número de filas
num_columnas = ceil(numel(datos) / num_filas);  % Calcula el número de columnas

num_datos = numel(datos);
max_num_puntos = max(cellfun(@(x) numel(x.time), datos));
velocidades_matriz = cell(num_datos, 1);

aceleraciones_matriz = cell(num_datos, 1);

% Itera sobre cada conjunto de datos en el arreglo
for i = 1:numel(datos)
    % Obtener las coordenadas de latitud y longitud del conjunto de datos actual
    lat = datos{i}.lat;
    lon = datos{i}.lon;
    
    % Calcular la diferencia de tiempo en segundos
    tiempo = datos{i}.time;
    diferencia_tiempo = seconds(diff(tiempo)); % Diferencia de tiempo entre cada punto menos el primero
    
    % vector para almacenar las velocidades
    velocidad = zeros(size(lat));
    curvaturas= zeros(size(lat));
    %guardar datos de tipo lat y lon pa usarlo en la funcion de curvatura
    Coordenada = struct('lat', 0, 'lon', 0);
    p1 = Coordenada;
    p2 = Coordenada;
    p3 = Coordenada;
    % Calcular la velocidad para cada punto
    for j = 2:numel(lat)
        % Calcular la distancia entre los puntos consecutivos
        distancia = gps_distance(lat(j-1), lon(j-1), lat(j), lon(j));
        
        % Calcular la velocidad en grados por segundo
        velocidad(j) = distancia / (diferencia_tiempo(j-1)*0.000277778); % velocidad en m/s o en km/h dependiendo 
        if(velocidad(j)>60)%60 km/h o 16.6667m/s
            velocidad(j)=60;
        end
        
    end
    
    for j=1:numel(lat)-3
       p1.lat=lat(j);
       p2.lat=lat(j+1);
       p3.lat=lat(j+2);
       p1.lon=lon(j);
       p2.lon=lon(j+1);
       p3.lon=lon(j+2);
       
       curvaturas(j)=determinar_curvatura_3puntos(p1, p2, p3);
       if  (curvaturas(j)>100)
           curvaturas(j)=-1;%curvatura negativa es que es muy leve 
       end
    end
    
    
    % Crear una nueva ventana
    figure;
    
    % Trazar el conjunto de datos actual utilizando geoscatter y especificando el tamaño de los puntos basado en la velocidad
    geoscatter(lat(2:end), lon(2:end), [], curvaturas(2:end)); % Excluye el primer punto
    colormap(jet); % Selecciona un mapa de colores (en este caso, un gradiente de colores)
    
    % Agregar título para distinguir los conjuntos de datos
    title(sprintf('Datos %d', i));
    
    % Ajustar la vista
    geolimits('auto');
    
    % Añadir una barra de color para mostrar la escala de velocidad
    colorbar;
    
    % Restaurar el estado de hold para permitir que otras funciones tracen en la misma figura
    hold off;
    
    velocidades_matriz{i} = velocidad;%velocidad en km/h
    velocidades_matriz{i,4}=diferencia_tiempo;
    velocidades_matriz{i,3}=diff(velocidad);%diferencia velocidad
    velocidades_matriz{i,5}=tiempo;
    velocidades_matriz{i,2}=(velocidades_matriz{i,3}./velocidades_matriz{i,4}).*0.277778;%velocidad sobre dif tiempo por constante de km/h a m/s
    velocidades_matriz{i,6}=curvaturas;%arreglo de curvaturas
end

% Agregar título global
%suptitle('Mapas de conjuntos de datos con velocidad calculada');

% Ajustar la posición de los subplots
%set(gcf, 'Position', get(0, 'Screensize')); % Maximizar la ventana

% Restaurar el estado de hold para permitir que otras funciones tracen en la misma figura
%hold off;



%%
%imprimir ambos cosos en un sola figura, cambiar para imprimir en una lado
%velocidad y en otro el radio ambos con mapas de calor

for i=1:numel(datos)
    velocidad=velocidades_matriz{i,1};
    lat = datos{i}.lat;
    lon = datos{i}.lon;
    
    % Crear una nueva figura con dos subgráficos
    figure;

    % Primer subgráfico
    subplot(1,2,1); % Define la disposición de subgráficos como 1 fila, 2 columnas, y selecciona el primero
    geoscatter(lat(2:end), lon(2:end), [], velocidad(2:end)); % Excluye el primer punto
    colormap(jet); % Selecciona un mapa de colores (en este caso, un gradiente de colores)
    j=i+1;
    title('figura ruta desde las ',j); % Título del primer subgráfico
    geolimits('auto'); % Ajustar la vista automáticamente
    colorbar; % Añadir una barra de color para mostrar la escala de velocidad

    % Segundo subgráfico
    subplot(1,2,2); % Define la disposición de subgráficos como 1 fila, 2 columnas, y selecciona el segundo
    
    
    hora_inicio = datetime(2024,2,14,j-1,0,0); % Hora de inicio
    hora_fin = datetime(2024,2,14,j,0,0); % Hora de fin,como los datos del celular son de una hora a otra pues aja
    
    datos_en_rango = sts(sts.fechaHoraEnvioDato >= hora_inicio & sts.fechaHoraEnvioDato <= hora_fin, :);
    lat2=datos_en_rango.latitud;
    lon2=datos_en_rango.longitud;
    velocidad2=datos_en_rango.velocidadVehiculo;
    geoscatter(lat2, lon2, [], velocidad2); % Trazar todos los datos
    colormap(jet); % Selecciona un mapa de colores (en este caso, un gradiente de colores)
    title('datos sts'); % Título del segundo subgráfico
    geolimits('auto'); % Ajustar la vista automáticamente
    colorbar; % Añadir una barra de color para mostrar la escala de velocidad

end
%%
%pruebas
subplot(3, 2, 5);
plot(velocidades_matriz{3,5},velocidades_matriz{3, 1});
grid on;
subplot(3, 2, 6);
plot(velocidades_matriz{3,5}(2:end),velocidades_matriz{3, 2});
grid on;

%%
%recalculo de aceleración

for i=1:16
    velocidad =velocidades_matriz{i} ;%velocidad en km/h
    velocidades_matriz{i,3}=diff(velocidad);%diferencia velocidad
    velocidades_matriz{i,2}=(velocidades_matriz{i,3}./velocidades_matriz{i,4}).*0.277778;%velocidad sobre dif tiempo por constante de km/h a m/s
end
%%
%correción de velocidad

for j = 1:16%cantidad de archivos txt
    for k = 1:numel(velocidades_matriz{j, 2})%columna de aceleraciones sobre tiempo
        
        try
            if (abs(velocidades_matriz{j, 2}(k))>2)%determina el limite de aceleración 
                for b=k:numel(velocidades_matriz{j, 2})
                    if(abs(velocidades_matriz{j, 2}(b))<2)%busca el siguiente punto bueno
                        a=b;
                        break;
                    end
                end
                p=((velocidades_matriz{j, 1}(b)-velocidades_matriz{j, 1}(k-1))/(b-k));
                z=1;
                for b=k:a
                    velocidades_matriz{j, 1}(b)=(z*p)+velocidades_matriz{j, 1}(k-1);
                    z=z+1;
                end
                %velocidades_matriz{j, 1} =correccion(velocidades_matriz,j,k); %se igual a la velocidad normal
                k=a;
                for i=1:16%recalcular aceleración
                    velocidad =velocidades_matriz{i} ;%velocidad en km/h
                    velocidades_matriz{i,3}=diff(velocidad);%diferencia velocidad
                    velocidades_matriz{i,2}=(velocidades_matriz{i,3}./velocidades_matriz{i,4}).*0.277778;%velocidad sobre dif tiempo por constante de km/h a m/s
                end
            end
        catch
            velocidades_matriz{j, 1}=velocidades_matriz{j, 1};
        end
        
    end
    
end
%velocidades_matriz{i,2}=(velocidades_matriz{i,3}./velocidades_matriz{i,4}).*0.277778;%velocidad sobre dif tiempo por constante de km/h a m/s
    


function matriz_corregida=correccion(velocidades_matriz,j,k)
    for a=k:numel(velocidades_matriz{j, 2})
        
        
    end 
    
    
    
    matriz_corregida = velocidades_matriz{j, 1}; % Devuelve la matriz modificada
end

%%
%codigo para ver que pasa con los datos, primero grafique los datos con el
%codigo anterior, luego vi que en datos 14 hay varios puntos rojos mayores
%a 60km/h, estos datos son unicos, por ende no son fisicamente posibles asi
%que 
% tiempo = datos{14}.time;
% diferencia_tiempo = seconds(diff(tiempo));
% b=1;
% lat = datos{14}.lat;
% lon = datos{14}.lon;
% raros=zeros(numel(tiempo));
  
% for a=2:numel(tiempo)
%     distancia = gps_distance(lat(a-1), lon(a-1), lat(a), lon(a));
%     
%     vel=distancia / (diferencia_tiempo(a-1)*0.000277778);
%     if(vel>55)
%               
%         % Calcular la velocidad en grados por segundo
%         raros(b,6)= gps_distance(lat(a), lon(a), lat(a+1), lon(a+1));
%         raros(b,5)= gps_distance(lat(a-2), lon(a-2), lat(a-1), lon(a-1));
%         raros(b,4)= distancia;
%         raros(b,3)= vel; 
%         raros(b)=diferencia_tiempo(a-1);
%         raros(b,2)=a-1;
%         b=b+1;
%     end
%     
% end
% raros(1,8)=gps_distance(lat(50), lon(50), lat(51), lon(51));  

%%

% 
% lat = datos{1,12}.lat;
% lon = datos{1,12}.lon;
% tiempo = datos{1,12}.time;
% diferencia_tiempo = seconds(diff(tiempo)); % Diferencia de tiempo entre cada punto menos el primero
% % vector para almacenar las velocidades
% velocidad = zeros(size(lat));
% % Calcular la velocidad para cada punto
% for j = 2:numel(lat)
%         % Calcular la distancia entre los puntos consecutivos
%     distancia = gps_distance(lat(j-1), lon(j-1), lat(j), lon(j));
%         
%         % Calcular la velocidad en grados por segundo
%     velocidad(j) = distancia / (diferencia_tiempo(j-1)*0.000277778); % Excluye el primer punto
% end
% 
% plot(tiempo,velocidad);


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

function radio = determinar_curvatura_3puntos(p1, p2, p3)
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


