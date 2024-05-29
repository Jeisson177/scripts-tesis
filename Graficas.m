classdef Graficas
    methods (Static)
        %%
        
        function grafica = velocidadTiempo(datos, fechaInicio, fechaFin, metodoVelocidad, titulo, colorYlinea,leyenda, grafica)
    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end

    % Filtrar los datos por el rango de fechas
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);

    % Elegir la función de cálculo de velocidad basada en el parámetro 'metodoVelocidad'
    switch metodoVelocidad
        case 'KH'
            velocidad = Calculos.calcularVelocidadKH(datosFiltrados);
        case 'MS'
            velocidad = Calculos.calcularVelocidadMS(datosFiltrados);
        case 'filtrar'
            velocidad = Calculos.corregirVelocidadPendiente(datosFiltrados, 3);
        otherwise
            error('Método de cálculo de velocidad no reconocido');
    end

    % Crear un nuevo gráfico o utilizar uno existente
    if nargin < 8 || isempty(grafica)
        grafica = figure;
        set(grafica, 'UserData', struct('Leyendas', [])); % Inicializar UserData para leyendas
    else
        figure(grafica); % Hace que 'grafica' sea la figura actual sin crear una nueva
    end

    % Trazar velocidad en función del tiempo
    plot(datosFiltrados{:, 1}(2:end), velocidad, colorYlinea,'LineWidth', 1);  % Se asume que la velocidad se calcula entre puntos consecutivos
    
    title(titulo);

    xlabel('Tiempo');
    ylabel('Velocidad (m/s)');  % Ajusta según la unidad usada
    grid on;

    % Actualizar y configurar la leyenda
    currentLegends = get(grafica, 'UserData').Leyendas;
    if nargin >= 7 && ~isempty(leyenda)
        newLegends = [currentLegends, {leyenda}];
        legend(newLegends, 'Location', 'best');
        set(grafica, 'UserData', struct('Leyendas', newLegends));
    end

    hold on; % Mantener el gráfico para más trazados
end

        
       
        
        
        %%
        
        function grafica = aceleracionTiempo(datos, fechaInicio, fechaFin, metodoAceleracion, titulo, colorYlinea, leyenda, grafica)
    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end

    % Obtener los datos en el rango de fechas
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);

    % Calcular la velocidad como paso preliminar para calcular la aceleración
    velocidad = Calculos.calcularVelocidadKH(datosFiltrados);
    velocidad = velocidad .* 0.277778;  % Convertir de km/h a m/s si es necesario

    % Elegir la función de cálculo de aceleración basada en el parámetro 'metodoAceleracion'
    switch metodoAceleracion
        case 'normal'
            aceleracion = Calculos.calcularAceleracion(velocidad, datosFiltrados);
        case 'metodo2'
            aceleracion = Calculos.calcularAceleracion2(velocidad, datosFiltrados);
        case 'filtrar'
            aceleracion = Calculos.calcularAceleracionFiltrada(datosFiltrados, 3);
        otherwise
            error('Método de cálculo de aceleración no reconocido');
    end

    % Crear un nuevo gráfico o utilizar uno existente
    if nargin < 8 || isempty(grafica)
        grafica = figure;
        set(grafica, 'UserData', struct('Leyendas', []));  % Inicializar UserData para leyendas
    else
        figure(grafica);  % Hace que 'grafica' sea la figura actual sin crear una nueva
    end

    % Trazar aceleración en función del tiempo
    plot(datosFiltrados{:, 1}(3:end), aceleracion, colorYlinea, 'LineWidth', 2);  % Asumimos que la aceleración se calcula desde el tercer punto

    % Configurar el título, etiquetas y leyenda
    if nargin >= 5 && ~isempty(titulo)
        title(titulo);
    else
        title('Aceleración en Función del Tiempo');
    end

    xlabel('Tiempo');
    ylabel('Aceleración (m/s²)');
    grid on;

    % Actualizar y configurar la leyenda
    currentLegends = get(grafica, 'UserData').Leyendas;
    if nargin >= 7 && ~isempty(leyenda)
        newLegends = [currentLegends, {leyenda}];
        legend(newLegends, 'Location', 'best');
        set(grafica, 'UserData', struct('Leyendas', newLegends));
    end

    hold on;  % Mantener el gráfico para más trazados
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
        function DistanciavsEnergia(datosp60,fechaInicio, fechaFin, conductor, bus)
            figure;
            
            if ischar(fechaInicio) || isstring(fechaInicio)
                fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
            end
            if ischar(fechaFin) || isstring(fechaFin)
                fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
            end
            datosFiltrados = datosp60(datosp60.fechaHoraLecturaDato >= fechaInicio & datosp60.fechaHoraLecturaDato <= fechaFin, :);
            
            distancia=Calculos.CalcularDistancia(datosFiltrados);
            datosFiltrados.kilometrosOdometro=datosFiltrados.kilometrosOdometro-datosFiltrados.kilometrosOdometro(1);
            plot(datosFiltrados.kilometrosOdometro,datosFiltrados.nivelRestanteEnergia);

            % porcentaje = Calculos.interpolarPorcentajeBateria3(datosFiltrados);
            % 
            % plot(distancia,porcentaje(:,end-1));
            title(['Conductor ', num2str(conductor),bus]); % Asegúrate de concatenar correctamente
            xlabel('Distancia');
            ylabel('Porcentaje de energía');
        end
        
        %%
        

       function riesgoVsCurva(datosCordenadasSensor, fechaInicio, fechaFin, tituloGeneral)
    % Calcula los datos de riesgo en curvas para un rango de fechas especificado
    datos = Calculos.riesgoCurva(datosCordenadasSensor, fechaInicio, fechaFin);
    
    % Inicializar contadores y almacenamiento para los resultados
    cantd = 1;
    max_c = [];
    valores_a = [];
    valores_b = [];
    Ncurvas = [];
    
    % Iteramos sobre los datos
    for n = 1:length(datos)
        if ~isempty(datos{n})
            % Extraemos el máximo de la columna 3
            [max_c(end+1,1), indice_max] = max(datos{n}(:,3));
            % Guardamos los valores correspondientes de las columnas 1 y 2
            valores_a(end+1,1) = datos{n}(indice_max, 1);
            valores_b(end+1,1) = datos{n}(indice_max, 2);
            Ncurvas(end+1,1) = cantd;
            cantd = cantd + 1;
        end
    end
    
    hFig = figure;
    set(hFig, 'Name', 'Análisis de Riesgo en Curvas', 'NumberTitle', 'off');
    
    % Subplot para el índice de riesgo
    subplot(3,1,1);
    plot(Ncurvas, max_c, 'b-o');
    xlabel('Número de curva');
    ylabel('Índice de riesgo');
    title('Índice de Riesgo por Curva');
    
    % Subplot para la velocidad
    subplot(3,1,2);
    plot(Ncurvas, valores_a, 'r-s');
    xlabel('Número de curva');
    ylabel('Velocidad (km/h)');
    title('Velocidad en el Punto de Riesgo Máximo');
    
    % Subplot para el radio de la curva
    subplot(3,1,3);
    plot(Ncurvas, valores_b, 'g-^');
    xlabel('Número de curva');
    ylabel('Radio de la curva (m)');
    title('Radio de Curva en el Punto de Riesgo Máximo');
    
    % Añadir título general para todos los subplots, utilizando el parámetro proporcionado
    sgtitle(tituloGeneral);
end

        
        
        
        %%
        
        function grafica = TiempovsEnergia(datos, fechaInicio, fechaFin, grafica)
    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    
    % Filtrar los datos por el rango de fechas
    indices = datos.fechaHoraLecturaDato >= fechaInicio & datos.fechaHoraLecturaDato <= fechaFin;
    datosFiltrados = datos(indices, :);
    
    % Ordenar los datos filtrados por fecha y hora de lectura para garantizar un trazado cronológico correcto
    datosFiltrados = sortrows(datosFiltrados, 'fechaHoraLecturaDato');
    
    % Crear un nuevo gráfico o utilizar uno existente
    if nargin < 4 || isempty(grafica)
        grafica = figure;
        hold on;  % Asegurarse de que las siguientes trazas se añadan al gráfico existente
    else
        figure(grafica); % Hace que 'grafica' sea la figura actual sin crear una nueva
    end
    

    % Trazar energía en función del tiempo
    plot(datosFiltrados.fechaHoraLecturaDato, datosFiltrados.nivelRestanteEnergia, 'LineWidth', 2);
    title('Energía Restante en Función del Tiempo');
    xlabel('Tiempo');
    ylabel('Nivel de Energía (%)');
    grid on;
    
    % Devolver el handle de la figura si es necesario
    if nargout > 0
        grafica = gcf;
    end
end


        %%

        function grafica = TiempovsEnergiaCorregida(datos, fechaInicio, fechaFin, grafica)
    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    
    % Filtrar los datos por el rango de fechas
    indices = datos.fechaHoraLecturaDato >= fechaInicio & datos.fechaHoraLecturaDato <= fechaFin;
    datosFiltrados = datos(indices, :);
    
    % Ordenar los datos filtrados por fecha y hora de lectura para garantizar un trazado cronológico correcto
    datosFiltrados = sortrows(datosFiltrados, 'fechaHoraLecturaDato');
    
    % Crear un nuevo gráfico o utilizar uno existente
    if nargin < 4 || isempty(grafica)
        grafica = figure;
        hold on;  % Asegurarse de que las siguientes trazas se añadan al gráfico existente
    else
        figure(grafica); % Hace que 'grafica' sea la figura actual sin crear una nueva
    end
    
    % Aproximación del porcentaje de la batería
    porcentaje = datosFiltrados.nivelRestanteEnergia; 

    % Aplicar suavizado usando un filtro de Savitzky-Golay
    ordenPol = 2; % Orden del polinomio
    ventana = 65; % Longitud de la ventana, debe ser impar
    if length(porcentaje) >= ventana % Asegurarse de que hay suficientes datos para aplicar el filtro
        porcentajeSuavizado = sgolayfilt(porcentaje, ordenPol, ventana);
    else
        porcentajeSuavizado = porcentaje; % No se aplica filtro si no hay suficientes datos
    end

    % Trazar energía en función del tiempo
    plot(datosFiltrados.fechaHoraLecturaDato, porcentajeSuavizado, 'LineWidth', 2);
    title('Energía Restante en Función del Tiempo (Suavizado)');
    xlabel('Tiempo');
    ylabel('Nivel de Energía (%)');
    grid on;
    
    % Devolver el handle de la figura si es necesario
    if nargout > 0
        grafica = gcf;
    end
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
        function grafica = graficarVelocidadSts(datos, fechaInicio, fechaFin, titulo, colorYlinea, leyenda, grafica)
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
    if nargin < 8 || isempty(grafica)
        grafica = figure;
        set(grafica, 'UserData', struct('Leyendas', [])); % Inicializar UserData para leyendas
    else
        figure(grafica); % Hacer que 'grafica' sea la figura actual sin crear una nueva
    end

    % Trazar velocidad en función del tiempo
    plot(fechas, velocidad, colorYlinea, 'LineWidth', 1);

    title(titulo);
    xlabel('Tiempo');
    ylabel('Velocidad (km/h)');
    grid on;

    % Actualizar y configurar la leyenda
    currentLegends = get(grafica, 'UserData').Leyendas;
    if nargin >= 6 && ~isempty(leyenda)
        newLegends = [currentLegends, {leyenda}];
        legend(newLegends, 'Location', 'best');
        set(grafica, 'UserData', struct('Leyendas', newLegends));
    end

    hold on; % Mantener el gráfico para más trazados
end


%%

function grafica = graficarAceleracionSts(datos, fechaInicio, fechaFin, titulo, colorYlinea, leyenda, grafica)
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
    velocidad = datosFiltrados{:, 'aceleracionVehiculo'};

    % Crear un nuevo gráfico o utilizar uno existente
    if nargin < 8 || isempty(grafica)
        grafica = figure;
        set(grafica, 'UserData', struct('Leyendas', [])); % Inicializar UserData para leyendas
    else
        figure(grafica); % Hacer que 'grafica' sea la figura actual sin crear una nueva
    end

    % Trazar velocidad en función del tiempo
    plot(fechas, velocidad, colorYlinea, 'LineWidth', 1);

    title(titulo);
    xlabel('Tiempo');
    ylabel('Aceleración (m/s2)');
    grid on;

    % Actualizar y configurar la leyenda
    currentLegends = get(grafica, 'UserData').Leyendas;
    if nargin >= 6 && ~isempty(leyenda)
        newLegends = [currentLegends, {leyenda}];
        legend(newLegends, 'Location', 'best');
        set(grafica, 'UserData', struct('Leyendas', newLegends));
    end

    hold on; % Mantener el gráfico para más trazados
end


%%

function grafica = graficarConsumoBateria(datos, fechaInicio, fechaFin, titulo, colorYlinea, leyenda, grafica)
    % Tamaño de la batería en kWh
    capacidadBateria = 280;  % kWh

    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end

    % Filtrar los datos por el rango de fechas
    datosFiltrados = datos(datos{:, 'fechaHoraLecturaDato'} >= fechaInicio & datos{:, 'fechaHoraLecturaDato'} <= fechaFin, :);

    % Calcular el consumo de la batería en kWh
    porcentajeBateria = Calculos.interpolarPorcentajeBateria2(datosFiltrados);
    consumoBateria = porcentajeBateria / 100 * capacidadBateria;

    % Crear un nuevo gráfico o utilizar uno existente
    if nargin < 7 || isempty(grafica)
        grafica = figure;
        set(grafica, 'UserData', struct('Leyendas', [])); % Inicializar UserData para leyendas
    else
        figure(grafica); % Hacer que 'grafica' sea la figura actual sin crear una nueva
    end

    % Trazar el consumo en función del tiempo
    plot(datosFiltrados{:, 'fechaHoraLecturaDato'}, consumoBateria, colorYlinea, 'LineWidth', 2);

    title(titulo);
    xlabel('Tiempo');
    ylabel('Consumo de Batería (kWh)');
    grid on;

    % Actualizar y configurar la leyenda
    currentLegends = get(grafica, 'UserData').Leyendas;
    if nargin >= 6 && ~isempty(leyenda)
        newLegends = [currentLegends, {leyenda}];
        legend(newLegends, 'Location', 'best');
        set(grafica, 'UserData', struct('Leyendas', newLegends));
    end

    hold on; % Mantener el gráfico para más trazados
end


%%

function ConsumoVsDistancia(datosBateria, datosDistancia, tamanoBateria, fechaInicio, fechaFin, titulo)
    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    end
    
    % Filtrar los datos por el rango de fechas
    datosBateriaFiltrados = datosBateria(datosBateria{:, 'fechaHoraLecturaDato'} >= fechaInicio & datosBateria{:, 'fechaHoraLecturaDato'} <= fechaFin, :);
    datosDistanciaFiltrados = datosDistancia(datosDistancia{:, 'fechaHoraLecturaDato'} >= fechaInicio & datosDistancia{:, 'fechaHoraLecturaDato'} <= fechaFin, :);
    
    % Asumiendo que los datos están ordenados cronológicamente y que las fechas coinciden en ambos conjuntos de datos
    energiaConsumida = zeros(height(datosBateriaFiltrados), 1);
    distanciaRecorrida = zeros(height(datosBateriaFiltrados), 1);

    for i = 1:height(datosBateriaFiltrados)-1
        % Calcula el cambio en el porcentaje de batería entre mediciones consecutivas
        deltaPorcentaje = datosBateriaFiltrados{i, 'porcentajeBateria'} - datosBateriaFiltrados{i+1, 'porcentajeBateria'};
        energiaConsumida(i) = (deltaPorcentaje / 100) * tamanoBateria;  % en kWh

        % Calcula la distancia recorrida entre las mismas mediciones
        distanciaRecorrida(i) = datosDistanciaFiltrados{i+1, 'distanciaAcumulada'} - datosDistanciaFiltrados{i, 'distanciaAcumulada'};  % en km
    end

    % Filtrar ceros que pueden aparecer por falta de movimiento o datos inconsistentes
    validIndices = distanciaRecorrida > 0;
    energiaConsumida = energiaConsumida(validIndices);
    distanciaRecorrida = distanciaRecorrida(validIndices);

    % Calcular el consumo de energía por km
    consumoPorKm = energiaConsumida ./ distanciaRecorrida;  % kWh por km

    % Crear la figura para graficar
    figure;
    plot(distanciaRecorrida, consumoPorKm, '-o');
    title(titulo);
    xlabel('Distancia (km)');
    ylabel('Consumo de energía (kWh/km)');
    grid on;
end


        %%
        function grafica = OcupacionVsTiempo(datos, fechaInicio, fechaFin, grafica)
            % Convertir fechas de inicio y fin a datetime si son strings
            if ischar(fechaInicio) || isstring(fechaInicio)
                fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
            end
            if ischar(fechaFin) || isstring(fechaFin)
                fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
            end
            
            % Filtrar los datos por el rango de fechas
            indices = datos.fechaHoraLecturaDato >= fechaInicio & datos.fechaHoraLecturaDato <= fechaFin;
            datosFiltrados = datos(indices, :);
            
            % Crear un nuevo gráfico o utilizar uno existente
            if nargin < 4 || isempty(grafica)
                grafica = figure;
            else
                figure(grafica); % Hace que 'grafica' sea la figura actual sin crear una nueva
            end
            
            % Trazar estimación de ocupación en función del tiempo
            plot(datosFiltrados.fechaHoraLecturaDato, datosFiltrados.estimacionOcupacionAbordo, 'LineWidth', 2);
            title('Ocupación en Función del Tiempo');
            xlabel('Tiempo');
            ylabel('Personas');
            grid on;
            hold on;
            
            % Devolver el handle de la figura si es necesario
            if nargout > 0
                grafica = gcf;
            end
        end
        
        
        %%
        
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
        
        function DistanciavsVelocidad2(datos, P20, fechaInicio, fechaFin, tituloGeneral)
    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    end
    
    % Filtrar los datos por el rango de fechas
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
    datosCordenadasP20Filtrados = P20(P20.fechaHoraLecturaDato >= fechaInicio & P20.fechaHoraLecturaDato <= fechaFin, :);

    % Crear figura
    hFig = figure;
    set(hFig, 'Name', tituloGeneral, 'NumberTitle', 'off');  % Establecer nombre y desactivar número de título

    % Primer subplot para los datos del celular
    distancia = Calculos.CalcularDistancia(datosFiltrados);
    velocidad = Calculos.calcularVelocidadKH(datosFiltrados);
    subplot(2, 1, 1);
    plot(distancia(1:end-1), velocidad);
    title('Velocidad vs distancia (celular)');
    xlabel('Distancia (km)');
    ylabel('Velocidad (km/h)');
    grid on;
    
    % Segundo subplot para los datos del dispositivo P20
    subplot(2, 1, 2);
    plot(datosCordenadasP20Filtrados.kilometrosOdometro - datosCordenadasP20Filtrados.kilometrosOdometro(1) , datosCordenadasP20Filtrados.velocidadVehiculo);
    title('Velocidad vs distancia (P20)');
    xlabel('Distancia (km)');
    ylabel('Velocidad (km/h)');
    grid on;

    % Añadir título general para la figura entera
    sgtitle(tituloGeneral);
end

        
        
        %%
        
        function DistanciavsVelocidad3(datos, P20, fechaInicio, fechaFin, puntosVerticales)
            % Convertir fechas de inicio y fin a datetime si son strings
            if ischar(fechaInicio) || isstring(fechaInicio)
                fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
            end
            if ischar(fechaFin) || isstring(fechaFin)
                fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
            end
            
            % Filtrar los datos por el rango de fechas
            datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
            datosCordenadasP20Filtrados = P20(P20.fechaHoraLecturaDato >= fechaInicio & P20.fechaHoraLecturaDato <= fechaFin, :);
            
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
            
            %distancia = Calculos.CalcularDistancia(datosCordenadasP20Filtrados);
            %velocidad = Calculos.calcularVelocidadKH(datosCordenadasP20Filtrados);
            
            subplot(2, 1, 2);
            plot(datosCordenadasP20Filtrados.kilometrosOdometro , datosCordenadasP20Filtrados.velocidadVehiculo);
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
        
        
        %%
        
        function visualizarPercentilesVelocidad(datosVelocidad, percentiles)
            
            if nargin < 2 || isempty(percentiles)
                percentiles = [25, 50, 75];
            end
            
            % Calcular los percentiles solicitados
            valoresPercentiles = prctile(datosVelocidad, percentiles, 1);  % Calcula los percentiles a lo largo de cada columna
            
            % Crear la figura para visualizar
            figure;
            hold on;
            
            % Generar colores diferentes para cada percentil
            colores = lines(numel(percentiles));  % Obtener colores distintos para cada línea
            
            % Trazar cada percentil
            for i = 1:numel(percentiles)
                plot(valoresPercentiles(i, :), 'LineWidth', 2, 'Color', colores(i, :));
            end
            
            % Añadir detalles al gráfico
            legend(arrayfun(@(p) sprintf('Percentil %d', p), percentiles, 'UniformOutput', false), ...
                'Location', 'best');
            title('Percentiles de Velocidad para Diferentes Conductores/Sesiones');
            xlabel('Índice de Sesión/Conductor');
            ylabel('Velocidad (m/s)');
            grid on;
            
            % Mantener el gráfico visible
            hold off;
        end
        
        
        
    end
end


