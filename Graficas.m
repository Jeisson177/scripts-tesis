classdef Graficas
    methods (Static)
%%

function grafica = velocidadTiempo(datos, fechaInicio, fechaFin, grafica)
    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    
    % Filtrar los datos por el rango de fechas
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
    
aceleracion = Calculos.calcularAceleracionFiltrada(datosFiltrados,20);


    % Calcular la velocidad usando la función proporcionada
    velocidad = Calculos.calcularVelocidadMS(datosFiltrados);
    
    % Crear un nuevo gráfico o utilizar uno existente
    if nargin < 4 || isempty(grafica)
        grafica = figure;
    else
        figure(grafica);
    end
    
    % Trazar velocidad en función del tiempo
    plot(datosFiltrados{:, 1}(2:end), velocidad, 'LineWidth', 2);  % Se asume que la velocidad se calcula entre puntos consecutivos
    title('Velocidad en Función del Tiempo');
    xlabel('Tiempo');
    ylabel('Velocidad (Km/h)');
    grid on;
    hold on
        end

%%

function grafica = velocidadTiempoCorregida(datos, fechaInicio, fechaFin, grafica)
    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    
    % Filtrar los datos por el rango de fechas
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
    
aceleracion = Calculos.calcularAceleracionFiltrada(datosFiltrados,20);


    % Calcular la velocidad usando la función proporcionada
    velocidad = Calculos.corregirVelocidadPendiente(datosFiltrados, 3);
    
    % Crear un nuevo gráfico o utilizar uno existente
    if nargin < 4 || isempty(grafica)
        grafica = figure;
    else
        figure(grafica);
    end
    
    % Trazar velocidad en función del tiempo
    plot(datosFiltrados{:, 1}(2:end), velocidad, 'LineWidth', 2);  % Se asume que la velocidad se calcula entre puntos consecutivos
    title('Velocidad en Función del Tiempo');
    xlabel('Tiempo');
    ylabel('Velocidad (Km/h)');
    grid on;
    hold on
        end


%%

function grafica = aceleracionTiempo(datos, fechaInicio, fechaFin,metodoAceleracion, grafica)



    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    
    % Obtener los datos en el rango de fechas
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
    
    % Calcular la aceleración usando la función proporcionada
    velocidad=Calculos.calcularVelocidadKH(datosFiltrados);
    velocidad=velocidad .* 0.277778;
    

        % Elegir la función de cálculo de aceleración basada en el parámetro 'metodoAceleracion'
    switch metodoAceleracion
        case 'metodo1'
            aceleracion = Calculos.calcularAceleracion(velocidad, datosFiltrados);
        case 'metodo2'
            aceleracion = Calculos.calcularAceleracion2(velocidad, datosFiltrados);
        case 'filtrar'
            aceleracion = Calculos.calcularAceleracionFiltrada(datosFiltrados,3);
        otherwise
            error('Método de cálculo de aceleración no reconocido');
    end


    disp(['Longitud de tiempo: ', num2str(length(datosFiltrados{:, 1}(3:end)))]);
disp(['Longitud de aceleración: ', num2str(length(aceleracion))]);

    
    % Crear un nuevo gráfico o utilizar uno existente
    if nargin < 5 || isempty(grafica)
        grafica = figure;
    else
        figure(grafica);
    end
    
    % Trazar aceleración en función del tiempo
    % Nota: La aceleración se calcula a partir del segundo punto, por lo que ajustamos los tiempos en el plot
    plot(datosFiltrados{:, 1}(3:end), aceleracion, 'LineWidth', 2);  % La aceleración se calcula a partir de la segunda velocidad
    title('Aceleración en Función del Tiempo');
    xlabel('Tiempo');
    ylabel('Aceleración (m/s²)');
    grid on;
    hold on
end
%%


function analizarAceleraciones(datos, fechaInicio, fechaFin)



     % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    
    % Obtener los datos en el rango de fechas
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
    
    % Calcular la aceleración usando la función proporcionada
    velocidad=Calculos.calcularVelocidadMS(datosFiltrados);




    % Calcular aceleraciones usando la función previa
    aceleracion = Calculos.calcularAceleracion(velocidad, datos);
    
    % Filtrar aceleraciones para encontrar valores significativos (mayores a 2 m/s^2)
    aceleracionesSignificativas = abs(aceleracion) > 2;
    
    % Encontrar los picos de aceleraciones significativas
    [pks, locs] = findpeaks(aceleracion(aceleracionesSignificativas));
    
    % Mostrar los picos de aceleraciones bruscas
    fprintf('Picos de aceleraciones significativas:\n');
    disp(table(pks, datos{locs, 1}, 'VariableNames', {'Aceleracion', 'Tiempo'}));
    
    % Crear un histograma de todas las aceleraciones
    figure;
    % Definir los bordes de los bins del histograma en pasos de 0.5 desde el mínimo hasta el máximo de 3
    binEdges = -3:0.5:3; % Asumiendo que también consideramos aceleraciones negativas hasta -3
    histogram(aceleracion, binEdges);
    title('Histograma de Aceleraciones');
    xlabel('Aceleración (m/s^2)');
    ylabel('Frecuencia');
    
    % Marcar las aceleraciones bruscas en el histograma
    hold on;
    histogram(aceleracion(aceleracionesSignificativas), binEdges);
    legend('Todas las Aceleraciones', 'Aceleraciones > 2 m/s^2');
    hold off;
    
    % Reporte adicional si es necesario
    if ~isempty(pks)
        fprintf('Se encontraron %d aceleraciones bruscas mayores a 2 m/s^2.\n', length(pks));
    else
        fprintf('No se encontraron aceleraciones bruscas mayores a 2 m/s^2.\n');
    end

end



%%
function grafica=DistanciavsEnergia()
    datosp60=ImportarDatos.P60();
    distancia=Calculos.CalcularDistancia(datosp60);
    % Crear un nuevo gráfico o utilizar uno existente
    if nargin < 4 || isempty(grafica)
        grafica = figure;
    else
        figure(grafica);
    end
    plot(distancia,datosp60.nivelRestanteEnergia);
    
end

%%
function grafica=TiempovsEnergia()
    datosp60=ImportarDatos.P60();
    if nargin < 4 || isempty(grafica)
        grafica = figure;
    else
        figure(grafica);
    end
    plot(datosp60.fechaHoraLecturaDato,datosp60.nivelRestanteEnergia);
end

%%

function grafica=Evento20(grafica)%como se va a cargar en un solo lugar no se tiene en cuenta para la distancia
    EV20=ImportarDatos.Evento20();
    if nargin < 4 || isempty(grafica)
        grafica = figure;
    else
        figure(grafica);
    end
    
    plot(EV20.fechaHoraLecturaDato, zeros(size(EV20.fechaHoraLecturaDato)), 'ro', 'MarkerSize', 5);
    title('Energia en Función del Tiempo');

end

%%

function grafica=Evento21(grafica)%como se va a cargar en un solo lugar no se tiene en cuenta para la distancia
    EV20=ImportarDatos.Evento21();
    if nargin < 4 || isempty(grafica)
        grafica = figure;
    else
        figure(grafica);
    end
    
    plot(EV20.fechaHoraLecturaDato, zeros(size(EV20.fechaHoraLecturaDato)), 'rx', 'MarkerSize', 5);
    title('Energia en Función del Tiempo');

end

%%

function grafica = Evento1(datos, fechaInicio, fechaFin, grafica)
    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    
    % Filtrar los datos por el rango de fechas
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
    
    % Crear un nuevo gráfico o utilizar uno existente
    if nargin < 4 || isempty(grafica)
        grafica = figure;
    else
        figure(grafica);
    end
    
    % Trazar velocidad en función del tiempo
    plot(datosFiltrados{:, 1}, zeros(size(datosFiltrados{:, 1})), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
    title('Velocidad en Función del Tiempo');
    xlabel('Tiempo');
    ylabel('Velocidad (unidad)');
    grid on;
    hold on

end

%%
function grafica = graficarVelocidadSts(datos, fechaInicio, fechaFin, grafica)
    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    
    % Filtrar los datos por el rango de fechas
    datosFiltrados = datos(datos{:, 'fechaHoraLecturaDato'} >= fechaInicio & datos{:, 'fechaHoraLecturaDato'} <= fechaFin, :);
    
    % No es necesario calcular la velocidad ya que ya viene en los datos filtrados
    fechas = datosFiltrados{:, 'fechaHoraLecturaDato'};
    velocidad = datosFiltrados{:, 'velocidadVehiculo'};
    
    % Crear un nuevo gráfico o utilizar uno existente
    if nargin < 4 || isempty(grafica)
        grafica = figure;
    else
        figure(grafica);
    end
    
    % Trazar velocidad en función del tiempo
    plot(fechas, velocidad, 'LineWidth', 2, 'Color', 'green');
    title('Velocidad en Función del Tiempo');
    xlabel('Tiempo');
    ylabel('Velocidad (km/h)');
    grid on;
    hold on;
end
function grafica=OcupacionVsTiempo()
    EV1=ImportarDatos.Evento1();
    if nargin < 4 || isempty(grafica)
        grafica = figure;
    else
        figure(grafica);
    end
    
    plot(EV1.fechaHoraLecturaDato,EV1.estimacionOcupacionAbordo);
    
    title('Ocupacion en Función del Tiempo');
    xlabel('Tiempo');
    ylabel('Personas'); 

    hold on
    plot(EV1.fechaHoraLecturaDato,EV1.peso);
end
function DistanciavsVelocidad(datos,datosCordenadasP20)
    
    distancia=Calculos.CalcularDistancia(datos);
    velocidad=Calculos.calcularVelocidadKH(datos);
    subplot(2,1,1);
    plot(distancia(1:end-1),velocidad);
    title('Velocidad vs ditancia (celular)');
    xlabel('Distancia(km)');
    ylabel('Velocidad(km/h)');
    grid on;
    
    
    distancia=Calculos.CalcularDistancia(datosCordenadasP20);
    velocidad=Calculos.calcularVelocidadKH(datosCordenadasP20);
    subplot(2,1,2);
    plot(distancia(1:end-1),velocidad);
    title('Velocidad vs ditancia (sts)');
    xlabel('Distancia(km)');
    ylabel('Velocidad(km/h)');
    grid on;
end

%%

function DistanciavsVelocidad2(datos, datosCordenadasP20, fechaInicio, fechaFin)
    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    end
    
    % Filtrar los datos por el rango de fechas
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
    datosCordenadasP20Filtrados = datosCordenadasP20(datosCordenadasP20{:, 1} >= fechaInicio & datosCordenadasP20{:, 1} <= fechaFin, :);
    
    % Calcular distancia y velocidad para datos filtrados
    distancia = Calculos.CalcularDistancia(datosFiltrados);
    velocidad = Calculos.calcularVelocidadKH(datosFiltrados);
    subplot(2, 1, 1);
    plot(distancia(1:end-1), velocidad);
    title('Velocidad vs distancia (celular)');
    xlabel('Distancia (km)');
    ylabel('Velocidad (km/h)');
    grid on;
    
    distancia = Calculos.CalcularDistancia(datosCordenadasP20Filtrados);
    velocidad = Calculos.calcularVelocidadKH(datosCordenadasP20Filtrados);
    subplot(2, 1, 2);
    plot(distancia(1:end-1), velocidad);
    title('Velocidad vs distancia (P20)');
    xlabel('Distancia (km)');
    ylabel('Velocidad (km/h)');
    grid on;
end


%%

function DistanciavsVelocidad3(datos, datosCordenadasP20, fechaInicio, fechaFin, puntosVerticales)
    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    end
    
    % Filtrar los datos por el rango de fechas
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
    datosCordenadasP20Filtrados = datosCordenadasP20(datosCordenadasP20{:, 1} >= fechaInicio & datosCordenadasP20{:, 1} <= fechaFin, :);
    
    % Calcular distancia y velocidad para datos filtrados
    distancia = Calculos.CalcularDistancia(datosFiltrados);
    velocidad = Calculos.calcularVelocidadKH(datosFiltrados);
    subplot(2, 1, 1);
    plot(distancia(1:end-1), velocidad);
    title('Velocidad vs distancia (celular)');
    xlabel('Distancia (km)');
    ylabel('Velocidad (km/h)');
    grid on;
    hold on;
    for i = 1:length(puntosVerticales)
        xline(puntosVerticales(i), '--r'); % Líneas verticales en rojo punteado
    end
    hold off;
    
    distancia = Calculos.CalcularDistancia(datosCordenadasP20Filtrados);
    velocidad = Calculos.calcularVelocidadKH(datosCordenadasP20Filtrados);
    subplot(2, 1, 2);
    plot(distancia(1:end-1), velocidad);
    title('Velocidad vs distancia (P20)');
    xlabel('Distancia (km)');
    ylabel('Velocidad (km/h)');
    grid on;
    hold on;
    for i = 1:length(puntosVerticales)
        xline(puntosVerticales(i), '--r'); % Líneas verticales en rojo punteado
    end
    hold off;
end


    end
end


