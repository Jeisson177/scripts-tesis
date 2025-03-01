classdef Calculos
    methods (Static)
        %%
          function [magnitudes_positivas, magnitudes_negativas, tiempos_positivos, tiempos_negativos] = aceleracionPorCuadrosMx(datos)
    % Aplicar el umbral de aceleración
    datos.Acc(abs(datos.Acc) <= 0.3) = 0;
    
    % Inicializar variables
    intervalo_inicio = 1;
    magnitudes_positivas = [];
    magnitudes_negativas = [];
    tiempos_positivos = [];
    tiempos_negativos = [];

    % Recorrer la señal para identificar intervalos positivos, negativos o 0
    while intervalo_inicio <= length(datos.Acc)
        if datos.Acc(intervalo_inicio) > 0
            % Buscar el final del intervalo positivo
            intervalo_fin = find(datos.Acc(intervalo_inicio:end) <= 0, 1) + intervalo_inicio - 2;
            if isempty(intervalo_fin)
                intervalo_fin = length(datos.Acc);
            end
            altura = max(datos.Acc(intervalo_inicio:intervalo_fin));

            % Calcular la duración del intervalo
            duracion = datos.Tiempo(intervalo_fin) - datos.Tiempo(intervalo_inicio);

            % Guardar magnitud y duración en arreglos separados para intervalos positivos
            magnitudes_positivas = [magnitudes_positivas; altura];
            tiempos_positivos = [tiempos_positivos; duracion];

        elseif datos.Acc(intervalo_inicio) < 0
            % Buscar el final del intervalo negativo
            intervalo_fin = find(datos.Acc(intervalo_inicio:end) >= 0, 1) + intervalo_inicio - 2;
            if isempty(intervalo_fin)
                intervalo_fin = length(datos.Acc);
            end
            altura = min(datos.Acc(intervalo_inicio:intervalo_fin));

            % Calcular la duración del intervalo
            duracion = datos.Tiempo(intervalo_fin) - datos.Tiempo(intervalo_inicio);

            % Guardar magnitud y duración en arreglos separados para intervalos negativos
            magnitudes_negativas = [magnitudes_negativas; altura];
            tiempos_negativos = [tiempos_negativos; duracion];

        else
            % Para los valores de 0
            intervalo_fin = find(datos.Acc(intervalo_inicio:end) ~= 0, 1) + intervalo_inicio - 2;
            if isempty(intervalo_fin)
                intervalo_fin = length(datos.Acc);
            end
        end

        % Actualizar el inicio del siguiente intervalo
        intervalo_inicio = intervalo_fin + 1;
    end

    % Eliminar las últimas 2 muestras de los arreglos
    if length(magnitudes_positivas) > 2
        magnitudes_positivas(end-1:end) = [];
    end

    if length(magnitudes_negativas) > 2
        magnitudes_negativas(end-1:end) = [];
    end

    if length(tiempos_positivos) > 2
        tiempos_positivos(end-1:end) = [];
    end

    if length(tiempos_negativos) > 2
        tiempos_negativos(end-1:end) = [];
    end
    tiempos_ent = floor(seconds(tiempos_positivos));
mtem = [tiempos_ent, magnitudes_positivas];
max_time = max(mtem(:,1));
prom_magnitudes = zeros(max_time+1, 1);

for i = 0:max_time
    prom_magnitudes(i+1) = mean(mtem(mtem(:,1) == i, 2));
end

plot(0:max_time, prom_magnitudes);

%scatter(tiempos_positivos, magnitudes_positivas)

xlabel('Segundos');
ylabel('Promedio de Magnitudes');
title('Promedio de Magnitudes por Segundo Entero');
hold on;

end

        
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
        

      function promediosVelocidad = calcularPromedioVelocidadPorSegmentos(datos, puntosSegmentos)
    % Asegurar que la distancia inicial (0 km) esté incluida si no está ya
    if puntosSegmentos(1) ~= 0
        puntosSegmentos = [0 puntosSegmentos];
    end

    % Calcular la distancia y la velocidad de los datos
    distancia = Calculos.CalcularDistancia(datos);
    velocidad = Calculos.calcularVelocidadKH(datos);

    % Ajustar la longitud de distancia para que coincida con velocidad
    % La distancia debe ser una menos que la longitud original
    if length(distancia) > length(velocidad)
        distancia = distancia(1:end-1);
    end

    % Verificar que distancia y velocidad tengan la misma longitud
    if length(distancia) ~= length(velocidad)
        error('La longitud de distancia y velocidad no coincide.');
    end

    
    puntosSegmentos = [puntosSegmentos, max(distancia)];
    

    % Inicializar el vector de promedios de velocidad y las listas de velocidad por segmento
    numSegmentos = length(puntosSegmentos) - 1;
    promediosVelocidad = zeros(numSegmentos, 1);
    velocidadesPorSegmento = cell(numSegmentos, 1);

    % Asignar cada velocidad a su respectivo segmento
    for i = 1:length(distancia)
        for j = 1:numSegmentos
            if distancia(i) >= puntosSegmentos(j) && distancia(i) < puntosSegmentos(j+1)
                velocidadesPorSegmento{j} = [velocidadesPorSegmento{j}, velocidad(i)];
                break;
            end
        end
    end

    % Calcular el promedio de velocidad para cada segmento
    for k = 1:numSegmentos
        if ~isempty(velocidadesPorSegmento{k})
            promediosVelocidad(k) = mean(velocidadesPorSegmento{k}, 'omitnan');
        else
            promediosVelocidad(k) = 0; % Rellenar con cero si no hay datos
        end
    end

    % Asegurar que la longitud sea consistente con los puntos de segmentación originales
    if length(promediosVelocidad) < numSegmentos
        promediosVelocidad = [promediosVelocidad; zeros(numSegmentos - length(promediosVelocidad), 1)];
    elseif length(promediosVelocidad) > numSegmentos
        promediosVelocidad = promediosVelocidad(1:numSegmentos);
    end

    % Verificación y salida de información
    disp('--- Verificación ---');
    disp(['Número de segmentos: ', num2str(numSegmentos)]);
    disp(['Longitud de promediosVelocidad: ', num2str(length(promediosVelocidad))]);
    disp('Valores de promediosVelocidad:');
    disp(promediosVelocidad);
    disp('--------------------');
end


%%


function promediosConsumo = calcularPromedioConsumoPorSegmentos(distancia, consumo, puntosSegmentos)
            % Asegurar que la distancia inicial (0 km) esté incluida si no está ya
            if puntosSegmentos(1) ~= 0
                puntosSegmentos = [0 puntosSegmentos];
            end

            % Ajustar la longitud de distancia para que coincida con consumo
            % La distancia debe ser una menos que la longitud original
            if length(distancia) > length(consumo)
                distancia = distancia(1:end-1);
            end

            % Verificar que distancia y consumo tengan la misma longitud
            if length(distancia) ~= length(consumo)
                error('La longitud de distancia y consumo no coincide.');
            end

            % Añadir el último punto de segmentación si no está incluido
            puntosSegmentos = [puntosSegmentos, max(distancia)];

            % Inicializar el vector de promedios de consumo y las listas de consumo por segmento
            numSegmentos = length(puntosSegmentos) - 1;
            promediosConsumo = zeros(numSegmentos, 1);
            consumosPorSegmento = cell(numSegmentos, 1);

            % Asignar cada consumo a su respectivo segmento
            for i = 1:length(distancia)
                for j = 1:numSegmentos
                    if distancia(i) >= puntosSegmentos(j) && distancia(i) < puntosSegmentos(j+1)
                        consumosPorSegmento{j} = [consumosPorSegmento{j}, consumo(i)];
                        break;
                    end
                end
            end

            % Calcular el promedio de consumo para cada segmento
            for k = 1:numSegmentos
                if ~isempty(consumosPorSegmento{k})
                    promediosConsumo(k) = mean(consumosPorSegmento{k}, 'omitnan');
                else
                    promediosConsumo(k) = 0; % Rellenar con cero si no hay datos
                end
            end

            % Asegurar que la longitud sea consistente con los puntos de segmentación originales
            if length(promediosConsumo) < numSegmentos
                promediosConsumo = [promediosConsumo; zeros(numSegmentos - length(promediosConsumo), 1)];
            elseif length(promediosConsumo) > numSegmentos
                promediosConsumo = promediosConsumo(1:numSegmentos);
            end

            % Verificación y salida de información
            disp('--- Verificación ---');
            disp(['Número de segmentos: ', num2str(numSegmentos)]);
            disp(['Longitud de promediosConsumo: ', num2str(length(promediosConsumo))]);
            disp('Valores de promediosConsumo:');
            disp(promediosConsumo);
            disp('--------------------');
        end

        %%


        function tablaOrdenada = ordenarTablaPorElementoVector(tabla, nombreColumna, indiceElemento, direccion)
    % Verificar si la tabla está vacía
    if isempty(tabla)
        error('La tabla proporcionada está vacía.');
    end
    
    % Verificar si la columna existe en la tabla
    if ~any(strcmp(tabla.Properties.VariableNames, nombreColumna))
        error('La columna especificada no existe en la tabla.');
    end
    
    % Verificar si la dirección del ordenamiento es válida
    if ~ismember(direccion, {'ascend', 'descend'})
        error('La dirección del ordenamiento debe ser "ascend" o "descend".');
    end
    
    % Extraer el elemento del vector en la posición dada para cada fila
    vectorColumn = tabla{:, nombreColumna};
    if any(cellfun(@(x) numel(x) < indiceElemento, vectorColumn))
        error('Algunos vectores no tienen el elemento en el índice especificado.');
    end
    elementosExtraidos = cellfun(@(x) x(indiceElemento), vectorColumn);
    
    % Ordenar la tabla basada en los elementos extraídos
    [~, idx] = sort(elementosExtraidos, direccion);
    tablaOrdenada = tabla(idx, :);
end



        %%

        
        function datosBuses = calcularPromedioVelocidadRutas(datosBuses)

            Ruta4104Ida = [0.85, 2.1, 4.1, 4.5, 5.2, 8.0, 8.6, 10.5, 13.9];
            Ruta4104Vuelta = [1.18, 2.1, 3.5, 5.2, 10.2, 11.9, 13.5];


            Ruta4020Ida = [2.3, 8.1, 11.9, 12.9, 14.8, 19.25];
            Ruta4020Vuelta = [2.04, 5.1, 8.6, 11.13, 14.65, 19.44];

    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};

        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de ruta y datos del sensor para el bus
            if isfield(datosBuses.(fecha).(bus), 'tiempoRuta') && isfield(datosBuses.(fecha).(bus), 'datosSensor')
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;
                datosSensor = datosBuses.(fecha).(bus).datosSensor;

                % Procesar cada ruta del día
                for k = 1:size(tiempoRuta, 1)
                    % Trayecto de ida
                    fechaInicioIda = tiempoRuta{k, 1};
                    fechaFinIda = tiempoRuta{k, 2};
                    dataFiltradaIda = ImportarDatos.filtrarDatosPorFechas(datosSensor, fechaInicioIda, fechaFinIda);

                    % Trayecto de vuelta
                    fechaInicioVuelta = tiempoRuta{k, 2};
                    fechaFinVuelta = tiempoRuta{k, 3};
                    dataFiltradaVuelta = ImportarDatos.filtrarDatosPorFechas(datosSensor, fechaInicioVuelta, fechaFinVuelta);

                    IDbus = bus(5:end);  % Asume que el nombre del bus es 'bus_XXXX'
                    
                    % Calcular y almacenar los promedios para ida
                    if strcmp(IDbus, '4020')
                        PromediosIda = Calculos.calcularPromedioVelocidadPorSegmentos(dataFiltradaIda, Ruta4020Ida);
                        PromediosVuelta = Calculos.calcularPromedioVelocidadPorSegmentos(dataFiltradaVuelta, Ruta4020Vuelta);
                    elseif strcmp(IDbus, '4104')
                        PromediosIda = Calculos.calcularPromedioVelocidadPorSegmentos(dataFiltradaIda, Ruta4104Ida);
                        PromediosVuelta = Calculos.calcularPromedioVelocidadPorSegmentos(dataFiltradaVuelta, Ruta4104Vuelta);
                    end
                    
                    % Almacenar los promedios en la estructura de datos
                    datosBuses.(fecha).(bus).PromediosIda{k, 1} = PromediosIda;
                    datosBuses.(fecha).(bus).PromediosVuelta{k, 1} = PromediosVuelta;
                end
            end
        end
    end
    return;
end




%%

function datosBuses = calcularPromedioConsumoRutas(datosBuses)

            Ruta4104Ida = [0.85, 2.1, 4.1, 4.5, 5.2, 8.0, 8.6, 10.5, 13.9];
            Ruta4104Vuelta = [1.18, 2.1, 3.5, 5.2, 10.2, 11.9, 13.5];


            Ruta4020Ida = [2.3, 8.1, 11.9, 12.9, 14.8, 19.25];
            Ruta4020Vuelta = [2.04, 5.1, 8.6, 11.13, 14.65, 19.44];

    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};

        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de ruta y datos del sensor para el bus
            if isfield(datosBuses.(fecha).(bus), 'consumoEnergiaRuta') && isfield(datosBuses.(fecha).(bus), 'segmentoP60') && isfield(datosBuses.(fecha).(bus), 'tiempoRuta')
                consumoEnergiaRuta = datosBuses.(fecha).(bus).consumoEnergiaRuta;
                P60 = datosBuses.(fecha).(bus).segmentoP60;
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;
                

                % Procesar cada ruta del día
                for k = 1:size(tiempoRuta, 1)
                    % Trayecto de ida
                    fechaInicioIda = tiempoRuta{k, 1};
                    fechaFinIda = tiempoRuta{k, 2};

                    % Trayecto de vuelta
                    fechaInicioVuelta = tiempoRuta{k, 2};
                    fechaFinVuelta = tiempoRuta{k, 3};

                    IDbus = bus(5:end);  % Asume que el nombre del bus es 'bus_XXXX'
                    
                    % Calcular y almacenar los promedios para ida
                    if strcmp(IDbus, '4020')
                        PromediosIda = Calculos.calcularPromedioConsumoPorSegmentos(P60{k, 1}.('kilometrosOdometro') - P60{k, 1}.('kilometrosOdometro')(1), consumoEnergiaRuta{k, 1}, Ruta4020Ida);
                        PromediosVuelta = Calculos.calcularPromedioConsumoPorSegmentos(P60{k, 2}.('kilometrosOdometro') - P60{k, 2}.('kilometrosOdometro')(1), consumoEnergiaRuta{k, 2}, Ruta4020Vuelta);
                    elseif strcmp(IDbus, '4104')
                        PromediosIda = Calculos.calcularPromedioConsumoPorSegmentos(P60{k, 1}.('kilometrosOdometro') - P60{k, 1}.('kilometrosOdometro')(1), consumoEnergiaRuta{k, 1}, Ruta4104Ida);
                        PromediosVuelta = Calculos.calcularPromedioConsumoPorSegmentos(P60{k, 2}.('kilometrosOdometro') - P60{k, 2}.('kilometrosOdometro')(1), consumoEnergiaRuta{k, 2}, Ruta4104Vuelta);
                    end
                    
                    % Almacenar los promedios en la estructura de datos
                    datosBuses.(fecha).(bus).PromediosConsumoIda{k, 1} = PromediosIda;
                    datosBuses.(fecha).(bus).PromediosConsumoVuelta{k, 1} = PromediosVuelta;
                end
            end
        end
    end
    return;
end



        
        %%
        function velocidad = calcularVelocidadMS(datos)
            % Asegurarse de que los datos son una tabla
            if ~istable(datos)
                error('La entrada debe ser una tabla.');
            end
            
            % Asumiendo que las columnas son: tiempo, latitud, longitud
            tiempo = datos.time;
            lat = datos.lat;
            lon = datos.lon;
            
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
            tiempo = datos.time;
            velocidad = Calculos.calcularVelocidadMS(datos);
            n = length(velocidad);
            velocidadCorregida = velocidad;
            
            i = 1;
            while i < n - 1
                % Convertir los objetos duration a segundos
                dt = seconds(tiempo(i+1) - tiempo(i));
                
                % Calcular la pendiente entre dos puntos consecutivos
                %%pendiente = (velocidadCorregida(i+1) - velocidadCorregida(i)) / dt;
                pendiente = (velocidad(i+1) - velocidad(i)) / dt;
                % Si la pendiente supera el umbral, encontrar un punto donde no lo haga
                if abs(pendiente) > umbral
                    j = i + 2; % Iniciar con el siguiente punto
                    
                    while j < n && abs(pendiente) > umbral
                        % Convertir los objetos duration a segundos
                        dt = seconds(tiempo(j) - tiempo(j-1));
                        
                        pendiente = (velocidadCorregida(j) - velocidadCorregida(j-1)) / dt;
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
        
        function curvatura = calcularCurvatura(datos,radio)
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
                
                if (curvatura(i) > radio)
                    curvatura(i) = -1;  % Ajustar el valor de la curvatura si es necesario
                end
            end
        end

        %%

        function porcentajesInterpolados = interpolarPorcentajeBateria(datosBateriaFiltrados, numPuntosInterpolacion)
    % Extraer los tiempos y porcentajes de batería de los datos filtrados
    tiempos = datosBateriaFiltrados{:, 'fechaHoraLecturaDato'};
    porcentajes = datosBateriaFiltrados{:, 'nivelRestanteEnergia'};
    
    % Convertir tiempos a valores numéricos para interpolación
    tiemposNumericos = datenum(tiempos);
    
    % Crear vector de tiempos para la interpolación
    tiemposInterp = linspace(min(tiemposNumericos), max(tiemposNumericos), numPuntosInterpolacion);
    
    % Realizar la interpolación lineal
    porcentajesInterpolados = interp1(tiemposNumericos, porcentajes, tiemposInterp, 'linear');
        end

        %%

     function porcentajeInterpolado = interpolarPorcentajeBateria2(datosFiltrados)
    % Obtener el vector de porcentajes de batería
    porcentajes = datosFiltrados{:, 'nivelRestanteEnergia'};

    % Inicializar el vector de porcentaje interpolado con los valores originales
    porcentajeInterpolado = porcentajes;

    % Encontrar los índices donde cambia el porcentaje de batería
    cambios = find(diff(porcentajes) ~= 0) + 1;  % Incluir índices correctos de los cambios

    % Asegurarse de incluir el primer y último punto
    cambios = unique([1; cambios; length(porcentajes)]);

    % Extraer los valores de porcentaje correspondientes a los índices de cambios
    x = cambios;  % Puntos x donde los cambios ocurren
    y = porcentajes(x);  % Valores de porcentaje en esos puntos

    % Realizar interpolación spline sobre todo el rango
    xq = 1:length(porcentajes);  % Puntos x de consulta para la interpolación
    porcentajeInterpolado = interp1(x, y, xq, 'pchip');  % Cambiado a 'pchip' para evitar problemas de interpolación

     end

     %%

     function porcentajeInterpolado = interpolarPorcentajeBateria3(datosFiltrados)
    % Asegurarse de que 'nivelRestanteEnergia' existe en datosFiltrados
    if ~ismember('nivelRestanteEnergia', datosFiltrados.Properties.VariableNames)
        error('La columna nivelRestanteEnergia no existe en datosFiltrados.');
    end

    % Obtener los porcentajes de la columna 'nivelRestanteEnergia'
    porcentajes = datosFiltrados{:, 'nivelRestanteEnergia'};
    
    % Calcular las diferencias entre elementos consecutivos
    diferencias = diff(porcentajes) ~= 0;
    
    % Obtener los índices donde ocurren cambios
    indicesCambio = find(diferencias) + 1; % +1 porque diff reduce la longitud por 1
    
    % Incluir el primer punto si es diferente al segundo
    indicesCambio = [1; indicesCambio]; 
    
    % Incluir los índices de los valores justo antes de cada cambio
    indicesAnteriores = indicesCambio - 1; % Calcular los índices previos
    indicesAnteriores = indicesAnteriores(indicesAnteriores > 0); % Filtrar índices inválidos

    % Combinar y ordenar los índices de los cambios y sus antecesores
    indicesDeCambio = unique([indicesCambio; indicesAnteriores]); % Combinar y eliminar duplicados

    % Inicializar el vector de porcentaje interpolado
    porcentajeInterpolado = porcentajes;  % Copia inicial de porcentajes
    
    % Umbral para cambio en la pendiente
    umbral = 0.09; 

    % Iniciar con el primer índice de cambio
    i = 1; 
    puntoInicial = indicesDeCambio(i);

    % Bucle principal para la interpolación
    while i < length(indicesDeCambio)
        pendienteInicial = (porcentajes(indicesDeCambio(i+1)) - porcentajes(indicesDeCambio(i))) / (indicesDeCambio(i+1) - indicesDeCambio(i));  % Pendiente inicial
        
        % Buscar el siguiente índice donde la pendiente cambia significativamente
        for j = i + 1:length(indicesDeCambio)
            puntoFinal = indicesDeCambio(j);
            pendienteActual = (porcentajes(puntoFinal) - porcentajes(puntoInicial)) / (puntoFinal - puntoInicial);

            % Verificar si la pendiente actual es significativamente diferente
            if abs(pendienteActual - pendienteInicial) > umbral
                % Interpolar desde el último punto de cambio hasta el actual
                porcentajeInterpolado(puntoInicial:puntoFinal) = linspace(porcentajes(puntoInicial), porcentajes(puntoFinal), puntoFinal - puntoInicial + 1);
                
                % Actualizar i al índice del último punto de cambio y romper el bucle interno
                i = j;
                puntoInicial = puntoFinal;
                break;
            end

            % Si estamos en el último índice, terminar la interpolación
            if j == length(indicesDeCambio)
                porcentajeInterpolado(puntoInicial:end) = linspace(porcentajes(puntoInicial), porcentajes(end), length(porcentajes) - puntoInicial + 1);
                i = length(indicesDeCambio);
            end
        end
    end
end

     %%

     function consumoPorKm = calcularConsumoEnergiaPorKm(datosFiltrados)
    % Capacidad de la batería en kWh
    capacidadBateria = 280;

    % Asegurarse de que 'nivelRestanteEnergiaSuavizado' y 'kilometrosOdometro' existen en datosFiltrados
    if ~ismember('nivelRestanteEnergiaSuavizado', datosFiltrados.Properties.VariableNames)
        error('La columna nivelRestanteEnergiaSuavizado no existe en datosFiltrados.');
    end
    if ~ismember('kilometrosOdometro', datosFiltrados.Properties.VariableNames)
        error('La columna kilometrosOdometro no existe en datosFiltrados.');
    end

    % Obtener los porcentajes de la columna 'nivelRestanteEnergiaSuavizado'
    porcentajes = datosFiltrados{:, 'nivelRestanteEnergiaSuavizado'};
    % Obtener los kilómetros de la columna 'kilometrosOdometro'
    kilometros = datosFiltrados{:, 'kilometrosOdometro'};

    % Interpolar los porcentajes de batería
    porcentajeInterpolado = porcentajes;

    % Calcular la diferencia en porcentaje de la batería y distancia recorrida
    deltaPorcentaje = porcentajeInterpolado(1:end-1) - porcentajeInterpolado(2:end);
    deltaKilometros = kilometros(2:end) - kilometros(1:end-1);

    % Calcular el consumo de energía en kWh para cada segmento
    consumoEnergia = (deltaPorcentaje / 100) * capacidadBateria;


    % Calcular el consumo de energía por km
    consumoPorKm = consumoEnergia ./ deltaKilometros;

    % Definir una tolerancia pequeña para considerar deltaKilometros como cero
    tolerancia = 0.05;

    % Manejar casos donde deltaKilometros es menor que la tolerancia para evitar división por cero
    consumoPorKm(abs(deltaKilometros) < tolerancia) = 0;
end


%%


function datosBuses = calcularPorcentajeBateriaRutas(datosBuses)

    % Esta función calcula el porcentaje de batería para las rutas de cada bus en cada fecha
    % basándose en los tiempos de ruta y los datos del sensor.
    
    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de ruta y datos del sensor para el bus
            if isfield(datosBuses.(fecha).(bus), 'tiempoRuta') && isfield(datosBuses.(fecha).(bus), 'datosSensor')
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;
                datosSensor = datosBuses.(fecha).(bus).P60;
                
                % Calcular el porcentaje de batería para cada trayecto de ida y vuelta en las rutas del día
                for k = 1:size(tiempoRuta, 1)
                    % Trayecto de ida
                    inicioIda = tiempoRuta{k, 1};
                    finIda = tiempoRuta{k, 2};
                    datosIda = datosSensor(datosSensor{:, 7} >= inicioIda & datosSensor{:, 7} <= finIda, :);
                    porcentajeBateriaIda = Calculos.interpolarPorcentajeBateria3(datosIda);
                    
                    % Trayecto de vuelta
                    inicioVuelta = tiempoRuta{k, 2};
                    finVuelta = tiempoRuta{k, 3};
                    datosVuelta = datosSensor(datosSensor{:, 7} >= inicioVuelta & datosSensor{:, 7} <= finVuelta, :);
                    porcentajeBateriaVuelta = Calculos.interpolarPorcentajeBateria3(datosVuelta);
                    
                    % Almacenar los datos calculados de porcentaje de batería en la estructura de datos
                    datosBuses.(fecha).(bus).porcentajeBateriaRuta{k, 1} = porcentajeBateriaIda;
                    datosBuses.(fecha).(bus).porcentajeBateriaRuta{k, 2} = porcentajeBateriaVuelta;
                end
            end
        end
    end

    return;
end


%%

function datosBuses = calcularPromedioVelocidadRutas2(datosBuses)

    % Definir segmentos para las rutas
    Rutas.Ruta4104.Ida = [0.85, 2.1, 4.1, 4.5, 5.2, 8.0, 8.6, 10.5, 13.9];
    Rutas.Ruta4104.Vuelta = [1.18, 2.1, 3.5, 5.2, 10.2, 11.9, 13.5];
    
    Rutas.Ruta4020.Ida = [2.3, 8.1, 11.9, 12.9, 14.8, 19.25];
    Rutas.Ruta4020.Vuelta = [2.04, 5.1, 8.6, 11.13, 14.65, 19.44];
    
    % Segments for week 2 to be added here
    Rutas.RutaXXXX.Ida = [1 2];
    Rutas.RutaXXXX.Vuelta = [1 2];

    Rutas.RutaXXXX.Ida = [1 2];
    Rutas.RutaXXXX.Vuelta = [1 2];

    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};

        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de ruta y datos del sensor para el bus
            if isfield(datosBuses.(fecha).(bus), 'tiempoRuta') && isfield(datosBuses.(fecha).(bus), 'datosSensor')
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;
                datosSensor = datosBuses.(fecha).(bus).datosSensor;

                % Procesar cada ruta del día
                for k = 1:size(tiempoRuta, 1)
                    % Trayecto de ida
                    fechaInicioIda = tiempoRuta{k, 1};
                    fechaFinIda = tiempoRuta{k, 2};
                    ruta = tiempoRuta{k, 4};  % Nombre de la ruta
                    dataFiltradaIda = ImportarDatos.filtrarDatosPorFechas(datosSensor, fechaInicioIda, fechaFinIda);

                    % Trayecto de vuelta
                    fechaInicioVuelta = tiempoRuta{k, 2};
                    fechaFinVuelta = tiempoRuta{k, 3};
                    dataFiltradaVuelta = ImportarDatos.filtrarDatosPorFechas(datosSensor, fechaInicioVuelta, fechaFinVuelta);

                    % Calcular y almacenar los promedios para ida y vuelta según la ruta
                    if isfield(Rutas, ruta)
                        PromediosIda = Calculos.calcularPromedioVelocidadPorSegmentos(dataFiltradaIda, Rutas.(ruta).Ida);
                        PromediosVuelta = Calculos.calcularPromedioVelocidadPorSegmentos(dataFiltradaVuelta, Rutas.(ruta).Vuelta);

                        % Almacenar los promedios en la estructura de datos
                        datosBuses.(fecha).(bus).PromediosIda{k, 1} = PromediosIda;
                        datosBuses.(fecha).(bus).PromediosVuelta{k, 1} = PromediosVuelta;
                    else
                        fprintf('Ruta %s no definida en la estructura de segmentos.\n', ruta);
                    end
                end
            end
        end
    end
    return;
end


%%

function datosBuses = calcularConsumoEnergiaRutas(datosBuses)
    % Esta función calcula el consumo de energía por km para las rutas de cada bus en cada fecha
    % basándose en los tiempos de ruta y los datos del sensor.

    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de ruta y datos del sensor para el bus
            if isfield(datosBuses.(fecha).(bus), 'tiempoRuta') && isfield(datosBuses.(fecha).(bus), 'P60')
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;

                
               % Intentar acceder a los datos de sensor y calcular el consumo de energía
try
    datosSensor = datosBuses.(fecha).(bus).segmentoP60;
    
    % Calcular el consumo de energía para cada trayecto de ida y vuelta en las rutas del día
    for k = 1:size(tiempoRuta, 1)
        % Trayecto de ida
        datosIda = datosSensor{k, 1};
        consumoEnergiaIda = Calculos.calcularConsumoEnergiaPorKm(datosIda);
        
        % Trayecto de vuelta
        datosVuelta = datosSensor{k, 2};
        consumoEnergiaVuelta = Calculos.calcularConsumoEnergiaPorKm(datosVuelta);
        
        % Almacenar los datos calculados de consumo de energía en la estructura de datos
        datosBuses.(fecha).(bus).consumoEnergiaRuta{k, 1} = consumoEnergiaIda;
        datosBuses.(fecha).(bus).consumoEnergiaRuta{k, 2} = consumoEnergiaVuelta;
    end

catch ME
    % Manejo de excepciones en caso de error
    fprintf('Error procesando los datos de %s en el bus %s: %s\n', fecha, bus, ME.message);
    % Aquí podrías también optar por hacer otras acciones como:
    % - Continuar con el siguiente bus/ruta sin detener el proceso
    % - Registrar el error en un archivo log
    % - Notificar a un sistema de monitoreo
end
            end
        end
    end

    return;
end



%%

%%


function marcadores = Lcurvasida4020()% se asegura que todas las curvas de esta ruta correspondan
    datosCordenadasSensor=ImportarDatos.Sensor('Datos\2024-04-15\4020');
    datosCordenadasSensor=ImportarDatos.SensorCordenadas(datosCordenadasSensor);
    fechaInicio='2024-04-15 3:30:23.434';
    fechaFin='2024-04-15 4:50:00.434';
    
    if ischar(fechaInicio) || isstring(fechaInicio)
       fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
       fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    datosCordenadasSensor = datosCordenadasSensor(datosCordenadasSensor.time >= fechaInicio & datosCordenadasSensor.time <= fechaFin, :);
            
            radio=Calculos.calcularCurvatura(datosCordenadasSensor,35);
            %velocidad=Calculos.calcularVelocidadKH(datosCordenadasSensor);
            velocidad=Calculos.corregirVelocidadPendiente(datosCordenadasSensor,3);
            curva=0;
            Ncurva=1;
            j=1;
            % Calcula numero curvatura
            for i = 1:length(radio)
                
                distancia2puntos=Calculos.geodist(datosCordenadasSensor.lat(i+1),datosCordenadasSensor.lon(i+1),datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2));
                if i>=(length(radio)-4)
                    d2=3;
                    d3=3;
                else
                    d2=Calculos.geodist(datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2),datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3));
                    d3=Calculos.geodist(datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3),datosCordenadasSensor.lat(i+4),datosCordenadasSensor.lon(i+4));
                    r1=radio(i);
                    r2=radio(i+1);
                    r3=radio(i+2);
                end
                
                
                if (r1 >1 && r2 >1 && curva==0 && velocidad(i) >1.5 && distancia2puntos>2.5 && d2>2.5 && d3>2.5)%empieza curva
                    marcador(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador(Ncurva,2)=datosCordenadasSensor.lon(i);
                    curva = 1;
                elseif (curva==1 && (r1 > 1 || r2 > 1 || r3 > 1))%la curva no ha terminado
                    
                    
                elseif(r1 < 1 && curva==1)%termina curva
                    marcador2(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador2(Ncurva,2)=datosCordenadasSensor.lon(i);
                    Ncurva = Ncurva + 1;
                    
                    curva = 0;
                end
            end
            
          
            cantidadN=1;
            marcadores{:,1}=marcador;
            marcadores{:,2}=marcador2;
  
end

function marcadores = LcurvasVuelta4020()% se asegura que todas las curvas de esta ruta correspondan
    datosCordenadasSensor=ImportarDatos.Sensor('Datos\2024-04-15\4020');
    datosCordenadasSensor=ImportarDatos.SensorCordenadas(datosCordenadasSensor);
    fechaInicio='15-Apr-2024 3:30:23.434';
    fechaFin='15-Apr-2024 4:50:00.434';
    
%     if ischar(fechaInicio) || isstring(fechaInicio)
%        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
%     end
%     if ischar(fechaFin) || isstring(fechaFin)
%        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
%     end
    datosCordenadasSensor = datosCordenadasSensor(datosCordenadasSensor.time >= fechaInicio & datosCordenadasSensor.time <= fechaFin, :);
            
            radio=Calculos.calcularCurvatura(datosCordenadasSensor,68);
            %velocidad=Calculos.calcularVelocidadKH(datosCordenadasSensor);
            velocidad=Calculos.corregirVelocidadPendiente(datosCordenadasSensor,3);
            curva=0;
            Ncurva=1;
            j=1;
            % Calcula numero curvatura
            for i = 1:length(radio)
                
                distancia2puntos=Calculos.geodist(datosCordenadasSensor.lat(i+1),datosCordenadasSensor.lon(i+1),datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2));
                if i>=(length(radio)-4)
                    d2=3;
                    d3=3;
                else
                    d2=Calculos.geodist(datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2),datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3));
                    d3=Calculos.geodist(datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3),datosCordenadasSensor.lat(i+4),datosCordenadasSensor.lon(i+4));
                    r1=radio(i);
                    r2=radio(i+1);
                    r3=radio(i+2);
                end
                
                
                if (r1 >1 && r2 >1 && curva==0 && velocidad(i) >1.5 && distancia2puntos>2.5 && d2>2.5 && d3>2.5)%empieza curva
                    marcador(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador(Ncurva,2)=datosCordenadasSensor.lon(i);
                    curva = 1;
                elseif (curva==1 && (r1 > 1 || r2 > 1 || r3 > 1))%la curva no ha terminado
                    
                    
                elseif(r1 < 1 && curva==1)%termina curva
                    marcador2(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador2(Ncurva,2)=datosCordenadasSensor.lon(i);
                    Ncurva = Ncurva + 1;
                    
                    curva = 0;
                end
            end
            
          
            cantidadN=1;
            marcador(end,:)=[];
            marcadores{:,1}=marcador;
            
            marcadores{:,2}=marcador2;
  
end
function marcadores=Lcurvasida4104s2()
    datosCordenadasSensor=ImportarDatos.Sensor('Datos\2024-04-23\4104');
    datosCordenadasSensor=ImportarDatos.SensorCordenadas(datosCordenadasSensor);
    fechaInicio='23-Apr-2024 3:30:23.434';
    fechaFin='23-Apr-2024 5:20:00.434';
    
    
    datosCordenadasSensor = datosCordenadasSensor(datosCordenadasSensor.time >= fechaInicio & datosCordenadasSensor.time <= fechaFin, :);
            
            radio=Calculos.calcularCurvatura(datosCordenadasSensor,68);
            %velocidad=Calculos.calcularVelocidadKH(datosCordenadasSensor);
            velocidad=Calculos.corregirVelocidadPendiente(datosCordenadasSensor,3);
            curva=0;
            Ncurva=1;
            j=1;
            % Calcula numero curvatura
            for i = 1:length(radio)
                
                distancia2puntos=Calculos.geodist(datosCordenadasSensor.lat(i+1),datosCordenadasSensor.lon(i+1),datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2));
                if i>=(length(radio)-4)
                    d2=3;
                    d3=3;
                else
                    d2=Calculos.geodist(datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2),datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3));
                    d3=Calculos.geodist(datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3),datosCordenadasSensor.lat(i+4),datosCordenadasSensor.lon(i+4));
                    r1=radio(i);
                    r2=radio(i+1);
                    r3=radio(i+2);
                end
                
                
                if (r1 >1 && r2 >1 && curva==0 && velocidad(i) >1.5 && distancia2puntos>2.5 && d2>2.5 && d3>2.5)%empieza curva
                    marcador(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador(Ncurva,2)=datosCordenadasSensor.lon(i);
                    curva = 1;
                elseif (curva==1 && (r1 > 1 || r2 > 1 || r3 > 1))%la curva no ha terminado
                    
                    
                elseif(r1 < 1 && curva==1)%termina curva
                    marcador2(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador2(Ncurva,2)=datosCordenadasSensor.lon(i);
                    Ncurva = Ncurva + 1;
                    
                    curva = 0;
                end
            end
            
          
            cantidadN=1;
            marcadores{:,1}=marcador;
            marcadores{:,2}=marcador2;
  
end

function marcadores=LcurvasVuelta4104s2()
    datosCordenadasSensor=ImportarDatos.Sensor('Datos\2024-04-23\4104');
    datosCordenadasSensor=ImportarDatos.SensorCordenadas(datosCordenadasSensor);
    fechaInicio='23-Apr-2024 5:00:23.434';
    fechaFin='23-Apr-2024 6:18:00.434';
    
    
    datosCordenadasSensor = datosCordenadasSensor(datosCordenadasSensor.time >= fechaInicio & datosCordenadasSensor.time <= fechaFin, :);
            
            radio=Calculos.calcularCurvatura(datosCordenadasSensor,68);
            %velocidad=Calculos.calcularVelocidadKH(datosCordenadasSensor);
            velocidad=Calculos.corregirVelocidadPendiente(datosCordenadasSensor,3);
            curva=0;
            Ncurva=1;
            j=1;
            % Calcula numero curvatura
            for i = 1:length(radio)
                
                distancia2puntos=Calculos.geodist(datosCordenadasSensor.lat(i+1),datosCordenadasSensor.lon(i+1),datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2));
                if i>=(length(radio)-4)
                    d2=3;
                    d3=3;
                else
                    d2=Calculos.geodist(datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2),datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3));
                    d3=Calculos.geodist(datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3),datosCordenadasSensor.lat(i+4),datosCordenadasSensor.lon(i+4));
                    r1=radio(i);
                    r2=radio(i+1);
                    r3=radio(i+2);
                end
                
                
                if (r1 >1 && r2 >1 && curva==0 && velocidad(i) >1.5 && distancia2puntos>2.5 && d2>2.5 && d3>2.5)%empieza curva
                    marcador(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador(Ncurva,2)=datosCordenadasSensor.lon(i);
                    curva = 1;
                elseif (curva==1 && (r1 > 1 || r2 > 1 || r3 > 1))%la curva no ha terminado
                    
                    
                elseif(r1 < 1 && curva==1)%termina curva
                    marcador2(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador2(Ncurva,2)=datosCordenadasSensor.lon(i);
                    Ncurva = Ncurva + 1;
                    
                    curva = 0;
                end
            end
            
          
            cantidadN=1;
            marcadores{:,1}=marcador;
            marcadores{:,2}=marcador2;
  
end
function marcadores=Lcurvasida4020s2()
    datosCordenadasSensor=ImportarDatos.Sensor('Datos\2024-04-23\4020');
    datosCordenadasSensor=ImportarDatos.SensorCordenadas(datosCordenadasSensor);
    fechaInicio='23-Apr-2024  4:47:00.434';
    fechaFin='23-Apr-2024 6:39:00.434';
    
    
    datosCordenadasSensor = datosCordenadasSensor(datosCordenadasSensor.time >= fechaInicio & datosCordenadasSensor.time <= fechaFin, :);
            
            radio=Calculos.calcularCurvatura(datosCordenadasSensor,75);
            %velocidad=Calculos.calcularVelocidadKH(datosCordenadasSensor);
            velocidad=Calculos.corregirVelocidadPendiente(datosCordenadasSensor,3);
            curva=0;
            Ncurva=1;
            j=1;
            % Calcula numero curvatura
            for i = 1:length(radio)
                
                distancia2puntos=Calculos.geodist(datosCordenadasSensor.lat(i+1),datosCordenadasSensor.lon(i+1),datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2));
                if i>=(length(radio)-4)
                    d2=3;
                    d3=3;
                else
                    d2=Calculos.geodist(datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2),datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3));
                    d3=Calculos.geodist(datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3),datosCordenadasSensor.lat(i+4),datosCordenadasSensor.lon(i+4));
                    r1=radio(i);
                    r2=radio(i+1);
                    r3=radio(i+2);
                end
                
                
                if (r1 >1 && r2 >1 && curva==0 && velocidad(i) >1.5 && distancia2puntos>2.5 && d2>2.5 && d3>2.5)%empieza curva
                    marcador(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador(Ncurva,2)=datosCordenadasSensor.lon(i);
                    curva = 1;
                elseif (curva==1 && (r1 > 1 || r2 > 1 || r3 > 1))%la curva no ha terminado
                    
                    
                elseif(r1 < 1 && curva==1)%termina curva
                    marcador2(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador2(Ncurva,2)=datosCordenadasSensor.lon(i);
                    Ncurva = Ncurva + 1;
                    
                    curva = 0;
                end
            end
            
          
            cantidadN=1;
            marcadores{:,1}=marcador;
            marcadores{:,2}=marcador2;
  
end
function marcadores=LcurvasVuelta4020s2()
    datosCordenadasSensor=ImportarDatos.Sensor('Datos\2024-04-23\4020');
    datosCordenadasSensor=ImportarDatos.SensorCordenadas(datosCordenadasSensor);
    fechaInicio='23-Apr-2024  6:39:00.434';
    fechaFin='23-Apr-2024 7:50:00.434';
    
    
    datosCordenadasSensor = datosCordenadasSensor(datosCordenadasSensor.time >= fechaInicio & datosCordenadasSensor.time <= fechaFin, :);
            
            radio=Calculos.calcularCurvatura(datosCordenadasSensor,75);
            %velocidad=Calculos.calcularVelocidadKH(datosCordenadasSensor);
            velocidad=Calculos.corregirVelocidadPendiente(datosCordenadasSensor,3);
            curva=0;
            Ncurva=1;
            j=1;
            % Calcula numero curvatura
            for i = 1:length(radio)
                
                distancia2puntos=Calculos.geodist(datosCordenadasSensor.lat(i+1),datosCordenadasSensor.lon(i+1),datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2));
                if i>=(length(radio)-4)
                    d2=3;
                    d3=3;
                else
                    d2=Calculos.geodist(datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2),datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3));
                    d3=Calculos.geodist(datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3),datosCordenadasSensor.lat(i+4),datosCordenadasSensor.lon(i+4));
                    r1=radio(i);
                    r2=radio(i+1);
                    r3=radio(i+2);
                end
                
                
                if (r1 >1 && r2 >1 && curva==0 && velocidad(i) >1.5 && distancia2puntos>2.5 && d2>2.5 && d3>2.5)%empieza curva
                    marcador(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador(Ncurva,2)=datosCordenadasSensor.lon(i);
                    curva = 1;
                elseif (curva==1 && (r1 > 1 || r2 > 1 || r3 > 1))%la curva no ha terminado
                    
                    
                elseif(r1 < 1 && curva==1)%termina curva
                    marcador2(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador2(Ncurva,2)=datosCordenadasSensor.lon(i);
                    Ncurva = Ncurva + 1;
                    
                    curva = 0;
                end
            end
            
          
            cantidadN=1;
            marcadores{:,1}=marcador;
            marcadores{:,2}=marcador2;
  
end



function marcadores = Lcurvasida4104()% se asegura que todas las curvas de esta ruta correspondan
    datosCordenadasSensor=ImportarDatos.Sensor('Datos\2024-04-16\4104');
    datosCordenadasSensor=ImportarDatos.SensorCordenadas(datosCordenadasSensor);
    fechaInicio='16-Apr-2024 03:31:19';
    fechaFin='16-Apr-2024 04:40:56';
    
    
    datosCordenadasSensor = datosCordenadasSensor(datosCordenadasSensor.time >= fechaInicio & datosCordenadasSensor.time <= fechaFin, :);
            
            radio=Calculos.calcularCurvatura(datosCordenadasSensor,35);
            %velocidad=Calculos.calcularVelocidadKH(datosCordenadasSensor);
            velocidad=Calculos.corregirVelocidadPendiente(datosCordenadasSensor,3);
            curva=0;
            Ncurva=1;
            j=1;
            % Calcula numero curvatura
            for i = 1:length(radio)
                
                distancia2puntos=Calculos.geodist(datosCordenadasSensor.lat(i+1),datosCordenadasSensor.lon(i+1),datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2));
                if i>=(length(radio)-4)
                    d2=3;
                    d3=3;
                else
                    d2=Calculos.geodist(datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2),datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3));
                    d3=Calculos.geodist(datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3),datosCordenadasSensor.lat(i+4),datosCordenadasSensor.lon(i+4));
                    r1=radio(i);
                    r2=radio(i+1);
                    r3=radio(i+2);
                end
                
                
                if (r1 >1 && r2 >1 && curva==0 && velocidad(i) >1.5 && distancia2puntos>2.5 && d2>2.5 && d3>2.5)%empieza curva
                    marcador(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador(Ncurva,2)=datosCordenadasSensor.lon(i);
                    curva = 1;
                elseif (curva==1 && (r1 > 1 || r2 > 1 || r3 > 1))%la curva no ha terminado
                    
                    
                elseif(r1 < 1 && curva==1)%termina curva
                    marcador2(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador2(Ncurva,2)=datosCordenadasSensor.lon(i);
                    Ncurva = Ncurva + 1;
                    
                    curva = 0;
                end
            end
            
          
            cantidadN=1;
            marcadores{:,1}=marcador;
            marcadores{:,2}=marcador2;
  
end

function marcadores = LcurvasVuelta4104()% se asegura que todas las curvas de esta ruta correspondan
    datosCordenadasSensor=ImportarDatos.Sensor('Datos\2024-04-16\4104');
    datosCordenadasSensor=ImportarDatos.SensorCordenadas(datosCordenadasSensor);
    fechaInicio='16-Apr-2024 04:35:56';
    fechaFin='16-Apr-2024 05:30:24';
    
    
    datosCordenadasSensor = datosCordenadasSensor(datosCordenadasSensor.time >= fechaInicio & datosCordenadasSensor.time <= fechaFin, :);
            
            radio=Calculos.calcularCurvatura(datosCordenadasSensor,60);
            %velocidad=Calculos.calcularVelocidadKH(datosCordenadasSensor);
            velocidad=Calculos.corregirVelocidadPendiente(datosCordenadasSensor,3);
            curva=0;
            Ncurva=1;
            j=1;
            % Calcula numero curvatura
            for i = 1:length(radio)
                
                distancia2puntos=Calculos.geodist(datosCordenadasSensor.lat(i+1),datosCordenadasSensor.lon(i+1),datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2));
                if i>=(length(radio)-4)
                    d2=3;
                    d3=3;
                else
                    d2=Calculos.geodist(datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2),datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3));
                    d3=Calculos.geodist(datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3),datosCordenadasSensor.lat(i+4),datosCordenadasSensor.lon(i+4));
                    r1=radio(i);
                    r2=radio(i+1);
                    r3=radio(i+2);
                end
                
                
                if (r1 >1 && r2 >1 && curva==0 && velocidad(i) >1.5 && distancia2puntos>2.5 && d2>2.5 && d3>2.5)%empieza curva
                    marcador(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador(Ncurva,2)=datosCordenadasSensor.lon(i);
                    curva = 1;
                elseif (curva==1 && (r1 > 1 || r2 > 1 || r3 > 1))%la curva no ha terminado
                    
                    
                elseif(r1 < 1 && curva==1)%termina curva
                    marcador2(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador2(Ncurva,2)=datosCordenadasSensor.lon(i);
                    Ncurva = Ncurva + 1;
                    
                    curva = 0;
                end
            end
            
          
            cantidadN=1;
            marcadores{:,1}=marcador;
            marcadores{:,2}=marcador2;
  
end


        %%
        function datosn=riesgoCurva(datosCordenadasSensor,fechaInicio, fechaFin)
            if ischar(fechaInicio) || isstring(fechaInicio)
                fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
            end
            if ischar(fechaFin) || isstring(fechaFin)
                fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
            end
            datosCordenadasSensor = datosCordenadasSensor(datosCordenadasSensor.time >= fechaInicio & datosCordenadasSensor.time <= fechaFin, :);
            
            radio=Calculos.calcularCurvatura(datosCordenadasSensor,68);
            %velocidad=Calculos.calcularVelocidadKH(datosCordenadasSensor);
            velocidad=Calculos.corregirVelocidadPendiente(datosCordenadasSensor,3);
            curva=0;
            Ncurva=1;
            j=1;
            % Calcula numero curvatura
            for i = 1:length(radio)
                
                distancia2puntos=Calculos.geodist(datosCordenadasSensor.lat(i+1),datosCordenadasSensor.lon(i+1),datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2));
                if i>=(length(radio)-4)
                    d2=3;
                    d3=3;
                else
                    d2=Calculos.geodist(datosCordenadasSensor.lat(i+2),datosCordenadasSensor.lon(i+2),datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3));
                    d3=Calculos.geodist(datosCordenadasSensor.lat(i+3),datosCordenadasSensor.lon(i+3),datosCordenadasSensor.lat(i+4),datosCordenadasSensor.lon(i+4));
                    r1=radio(i);
                    r2=radio(i+1);
                    r3=radio(i+2);
                end
                
                
                if (r1 >1 && r2 >1 && curva==0 && velocidad(i) >1.5 && distancia2puntos>2.5 && d2>2.5 && d3>2.5)%empieza curva
                    marcador(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador(Ncurva,2)=datosCordenadasSensor.lon(i);
                    curva = 1;
                elseif (curva==1 && (r1 > 1 || r2 > 1 || r3 > 1))%la curva no ha terminado
                    datos{Ncurva}(j,1)=velocidad(i);
                    datos{Ncurva}(j,2)=radio(i);
                    datos{Ncurva}(j,3)=velocidad(i)/radio(i);
                    j=j+1;
                elseif(r1 < 1 && curva==1)%termina curva
                    marcador2(Ncurva,1)=datosCordenadasSensor.lat(i);
                    marcador2(Ncurva,2)=datosCordenadasSensor.lon(i);
                    Ncurva = Ncurva + 1;
                    j=1;
                    curva = 0;
                end
            end
            mapita=Map.Curvatura(datosCordenadasSensor, fechaInicio, fechaFin,'titulo');
            hold on
            geoscatter(marcador(:, 1), marcador(:, 2), 'Filled', 'Marker', 'x', 'MarkerEdgeColor', 'red', 'DisplayName', 'Posiciones', 'SizeData', 200);
            geoscatter(marcador2(:, 1), marcador2(:, 2), 'Filled', 'Marker', 'o', 'MarkerEdgeColor', 'blue', 'DisplayName', 'Posiciones', 'SizeData', 100);
            tam=size(datos);%cantidad de curvas
            cantidadN=1;
            
            for i=1:tam(2)
                tamaC=size(datos{1,i});%cantidad de puntos por curva, se dice que debe haber almenos 3 puntos por cuva
                
                if tamaC(1)>3
                    datosn{cantidadN}=datos{1,i};
                    cantidadN=cantidadN+1;
                end
                
            end
            
        end
        
    %%
    
    function datosn = riesgoCurva2(datosCordenadasSensor, fechaInicio, fechaFin, pCurvas)
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone', '');
    end
    datosCordenadasSensor = datosCordenadasSensor(datosCordenadasSensor.time >= fechaInicio & datosCordenadasSensor.time <= fechaFin, :);
            
    radio = Calculos.calcularCurvatura(datosCordenadasSensor,300);
    velocidad = Calculos.corregirVelocidadPendiente(datosCordenadasSensor, 3);
    
    Ccurvas = size(pCurvas{1, 1}, 1); % Número total de curvas
    datosn = cell(1, Ccurvas); % Inicializar celda para almacenar datos de cada curva
   
    for Ncurva = 1:Ccurvas
        inicioCurva = pCurvas{1, 1}(Ncurva, :); % Punto de inicio de la curva
        finCurva = pCurvas{1, 2}(Ncurva, :); % Punto de final de la curva
        
        % Inicializar variables para esta curva
        datosCurva = []; % Almacenar datos de esta curva
        j = 1; % Índice para datos de la curva
        
        % Recorrer los datos de sensor para encontrar los puntos en la curva
        for i = 1:size(datosCordenadasSensor, 1)
    if i <= numel(radio) % Verificar que el índice sea válido para radio
        distanciaInicio = Calculos.geodist(datosCordenadasSensor.lat(i), datosCordenadasSensor.lon(i), inicioCurva(1), inicioCurva(2));
        distanciaFin = Calculos.geodist(datosCordenadasSensor.lat(i), datosCordenadasSensor.lon(i), finCurva(1), finCurva(2));

        if distanciaInicio < 10 % Si estamos cerca del inicio de la curva
            % Guardar los datos de velocidad, radio y relación velocidad/radio
            if ~isnan(radio(i)) && radio(i) ~= -1 % Verificar que radio sea un valor válido
                datosCurva(j, 2) = radio(i);
                datosCurva(j, 1) = velocidad(i);
                datosCurva(j, 3) = velocidad(i) / radio(i);

                if velocidad(i) < 1.5
                    radio(i) = 1;
                end

                if isnan(datosCurva(j, 3))
                    datosCurva(j, 3) = 0;
                end

                j = j + 1;
            end
        elseif distanciaFin < 10 % Si estamos cerca del final de la curva
            break; % Salir del bucle
        end
    else
        break; % Si el índice es mayor que el tamaño de radio, salir del bucle
    end
end

        % Almacenar los datos de esta curva en datosn
        datosn{Ncurva} = datosCurva;
        
        % Calcular el máximo de la columna 3 (relación velocidad/radio) de esta curva
        %if ~isempty(datosCurva) % Verificar si datosCurva no está vacío
        try    
        maximos(Ncurva,1) = mean(datosCurva(:, 3));
        catch
           maximos(Ncurva,1)=0; 
        end
        %end
    end
    
    % Guardar los máximos de cada curva en una variable de salida
    datosn = maximos;
end

    
    %%
        function percentiles = calcularPercentilesConsumo()
            % Rutas a los archivos de datos para cada día de la semana
            rutas = {
                'CarpetaCelulares\semana 1\lunes\4020\LOG',
                'CarpetaCelulares\semana 1\martes\4020\LOG',
                'CarpetaCelulares\semana 1\miercoles\4020\LOG',
                'CarpetaCelulares\semana 1\jueves\4020\LOG',
                'CarpetaCelulares\semana 1\viernes\4020\LOG'
                };
            telefonos={
                'CarpetaCelulares\semana 1\lunes\4020',
                'CarpetaCelulares\semana 1\martes\4020',
                'CarpetaCelulares\semana 1\miercoles\4020',
                'CarpetaCelulares\semana 1\jueves\4020',
                'CarpetaCelulares\semana 1\viernes\4020'
                };
            %se deben filtrar los datos por inicio final
            %osea ida y vuelta
            %luego para todos los de ida en un arreglo se les saca el percentil y para
            %los de vuelta tambien
            Ida4020 = [4.593216, -74.178910];
            Vuelta4020 = [4.6096941, -74.0738544];
            
            for i=1: 5%siempre son 5 dias
                datos = ImportarDatos.Sensor(telefonos{i});
                datos=ImportarDatos.SensorCordenadas(datos);
                tiempos{i}=Calculos.Ruta(datos,Ida4020,Vuelta4020,20);%se guardan tiempos por dias
                
            end
            for i=1:5
                datos = ImportarDatos.P60(rutas{i});
                for j=1:length(tiempos{i})
                    t=tiempos{i};
                    conductor{j,i}=datos(datos.time>=t{j,1} & datos.time<=t{j,2});
                end
            end
            %hasta este punto ya tengo los conductores
            %segmentos de distancias solo ida
            
            
            distancias = [7.35, 14.55, 21.5];
            
            % Inicializa el vector de percentiles
            numper=1;
            
            for i=1:5 %dias de la semana
                for j=1:length(tiempos{i})
                    distanciaR=Calculos.CalcularDistancia(conductor{j,i});%devuelve un arreglo de distancia incrementando
                    valoresP{i,j}(:,1)=distanciaR;
                    valoresP{i,j}(:,2)=conductor{j,i}.nivelRestanteEnergia-conductor{j,i}.nivelRestanteEnergia(1);
                    
                    indices_intervalo = find(valoresP{i,j}(:,1) >= 0 & valoresP{i,j}(:,1) <= distancias(1));
                    % Extraer los datos correspondientes a los intervalos de distancia
                    datos_intervalo = valoresP{i,j}(indices_intervalo, :);
                    percentild1(numper)=sum(datos_intervalo(:,2));%suma de los datos de consumo por primera distancia
                    
                    
                    
                    indices_intervalo = find(valoresP{i,j}(:,1) >= distancias(1) & valoresP{i,j}(:,1) <= distancias(2));
                    % Extraer los datos correspondientes a los intervalos de distancia
                    datos_intervalo = valoresP{i,j}(indices_intervalo, :);
                    percentild2(numper)=sum(datos_intervalo(:,2));%suma de los datos de consumo por primera distancia
                    
                    indices_intervalo = find(valoresP{i,j}(:,1) >= distancias(2) & valoresP{i,j}(:,1) <= distancias(3));
                    % Extraer los datos correspondientes a los intervalos de distancia
                    datos_intervalo = valoresP{i,j}(indices_intervalo, :);
                    percentild3(numper)=sum(datos_intervalo(:,2));%suma de los datos de consumo por primera distancia
                    
                    numper=numper+1;
                    
                end
                
            end
            %ya tengo en un arreglo los valores para hacer el percentil
            
            
            
            %percentiles(i, j) = prctile(franja_actual.nivelRestanteEnergia, 75);
            percentiles=0;
            
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
            
            % % Comprobar si el último viaje iniciado no ha sido cerrado correctamente
            % if estadoViaje == 2
            %     llegadaVuelta = datos{:, 1}(end);
            %     tiempos = [tiempos; {salidaIda, llegadaIda, llegadaVuelta}];
            % end
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
        
        %%
        
        
        function datosBuses = calcularTiemposRutas(datosBuses)
    % Esta función calcula todos los tiempos de ruta para los buses en los datos proporcionados
    % y almacena los resultados directamente en la estructura de entrada datosBuses.
    
    % Definir las rutas con sus coordenadas de ida y vuelta
    rutas = struct();
    rutas.Ruta4020.Ida = [4.593216, -74.178910];
    rutas.Ruta4020.Vuelta = [4.6096941, -74.0738544];
    
    rutas.Ruta4104.Ida = [4.587917000000000, -74.149976900000000];
    rutas.Ruta4104.Vuelta = [4.562243400000000, -74.083503800000000];

    rutas.Ruta4104S2.Ida = [4.587954800000000, -74.172482000000000];
    rutas.Ruta4104S2.Vuelta = [4.652558600000000, -74.061468400000000];
    
    rutas.Ruta4020S2.Ida = [4.575836400000000, -74.168218100000000];
    rutas.Ruta4020S2.Vuelta = [4.676501100000000, -74.141395100000000];
    
    % Fechas disponibles en los datos
    fechas = fieldnames(datosBuses);
    
    % Iterar sobre cada fecha
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            datosSensor = datosBuses.(fecha).(bus).datosSensor;

            if isempty(datosSensor)
                continue;
            end
            
            % Inicializar el campo tiempoRuta como una celda vacía
            datosBuses.(fecha).(bus).tiempoRuta = {};
            
            % Iterar sobre cada ruta y calcular los tiempos de ruta
            rutaNames = fieldnames(rutas);
            for k = 1:numel(rutaNames)
                ruta = rutaNames{k};
                Ida = rutas.(ruta).Ida;
                Vuelta = rutas.(ruta).Vuelta;
                
                % Calcular los tiempos de ruta y almacenar en una celda temporal
                tiempoRutaTemp = Calculos.Ruta(datosSensor, Ida, Vuelta, 20);
                
                % Añadir el nombre de la ruta a cada fila de tiempoRutaTemp
                nombreRuta = repmat({ruta}, size(tiempoRutaTemp, 1), 1);
                tiempoRutaTemp = [tiempoRutaTemp, nombreRuta];
                
                % Concatenar los resultados en el campo tiempoRuta
                datosBuses.(fecha).(bus).tiempoRuta = [datosBuses.(fecha).(bus).tiempoRuta; tiempoRutaTemp];
            end
        end
    end
    
    return;
end

      

%%


function datosBuses = calcularVelocidadRutas(datosBuses)
    % Esta función calcula la velocidad para las rutas de cada bus en cada fecha
    % basándose en los tiempos de ruta y los datos del sensor.
    
    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de ruta y datos del sensor para el bus
            if isfield(datosBuses.(fecha).(bus), 'tiempoRuta') && isfield(datosBuses.(fecha).(bus), 'datosSensor')
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;
                datosSensor = datosBuses.(fecha).(bus).datosSensor;
                
                % Calcular la velocidad para cada trayecto de ida y vuelta en las rutas del día
                for k = 1:size(tiempoRuta, 1)
                    % Trayecto de ida
                    inicioIda = tiempoRuta{k, 1};
                    finIda = tiempoRuta{k, 2};
                    datosIda = datosSensor(datosSensor{:, 1} >= inicioIda & datosSensor{:, 1} <= finIda, :);
                    velocidadIda = Calculos.corregirVelocidadPendiente(datosIda, 3);
                    
                    % Trayecto de vuelta
                    inicioVuelta = tiempoRuta{k, 2};
                    finVuelta = tiempoRuta{k, 3};
                    datosVuelta = datosSensor(datosSensor{:, 1} >= inicioVuelta & datosSensor{:, 1} <= finVuelta, :);
                    velocidadVuelta = Calculos.corregirVelocidadPendiente(datosVuelta, 3);
                    
                    % Almacenar los datos calculados de velocidad en la estructura de datos
                    datosBuses.(fecha).(bus).velocidadRuta{k, 1} = velocidadIda;
                    datosBuses.(fecha).(bus).velocidadRuta{k, 2} = velocidadVuelta;
                end
            end
        end
    end

    return;

end

%%

function datosBuses = calcularAceleracionRutas(datosBuses)
    % Esta función calcula la aceleración para las rutas de cada bus en cada fecha
    % basándose en los datos de velocidad ya calculados.
    
    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de velocidad para el bus
            if isfield(datosBuses.(fecha).(bus), 'velocidadRuta')
                velocidadRuta = datosBuses.(fecha).(bus).velocidadRuta;
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;
                datosSensor = datosBuses.(fecha).(bus).datosSensor;
                
                % Calcular la aceleración para cada trayecto de ida y vuelta en las rutas del día
                for k = 1:size(velocidadRuta, 1)
                    % Datos de velocidad de ida y de vuelta
                    velocidadIda = velocidadRuta{k, 1};
                    velocidadVuelta = velocidadRuta{k, 2};
                    
                    % Tiempos de los datos de velocidad
                    inicioIda = tiempoRuta{k, 1};
                    finIda = tiempoRuta{k, 2};

                    % Calcular aceleración de ida
                    aceleracionIda = diff(velocidadIda);
                    
                    % Calcular aceleración de vuelta
                    aceleracionVuelta = diff(velocidadVuelta);
                    
                    % Almacenar los datos calculados de aceleración en la estructura de datos
                    datosBuses.(fecha).(bus).aceleracionRuta{k, 1} =  aceleracionIda;
                    datosBuses.(fecha).(bus).aceleracionRuta{k, 2} =  aceleracionVuelta;
                end
            end
        end
    end

    return;
end

%%

function datosBuses = extraerP60(datosBuses)
    % Esta función extrae segmentos de la tabla P60 para cada ruta de cada bus en cada fecha.

    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de ruta y datos P60 para el bus
            if isfield(datosBuses.(fecha).(bus), 'tiempoRuta') && isfield(datosBuses.(fecha).(bus), 'P60')
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;
                datosP60 = datosBuses.(fecha).(bus).P60;
                
                % Calcular y almacenar el segmento P60 para cada trayecto de ida y vuelta en las rutas del día
                for k = 1:size(tiempoRuta, 1)
                    % Trayecto de ida
                    inicioIda = tiempoRuta{k, 1};
                    finIda = tiempoRuta{k, 2};
                    segmentoP60Ida = datosP60(datosP60.fechaHoraLecturaDato >= inicioIda & datosP60.fechaHoraLecturaDato <= finIda, :);
                    
                    % Almacenar los segmentos P60 en la estructura de datos
                    datosBuses.(fecha).(bus).segmentoP60{k, 1} = segmentoP60Ida;
                end
            end
        end
    end

    return;
end


%%

function datosBuses = extraerSegmentosDatos(datosBuses)
    % Esta función extrae segmentos de datosSensor para cada ruta de cada bus en cada fecha.

    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de ruta y datosSensor para el bus
            if isfield(datosBuses.(fecha).(bus), 'tiempoRuta') && isfield(datosBuses.(fecha).(bus), 'datosSensor')
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;
                datosSensor = datosBuses.(fecha).(bus).datosSensor;
                
                % Calcular y almacenar los segmentos de datosSensor para cada trayecto de ida y vuelta en las rutas del día
                for k = 1:size(tiempoRuta, 1)
                    % Trayecto de ida
                    inicioIda = tiempoRuta{k, 1};
                    finIda = tiempoRuta{k, 2};
                    segmentoDatosIda = ImportarDatos.filtrarDatosPorFechas(datosSensor, inicioIda, finIda);
                    
                    % Trayecto de vuelta
                    inicioVuelta = tiempoRuta{k, 2};
                    finVuelta = tiempoRuta{k, 3};
                    segmentoDatosVuelta = ImportarDatos.filtrarDatosPorFechas(datosSensor, inicioVuelta, finVuelta);
                    
                    % Almacenar los segmentos de datosSensor en la estructura de datos
                    if ~isfield(datosBuses.(fecha).(bus), 'segmentosDatos')
                        datosBuses.(fecha).(bus).segmentosDatos = cell(size(tiempoRuta, 1), 2);
                    end
                    datosBuses.(fecha).(bus).segmentosDatos{k, 1} = segmentoDatosIda;
                    datosBuses.(fecha).(bus).segmentosDatos{k, 2} = segmentoDatosVuelta;
                end
            end
        end
    end

    return;
end



%%

function datosBuses = extraerEV1(datosBuses)
    % Esta función extrae segmentos de la tabla EV1 para cada ruta de cada bus en cada fecha.

    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de ruta y datos EV1 para el bus
            if isfield(datosBuses.(fecha).(bus), 'tiempoRuta') && isfield(datosBuses.(fecha).(bus), 'EV1')
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;
                datosEV1 = datosBuses.(fecha).(bus).EV1;
                
                % Calcular y almacenar el segmento EV1 para cada trayecto de ida y vuelta en las rutas del día
                for k = 1:size(tiempoRuta, 1)
                    % Trayecto de ida
                    inicioIda = tiempoRuta{k, 1};
                    finIda = tiempoRuta{k, 2};
                    segmentoEV1Ida = datosEV1(datosEV1.fechaHoraLecturaDato >= inicioIda & datosEV1.fechaHoraLecturaDato <= finIda, :);
                    
                    % Trayecto de vuelta
                    inicioVuelta = tiempoRuta{k, 2};
                    finVuelta = tiempoRuta{k, 3};
                    segmentoEV1Vuelta = datosEV1(datosEV1.fechaHoraLecturaDato >= inicioVuelta & datosEV1.fechaHoraLecturaDato <= finVuelta, :);
                    
                    % Almacenar los segmentos EV1 en la estructura de datos
                    datosBuses.(fecha).(bus).segmentoEV1{k, 1} = segmentoEV1Ida;
                    datosBuses.(fecha).(bus).segmentoEV1{k, 2} = segmentoEV1Vuelta;
                end
            end
        end
    end

    return;
end

%%

function datosBuses = extraerEV2(datosBuses)
    % Esta función extrae segmentos de la tabla EV2 para cada ruta de cada bus en cada fecha.

    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de ruta y datos EV2 para el bus
            if isfield(datosBuses.(fecha).(bus), 'tiempoRuta') && isfield(datosBuses.(fecha).(bus), 'EV2')
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;
                datosEV2 = datosBuses.(fecha).(bus).EV2;
                
                % Calcular y almacenar el segmento EV2 para cada trayecto de ida y vuelta en las rutas del día
                for k = 1:size(tiempoRuta, 1)
                    % Trayecto de ida
                    inicioIda = tiempoRuta{k, 1};
                    finIda = tiempoRuta{k, 2};
                    segmentoEV2Ida = datosEV2(datosEV2.fechaHoraLecturaDato >= inicioIda & datosEV2.fechaHoraLecturaDato <= finIda, :);
                    
                    % Trayecto de vuelta
                    inicioVuelta = tiempoRuta{k, 2};
                    finVuelta = tiempoRuta{k, 3};
                    segmentoEV2Vuelta = datosEV2(datosEV2.fechaHoraLecturaDato >= inicioVuelta & datosEV2.fechaHoraLecturaDato <= finVuelta, :);
                    
                    % Almacenar los segmentos EV2 en la estructura de datos
                    datosBuses.(fecha).(bus).segmentoEV2{k, 1} = segmentoEV2Ida;
                    datosBuses.(fecha).(bus).segmentoEV2{k, 2} = segmentoEV2Vuelta;
                end
            end
        end
    end

    return;
end

%%

function datosBuses = extraerEV8(datosBuses)
    % Esta función extrae segmentos de la tabla EV8 para cada ruta de cada bus en cada fecha.

    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de ruta y datos EV8 para el bus
            if isfield(datosBuses.(fecha).(bus), 'tiempoRuta') && isfield(datosBuses.(fecha).(bus), 'EV8')
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;
                datosEV8 = datosBuses.(fecha).(bus).EV8;
                
                % Calcular y almacenar el segmento EV8 para cada trayecto de ida y vuelta en las rutas del día
                for k = 1:size(tiempoRuta, 1)
                    % Trayecto de ida
                    inicioIda = tiempoRuta{k, 1};
                    finIda = tiempoRuta{k, 2};
                    segmentoEV8Ida = datosEV8(datosEV8.fechaHoraLecturaDato >= inicioIda & datosEV8.fechaHoraLecturaDato <= finIda, :);
                    
                    % Trayecto de vuelta
                    inicioVuelta = tiempoRuta{k, 2};
                    finVuelta = tiempoRuta{k, 3};
                    segmentoEV8Vuelta = datosEV8(datosEV8.fechaHoraLecturaDato >= inicioVuelta & datosEV8.fechaHoraLecturaDato <= finVuelta, :);
                    
                    % Almacenar los segmentos EV8 en la estructura de datos
                    datosBuses.(fecha).(bus).segmentoEV8{k, 1} = segmentoEV8Ida;
                    datosBuses.(fecha).(bus).segmentoEV8{k, 2} = segmentoEV8Vuelta;
                end
            end
        end
    end

    return;
end

%%

function datosBuses = extraerEV18(datosBuses)
    % Esta función extrae segmentos de la tabla EV18 para cada ruta de cada bus en cada fecha.

    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de ruta y datos EV18 para el bus
            if isfield(datosBuses.(fecha).(bus), 'tiempoRuta') && isfield(datosBuses.(fecha).(bus), 'EV18')
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;
                datosEV18 = datosBuses.(fecha).(bus).EV18;
                
                % Calcular y almacenar el segmento EV18 para cada trayecto de ida y vuelta en las rutas del día
                for k = 1:size(tiempoRuta, 1)
                    % Trayecto de ida
                    inicioIda = tiempoRuta{k, 1};
                    finIda = tiempoRuta{k, 2};
                    segmentoEV18Ida = datosEV18(datosEV18.fechaHoraLecturaDato >= inicioIda & datosEV18.fechaHoraLecturaDato <= finIda, :);
                    
                    % Trayecto de vuelta
                    inicioVuelta = tiempoRuta{k, 2};
                    finVuelta = tiempoRuta{k, 3};
                    segmentoEV18Vuelta = datosEV18(datosEV18.fechaHoraLecturaDato >= inicioVuelta & datosEV18.fechaHoraLecturaDato <= finVuelta, :);
                    
                    % Almacenar los segmentos EV18 en la estructura de datos
                    datosBuses.(fecha).(bus).segmentoEV18{k, 1} = segmentoEV18Ida;
                    datosBuses.(fecha).(bus).segmentoEV18{k, 2} = segmentoEV18Vuelta;
                end
            end
        end
    end

    return;
end


%%

function datosBuses = extraerEV19(datosBuses)
    % Esta función extrae segmentos de la tabla EV19 para cada ruta de cada bus en cada fecha.

    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de ruta y datos EV19 para el bus
            if isfield(datosBuses.(fecha).(bus), 'tiempoRuta') && isfield(datosBuses.(fecha).(bus), 'EV19')
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;
                datosEV19 = datosBuses.(fecha).(bus).EV19;
                
                % Filtrar los datos del evento 19
                datosEvento19 = datosEV19(datosEV19.codigoEvento == "EV19", :);
                
                % Inicializar tablas de salida para cada tipo
                tabla1 = table();
                tabla2 = table();
                tabla3 = table();
                tabla4 = table();
                
                % Verificar y asignar datos para cada código de comportamiento anómalo
                for codigo = 1:4
                    datosFiltrados = datosEvento19(datosEvento19.codigoComportamientoAnomalo == string(codigo), {'fechaHoraLecturaDato', 'latitud', 'longitud', 'codigoComportamientoAnomalo'});
                    switch codigo
                        case 1
                            tabla1 = datosFiltrados;
                        case 2
                            tabla2 = datosFiltrados;
                        case 3
                            tabla3 = datosFiltrados;
                        case 4
                            tabla4 = datosFiltrados;
                    end
                end
                
                % Calcular y almacenar el segmento EV19 para cada trayecto de ida y vuelta en las rutas del día
                for k = 1:size(tiempoRuta, 1)
                    % Trayecto de ida
                    inicioIda = tiempoRuta{k, 1};
                    finIda = tiempoRuta{k, 2};
                    segmentoEV19_1_Ida = tabla1(tabla1.fechaHoraLecturaDato >= inicioIda & tabla1.fechaHoraLecturaDato <= finIda, :);
                    segmentoEV19_2_Ida = tabla2(tabla2.fechaHoraLecturaDato >= inicioIda & tabla2.fechaHoraLecturaDato <= finIda, :);
                    segmentoEV19_3_Ida = tabla3(tabla3.fechaHoraLecturaDato >= inicioIda & tabla3.fechaHoraLecturaDato <= finIda, :);
                    segmentoEV19_4_Ida = tabla4(tabla4.fechaHoraLecturaDato >= inicioIda & tabla4.fechaHoraLecturaDato <= finIda, :);
                    
                    % Trayecto de vuelta
                    inicioVuelta = tiempoRuta{k, 2};
                    finVuelta = tiempoRuta{k, 3};
                    segmentoEV19_1_Vuelta = tabla1(tabla1.fechaHoraLecturaDato >= inicioVuelta & tabla1.fechaHoraLecturaDato <= finVuelta, :);
                    segmentoEV19_2_Vuelta = tabla2(tabla2.fechaHoraLecturaDato >= inicioVuelta & tabla2.fechaHoraLecturaDato <= finVuelta, :);
                    segmentoEV19_3_Vuelta = tabla3(tabla3.fechaHoraLecturaDato >= inicioVuelta & tabla3.fechaHoraLecturaDato <= finVuelta, :);
                    segmentoEV19_4_Vuelta = tabla4(tabla4.fechaHoraLecturaDato >= inicioVuelta & tabla4.fechaHoraLecturaDato <= finVuelta, :);
                    
                    % Almacenar los segmentos EV19 en la estructura de datos
                    datosBuses.(fecha).(bus).segmentoEV19_1{k, 1} = segmentoEV19_1_Ida;
                    datosBuses.(fecha).(bus).segmentoEV19_1{k, 2} = segmentoEV19_1_Vuelta;
                    datosBuses.(fecha).(bus).segmentoEV19_2{k, 1} = segmentoEV19_2_Ida;
                    datosBuses.(fecha).(bus).segmentoEV19_2{k, 2} = segmentoEV19_2_Vuelta;
                    datosBuses.(fecha).(bus).segmentoEV19_3{k, 1} = segmentoEV19_3_Ida;
                    datosBuses.(fecha).(bus).segmentoEV19_3{k, 2} = segmentoEV19_3_Vuelta;
                    datosBuses.(fecha).(bus).segmentoEV19_4{k, 1} = segmentoEV19_4_Ida;
                    datosBuses.(fecha).(bus).segmentoEV19_4{k, 2} = segmentoEV19_4_Vuelta;
                end
            end
        end
    end

    return;
end


%%


function datosBuses = calcularPicosAceleracionRutas(datosBuses)
    % Esta función calcula los picos de aceleración para las rutas de cada bus en cada fecha
    % basándose en los tiempos de ruta y los datos del sensor.
    
    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de ruta y datos del sensor para el bus
            if isfield(datosBuses.(fecha).(bus), 'tiempoRuta') && isfield(datosBuses.(fecha).(bus), 'datosSensor')
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;
                datosSensor = datosBuses.(fecha).(bus).datosSensor;
                
                % Calcular los picos de aceleración para cada trayecto de ida y vuelta en las rutas del día
                for k = 1:size(tiempoRuta, 1)
                    % Trayecto de ida
                    inicioIda = tiempoRuta{k, 1};
                    finIda = tiempoRuta{k, 2};
                    datosIda = datosSensor(datosSensor{:, 1} >= inicioIda & datosSensor{:, 1} <= finIda, :);
                    aceleracionIda = datosBuses.(fecha).(bus).aceleracionRuta{k, 1};
                    picosIda = Calculos.encontrarPicos(aceleracionIda);
                    
                    % Trayecto de vuelta
                    inicioVuelta = tiempoRuta{k, 2};
                    finVuelta = tiempoRuta{k, 3};
                    datosVuelta = datosSensor(datosSensor{:, 1} >= inicioVuelta & datosSensor{:, 1} <= finVuelta, :);
                    aceleracionVuelta = datosBuses.(fecha).(bus).aceleracionRuta{k, 2};
                    picosVuelta = Calculos.encontrarPicos(aceleracionVuelta);
                    
                    % Almacenar los datos de picos de aceleración en la estructura de datos
                    datosBuses.(fecha).(bus).picosAceleracion{k, 1} = picosIda;
                    datosBuses.(fecha).(bus).picosAceleracion{k, 2} = picosVuelta;
                end
            end
        end
    end

    return;
end

function picos = encontrarPicos(aceleracion)
    % Esta función encuentra los picos en los datos de aceleración, tanto positivos como negativos
    % Utiliza la función findpeaks de MATLAB para identificar los picos y valles.
    
    % Asegurarse de que la aceleración sea un vector
    if ~isvector(aceleracion)
        aceleracion = aceleracion(:);  % Convertir a vector si no lo es
    end
    
    % Encontrar picos positivos (aceleración hacia arriba)
    [picosPositivos, ~] = findpeaks(aceleracion);
    
    % Encontrar picos negativos (aceleración hacia abajo) invirtiendo el signo de la aceleración
    [picosNegativos, ~] = findpeaks(-aceleracion);
    picosNegativos = -picosNegativos;  % Revertir el signo para obtener los valores originales de los valles como picos negativos
    
    % Combinar los picos positivos y negativos en un solo array
    picos = [picosPositivos; picosNegativos];
    
    return;
end

%%

function datosBuses = calcularPosAceleracion(datosBuses)
    % Esta función calcula los promedios de aceleración para valores por
    % encima y por debajo de 0.8 m/s^2 y actualiza la estructura datosBuses

    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de aceleración para el bus
            if isfield(datosBuses.(fecha).(bus), 'aceleracionRuta')
               
                
                % Iterar sobre cada trayecto de ida y vuelta en las rutas del día
                for k = 1:size(datosBuses.(fecha).(bus).aceleracionRuta, 1)


                     % Inicializar sumas y conteos para los promedios
              


                    % Obtener las aceleraciones de ida y vuelta
                    aceleracionIda = datosBuses.(fecha).(bus).aceleracionRuta{k, 1};
                    aceleracionVuelta = datosBuses.(fecha).(bus).aceleracionRuta{k, 2};
                    
                    % Filtrar y acumular las aceleraciones mayores y menores que 0.8 m/s^2
                    sumaAltoIda = sum(aceleracionIda(aceleracionIda > 0.8));
                    conteoAltoIda = sum(aceleracionIda > 0.8);

                    % Filtrar y acumular las aceleraciones mayores y menores que 0.8 m/s^2
                    sumaAltoVuelta = sum(aceleracionVuelta(aceleracionVuelta > 0.8));
                    conteoAltoVuelta = sum(aceleracionVuelta > 0.8);
                    
                    sumaBajoIda = sum(aceleracionIda(aceleracionIda <= 0.8));
                    conteoBajoIda = sum(aceleracionIda <= 0.8);

                    sumaBajoVuelta = sum(aceleracionVuelta(aceleracionVuelta <= 0.8));
                    conteoBajoVuelta = sum(aceleracionVuelta <= 0.8);



                    % Calcular los promedios
                if conteoAltoIda > 0
                    promedioAltoIda = sumaAltoIda / conteoAltoIda;
                else
                    promedioAltoIda = NaN; % Si no hay valores por encima de 0.8, retornar NaN
                end

                if conteoBajoIda > 0
                    promedioBajoIda = sumaBajoIda / conteoBajoIda;
                else
                    promedioBajoIda = NaN; % Si no hay valores por debajo de 0.8, retornar NaN
                end

                if conteoAltoVuelta > 0
                    promedioAltoVuelta = sumaAltoVuelta / conteoAltoVuelta;
                else
                    promedioAltoVuelta = NaN; % Si no hay valores por encima de 0.8, retornar NaN
                end

                if conteoBajoVuelta > 0
                    promedioBajoVuelta = sumaBajoVuelta / conteoBajoVuelta;
                else
                    promedioBajoVuelta = NaN; % Si no hay valores por debajo de 0.8, retornar NaN
                end
                
                % Actualizar la estructura con los promedios calculados
                datosBuses.(fecha).(bus).promedioAceleracionAlto{k, 1} = promedioAltoIda;
                datosBuses.(fecha).(bus).promedioAceleracionBajo{k, 1} = promedioBajoIda;

                % Actualizar la estructura con los promedios calculados
                datosBuses.(fecha).(bus).promedioAceleracionAlto{k, 2} = promedioAltoVuelta;
                datosBuses.(fecha).(bus).promedioAceleracionBajo{k, 2} = promedioBajoVuelta;

                % Actualizar la estructura con los promedios calculados
                datosBuses.(fecha).(bus).conteoAceleracionAlto{k, 1} = conteoAltoIda;
                datosBuses.(fecha).(bus).conteoAceleracionBajo{k, 1} = conteoBajoIda;

                % Actualizar la estructura con los promedios calculados
                datosBuses.(fecha).(bus).conteoAceleracionAlto{k, 2} = conteoAltoVuelta;
                datosBuses.(fecha).(bus).conteoAceleracionBajo{k, 2} = conteoBajoVuelta;



                end
                
                
            end
        end
    end
end


%%

function datosBuses = aproximarNivelBateria(datosBuses)
    % Esta función calcula y almacena una versión suavizada del nivel de batería para cada bus en cada fecha.
    
    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de nivel de batería para el bus
            if isfield(datosBuses.(fecha).(bus), 'P60')
                % Acceder a los datos de nivel de batería
                datosP60 = datosBuses.(fecha).(bus).P60;
                
                
                    % Acceder al nivel de batería del segmento
                    nivelBateria = datosP60.nivelRestanteEnergia;
                    
                    % Suavizar el nivel de batería usando un filtro de Savitzky-Golay
                    ordenPol = 3; % Orden del polinomio
                    ventana = 65; % Longitud de la ventana, debe ser impar
                    if length(nivelBateria) >= ventana % Asegurarse de que hay suficientes datos para aplicar el filtro
                        nivelBateriaSuavizado = sgolayfilt(nivelBateria, ordenPol, ventana);
                    else
                        nivelBateriaSuavizado = nivelBateria; % No se aplica filtro si no hay suficientes datos
                    end
                    
                    % Almacenar los datos suavizados de nivel de batería en un nuevo campo en la estructura de datos
                    datosBuses.(fecha).(bus).P60.nivelRestanteEnergiaSuavizado = nivelBateriaSuavizado;
               
            end
        end
    end

    return;
end



%%

function datosBuses = calcularAceleracionRutas2(datosBuses)
    % Esta función calcula la aceleración para las rutas de cada bus en cada fecha
    % basándose en los tiempos de ruta y los datos del sensor.
    
    % Iterar sobre todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    for i = 1:numel(fechas)
        fecha = fechas{i};
        
        % Buscar cada tipo de bus en la fecha actual
        buses = fieldnames(datosBuses.(fecha));
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Asegurarse de que existen datos de ruta y datos del sensor para el bus
            if isfield(datosBuses.(fecha).(bus), 'tiempoRuta') && isfield(datosBuses.(fecha).(bus), 'datosSensor')
                tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;
                datosSensor = datosBuses.(fecha).(bus).datosSensor;
                
                % Calcular la aceleración para cada trayecto de ida y vuelta en las rutas del día
                for k = 1:size(tiempoRuta, 1)
                    % Trayecto de ida
                    inicioIda = tiempoRuta{k, 1};
                    finIda = tiempoRuta{k, 2};
                    datosIda = datosSensor(datosSensor{:, 1} >= inicioIda & datosSensor{:, 1} <= finIda, :);
                    aceleracionIda = Calculos.calcularAceleracionFiltrada(datosIda, 3);
                    
                    % Trayecto de vuelta
                    inicioVuelta = tiempoRuta{k, 2};
                    finVuelta = tiempoRuta{k, 3};
                    datosVuelta = datosSensor(datosSensor{:, 1} >= inicioVuelta & datosSensor{:, 1} <= finVuelta, :);
                    aceleracionVuelta = Calculos.calcularAceleracionFiltrada(datosVuelta, 3);
                    
                    % Almacenar los datos calculados de aceleración en la estructura de datos
                    datosBuses.(fecha).(bus).aceleracionRuta{k, 1} = aceleracionIda;
                    datosBuses.(fecha).(bus).aceleracionRuta{k, 2} = aceleracionVuelta;
                end
            end
        end
    end

    return;
end



        %%

        function busesOrganizados = reorganizarDatosPorBus(tiemposRutas)
            % Esta función reorganiza los tiempos de ruta para acceder primero por bus y luego por fecha.
            
            % Inicializar estructura para los datos organizados por bus
            % Inicialización segura con un campo dummy que será eliminado después
            busesOrganizados = struct('dummyField', []);
            
            % Extraer las fechas disponibles de la estructura de entrada
            fechas = fieldnames(tiemposRutas);
            
            % Preparar subestructuras para cada bus
            busesOrganizados.bus4104 = struct();
            busesOrganizados.bus4020 = struct();
            
            % Iterar sobre cada fecha para reorganizar los datos
            for i = 1:numel(fechas)
                fecha = fechas{i};
                
                % Extraer los datos de cada bus para esta fecha, si están disponibles
                if isfield(tiemposRutas.(fecha), 'bus4104')
                    busesOrganizados.bus4104.(fecha) = tiemposRutas.(fecha).bus4104;
                end
                if isfield(tiemposRutas.(fecha), 'bus4020')
                    busesOrganizados.bus4020.(fecha) = tiemposRutas.(fecha).bus4020;
                end
            end
            
            % Eliminar el campo dummy si se había agregado
            if isfield(busesOrganizados, 'dummyField')
                busesOrganizados = rmfield(busesOrganizados, 'dummyField');
            end
            
            return ;
        end
        
        
        
        
        
        
    end
end

%%
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






