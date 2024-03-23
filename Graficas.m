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
    ylabel('Velocidad (unidad)');
    grid on;
    hold on
        end
%%

function grafica = aceleracionTiempo(datos, fechaInicio, fechaFin, grafica)
    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    
    % Filtrar los datos por el rango de fechas
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
    
    % Calcular la aceleración usando la función proporcionada
    aceleracion = Calculos.calcularAceleracion(datosFiltrados);
    
    % Crear un nuevo gráfico o utilizar uno existente
    if nargin < 4 || isempty(grafica)
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

function Distanciavstiempo(datos,datosCordenadasP20)
    
    distancia=Calculos.CalcularDistancia(datos);
    velocidad=Calculos.calcularVelocidadKH(datos);
    plot(distancia(1:end-1),velocidad);
    title('Velocidad vs ditancia');
    xlabel('Distancia(m)');
    ylabel('Velocidad(m/s)');
    grid on;
    hold on
    distancia=Calculos.CalcularDistancia(datosCordenadasP20);
    velocidad=Calculos.calcularVelocidadKH(datosCordenadasP20);
    plot(distancia(1:end-1),velocidad);
end


    end
end


