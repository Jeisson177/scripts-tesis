%Datos del telefono
datosSensor = ImportarDatos.Sensor();
datosCordenadasSensor = ImportarDatos.SensorCordenadas(datosSensor);

%Tramas de p20 recolectadas del bus
datosP20 = ImportarDatos.P20();
datosCordenadasP20 = ImportarDatos.P20Cordenadas(datosP20);

% Trama de los eventos del bus
datosEventos = ImportarDatos.Evento19();
[tabla1, tabla2, tabla3, tabla4] = ImportarDatos.Evento19Coordenadas(datosEventos);

%%
myMapaV = Map.FiltrarYDibujarVelocidad(datosCordenadasSensor, '2024-02-15 10:30:00.434', '2024-02-15 11:20:00.434')

%%

% Definir colores y formas para cada código anómalo
colores = {'red', 'blue', 'green', 'yellow'};
formas = {'x', 'o', '^', 's'};
leyenda = {}; % Inicializar un cell array para los textos de la leyenda

nombresLeyenda = {'Código Anómalo 1', 'Código Anómalo 2', 'Código Anómalo 3', 'Código Anómalo 4'};

% Agrupar las tablas en un arreglo de celdas
tablas = {tabla1, tabla2, tabla3, tabla4};

% Iterar sobre cada tabla para agregar marcadores
for i = 1:1
    tablaActual = tablas{i};
    
    % Verificar si la tabla está vacía
    if isempty(tablaActual)
        continue; % Saltar esta iteración si la tabla está vacía
    end

    % Agregar marcadores al mapa para cada tabla
    Map.FiltrarYAgregarMarcadores(tablaActual, '2024-02-14 10:30:00.434', '2024-02-16 11:35:00.434', myMapaV, colores{i}, formas{i});

%Map.AgregarEtiquetasAEventos(tablaActual, myMapaV);

leyenda{end+1} = sprintf('Código Anómalo %d', i);
end


% Dibujar un marcador invisible para cada forma y color y agregarlos a la leyenda
for i = 1:length(colores)
    geoscatter(nan, nan, formas{i}, colores{i}, 'DisplayName', nombresLeyenda{i});
end

% Crear la leyenda
legend('Location', 'best');
hold off;


%%
mygraficaV = Graficas.velocidadTiempo(datosCordenadasSensor, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434');
mygraficaA = Graficas.aceleracionTiempo(datosCordenadasSensor, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434');
mymap = Map.FiltrarYMostrarRuta(datosCordenadasSensor, '2024-02-14 07:30:00.434', '2024-02-16 09:59:00.434');
%%
%Comparacion aceleraciones
mygraficaAc = Graficas.aceleracionTiempo(datosCordenadasSensor, '2024-02-15 9:30:00.434', '2024-02-15 9:35:00.434');
mygraficaAs = Graficas.aceleracionTiempo(datosCordenadasP20, '2024-02-15 9:30:00.434', '2024-02-15 9:35:00.434', mygraficaAc);

%%
Graficas.DistanciavsVelocidad(datosCordenadasSensor,datosCordenadasP20)
%%
mygraficaV = Graficas.velocidadTiempo(datosCordenadasSensor, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434');

mygraficaV2 = Graficas.graficarVelocidadSts(datosP20, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434');

%mygraficaA = Graficas.aceleracionTiempo(datosCordenadasSensor, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434');
%mymap = Map.FiltrarYMostrarRuta(datosCordenadasP20, '2024-02-14 07:30:00.434', '2024-02-16 09:59:00.434');


%%
mymap=Map.FiltrarYDibujarCurvatura(datosCordenadasSensor, '2024-02-15 07:30:00.434', '2024-02-15 08:30:00.434');
%%
mymap=Map.FiltrarYDibujarDireccion(datosCordenadasSensor, '2024-02-15 07:30:00.434', '2024-02-15 08:30:00.434');
%%
velocidadp20 = ImportarDatos.P20Velocidad();
mygraficaV = Graficas.graficarVelocidadSts(velocidadp20, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434');


%%
Graficas.Distanciavstiempo(datosCordenadasSensor,datosCordenadasP20);

%Graficas.aceleracionTiempo(datosCordenadasSensor, '2024-02-15 00:30:00.434', '2024-02-15 23:35:00.434')
%Graficas.velocidadTiempo(datosCordenadasSensor, '2024-02-15 00:30:00.434', '2024-02-15 23:35:00.434')
%mygrafica = Graficas.velocidadTiempo(datosCordenadasP20, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434');
%Graficas.aceleracionTiempo(datosCordenadasP20, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434')
%mymap = Map.FiltrarYMostrarRuta(datosCordenadasP20, '2024-02-14 07:30:00.434', '2024-02-14 07:59:00.434');

%%
datosEventos = ImportarDatos.Evento1();
datosEventosCord = ImportarDatos.Evento1Coordenadas(datosEventos);
Graficas.Evento1(datosEventosCord, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434', mygraficaV)
Graficas.Evento1(datosEventosCord, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434', mygraficaA)

Map.FiltrarYAgregarMarcadores(datosEventosCord, '2024-02-14 07:30:00.434', '2024-02-14 07:59:00.434', mymap)
%%

%mymap = Map.FiltrarYDibujarVelocidad(datosCordenadasSensor, '2024-02-15 08:45:00.434', '2024-02-15 08:49:00.434');
mymap = Map.FiltrarYDibujarCurvatura(datosCordenadasSensor, '2024-02-15 08:00:00.434', '2024-02-15 08:49:00.434');
%%
velocidadSensor = Calculos.calcularVelocidadKH(datosCordenadasSensor);
aceleracion= Calculos.calcularAceleracion(datosCordenadasSensor);
%%
datosP20 = ImportarDatos.P20();
datosCordenadasP20 = ImportarDatos.P20Cordenadas(datosP20);
%mymap = Map.FiltrarYMostrarRuta(datosCordenadasP20, '2024-02-14 07:30:00.434', '2024-02-14 07:59:00.434');
%%
datosEventos = ImportarDatos.Evento1();
datosEventosCord = ImportarDatos.Evento1Coordenadas(datosEventos);
%mymap = Map.FiltrarYAgregarMarcadores(datosEventosCord, '2024-02-14 07:30:00.434', '2024-02-14 07:59:00.434', mymap);


%%
mymap = Map.FiltrarYDibujarVelocidad(datosCordenadasSensor, '2024-02-15 08:45:00.434', '2024-02-15 08:49:00.434');




%%


%aceleracion= Calculos.calcularAceleracion(datosCordenadasSensor);

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


