%% Segmentación de las rutas
Ruta4104Ida = [0.85, 2.1, 4.1, 4.5, 5.2, 8.0, 8.6, 10.5, 13.9];
Ruta4104Vuelta = [1.18, 2.1, 3.5, 5.2, 10.2, 11.9, 13.5];


Ruta4020Ida = [2.3, 8.1, 11.9, 12.9, 14.8, 19.25];
Ruta4020Vuelta = [2.04, 5.1, 8.6, 11.13, 14.65, 19.44];



Sexo4104 = ['H', 'H', 'M', 'M', 'M', 'M'];

Ida4020 = [4.593216, -74.178910];
Vuelta4020 = [4.6096941, -74.0738544];

Ida4104 = [4.587917000000000, -74.149976900000000];
Vuelta4104 = [4.562243400000000, -74.083503800000000];

%% importar solo un dato
% Sensor=ImportarDatos.Sensor('Datos\2024-04-16\4104');
% datosCordenadasSensor=ImportarDatos.SensorCordenadas(Sensor);
% tiempoR=Calculos.Ruta(datosCordenadasSensor,Ida4104,Vuelta4104,20);
% T=size(tiempoR);
Ccurvas1=Calculos.Lcurvasida4020();
Ccurvas2=Calculos.LcurvasVuelta4020();
Ccurvas3=Calculos.Lcurvasida4104();
Ccurvas4=Calculos.LcurvasVuelta4104();
% for i=1:T(1)
% array(:,i)=Calculos.riesgoCurva2(datosCordenadasSensor,tiempoR{i,2},tiempoR{i,3},Ccurvas);
% end
% for i=1:T(1)
%     m{i}=Map.Ruta(datosCordenadasSensor,tiempoR{i,1},tiempoR{i,2},'r','ida','ida');
%     m2{i}=Map.Ruta(datosCordenadasSensor,tiempoR{i,2},tiempoR{i,3},'b','vuelta','vuelta');
%     
% end
%% Importar todos los datos tomados por el movil

datosBuses = ImportarDatos.importarTodosLosDatos('Datos');


%% Calculo de todos los tiempos para cada ruta

datosBuses = Calculos.calcularTiemposRutas(datosBuses);

%% calcula la velocidad

datosBuses = Calculos.calcularVelocidadRutas(datosBuses);

%%

datosBuses = Calculos.extraerP60(datosBuses);

%% Calcula los promedios por segmentos

datosBuses = Calculos.calcularPromedioVelocidadRutas(datosBuses);

%% Organiza la estructura por bus y ruta

Buses = ImportarDatos.reorganizarDatosBuses(datosBuses);


%%

generarDatos(Buses.bus_4020.ida.f_2024_04_15.("Hora Inicio")(1), Buses.bus_4020.ida.f_2024_04_15.("Hora Fin")(1), '4020', 'ida');

%%
generarDatos(Buses.bus_4020.ida.f_2024_04_15.("Hora Inicio")(2), Buses.bus_4020.ida.f_2024_04_15.("Hora Fin")(2), '4020', 'ida');
generarDatos(Buses.bus_4020.ida.f_2024_04_15.("Hora Inicio")(3), Buses.bus_4020.ida.f_2024_04_15.("Hora Fin")(3), '4020', 'ida');

%%

Calculos.ordenarTablaPorElementoVector(Buses.bus_4020.ida.General, 'Promedio velocidad', 1, 'ascend' );


%%

procesarRutas(Buses);


%% Reorganiza los tiempos

tiemposRutasShufle = Calculos.reorganizarDatosPorBus(tiemposRutas);
%% poner las curvas de ida y venida para semana 1 para ambos buses
Cida4020=Calculos.Lcurvasida4020();
Cretorno4020=Calculos.LcurvasVuelta4020();
Cida4104=Calculos.Lcurvasida4104();
Cretorno4104=Calculos.LcurvasVuelta4104();


%% Recorrer todo

fechas = fieldnames(tiemposRutas);  % Obtiene todos los campos de fecha

% Iterar sobre cada fecha
for i = 1:length(fechas)
    fecha = fechas{i};  % fecha actual en el ciclo
    buses = fieldnames(tiemposRutas.(fecha));  % Obtiene todos los buses para la fecha actual
    if fecha<='2024-04-20'
        break;%se rompe cuando acaba semana 1
    end
    % Iterar sobre cada bus para la fecha actual
    for j = 1:length(buses)
        bus = buses{j};  % bus actual en el ciclo
        busNumber = strrep(bus, 'bus', '');  % Eliminar el prefijo 'bus'
        rutas = tiemposRutas.(fecha).(bus);  % Matriz de celdas con rutas para el bus actual
        if busNumber=='4020'
            ida=Cida4020;
            vuelta=Cretorno4020;
        elseif busNumber=='4104'
            ida=Cida4104;
            vuelta=Cretorno4104;
        end
        % Comprobar que la variable contiene una matriz de celdas
        if iscell(rutas)
            % Iterar sobre cada fila de la matriz de celdas (cada ruta)
            for k = 1:size(rutas, 1)
                inicio = rutas{k, 1};  % Hora de inicio
                retorno = rutas{k, 2}; % Hora de llegada al punto de retorno
                fin = rutas{k, 3};     % Hora de llegada al punto de inicio

                % Ejecutar para Ida usando la hora de inicio
                generarDatos(inicio, retorno, busNumber, 'Ida');
                % Convertir las fechas de inicio y final a formato datetime

fechaInicioDT = datetime(inicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
fechaFinalDT = datetime(retorno, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');

% Extraer la fecha y hora de inicio y final para el título
fechaArchivo = datestr(fechaInicioDT, 'yyyy-mm-dd');
horaInicio = datestr(fechaInicioDT, 'HH:MM:SS');
horaFinal = datestr(fechaFinalDT, 'HH:MM:SS');


% Rutas para datos del teléfono y P20
rutaSensor = fullfile('Datos', fechaArchivo, strrep(busNumber, 'bus_', ''));
datosSensor = ImportarDatos.Sensor(rutaSensor);
datosCordenadasSensor = ImportarDatos.SensorCordenadas(datosSensor);

                
                arrayI(:,k){i,j}=Calculos.riesgoCurva2(datosCordenadasSensor,inicio,retorno,ida);
 
                
                % Ejecutar para Vuelta usando la hora de retorno como inicio
               
                generarDatos(retorno, fin, busNumber, 'Vuelta');
                
                fechaInicioDT = datetime(retorno, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
fechaFinalDT = datetime(fin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');

% Extraer la fecha y hora de inicio y final para el título
fechaArchivo = datestr(fechaInicioDT, 'yyyy-mm-dd');
horaInicio = datestr(fechaInicioDT, 'HH:MM:SS');
horaFinal = datestr(fechaFinalDT, 'HH:MM:SS');
rutaSensor = fullfile('Datos', fechaArchivo, strrep(busNumber, 'bus_', ''));
datosSensor = ImportarDatos.Sensor(rutaSensor);
datosCordenadasSensor = ImportarDatos.SensorCordenadas(datosSensor);

arrayV(:,k){i,j}=Calculos.riesgoCurva2(datosCordenadasSensor,retorno,fin,vuelta);
 
                disp(['Ruta ', num2str(k), ' del bus ', busNumber, ' en la fecha ', fecha, ' procesada.']);
            end
        else
            disp(['El bus ', bus, ' en la fecha ', fecha, ' no contiene una matriz de celdas con datos.']);
        end
    end
end





%% Importar datos para un día en especifico
datosSensor = ImportarDatos.Sensor("Datos\2024-04-15\4020");% Importar los datos del telefono
datosCordenadasSensor = ImportarDatos.SensorCordenadas(datosSensor);%Importar coordenadas y stampas de tiempo del telefono

%%

tiemposViaje = Calculos.Ruta(datosCordenadasSensor, Ida4104, Vuelta4104, 20);

%% Prueba para probar la generacion

generarDatos('2024-04-16 3:31:23.434', '2024-04-16 4:34:00.434', '4104', 'Ida')

%%
%Tramas de p20 recolectadas del bus
datosP20 = ImportarDatos.P60("Datos\2024-04-15\4020\log");

%%
% Trama de los eventos del bus
datosEventos = ImportarDatos.Evento19();
[tabla1, tabla2, tabla3, tabla4] = ImportarDatos.Evento19Coordenadas(datosEventos);


%% Graficar ruta
HoraInicio = '2024-04-16 3:31:23.434';
HoraFinal  = '2024-04-16 4:34:00.434';

mis = Map.Ruta(datosCordenadasSensor, HoraInicio, HoraFinal, 'b-')
mis = Map.Ruta(datosCordenadasSensor, HoraFinal, '2024-04-16 6:20:45.434','r-', mis)


%%
% Verificar si hay datos en tiemposViaje
if isempty(tiemposViaje)
    disp('No hay datos suficientes para dibujar rutas.');
else
    % Bucle sobre cada fila en tiemposViaje para dibujar las rutas en mapas individuales
    for i = 1:size(tiemposViaje, 1)
        HoraInicio = tiemposViaje{i, 1};  % Tiempo de inicio del viaje
        HoraRetorno = tiemposViaje{i, 2};  % Tiempo de llegada al punto de retorno
        HoraFinal = tiemposViaje{i, 3};   % Tiempo de regreso al inicio
        
        % Crear un nuevo mapa para cada viaje
        mapa = Map.Ruta(datosCordenadasSensor, HoraInicio, HoraRetorno, 'b-'); % Azul para la ida
        
        % Dibujar el trayecto de regreso al inicio en el mismo mapa
        mapa = Map.Ruta(datosCordenadasSensor, HoraRetorno, HoraFinal, 'r-', mapa); % Rojo para la vuelta
    end
end


%% Mapa de calor velocidad
myMapaV = Map.Velocidad(datosCordenadasSensor, HoraInicio, HoraFinal);

%% Graficar segmentos de ruta en mapa
myMapaV = Map.MarcadoresEspeciales(datosCordenadasSensor, HoraInicio, HoraFinal, myMapaV, 'x', Ruta4020);

%% Grafica de velocidad vs tiempo
mygraficaV = Graficas.velocidadTiempoCorregida(datosCordenadasSensor, HoraInicio, HoraFinal);

%% Grafica distancia vs velocidad
Graficas.DistanciavsVelocidad3(datosCordenadasSensor, datosCordenadasP20, HoraInicio, HoraFinal, Ruta4020);

%% Graficar eventos 19 en el mapa

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
    Map.Marcadores(tablaActual, '2024-02-14 10:30:00.434', '2024-02-16 11:35:00.434', myMapaV, colores{i}, formas{i});
    
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


%% Comparativa velocidad original y velocidad corregida

mygraficaV = Graficas.velocidadTiempo(datosCordenadasSensor, '2024-02-15 0:30:00.434', '2024-02-15 23:35:00.434');
mygraficaV = Graficas.velocidadTiempoCorregida(datosCordenadasSensor, '2024-02-15 0:30:00.434', '2024-02-15 23:35:00.434', mygraficaV);


%% Comparativa aceleracion original y aceleración corregida
Graficas.analizarAceleraciones(datosCordenadasSensor, '2024-02-15 0:30:00.434', '2024-02-15 23:35:00.434')
mygraficaA = Graficas.aceleracionTiempo(datosCordenadasSensor, '2024-02-15 9:30:00.434', '2024-02-15 9:35:00.434');


%% comparativa, velocidad del sts y velocidad del celular
mygraficaV = Graficas.velocidadTiempo(datosCordenadasSensor, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434');

mygraficaV2 = Graficas.graficarVelocidadSts(datosP20, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434');

%mygraficaA = Graficas.aceleracionTiempo(datosCordenadasSensor, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434');
%mymap = Map.FiltrarYMostrarRuta(datosCordenadasP20, '2024-02-14 07:30:00.434', '2024-02-16 09:59:00.434');


%% Muetra las curvaturas en el mapa
mymap=Map.FiltrarYDibujarCurvatura(datosCordenadasSensor, '2024-02-15 07:30:00.434', '2024-02-15 08:30:00.434');

%% Grafica la velocidad registrada por el sts
velocidadp20 = ImportarDatos.P20Velocidad();
mygraficaV = Graficas.graficarVelocidadSts(velocidadp20, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434');

%% Importa los datos del evento 1 y los grafica
datosEventos = ImportarDatos.Evento1();
datosEventosCord = ImportarDatos.Evento1Coordenadas(datosEventos);
Graficas.Evento1(datosEventosCord, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434', mygraficaV)
Graficas.Evento1(datosEventosCord, '2024-02-14 00:30:00.434', '2024-02-15 23:35:00.434', mygraficaA)

Map.FiltrarYAgregarMarcadores(datosEventosCord, '2024-02-14 07:30:00.434', '2024-02-14 07:59:00.434', mymap)

%% 
fechas = fieldnames(tiemposRutas);  % Obtiene todos los campos de fecha
for i=1: 1:length(fechas)
    fecha = fechas{i};  % fecha actual en el ciclo
    buses = fieldnames(tiemposRutas.(fecha));  % Obtiene todos los buses para la fecha actual
   for j= length(buses)
        bus = buses{j};  % bus actual en el ciclo
        busNumber = strrep(bus, 'bus', '');  % Eliminar el prefijo 'bus'
        rutas = tiemposRutas.(fecha).(bus);  % Matriz de celdas con rutas para el bus actual
        if iscell(rutas)
            % Iterar sobre cada fila de la matriz de celdas (cada ruta)
            for k = 1:size(rutas, 1)
                inicio = rutas{k, 1};  % Hora de inicio
                retorno = rutas{k, 2}; % Hora de llegada al punto de retorno
                fin = rutas{k, 3};     % Hora de llegada al punto de inicio
                fechaArchivo = datestr(inicio, 'yyyy-mm-dd');
                horaInicio = datestr(inicio, 'HH:MM:SS');
                horaR = datestr(retorno, 'HH:MM:SS');
                horaF = datestr(fin, 'HH:MM:SS');

                % Rutas para datos del teléfono y P20
                rutaSensor = fullfile('Datos', fechaArchivo, busNumber);
                disp(['Ruta ', num2str(k), ' del bus ', busNumber, ' en la fecha ', fecha, ' procesada.']);
                datosSensor = ImportarDatos.Sensor(rutaSensor);
                datosCordenadasSensor = ImportarDatos.SensorCordenadas(datosSensor);
                if bus=='bus4020'
                    conductoresida4020{i,j}=Calculos.riesgoCurva2(datosCordenadasSensor,inicio,retorno,Cida4020);
                    conductoresRetorno4020{i,j}=Calculos.riesgoCurva2(datosCordenadasSensor,retorno,fin,Cretorno4020);
                elseif bus=='bus4104'
                    conductoresida4104{i,j}=Calculos.riesgoCurva2(datosCordenadasSensor,inicio,retorno,Cida4104);
                    conductoresRetorno4104{i,j}=Calculos.riesgoCurva2(datosCordenadasSensor,retorno,fin,Cretorno4104);
               
                end
                
%                 
%                 conductoresRetorno{}
            end
        else
            disp(['El bus ', bus, ' en la fecha ', fecha, ' no contiene una matriz de celdas con datos.']);
        end
   end
end

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


%%

function generarDatos(fechaInicio, fechaFinal, IDbus, Etiqueta)
% Esta función organiza y visualiza datos de acuerdo con las especificaciones dadas.

% Convertir las fechas de inicio y final a formato datetime
fechaInicioDT = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
fechaFinalDT = datetime(fechaFinal, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');

% Extraer la fecha y hora de inicio y final para el título
fechaArchivo = datestr(fechaInicioDT, 'yyyy-mm-dd');
horaInicio = datestr(fechaInicioDT, 'HH:MM:SS');
horaFinal = datestr(fechaFinalDT, 'HH:MM:SS');


% Rutas para datos del teléfono y P20
rutaSensor = fullfile('Datos', fechaArchivo, strrep(IDbus, 'bus_', ''));
rutalogs = fullfile('Datos', fechaArchivo, strrep(IDbus, 'bus_', ''), 'log');

% Importar datos del sensor y del P20
datosSensor = ImportarDatos.Sensor(rutaSensor);
datosCordenadasSensor = ImportarDatos.SensorCordenadas(datosSensor);

datosP20 = ImportarDatos.P20(rutalogs);
%datosCordenadasP20 = ImportarDatos.P20Cordenadas(datosP20);

datosP60 = ImportarDatos.P60(rutalogs);

% Eventos

evento1 = ImportarDatos.Evento1(rutalogs);

% Visualizaciones y análisis

General = sprintf(' - Fecha: %s, Bus ID: %s, Hora: %s-%s', fechaArchivo, IDbus, horaInicio, horaFinal);

%Graficas.graficarConsumoBateria(datosP60, fechaInicio, fechaFinal, 'Consumo', 'b-', 'Bus');

% Preparar el título con la palabra 'velocidad', la fecha, el ID del bus y las horas de inicio y final
tituloGrafica = [Etiqueta sprintf(' Ruta -celular y sts ') General];
% ruta celular
% MapaRuta = Map.Ruta(datosCordenadasSensor, fechaInicio, fechaFinal, 'r-', tituloGrafica, 'Celular');
% ruta sts
%Map.Ruta(datosCordenadasP20, fechaInicio, fechaFinal, 'r--', tituloGrafica, 'STS', MapaRuta);


%tituloGrafica = [Etiqueta sprintf('Mapa de calor velocidades celular ') General];
% Mapa velocidad celular
%Map.Velocidad(datosCordenadasSensor, fechaInicio, fechaFinal, tituloGrafica, 'Celular');
% Mapa velocidad pocision sts
%tituloGrafica = [Etiqueta sprintf(' Velocidad P20 coordenadas ') General];
%Map.Velocidad(datosCordenadasP20, fechaInicio, fechaFinal, tituloGrafica, 'sts');


%tituloGrafica = [Etiqueta sprintf(' Velocidad P20 Tramar ') General];
% Mapa velocidad trama sts
%Map.VelocidadSTS(datosP20, fechaInicio, fechaFinal, tituloGrafica, 'STS')

% Mapa direccion
%Map.Direccion(datosCordenadasSensor, fechaInicio, fechaFinal);

%tituloGrafica = [Etiqueta sprintf(' Velocidad filtrada y sin filtar ') General];
% grafica Velocidad celular sin correccion y con correccion
%graficaVelocidad = Graficas.velocidadTiempo(datosCordenadasSensor, fechaInicio, fechaFinal, 'MS', tituloGrafica, 'b-' , 'sin filtrar' );
%Graficas.velocidadTiempo(datosCordenadasSensor, fechaInicio, fechaFinal,'filtrar', tituloGrafica, 'y-','filtrada', graficaVelocidad);

%tituloGrafica = [Etiqueta sprintf(' Velocidad coordenadas p20 ') General];
% Grafica sts velocidad
%Graficas.velocidadTiempo(datosCordenadasP20, fechaInicio, fechaFinal, 'MS', tituloGrafica, 'b-', 'P20 coordenadas');

%tituloGrafica = [Etiqueta sprintf(' Velocidad  P20 Trama ') General];
% Grafico sts velocidad trama
%Graficas.graficarVelocidadSts(datosP20, fechaInicio, fechaFinal, tituloGrafica, 'b-', 'P20');

%tituloGrafica = [Etiqueta sprintf(' Aceleracion Celular ') General];
%Grafica aceleracion celular
%graficaAce = Graficas.aceleracionTiempo(datosCordenadasSensor, fechaInicio, fechaFinal, 'normal', tituloGrafica, 'b-', 'sin filtrar');
%Graficas.aceleracionTiempo(datosCordenadasSensor, fechaInicio, fechaFinal, 'filtrar', tituloGrafica, 'r-', 'filtrada', graficaAce);


%tituloGrafica = [Etiqueta sprintf(' Aceleracion STS coordenadas ') General];
% Grafica aceleracion sts cordenadas
%Graficas.aceleracionTiempo(datosCordenadasP20, fechaInicio, fechaFinal, 'normal', tituloGrafica, 'b-', 'STS coordenadas');

%tituloGrafica = [Etiqueta sprintf(' Aceleracion STS Trama ') General];
% Grafica aceleracion trama
%Graficas.graficarAceleracionSts(datosP20, fechaInicio, fechaFinal, tituloGrafica, 'b-', 'STS');

%tituloGrafica = [Etiqueta sprintf(' Curvatura ') General];
% Mapa giros
%Map.Curvatura(datosCordenadasSensor, fechaInicio, fechaFinal, tituloGrafica)



Ruta4104Ida = [0.85, 2.1, 4.1, 4.5, 5.2, 8.0, 8.6, 10.5, 13.9];
Ruta4104Vuelta = [1.18, 2.1, 3.5, 5.2, 10.2, 11.9, 13.5];


Ruta4020Ida = [2.3, 8.1, 11.9, 12.9, 14.8, 19.25];
Ruta4020Vuelta = [2.04, 5.1, 8.6, 11.13, 14.65, 19.44];





% Grafica giros
tituloGrafica = [Etiqueta sprintf(' Riesgo curvatura ') General];
% Graficas.riesgoVsCurva(datosCordenadasSensor, fechaInicio, fechaFinal, tituloGrafica);

tituloGrafica = [Etiqueta sprintf(' Distancia vs velocidad ') General];
% Grafica de distancia vs velocidad
%Graficas.DistanciavsVelocidad2(datosCordenadasSensor,datosP60, fechaInicio, fechaFinal, tituloGrafica);

dataFiltrada = ImportarDatos.filtrarDatosPorFechas(datosCordenadasSensor, fechaInicio, fechaFinal);






%Grafica de distancia vs energia
%Graficas.DistanciavsEnergia(datosP60, fechaInicio, fechaFinal, '1', '2');

% Grafica de aceleraciones histograma
%Graficas.analizarAceleraciones(datosCordenadasSensor, fechaInicio, fechaFinal);

% Grafica tiempo vs energia
Velocidad = Graficas.TiempovsEnergia(datosP60, fechaInicio, fechaFinal);
Graficas.TiempovsEnergiaCorregida(datosP60, fechaInicio, fechaFinal, Velocidad);

% Graficas ocupacion vs tiempo
%Graficas.OcupacionVsTiempo(evento1, fechaInicio, fechaFinal);
end


%%

function procesarRutas(datosReorganizados)
    % Esta función procesa las rutas para cada bus según los tiempos y datos reorganizados.

    % Obtener todos los buses disponibles en los datos
    buses = fieldnames(datosReorganizados);
    
    % Iterar sobre cada bus
    for i = 1:length(buses)
        bus = buses{i};  % bus actual en el ciclo
        tiposRuta = fieldnames(datosReorganizados.(bus));  % 'ida' y 'vuelta'

        % Iterar sobre cada tipo de ruta ('ida' y 'vuelta')
        for j = 1:length(tiposRuta)
            tipoRuta = tiposRuta{j};  % 'ida' o 'vuelta'
            fechas = fieldnames(datosReorganizados.(bus).(tipoRuta));  % Todas las fechas para este tipo de ruta

            % Iterar sobre cada fecha
            for k = 1:length(fechas)
                fecha = fechas{k};  % fecha actual en el ciclo
                datosRuta = datosReorganizados.(bus).(tipoRuta).(fecha);
                
                % Asumiendo que datosRuta es un array de celdas con {inicio, fin}
                % y que cada fila corresponde a una ruta diferente
                for m = 1:size(datosRuta, 1)
                    inicio = datosRuta{m, 3};  % Hora de inicio
                    fin = datosRuta{m, 4};     % Hora de fin

                    % Llamar a la función generarDatos con la hora de inicio y fin
                    generarDatos(inicio, fin, bus, tipoRuta);
                    disp(['Ruta ', num2str(m), ' del bus ', bus, ' tipo ', tipoRuta, ' en la fecha ', fecha, ' procesada.']);
                end
            end
        end
    end
end


