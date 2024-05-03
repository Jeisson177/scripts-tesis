classdef Map
    
    
    methods (Static)
        
        %Muestra la ruta recorrida
        function mapa = Ruta(datos, fechaInicio, fechaFin, colorYlinea, titulo, leyenda, mapa)
            % Verificar que 'datos' sea una tabla
            if ~istable(datos)
                error('La entrada debe ser una tabla.');
            end
            
            % Comprobar si se ha pasado un mapa como argumento
            if nargin < 7 || isempty(mapa)
                mapa = figure;
                set(mapa, 'UserData', struct('Leyendas', [])); % Inicializar UserData para leyendas
            else
                if ~isa(mapa, 'matlab.ui.Figure')
                    error('El último parámetro debe ser un objeto de figura de MATLAB.');
                end
                figure(mapa); % Hace que 'mapa' sea la figura actual sin crear una nueva
            end
            
            % Convertir las fechas de inicio y fin si son strings a datetime
            fechaInicioDT = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
            fechaFinDT = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
            
            % Filtrar los datos entre las fechas de inicio y fin
            datosFiltrados = datos(datos{:, 1} >= fechaInicioDT & datos{:, 1} <= fechaFinDT, :);
            
            % Verificar si hay datos para trazar
            if height(datosFiltrados) < 2
                warning('No hay suficientes datos entre las fechas proporcionadas para mostrar una ruta.');
                return;
            end
            
            % Trama la ruta
            geoplot(datosFiltrados{:, 2}, datosFiltrados{:, 3}, colorYlinea, 'LineWidth', 2);
            hold on;
            
            % Configurar el título
            title(titulo);
            
            % Actualizar y configurar la leyenda
            currentLegends = get(mapa, 'UserData').Leyendas;
            if nargin >= 6 && ~isempty(leyenda)
                newLegends = [currentLegends, {leyenda}];
                legend(newLegends, 'Location', 'best');
                set(mapa, 'UserData', struct('Leyendas', newLegends));
            end
            
            geolimits('auto'); % Ajustar los límites para mostrar toda la ruta
        end
        
        
        %%
        %Creo que agrega donde se ubican en el mapa las posiciones
        function mapa = Marcadores(datos, fechaInicio, fechaFin, mapa, colorMarcador, formaMarcador)
            % Verificar que 'datos' sea una tabla
            if ~istable(datos)
                error('La entrada debe ser una tabla.');
            end
            
            % Comprobar si se ha pasado un mapa como argumento
            if nargin >= 4 && ishandle(mapa) && isa(mapa, 'matlab.ui.Figure')
                figure(mapa); % Solo establecerlo como figura actual si es válido
            else
                mapa = figure; % Crear una nueva figura si 'mapa' no es válido
            end
            
            % Convertir las fechas de inicio y fin si son cadenas a datetime
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
            figure(mapa);
            
            % Agregar marcadores con el color y la forma especificados
            geoscatter(datosFiltrados{:, 2}, datosFiltrados{:, 3}, 'Filled', 'Marker', formaMarcador, 'MarkerEdgeColor', colorMarcador, 'DisplayName', 'Posiciones', 'SizeData', 250);
            hold on; % Mantener el gráfico actual para añadir texto
        end
        
        
        %%
        function mapa = Velocidad(datos, fechaInicio, fechaFin, titulo, leyenda, mapa)
    % Verificar que 'datos' sea una tabla
    if ~istable(datos)
        error('La entrada debe ser una tabla.');
    end

    % Verificar y manejar el argumento 'mapa'
    if nargin < 6 || isempty(mapa) || ~ishandle(mapa) || ~isa(mapa, 'matlab.ui.Figure')
        mapa = figure; % Crear una nueva figura si no se proporciona o es inválido
    else
        figure(mapa); % Hacer que 'mapa' sea la figura actual sin crear una nueva
    end

    % Convertir las fechas de inicio y fin si son strings a datetime
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

    % Calcular la velocidad y trazarla como un mapa de calor
    velocidadSensor = Calculos.calcularVelocidadKH(datosFiltrados);
    geoscatter(datosFiltrados{2:end, 2}, datosFiltrados{2:end,3}, 10, velocidadSensor, 'filled');
    colormap(jet);
    colorbar; % Añade una barra de color para interpretar las velocidades

    % Configurar el título y la leyenda
    if nargin >= 4 && ~isempty(titulo)
        title(titulo);
    else
        title('Mapa de Calor de Velocidad'); % Título por defecto
    end

    if nargin >= 5 && ~isempty(leyenda)
        legend(leyenda, 'Location', 'best');
    end

    geolimits('auto'); % Ajustar los límites para mostrar toda la ruta
    hold on;
end

%%
function mapa = VelocidadSTS(datos, fechaInicio, fechaFin, titulo, leyenda, mapa)
    % Verificar que 'datos' sea una tabla
    if ~istable(datos)
        error('La entrada debe ser una tabla.');
    end

    % Verificar y manejar el argumento 'mapa'
    if nargin < 6 || isempty(mapa) || ~ishandle(mapa) || ~isa(mapa, 'matlab.ui.Figure')
        mapa = figure; % Crear una nueva figura si no se proporciona o es inválido
        set(mapa, 'UserData', struct('Leyendas', [])); % Inicializar UserData para leyendas
    else
        figure(mapa); % Hacer que 'mapa' sea la figura actual sin crear una nueva
    end

    % Convertir las fechas de inicio y fin si son strings a datetime
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end

    % Filtrar los datos entre las fechas de inicio y fin usando nombres de columna como texto
    datosFiltrados = datos(datos{:, 'fechaHoraLecturaDato'} >= fechaInicio & datos{:, 'fechaHoraLecturaDato'} <= fechaFin, :);

    % Verificar si hay datos para trazar
    if height(datosFiltrados) < 1
        warning('No hay suficientes datos entre las fechas proporcionadas para mostrar un mapa de calor.');
        return;
    end

    geoscatter(datosFiltrados{:, 'lat'}, datosFiltrados{:, 'lon'}, 10,  datosFiltrados{:, 'velocidadVehiculo'}, 'filled');
    colormap(jet);
    colorbar; % Añade una barra de color para interpretar las velocidades

    % Configurar el título y la leyenda
    if nargin >= 4 && ~isempty(titulo)
        title(titulo);
    else
        title('Mapa de Calor de Velocidad'); % Título por defecto
    end

    % Actualizar y configurar la leyenda
    currentLegends = get(mapa, 'UserData').Leyendas;
    if nargin >= 5 && ~isempty(leyenda)
        newLegends = [currentLegends, {leyenda}];
        legend(newLegends, 'Location', 'best');
        set(mapa, 'UserData', struct('Leyendas', newLegends));
    end

    geolimits('auto'); % Ajustar los límites para mostrar toda la ruta
    hold on;
end


        %%
        
        function mapa = Curvatura(datos, fechaInicio, fechaFin, titulo, mapa)
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
            if nargin < 5 || isempty(mapa)
                mapa = figure;  % Crear una nueva figura si no se proporciona un objeto gráfico
            else
                figure(mapa);  % Usar la figura proporcionada
            end
            
            % Dibujar los valores de curvatura en el mapa como puntos
            % La curvatura se calcula a partir del segundo punto, por lo que ajustamos los datos en el plot
            geoscatter(datosFiltrados{3:end, 2}, datosFiltrados{3:end, 3}, 10, curvatura, 'filled');
            colormap(jet);  % Usa un mapa de colores para representar los valores de curvatura
            colorbar;  % Añade una barra de color para interpretar la curvatura
            
            title(titulo);
            geolimits('auto');  % Ajusta los límites para incluir todos los puntos
            
            hold on;  % Finalizar el modo hold
        end
        %%
        function mapa = Direccion(datos, fechaInicio, fechaFin, mapa)
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
        
        
        %%
        function AgregarEtiquetasAEventos(datos, mapa)
            % Verificar que los datos sean una tabla
            if ~istable(datos)
                error('La entrada debe ser una tabla.');
            end
            
            % Asegurarse de que las columnas requeridas existan en 'datos'
            columnasRequeridas = {'latitud', 'longitud', 'codigoComportamientoAnomalo'};
            if ~all(ismember(columnasRequeridas, datos.Properties.VariableNames))
                error('La tabla de entrada no contiene las columnas necesarias.');
            end
            
            % Seleccionar el mapa para agregar las etiquetas
            figure(mapa);
            
            % Mantener los marcadores existentes y solo agregar etiquetas
            hold on;
            
            % Añadir texto a cada marcador con información del código anómalo
            for i = 1:height(datos)
                etiquetaTexto = sprintf('CA: %s', datos.codigoComportamientoAnomalo{i});
                text(datos.latitud(i), datos.longitud(i), etiquetaTexto, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
            end
            
            hold on;
        end
        
        %%
        
        function mapa = MarcadoresEspeciales(datos, fechaInicio, fechaFin, mapa, formaMarcador, puntosKm)
            % Verificar que 'datos' sea una tabla
            if ~istable(datos)
                error('La entrada debe ser una tabla.');
            end
            
            % Comprobar si se ha pasado un mapa como argumento
            if nargin >= 4 && ishandle(mapa) && isa(mapa, 'matlab.ui.Figure')
                figure(mapa); % Solo establecerlo como figura actual si es válido
            else
                mapa = figure; % Crear una nueva figura si 'mapa' no es válido
            end
            
            % Convertir las fechas de inicio y fin si son cadenas a datetime
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
            
            % Calcular distancia para datos filtrados
            distancia = Calculos.CalcularDistancia(datosFiltrados);
            
            % Verificar si hay datos para trazar
            if height(datosFiltrados) < 1
                warning('No hay suficientes datos entre las fechas proporcionadas para agregar marcadores.');
                return;
            end
            
            % Seleccionar el mapa para trazar
            figure(mapa);
            
            % Agregar marcadores especiales en los puntos de kilómetros especificados en puntosKm
            for i = 1:length(puntosKm)
                kmIndex = find(distancia >= puntosKm(i), 1, 'first'); % Encuentra el primer índice donde la distancia supera cada punto en puntosKm
                if ~isempty(kmIndex) && kmIndex <= height(datosFiltrados)
                    geoscatter(datosFiltrados{kmIndex, 2}, datosFiltrados{kmIndex, 3}, 'Marker', formaMarcador, 'MarkerEdgeColor', 'red', 'DisplayName', ['Km ' num2str(puntosKm(i))], 'SizeData', 300);
                end
            end
            hold off; % Finalizar la edición del gráfico
        end
        
        
    end
end

