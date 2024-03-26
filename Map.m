classdef Map
    
    
    methods (Static)

        function mapa = FiltrarYMostrarRuta(datos, fechaInicio, fechaFin, mapa)
    % Verificar que 'datos' sea una tabla
    if ~istable(datos)
        error('La entrada debe ser una tabla.');
    end

    % % Comprobar si se ha pasado un mapa como argumento
    if nargin < 4 || isempty(mapa)
        mapa = figure; % Crear una nueva figura si no se proporciona el mapa
    else
        if ~isa(mapa, 'matlab.ui.Figure')
            error('El cuarto parámetro debe ser un objeto de figura de MATLAB.');
        end
        figure(mapa); % Hace que 'mapa' sea la figura actual sin crear una nueva
    end
    
    % Convertir las fechas de inicio y fin si son strings a datetime
    % Asegurarse de que no tengan zona horaria para que coincidan con los datos
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    
    % Convertir las fechas en 'datos' a datetimes sin zona horaria para la comparación
    datos{:, 1} = datetime(datos{:, 1}, 'TimeZone', '');
    
    % Filtrar los datos entre las fechas de inicio y fin
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
    
    % Verificar si hay datos para trazar
    if height(datosFiltrados) < 2
        warning('No hay suficientes datos entre las fechas proporcionadas para mostrar una ruta.');
        return;
    end
    
    % Seleccionar el mapa para trazar
    figure(mapa);

    geoplot(datosFiltrados{:, 2}, datosFiltrados{:, 3}, 'r-', 'LineWidth', 2);
    title('Ruta entre las fechas especificadas');
    geolimits('auto'); % Ajustar los límites para mostrar toda la ruta
    hold on
end
%%
        function mapa = FiltrarYAgregarMarcadores(datos, fechaInicio, fechaFin, mapa)
    % Verificar que 'datos' sea una tabla
    if ~istable(datos)
        error('La entrada debe ser una tabla.');
    end

    % Comprobar si se ha pasado un mapa como argumento
    % At the beginning of FiltrarYAgregarMarcadores function
if nargin >= 4 && ishandle(mapa) && isa(mapa, 'matlab.ui.Figure')
    figure(mapa); % Only set it as current figure if it's valid
else
    mapa = figure; % Create a new figure if mapa is not valid
end

    % Convertir las fechas de inicio y fin si son strings a datetime
    % Asegurarse de que no tengan zona horaria para que coincidan con los datos
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    
    % Convertir las fechas en 'datos' a datetimes sin zona horaria para la comparación
    datos{:, 1} = datetime(datos{:, 1}, 'TimeZone', '');
    
    % Filtrar los datos entre las fechas de inicio y fin
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
    
    % Verificar si hay datos para trazar
    if height(datosFiltrados) < 1
        warning('No hay suficientes datos entre las fechas proporcionadas para agregar marcadores.');
        return;
    end
    
    % Seleccionar el mapa para trazar
    if ~exist('mapa', 'var') || isempty(mapa)
        mapa = figure;
        %geoAx = geoaxes; % Crea nuevos ejes geográficos si no se ha proporcionado 'mapa'
    else
        figure(mapa); % Activa la figura dada
        %geoAx = gca; % Asume que los ejes actuales son los que se deben usar
    end


    % Asegurarte de que estás trabajando con GeographicAxes
    % if ~isa(geoAx, 'matlab.graphics.axis.GeographicAxes')
    %     error('Los ejes actuales no son ejes geográficos. Se requiere un GeographicAxes para geoscatter.');
    % end


    % Agregar marcadores en lugar de trazar una línea
    geoscatter(datosFiltrados{:, 2}, datosFiltrados{:, 3}, 'Filled', 'DisplayName', 'Posiciones');
    hold on
end
%%
function mapa = FiltrarYDibujarVelocidad(datos, fechaInicio, fechaFin, mapa)
    % Verificar que 'datos' sea una tabla
    if ~istable(datos)
        error('La entrada debe ser una tabla.');
    end

    % Comprobar si se ha pasado un mapa como argumento
    % At the beginning of FiltrarYAgregarMarcadores function
if nargin >= 4 && ishandle(mapa) && isa(mapa, 'matlab.ui.Figure')
    figure(mapa); % Only set it as current figure if it's valid
else
    mapa = figure; % Create a new figure if mapa is not valid
end

    % Convertir las fechas de inicio y fin si son strings a datetime
    % Asegurarse de que no tengan zona horaria para que coincidan con los datos
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    
    % Convertir las fechas en 'datos' a datetimes sin zona horaria para la comparación
    datos{:, 1} = datetime(datos{:, 1}, 'TimeZone', '');
    
    % Filtrar los datos entre las fechas de inicio y fin
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
    
    % Verificar si hay datos para trazar
    if height(datosFiltrados) < 1
        warning('No hay suficientes datos entre las fechas proporcionadas para agregar marcadores.');
        return;
    end
    
    % Seleccionar el mapa para trazar
    if ~exist('mapa', 'var') || isempty(mapa)
        mapa = figure;
        %geoAx = geoaxes; % Crea nuevos ejes geográficos si no se ha proporcionado 'mapa'
    else
        figure(mapa); % Activa la figura dada
        %geoAx = gca; % Asume que los ejes actuales son los que se deben usar
    end


    velocidadSensor = Calculos.calcularVelocidad(datosFiltrados);
geoscatter(datosFiltrados{2:end, 2}, datosFiltrados{2:end,3}, 10, velocidadSensor, 'filled');
colormap(jet);
    colorbar;  % Añade una barra de color para interpretar las velocidades
    title('Mapa de Calor de Velocidad');
    
    % Ajusta los límites para que incluyan todos los puntos
    geolimits('auto');

    hold on
end

%%

function mapa = FiltrarYDibujarCurvatura(datos, fechaInicio, fechaFin, mapa)
    % Verificar que 'datos' sea una tabla
    if ~istable(datos)
        error('La entrada debe ser una tabla.');
    end

    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end

    % Filtrar los datos entre las fechas de inicio y fin
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
    
    % Calcular la curvatura
    curvatura = Calculos.calcularCurvatura(datosFiltrados);

    % Preparar el mapa
    if nargin < 4 || isempty(mapa)
        mapa = figure;  % Crear una nueva figura si no se proporciona un objeto gráfico
    else
        figure(mapa);  % Usar la figura proporcionada
    end

    % Dibujar los valores de curvatura en el mapa como puntos
    % La curvatura se calcula a partir del segundo punto, por lo que ajustamos los datos en el plot
    geoscatter(datosFiltrados{3:end, 2}, datosFiltrados{3:end, 3}, 10, curvatura, 'filled');
    colormap(jet);  % Usa un mapa de colores para representar los valores de curvatura
    colorbar;  % Añade una barra de color para interpretar la curvatura

    title('Mapa de Calor de Curvatura');
    geolimits('auto');  % Ajusta los límites para incluir todos los puntos

    hold on;  % Finalizar el modo hold
end

function mapa=FiltrarYDibujarDireccion(datos, fechaInicio, fechaFin, mapa)
     %Verificar que 'datos' sea una tabla
    if ~istable(datos)
        error('La entrada debe ser una tabla.');
    end

    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end

    % Filtrar los datos entre las fechas de inicio y fin
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
    
    % direccion
    dire = Calculos.detectardireccion(datosFiltrados);

    % Preparar el mapa
    if nargin < 4 || isempty(mapa)
        mapa = figure;  % Crear una nueva figura si no se proporciona un objeto gráfico
    else
        figure(mapa);  % Usar la figura proporcionada
    end

    % Dibujar los valores de curvatura en el mapa como puntos
    % La curvatura se calcula a partir del segundo punto, por lo que ajustamos los datos en el plot
    geoscatter(datosFiltrados{2:end, 2}, datosFiltrados{2:end, 3}, 10, dire, 'filled');
    colormap(jet);  % Usa un mapa de colores para representar los valores de curvatura
    colorbar;  % Añade una barra de color para interpretar la curvatura

    title('Mapa de Calor de Curvatura');
    geolimits('auto');  % Ajusta los límites para incluir todos los puntos

    hold on;  % Finalizar el modo hold
end


    end
end

