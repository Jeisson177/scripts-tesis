classdef Calcular
    methods (Static)

        %%
        function datosBuses = velocidadTotal(datosBuses, unidades, filtro)
            % Esta función calcula la velocidad total para los datos de sensores de cada bus en cada fecha.
            % La velocidad se puede calcular en kilómetros por hora (kph) o metros por segundo (mps).
            % Un filtro puede ser aplicado si se especifica.

            % Validar la entrada de unidades
            if nargin < 2 || isempty(unidades)
                unidades = 'm/s'; % valor por defecto
            end
            if nargin < 3
                filtro = 'sin_filtro'; % valor por defecto
            end

            % Almacenar la información general de unidades y filtro en la estructura principal
            datosBuses.info.velocidad.unidades = unidades;
            datosBuses.info.velocidad.filtro = filtro;

            % Obtener los campos de los buses
            buses = fieldnames(datosBuses);

            % Iterar sobre cada bus
            for i = 1:numel(buses)
                bus = buses{i};

                % Saltar el campo 'info'
                if strcmp(bus, 'info')
                    continue;
                end

                % Obtener los campos de las fechas para el bus actual
                fechas = fieldnames(datosBuses.(bus));

                % Iterar sobre cada fecha
                for j = 1:numel(fechas)
                    fecha = fechas{j};

                    % Verificar si existen datos del sensor para la fecha actual
                    if isfield(datosBuses.(bus).(fecha), 'datosSensor')
                        datosSensor = datosBuses.(bus).(fecha).datosSensor;

                        if isempty(datosSensor)
                            continue;
                        end

                        % Calcular la velocidad total con el filtro especificado
                        velocidadTotal = Calcular.velocidadConFiltro(datosSensor, 'time', 'lat', 'lon', filtro);


                        % Convertir la velocidad según las unidades especificadas
                        try
                            if ~strcmp(unidades, 'm/s')
                                velocidadTotal = convvel(velocidadTotal, 'm/s', unidades);
                            end
                        catch
                            warning('No se pudo convertir la velocidad a las unidades especificadas: %s. Se dejará en m/s.', unidades);
                        end

                        % Almacenar los datos calculados de velocidad en la estructura de datos
                        datosBuses.(bus).(fecha).(['velocidadTotal_' strrep(unidades, '/', '_')]) = velocidadTotal;

                        % Mostrar mensaje de confirmación
                        disp(['Procesamiento completado para bus ' bus ' en la fecha ' fecha '.']);

                    end
                end
            end
        end

        %%
        function trayectoria_filtrada = filtraGPS_mediana(datosBuses, k)
            % lat, lon: vectores columna o fila de posiciones
            % ventana: número impar, tamaño de la ventana de filtrado
            lat = datosBuses.datosSensorRuta{k, 2}.lat;
            lon = datosBuses.datosSensorRuta{k, 2}.lon;
            lat_f = medfilt1(lat, ventana);
            lon_f = medfilt1(lon, ventana);
            trayectoria_filtrada = [lat_f(:), lon_f(:)];
        end


        %%

        function trayectoria_filtrada = filtraGPS_kalman(datosBuses, k)
            lat = datosBuses.datosSensorRuta{k, 2}.lat;
            lon = datosBuses.datosSensorRuta{k, 2}.lon;
            t = datosBuses.datosSensorRuta{k, 2}.time;

            N = length(lat);
            trayectoria_filtrada = zeros(N, 2);

            % Estado inicial: [lat; lon; vlat; vlon; alat; alon]
            Xk = [lat(1); lon(1); 0; 0; 0; 0];
            Pk = 1e-3 * eye(6);

            % Ajusta según tu caso
            sigma_gps = 5 / 111320; % 5 metros de error típico GPS
            R = (sigma_gps^2) * eye(2);

            Q_base = (1e-9 * eye(6))/10000; % Ajusta según comportamiento del bus

            for i = 1:N
                if i == 1
                    dt = 0.1; % Valor pequeño para el primer ciclo
                else
                    dt = seconds(t(i) - t(i-1));
                    if dt <= 0, dt = 0.1; end
                end

                % F y Q actualizadas en cada ciclo
                F = [1 0 dt 0 0.5*dt^2 0;
                    0 1 0 dt 0 0.5*dt^2;
                    0 0 1 0 dt 0;
                    0 0 0 1 0 dt;
                    0 0 0 0 1 0;
                    0 0 0 0 0 1];

                % Escalamiento opcional de Q con dt (si hay mucho cambio en dt)
                Q = Q_base * (1 + dt);

                % Predicción
                Xk_pred = F * Xk;
                Pk_pred = F * Pk * F' + Q;

                % Medición
                zk = [lat(i); lon(i)];

                % Actualización
                H = [1 0 0 0 0 0; 0 1 0 0 0 0];
                K = Pk_pred * H' / (H * Pk_pred * H' + R);
                Xk = Xk_pred + K * (zk - H * Xk_pred);
                Pk = (eye(6) - K * H) * Pk_pred;

                trayectoria_filtrada(i, :) = Xk(1:2)';
            end
        end

        %%
        function datosBuses = kalmanFiltro2D(datosBuses, k)


            lat = datosBuses.datosSensorRuta{k, 2}.lat(:);
            lon = datosBuses.datosSensorRuta{k, 2}.lon(:);
            t = datosBuses.datosSensorRuta{k, 2}.time(:);
            N = numel(t);

            % Modelo simple: posición pura
            % Estado: posición
            A = 1;
            C = 1;
            Q = 1e-6; % Ruido de proceso bajo (ajusta según experiencia)
            R_base = 1e-9; % Varianza de medición (ajusta según precisión GPS)
            factor = 1e-8;

            R_max = 1e-5;   % R cuando distancia es pequeña
            R_min = 1e-12;  % R cuando distancia es grande
            epsilon = 1e-3; % Para evitar división por cero

            % Inicialización
            x_lat = lat(1);
            P_lat = 1e-6;
            x_lon = lon(1);
            P_lon = 1e-6;

            lat_f = zeros(N,1);
            lon_f = zeros(N,1);

            distancias = zeros(N,1);
            R_values = zeros(N,1);


            for i = 1:N
                if i == 1
                    dist = 0;
                else
                    % Calcula distancia euclidiana (o usa Haversine si lo prefieres)

                    dist = Calculos.geodist(lat(i), lon(i), lat(i-1), lon(i-1));
                end

                dist_normalized = dist + epsilon;
                R_dynamic = R_min + (R_max - R_min) * (1 ./ dist_normalized);
                R_dynamic = min(max(R_dynamic, R_min), R_max); % Limitar rango
                distancias(i) = dist;
                R_values(i) = R_dynamic;

                % Predicción
                x_lat = A * x_lat;
                P_lat = A * P_lat * A' + Q;

                % Medición
                z = lat(i);

                % Ganancia de Kalman (usa R_dynamic)
                S = C * P_lat * C' + R_dynamic;
                K = P_lat * C' / S;

                % Actualización
                x_lat = x_lat + K * (z - C * x_lat);
                P_lat = (1 - K * C) * P_lat;

                lat_f(i) = x_lat;
            end

            % Idéntico para longitud
            for i = 1:N
                if i == 1
                    dist = 0;
                else
                    dist = Calculos.geodist(lat(i), lon(i), lat(i-1), lon(i-1));
                end
                dist_normalized = dist + epsilon;
                R_dynamic = R_min + (R_max - R_min) * (1 ./ dist_normalized);
                R_dynamic = min(max(R_dynamic, R_min), R_max);

                x_lon = A * x_lon;
                P_lon = A * P_lon * A' + Q;

                z = lon(i);

                S = C * P_lon * C' + R_dynamic;
                K = P_lon * C' / S;

                x_lon = x_lon + K * (z - C * x_lon);
                P_lon = (1 - K * C) * P_lon;

                lon_f(i) = x_lon;
            end

            trayectoria_filtrada.lat = lat_f;
            trayectoria_filtrada.lon = lon_f;
            trayectoria_filtrada.time = t;

            % Si no existe, inicializar vacío
            if ~isfield(datosBuses,'trayectoriaFiltrada')
                datosBuses.trayectoriaFiltrada = repmat(struct(), size(datosBuses.datosSensorRuta,1), 1);
            end

            % Unificar campos entre plantilla existente y nueva estructura
            todos = union(fieldnames(datosBuses.trayectoriaFiltrada), fieldnames(trayectoria_filtrada));

            % Asegurar que todos los elementos de trayectoriaFiltrada tengan los mismos campos
            for f = 1:numel(todos)
                nombre = todos{f};
                if ~isfield(trayectoria_filtrada,nombre)
                    trayectoria_filtrada.(nombre) = [];
                end
                if ~isfield(datosBuses.trayectoriaFiltrada, nombre)
                    [datosBuses.trayectoriaFiltrada.(nombre)] = deal([]);
                end
            end

            % Ahora sí: asignación segura
            datosBuses.trayectoriaFiltrada(k) = trayectoria_filtrada;





            %Extraer datos filtrados
            % lat_f = trayectoria_filtrada.lat(:);
            % lon_f = trayectoria_filtrada.lon(:);
            %
            % figure
            % plot(lon, lat, 'r.', 'DisplayName', 'GPS Original')
            % hold on
            % plot(lon_f, lat_f, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Kalman Filtrado')
            % xlabel('Longitud')
            % ylabel('Latitud')
            % legend('show', 'Location', 'best')
            % title('Trayectoria GPS: Original vs Kalman Filtrado')
            % grid on
            % axis equal

        end
        
        %%

        function datosBuses = detectar_curvas_multi_escala(datosBuses, k)
            % Primera pasada: Curvas pequeñas
            parametros1.ventana = 5;
            parametros1.umbral = 0.0013;
            parametros1.radio_maximo = 0.005;
            parametros1.umbral_longitud = 15;
            parametros1.proporcion_minima = 0.08;
            parametros1.velocidad_minima = 1.1;

            % Segunda pasada: Curvas grandes
            parametros2.ventana = 15;
            parametros2.umbral = 0.0035;
            parametros2.radio_maximo = 0.03;      % Permite radios más grandes
            parametros2.umbral_longitud = 30;     % Longitud mínima más alta
            parametros2.proporcion_minima = 0.04; % Proporción menor para grandes
            parametros2.velocidad_minima = 1.1;

            % Detectar curvas pequeñas
            datosBuses = Calcular.detectar_curvas_con_parametros(datosBuses, k, parametros1, 'curvasPequenas');
            % Detectar curvas grandes
            datosBuses = Calcular.detectar_curvas_con_parametros(datosBuses, k, parametros2, 'curvasGrandes');

            Calcular.fusionar_y_graficar_curvas(datosBuses, k);

            % Aquí podrías fusionar los resultados, según como guardes la info.
        end


        %%

        function datosBuses = detectar_curvas_graficar(datosBuses, k)
            % data cache
            lat = datosBuses.trayectoriaFiltrada(k).lat;
            lon = datosBuses.trayectoriaFiltrada(k).lon;
            velocidad = datosBuses.velocidadRuta{k,2}; % Vector columna de tamaño N-1
            x = lon(:);
            y = lat(:);


            % Configuracion
            ventana = 3; % número de puntos a cada lado
            umbral = 0.0014;           % para detectar curva
            radio_maximo = 0.005;      % radio máximo permitido para graficar círculo
            umbral_longitud = 10;
            proporcion_minima = 0.1;
            velocidad_minima = 0.1;



            [radio_curvatura, direccion_curva, signo_curvatura] =  Calcular.calcular_radio_curvatura(x, y, ventana);
            datosBuses.trayectoriaFiltrada(k).radioCurvatura = radio_curvatura;



            en_curva = radio_curvatura < umbral;
            cambio = diff([0; en_curva; 0]);
            inicio = find(cambio == 1);
            fin = find(cambio == -1) - 1;

            curvas = [];

            % figure;
            % plot(x, y, 'b-', 'LineWidth', 1); hold on;
            % %scatter(x, y, 20, velocidad, 'filled');
            % %colorbar;
            % dcm = datacursormode(gcf);
            % set(dcm, 'UpdateFcn', {@Calcular.mi_callback, x, y, velocidad, radio_curvatura, signo_curvatura});

            for s = 1:length(inicio)
                idx = inicio(s):fin(s);


                % Calcular longitud acumulada del segmento de curva usando geodist
                long_acum = 0;
                for j = 2:length(idx)
                    long_acum = long_acum + Calculos.geodist(...
                        lat(idx(j-1)), lon(idx(j-1)), lat(idx(j)), lon(idx(j)));
                end


                % Ajustar círculo al segmento
                [xc, yc, R] = Calcular.circle_fit(x(idx), y(idx));
                perimetro_circulo = 2*pi*R*100000;
                proporcion = long_acum / perimetro_circulo;


                vel_idx_ini = idx(1);
                vel_idx_end = idx(end)-1;
                if vel_idx_end > length(velocidad)
                    vel_idx_end = length(velocidad);
                end

                % Velocidad promedio del segmento
                vel_prom = mean(velocidad(vel_idx_ini:vel_idx_end));

                % Solo graficar si el radio está dentro del límite
                if R < radio_maximo && ...
                        long_acum >= umbral_longitud && ...
                        proporcion >= proporcion_minima && ...
                        vel_prom >= velocidad_minima

                    plot(x(idx), y(idx), 'r-', 'LineWidth', 3);
                    theta = linspace(0, 2*pi, 200);
                    xcirc = xc + R*cos(theta);
                    ycirc = yc + R*sin(theta);
                    plot(xcirc, ycirc, 'g--', 'LineWidth', 1.5);

                    % Dibuja la normal desde el punto de mitad de longitud real
                    [xm, ym] = Calcular.punto_mitad_longitud(idx, x, y, lat, lon);
                    plot([xm xc], [ym yc], 'k-', 'LineWidth', 2);

                    curva.idx = idx;
                    curva.xc = xc;
                    curva.yc = yc;
                    curva.R = R;
                    curva.long_acum = long_acum;
                    curva.perimetro_circulo = perimetro_circulo;
                    curva.proporcion = proporcion;
                    curva.vel_prom = vel_prom;
                    curva.direccion = direccion_curva(idx);
                    curva.signo = signo_curvatura(idx);
                    curva.v2_sobre_R = vel_prom^2 / R;
                    curvas = [curvas; curva];

                end
            end
            datosBuses.trayectoriaFiltrada(k).curvas = curvas;
            axis equal;
            title('Trayectoria, curvas y círculos ajustados (limitado)');
            xlabel('Longitud');
            ylabel('Latitud');
            legend('Trayectoria', 'Curvas', 'Círculo ajustado');
            hold off;
        end


        function datosBuses = detectar_curvas(datosBuses, k)
            lat = datosBuses.trayectoriaFiltrada(k).lat;
            lon = datosBuses.trayectoriaFiltrada(k).lon;
            velocidad = datosBuses.velocidadRuta{k,2}; % Vector columna de tamaño N-1
            x = lon(:);
            y = lat(:);

            % Configuración
            ventana = 3; % número de puntos a cada lado
            umbral = 0.0014;           % para detectar curva
            radio_maximo = 0.005;      % radio máximo permitido para aceptar curva
            umbral_longitud = 10;
            proporcion_minima = 0.1;
            velocidad_minima = 0.1;

            [radio_curvatura, direccion_curva, signo_curvatura] = Calcular.calcular_radio_curvatura(x, y, ventana);
            datosBuses.trayectoriaFiltrada(k).radioCurvatura = radio_curvatura;

            en_curva = radio_curvatura < umbral;
            cambio = diff([0; en_curva; 0]);
            inicio = find(cambio == 1);
            fin = find(cambio == -1) - 1;

            curvas = [];

            for s = 1:length(inicio)
                idx = inicio(s):fin(s);

                % Calcular longitud acumulada del segmento de curva usando geodist
                long_acum = 0;
                for j = 2:length(idx)
                    long_acum = long_acum + Calculos.geodist(...
                        lat(idx(j-1)), lon(idx(j-1)), lat(idx(j)), lon(idx(j)));
                end

                % Ajustar círculo al segmento
                [xc, yc, R] = Calcular.circle_fit(x(idx), y(idx));
                perimetro_circulo = 2*pi*R*100000;
                proporcion = long_acum / perimetro_circulo;

                idx_vel = idx;
                idx_vel(idx_vel > length(velocidad)) = []; % elimina índices fuera de rango
                vel_curva = velocidad(idx_vel);


                % Filtros
                if R < radio_maximo && ...
                        long_acum >= umbral_longitud && ...
                        proporcion >= proporcion_minima && ...
                        mean(vel_curva) >= velocidad_minima

                    curva.idx = idx;
                    curva.xc = xc;
                    curva.yc = yc;
                    curva.R = R;
                    curva.long_acum = long_acum;
                    curva.perimetro_circulo = perimetro_circulo;
                    curva.proporcion = proporcion;
                    curva.vel_prom = mean(vel_curva);
                    % Guardar valores para cada punto de la curva:
                    curva.radio_curvatura = radio_curvatura(idx);
                    curva.direccion = direccion_curva(idx);
                    curva.signo = signo_curvatura(idx);
                    curva.velocidad = vel_curva;
                    curva.v2_sobre_R = (vel_curva.^2) ./ curva.radio_curvatura;

                    latitud_media = mean(lat(idx));  % O de todo el trayecto si es más estable
                    curva.v2_sobre_R_p80 = Calcular.calcular_v2_sobre_R_p80(vel_curva, curva.radio_curvatura, latitud_media);



                    curvas = [curvas; curva];
                end
            end

            datosBuses.trayectoriaFiltrada(k).curvas = curvas;
        end


        function v2_sobre_R_p80 = calcular_v2_sobre_R_p80(velocidad, radio_curvatura_grados, latitud_media)
            metros_por_grado = 111320;
            factor_lon = cosd(latitud_media);
            escala_metros = metros_por_grado * factor_lon;

            radio_curvatura_metros = radio_curvatura_grados * escala_metros;

            % Validación y cálculo
            mascara = ~isnan(radio_curvatura_metros) & radio_curvatura_metros > 0;
            v2_sobre_R = (velocidad(mascara).^2) ./ radio_curvatura_metros(mascara);

            if isempty(v2_sobre_R)
                v2_sobre_R_p80 = NaN;
            else
                v2_sobre_R_p80 = prctile(v2_sobre_R, 80);
            end
        end


        %%


        function output_txt = mi_callback(~, event_obj, x, y, velocidad, radio_curvatura, direccion_curva)
            pos = get(event_obj, 'Position');
            % Buscar el índice más cercano a pos
            dist = hypot(x - pos(1), y - pos(2));
            [~, idx] = min(dist);

            output_txt = {...
                ['Longitud: ', num2str(pos(1), '%.6f')], ...
                ['Latitud: ', num2str(pos(2), '%.6f')], ...
                ['Índice: ', num2str(idx)], ...
                ['Velocidad: ', num2str(velocidad(idx), '%.2f')], ...
                ['Radio curvatura: ', num2str(radio_curvatura(idx), '%.6f')] ...
                ['Dirección curva: ', num2str(direccion_curva(idx), '%.6f')] ...
                };
        end


        function [radio_curvatura, direccion_curva, signo_curvatura] = calcular_radio_curvatura(x, y, ventana)
            N = length(x);
            radio_curvatura = nan(N,1);
            direccion_curva = nan(N,1);
            signo_curvatura = nan(N,1);
            for i = ventana+1:N-ventana
                x1 = x(i-ventana); y1 = y(i-ventana);
                x2 = x(i);         y2 = y(i);
                x3 = x(i+ventana); y3 = y(i+ventana);

                % Ajuste de círculo
                A = [x1, y1, 1; x2, y2, 1; x3, y3, 1];
                B = [-(x1^2 + y1^2); -(x2^2 + y2^2); -(x3^2 + y3^2)];
                params = A\B;
                xc = -0.5*params(1);
                yc = -0.5*params(2);
                r = sqrt((xc-x1)^2 + (yc-y1)^2);
                radio_curvatura(i) = r;

                % Dirección de la curva: ángulo de la tangente en el punto central
                dx = x3 - x1;
                dy = y3 - y1;
                direccion_curva(i) = atan2(dy, dx);

                % Cálculo del signo de la curvatura
                v1 = [x2 - x1; y2 - y1];
                v2 = [x3 - x2; y3 - y2];
                cross_z = v1(1)*v2(2) - v1(2)*v2(1);
                if cross_z > 0
                    signo_curvatura(i) = -1; % izquierda
                elseif cross_z < 0
                    signo_curvatura(i) = 1; % derecha
                else
                    signo_curvatura(i) = 0;
                end
            end
        end

        function radio_curvatura = radio_curvatura_punto_kasa(x, y, m_min, m_max)
            N = length(x);
            radio_curvatura = nan(N,1);

            for i = 1:N
                min_error = inf;
                best_r = nan;
                for w = m_min:m_max
                    w2 = floor(w/2);
                    i1 = max(1, i-w2);
                    i2 = min(N, i+w2);
                    idx = i1:i2;
                    if numel(idx) < 3
                        continue;
                    end

                    xi = x(idx);
                    yi = y(idx);
                    n = length(xi);

                    theta = abs(atan2(yi(end)-yi(1), xi(end)-xi(1)));
                    if theta < deg2rad(5)
                        continue; % no ajustar si el arco es muy pequeño
                    end

                    % Kasa least squares circle fitting
                    Zi = xi(:).^2 + yi(:).^2;
                    A = [xi(:) yi(:) ones(n,1)];
                    b = -Zi;
                    params = A\b;
                    a = params(1);
                    b_ = params(2);
                    c = params(3);

                    xc = -0.5*a;
                    yc = -0.5*b_;
                    r = sqrt(xc^2 + yc^2 - c);

                    % Error de ajuste para esta ventana
                    dists = sqrt((xi-xc).^2 + (yi-yc).^2);
                    err = sum((dists - r).^2);

                    if err < min_error
                        min_error = err;
                        best_r = r;
                    end
                end
                radio_curvatura(i) = best_r;
            end
        end


        function [radio_curvatura, direccion_curva, signo_curvatura] = calcular_radio_curvatura_kasa(x, y, ventana)
            N = length(x);
            radio_curvatura = nan(N,1);
            direccion_curva = nan(N,1);
            signo_curvatura = nan(N,1);
            for i = ventana+1:N-ventana
                idx = (i-ventana):(i+ventana);
                xi = x(idx);
                yi = y(idx);
                n = length(xi);

                % Kasa least squares circle fitting
                Xi = xi(:); Yi = yi(:);
                Zi = Xi.^2 + Yi.^2;
                A = [Xi Yi ones(n,1)];
                b = -Zi;
                params = A\b;
                a = params(1);
                b_ = params(2);
                c = params(3);

                xc = -0.5*a;
                yc = -0.5*b_;
                r = sqrt(xc^2 + yc^2 - c);

                radio_curvatura(i) = r;

                % Dirección de la curva (aproximación por ángulo de la tangente)
                dx = x(i+ventana) - x(i-ventana);
                dy = y(i+ventana) - y(i-ventana);
                direccion_curva(i) = atan2(dy, dx);

                % Cálculo del signo de la curvatura
                % (usando los 3 puntos: inicio, centro, fin)
                v1 = [x(i) - x(i-ventana); y(i) - y(i-ventana)];
                v2 = [x(i+ventana) - x(i); y(i+ventana) - y(i)];
                cross_z = v1(1)*v2(2) - v1(2)*v2(1);
                if cross_z > 0
                    signo_curvatura(i) = 1; % curva a la izquierda
                elseif cross_z < 0
                    signo_curvatura(i) = -1; % curva a la derecha
                else
                    signo_curvatura(i) = 0; % sin curvatura
                end
            end
        end


        function [xc, yc, R] = circle_fit(x, y)
            x = x(:);
            y = y(:);
            A = [2*x, 2*y, ones(size(x))];
            b = x.^2 + y.^2;
            params = A\b;
            xc = params(1);
            yc = params(2);
            R = sqrt(params(3) + xc^2 + yc^2);
        end


        function [x_m, y_m] = punto_mitad_longitud(idx, x, y, lat, lon)
            % Calcula el punto del segmento idx (curva) que está a la mitad de la longitud real
            dist_acum = zeros(length(idx), 1);
            for j = 2:length(idx)
                dist_acum(j) = dist_acum(j-1) + Calculos.geodist(...
                    lat(idx(j-1)), lon(idx(j-1)), lat(idx(j)), lon(idx(j)));
            end
            long_total = dist_acum(end);
            i_mitad = find(dist_acum >= long_total/2, 1, 'first');
            x_m = x(idx(i_mitad));
            y_m = y(idx(i_mitad));
        end


        function datosBuses = detectar_curvas_con_parametros(datosBuses, k, parametros, campoSalida)
            lat = datosBuses.trayectoriaFiltrada(k).lat;
            lon = datosBuses.trayectoriaFiltrada(k).lon;
            velocidad = datosBuses.velocidadRuta{k,2};

            x = lon(:);
            y = lat(:);

            N = length(x);
            radio_curvatura = nan(N,1);

            ventana = parametros.ventana;
            umbral = parametros.umbral;
            radio_maximo = parametros.radio_maximo;
            umbral_longitud = parametros.umbral_longitud;
            proporcion_minima = parametros.proporcion_minima;
            velocidad_minima = parametros.velocidad_minima;

            for i = ventana+1:N-ventana
                x1 = x(i-ventana); y1 = y(i-ventana);
                x2 = x(i);         y2 = y(i);
                x3 = x(i+ventana); y3 = y(i+ventana);

                A = [x1, y1, 1;
                    x2, y2, 1;
                    x3, y3, 1];
                B = [-(x1^2 + y1^2);
                    -(x2^2 + y2^2);
                    -(x3^2 + y3^2)];
                params = A\B;
                xc = -0.5*params(1);
                yc = -0.5*params(2);
                r = sqrt((xc-x1)^2 + (yc-y1)^2);

                radio_curvatura(i) = r;
            end

            en_curva = radio_curvatura < umbral;
            cambio = diff([0; en_curva; 0]);
            inicio = find(cambio == 1);
            fin = find(cambio == -1) - 1;

            curvas = {};
            for s = 1:length(inicio)
                idx = inicio(s):fin(s);

                % Longitud acumulada
                long_acum = 0;
                for j = 2:length(idx)
                    long_acum = long_acum + Calculos.geodist(...
                        lat(idx(j-1)), lon(idx(j-1)), lat(idx(j)), lon(idx(j)));
                end

                % Círculo ajustado
                [xc, yc, R] = Calcular.circle_fit(x(idx), y(idx));
                perimetro_circulo = 2*pi*R*100000;
                proporcion = long_acum / perimetro_circulo;

                vel_idx_ini = idx(1);
                vel_idx_end = idx(end)-1;
                if vel_idx_end > length(velocidad)
                    vel_idx_end = length(velocidad);
                end
                vel_prom = mean(velocidad(vel_idx_ini:vel_idx_end));

                if R < radio_maximo && ...
                        long_acum >= umbral_longitud && ...
                        proporcion >= proporcion_minima && ...
                        vel_prom >= velocidad_minima

                    curvas{end+1} = idx;
                end
            end

            % Guarda los índices de las curvas detectadas en el campo correspondiente
            datosBuses.trayectoriaFiltrada(k).(campoSalida) = curvas;
        end

        function fusionar_y_graficar_curvas(datosBuses, k)
            % Extraer datos
            lat = datosBuses.trayectoriaFiltrada(k).lat;
            lon = datosBuses.trayectoriaFiltrada(k).lon;
            x = lon(:);
            y = lat(:);

            curvasPeq = datosBuses.trayectoriaFiltrada(k).curvasPequenas;
            curvasGra = datosBuses.trayectoriaFiltrada(k).curvasGrandes;

            % Unir todos los segmentos, etiquetar tipo: 1=pequeña, 2=grande
            % Para cada segmento, calcula también el signo de curvatura
            [segs_peq, signos_peq] = Calcular.obtener_segmentos_y_signos(curvasPeq, x, y);
            [segs_gra, signos_gra] = Calcular.obtener_segmentos_y_signos(curvasGra, x, y);

            todos = [segs_peq, ones(size(segs_peq,1),1), signos_peq; ...
                segs_gra, 2*ones(size(segs_gra,1),1), signos_gra];

            % Ordenar por inicio
            todos = sortrows(todos,1);

            % Fusión de segmentos solapados o muy próximos Y CON EL MISMO SIGNO DE CURVATURA
            fusionados = [];
            i = 1;
            while i <= size(todos,1)
                ini = todos(i,1);
                fin = todos(i,2);
                tipo = todos(i,3);
                signo = todos(i,4);
                j = i+1;
                while j <= size(todos,1) && todos(j,1) <= fin+2 && todos(j,4) == signo
                    fin = max(fin, todos(j,2));
                    tipo = max(tipo, todos(j,3)); % Prioriza tipo más grande
                    j = j+1;
                end
                fusionados = [fusionados; ini, fin, tipo, signo];
                i = j;
            end

            % Gráfica
            figure; hold on;
            plot(x, y, 'k-', 'LineWidth', 1); % Trayectoria base
            ley = {'Trayectoria'};

            for f = 1:size(fusionados,1)
                idx = fusionados(f,1):fusionados(f,2);
                signo = fusionados(f,4);

                % Color según tipo y sentido de curva
                if fusionados(f,3)==1
                    color_curva = 'r';
                    color_circulo = [1 0.6 0.6]; % rojo claro
                    nombre = 'Curva pequeña';
                else
                    color_curva = 'b';
                    color_circulo = [0.6 0.6 1]; % azul claro
                    nombre = 'Curva grande';
                end
                if signo < 0
                    color_curva = [0 0.7 0]; % verde para curvas hacia otro lado
                    color_circulo = [0.6 1 0.6];
                    nombre = [nombre ' reversa'];
                end
                ley{end+1} = nombre;

                plot(x(idx), y(idx), '-', 'Color', color_curva, 'LineWidth', 2);

                % Ajuste de círculo al segmento
                [xc, yc, R] = Calcular.circle_fit(x(idx), y(idx));
                theta = linspace(0,2*pi,200);
                xcirc = xc + R*cos(theta);
                ycirc = yc + R*sin(theta);
                plot(xcirc, ycirc, '--', 'Color', color_circulo, 'LineWidth', 1.5);

                % Dibuja la normal desde el punto de mitad de longitud real
                [xm, ym] = Calcular.punto_mitad_longitud(idx, x, y, lat, lon);
                plot([xm xc], [ym yc], 'k-', 'LineWidth', 2);
            end

            legend(ley, 'Location', 'best');
            title('Trayectoria, curvas fusionadas (con signo), círculos y normales');
            xlabel('Longitud');
            ylabel('Latitud');
            axis equal; hold off;
        end

        function [segs, signos] = obtener_segmentos_y_signos(curvas, x, y)
            n = numel(curvas);
            segs = zeros(n,2);
            signos = zeros(n,1);
            for i = 1:n
                idx = curvas{i};
                segs(i,:) = [idx(1) idx(end)];
                signos(i) = Calcular.signo_curvatura_segmento(x(idx), y(idx));
            end
        end

        function signo = signo_curvatura_segmento(xseg, yseg)
            % Usa los extremos y el punto intermedio
            N = numel(xseg);
            if N < 3
                signo = 0;
                return
            end
            x1 = xseg(1);   y1 = yseg(1);
            x2 = xseg(round(N/2)); y2 = yseg(round(N/2));
            x3 = xseg(end); y3 = yseg(end);
            % Determinante del triángulo
            area2 = (x2-x1)*(y3-y1) - (y2-y1)*(x3-x1);
            signo = sign(area2); % +1 izquierda, -1 derecha (según convención)
        end

        %%

        function velocidad = velocidadSinFiltro(datos, etiquetaTiempo, etiquetaLatitud, etiquetaLongitud)
            % Asegurarse de que los datos son una tabla
            if ~istable(datos)
                error('La entrada debe ser una tabla.');
            end

            % Asumiendo que las columnas son: tiempo, latitud, longitud
            tiempo = datos.(etiquetaTiempo);
            lat = datos.(etiquetaLatitud);
            lon = datos.(etiquetaLongitud);

            % Calcular la diferencia de tiempo en segundos
            diferenciaTiempo = seconds(diff(tiempo));

            % Preasignando espacio para la velocidad
            velocidad = zeros(length(lat) - 1, 1);

            % Calcular la velocidad para cada punto
            for i = 1:length(lat) - 1
                % Calcular la distancia en metros usando la función distance de MATLAB
                distancia = distance(lat(i), lon(i), lat(i+1), lon(i+1), wgs84Ellipsoid('meters'));
                velocidad(i) = distancia / diferenciaTiempo(i); % Dividir la distancia en metros por el tiempo en segundos
            end
        end


        %%


        function datosBuses = GenerarSegmentos(datosBuses, k)
            % Obtener la info de paradas del recorrido k
            infoParadas = datosBuses.tiempoRuta.InfoParadas{k};
            validas = datosBuses.tiempoRuta.ParadasVisitadas{k}; % vector lógico

            % Verificar que existan paradas suficientes
            if isempty(infoParadas) || height(infoParadas) < 2
                datosBuses.segmentos{k} = table();
                return;
            end

            % Inicializar celdas para los segmentos
            nSeg = height(infoParadas) - 1;
            nombresSegmentos = strings(nSeg,1);
            paradaInicio = strings(nSeg,1);
            paradaFin = strings(nSeg,1);
            tiempoInicio = NaT(nSeg,1);
            tiempoFin = NaT(nSeg,1);
            duracion = NaN(nSeg,1);
            promedioVelocidad = NaN(nSeg, 1);


            

            valido = false(nSeg,1);

            datosSensor = datosBuses.datosSensorRuta{k,2};
            velocidades = datosBuses.velocidadRuta{k,2};

            % Extraer información de las paradas
            nombresParadas = string(infoParadas.Parada);
            tiemposParadas = infoParadas.TiempoLlegada;

            % Iterar sobre pares consecutivos de paradas
            for s = 1:nSeg
                paradaInicio(s) = nombresParadas(s);
                paradaFin(s) = nombresParadas(s+1);

                

                nombresSegmentos(s) = paradaInicio(s) + "-" + paradaFin(s);

                % Validación: ambas paradas deben ser válidas
                if validas(s) && validas(s+1)
                    tiempoInicio(s) = tiemposParadas(s);
                    tiempoFin(s) = tiemposParadas(s+1);

                    tInicio = tiempoInicio(s);
                    tFin = tiempoFin(s);

                    tiempos = datosSensor.time;
                    idx = find(tiempos >= tInicio & tiempos <= tFin);

                    duracion(s) = seconds(tiempoFin(s) - tiempoInicio(s));


                            if numel(idx) > 1
                                % Velocidades entre esos tiempos
                                velSeg = velocidades(idx(1):idx(end)-1);

                                if ~isempty(velSeg)
                                    promedioVelocidad(s) = mean(velSeg, 'omitnan');
                                end
                            end


                    valido(s) = true;
                end
            end

            % Construir tabla de segmentos
            tablaSegmentos = table(nombresSegmentos, paradaInicio, paradaFin, ...
                tiempoInicio, tiempoFin, duracion, valido, promedioVelocidad);

            % Guardar en la estructura
            datosBuses.segmentos{k} = tablaSegmentos;
        end


        %%


function datosBuses = GenerarSegmentosEquilibrados(datosBuses, k, nSeg)
    % Obtener la info de paradas del recorrido k
    infoParadas = datosBuses.tiempoRuta.InfoParadas{k};
    validas = datosBuses.tiempoRuta.ParadasVisitadas{k}; % vector lógico

    nParadas = height(infoParadas);

    if isempty(infoParadas) || nParadas < 2
        datosBuses.segmentos{k} = table();
        return;
    end

    % División equilibrada de paradas
    base = floor(nParadas / nSeg);
    resto = mod(nParadas, nSeg);
    bloques = repmat(base, nSeg, 1);
    bloques(1:resto) = bloques(1:resto) + 1; % repartir resto a los primeros segmentos

    % Inicializar
    nombresSegmentos = strings(nSeg,1);
    paradaInicio = strings(nSeg,1);
    paradaFin = strings(nSeg,1);
    tiempoInicio = NaT(nSeg,1);
    tiempoFin = NaT(nSeg,1);
    duracion = NaN(nSeg,1);
    promedioVelocidad = NaN(nSeg,1);
    fiabilidad = NaN(nSeg,1);
    valido = false(nSeg,1);

    datosSensor = datosBuses.datosSensorRuta{k,2};
    velocidades = datosBuses.velocidadRuta{k,2};

    nombresParadas = string(infoParadas.Parada);
    tiemposParadas = infoParadas.TiempoLlegada;

    % Recorrer segmentos con bloques
    idxStart = 1;
    for s = 1:nSeg
        idxEnd = idxStart + bloques(s) - 1;

        % Definir inicio y fin de segmento
        paradaInicio(s) = nombresParadas(idxStart);
        paradaFin(s)   = nombresParadas(idxEnd);
        nombresSegmentos(s) = paradaInicio(s) + "-" + paradaFin(s);

        tiempoInicio(s) = tiemposParadas(idxStart);
        tiempoFin(s)   = tiemposParadas(idxEnd);
        duracion(s)    = seconds(tiempoFin(s) - tiempoInicio(s));

        % Velocidades en el rango
        tInicio = tiempoInicio(s);
        tFin = tiempoFin(s);
        tiempos = datosSensor.time;
        idx = find(tiempos >= tInicio & tiempos <= tFin);

        if numel(idx) > 1
            velSeg = velocidades(idx(1):idx(end)-1);
            if ~isempty(velSeg)
                promedioVelocidad(s) = mean(velSeg, 'omitnan');
            end
        end

        % Calcular fiabilidad = % de paradas válidas en el segmento
        fiabilidad(s) = mean(validas(idxStart:idxEnd));
        valido(s) = fiabilidad(s) > 0.5; % ejemplo: válido si más de la mitad son buenas

        idxStart = idxEnd; % avanzar
    end

    % Construir tabla
    tablaSegmentos = table(nombresSegmentos, paradaInicio, paradaFin, ...
        tiempoInicio, tiempoFin, duracion, valido, promedioVelocidad, fiabilidad);

    datosBuses.segmentos8{k} = tablaSegmentos;
end



        %%

        function [velocidadOriginal, velocidad] = velocidadConFiltro(datos, etiquetaTiempo, etiquetaLatitud, etiquetaLongitud, filtro)
            switch filtro
                case 'pendiente'
                    [velocidadOriginal, velocidad] = Calcular.corregirVelocidadPendiente(datos, 3);
                case 'sin_filtro'
                    velocidad = Calcular.velocidadSinFiltro(datos, etiquetaTiempo, etiquetaLatitud, etiquetaLongitud);
                    velocidadOriginal = [];
                otherwise
                    error('Filtro no reconocido: %s. Use "media_movil", "kalman", "pendiente", "sin_filtro" u otros filtros disponibles.', filtro);
            end
        end



        %%

        function [velocidadOriginal, velocidadCorregida] = corregirVelocidadPendiente(datos, umbral)
            tiempo = datos.time;
            velocidadOriginal = Calculos.calcularVelocidadMS(datos);

         
            n = length(velocidadOriginal);
            velocidadCorregida = velocidadOriginal;



            i = 1;
            while i < n - 1
                % Convertir los objetos duration a segundos
                dt = seconds(tiempo(i+1) - tiempo(i));

                % Calcular la pendiente entre dos puntos consecutivos
                %%pendiente = (velocidadCorregida(i+1) - velocidadCorregida(i)) / dt;
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

                    j = j -1;

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
        end


        %%

        function datosBuses = tiemposRutas(datosBuses, rutas, conductores)


            % Obtener los campos de los buses
            buses = fieldnames(datosBuses);

            % Iterar sobre cada bus
            for i = 1:numel(buses)
                bus = buses{i};

                % Saltar el campo 'info'
                if strcmp(bus, 'info')
                    continue;
                end

                % Extraer los últimos 4 caracteres del bus para buscar coincidencia con MOVIL
                bus_id = extractAfter(bus, 4); % Obtiene "XXXX" de "bus_XXXX"

                % Obtener los campos de las fechas para el bus actual
                fechas = fieldnames(datosBuses.(bus));

                % Iterar sobre cada fecha
                for j = 1:numel(fechas)




                    fecha = fechas{j};
                    datosSensor = datosBuses.(bus).(fecha).datosSensor;




                    % Extrae los P60

                    if isfield(datosBuses, bus) && isfield(datosBuses.(bus), fecha) && isfield(datosBuses.(bus).(fecha), 'P60') ...
                            && istable(datosBuses.(bus).(fecha).P60) && ~isempty(datosBuses.(bus).(fecha).P60)
                        p60 = datosBuses.(bus).(fecha).P60;
                    else
                        warning('El campo P60 no existe para el bus %s en la fecha %s', bus, fecha);
                        continue
                    end


                    if isempty(datosSensor)
                        warning("No se encontraron los datos del telefono para " + bus +  " para el dia " + fecha)
                        continue;
                    end

                    if isempty(p60)
                        warning("No se encontraron los datos P60 " + bus +  " para el dia " + fecha)
                        continue;
                    end

                    % Convertir la fecha de formato "f_dd_mm_yyyy" a "yyyy-MM-dd"
                    fechaConvertida = datetime(fecha(3:end), 'InputFormat', 'dd_MM_yyyy', 'Format', 'yyyy-MM-dd');


                    % Inicializar el campo tiempoRuta como una tabla vacía con encabezados

                    headers = {'Inicio_Ruta','Fin_Ruta','Ruta','ParadasVisitadas','InfoParadas', 'Genero_Conductor', 'Id'};
                    datosBuses.(bus).(fecha).tiempoRuta = cell2table(cell(0, 7), 'VariableNames', headers);  % Inicializar tabla vacía



                    for k = 1:numel(1)

                        % Busca una ruta especifica y retorna todas las
                        % coincidencias
                        tiempoRutaTemp = Calcular.RutaOptimizada(p60, datosSensor, rutas, 50, .7);

                        if isempty(tiempoRutaTemp)
                            continue
                        end

                        % Añadir el nombre de la ruta a cada fila de tiempoRutaTemp
                        % nombreRuta = repmat({ruta}, size(tiempoRutaTemp, 1), 1);
                        % tiempoRutaTemp = [tiempoRutaTemp, nombreRuta];


                        % Buscar el género del conductor más adecuado
                        generoConductor = repmat({"NA"}, size(tiempoRutaTemp, 1), 1); % Default a "NA"
                        idConductor = repmat({0}, size(tiempoRutaTemp, 1), 1);

                        % Filtrar los conductores por el mismo MOVIL y fecha
                        conductoresBusFecha = conductores(strcmp(extractAfter(conductores.MOVIL, 4), bus_id) & conductores.Fecha == fechaConvertida, :);




                        for m = 1:size(tiempoRutaTemp, 1)
                            inicioRuta = tiempoRutaTemp{m, 1}; % Inicio de la ruta
                            finRuta = tiempoRutaTemp{m, 2}; % Fin de la ruta


                            if ~isempty(conductoresBusFecha)
                                for m = 1:size(tiempoRutaTemp, 1)
                                    inicioRuta = tiempoRutaTemp{m, 1}; % Inicio de la ruta
                                    finRuta = tiempoRutaTemp{m, 2}; % Fin de la ruta

                                    mejorDiferencia = inf;
                                    mejorGenero = "NA";
                                    mejorId = 0;

                                    for n = 1:height(conductoresBusFecha)
                                        login = conductoresBusFecha.Login(n);
                                        logout = conductoresBusFecha.Logout(n);

                                        inicioRutaTemp = timeofday(inicioRuta);
                                        finRutaTemp = timeofday(finRuta);

                                        % Verificar si el tiempo de ruta está dentro del tiempo del conductor
                                        if (inicioRutaTemp < logout && finRutaTemp > login)  % Hay algún solapamiento
                                            % Calcular el porcentaje de solapamiento
                                            duracionRuta = finRutaTemp - inicioRutaTemp;
                                            duracionSolapada = min(finRutaTemp, logout) - max(inicioRutaTemp, login);
                                            porcentajeSolapamiento = duracionSolapada / duracionRuta;

                                            if porcentajeSolapamiento > 0.65  %  es el valor mínimo aceptado
                                                diferencia = abs(inicioRutaTemp - login) + abs(finRutaTemp - logout);
                                                if diferencia < mejorDiferencia
                                                    mejorDiferencia = diferencia;
                                                    mejorGenero = conductoresBusFecha.Genero(n);
                                                    mejorId = conductoresBusFecha.ID_Conductor(n);
                                                end
                                            end
                                        end

                                    end
                                    generoConductor{m} = mejorGenero;
                                    idConductor{m} = mejorId;
                                end
                            end
                        end

                        % Agregar la columna del género del conductor
                        tiempoRutaTemp = [tiempoRutaTemp, generoConductor, idConductor];






                        % Concatenar los resultados en el campo tiempoRuta
                        datosBuses.(bus).(fecha).tiempoRuta = [datosBuses.(bus).(fecha).tiempoRuta; tiempoRutaTemp];
                    end
                end
            end
        end


        %%
        function tiempos = Ruta(datosP20, paradas, distanciaUmbral, porcentajeMinimoParadas)
            % Esta función devuelve un array con los tiempos de salida, llegada al punto de regreso,
            % y regreso al punto de inicio para cada viaje.

            % Convertir las fechas en 'datosP20' a datetimes sin zona horaria para la comparación
            datosP20{:, 'fechaHoraLecturaDato'} = datetime(datosP20{:, 'fechaHoraLecturaDato'}, 'TimeZone', '');

            % Inicializar variables
            tiempos = [];  % Inicializar una matriz para guardar los tiempos de cada viaje
            estadoViaje = 0;  % 0 = fuera de la ruta, 1 = en la ruta
            paradasVisitadas = false(height(paradas), 1);  % Marcador para saber si se ha pasado por la parada
            ultimoStopSequence = 0;  % Inicializar el último `stop_sequence` visitado
            tiempoRecarga = minutes(1);  % Tiempo mínimo de recarga antes de iniciar una nueva ruta
            lastTime = datetime('0000-01-01', 'TimeZone', '');  % Inicializar la última hora registrada
            inicioRuta = datetime('0000-01-01', 'TimeZone', '');  % Inicializar tiempo de inicio de ruta
            porcentajeVisitadas = 0;

            % Recorrer todos los puntos de datos de p20
            for i = 1:height(datosP20)
                % Obtener la posición actual del bus
                latBus = datosP20.latitud(i);
                lonBus = datosP20.longitud(i);

                % Verificar la distancia a cada parada en orden de `stop_sequence`
                for j = 1:height(paradas)
                    latParada = paradas.lat(j);
                    lonParada = paradas.lon(j);
                    stopSequence = paradas.stop_sequence(j);  % Obtener el stop_sequence actual



                    % Calcular la distancia entre el bus y la parada actual
                    distParada = Calculos.geodist(latBus, lonBus, latParada, lonParada);

                    % Si la distancia es menor que el umbral, se marca como visitada
                    if distParada < distanciaUmbral

                        if porcentajeVisitadas == 0

                            inicioRuta = datosP20.fechaHoraLecturaDato(i);  % Guardar el tiempo de inicio
                        end
                        if ultimoStopSequence > (stopSequence)
                            estadoViaje = 0;
                            paradasVisitadas(:) = false;  % Reiniciar las paradas visitadas para el siguiente viaje
                            ultimoStopSequence = 0;  % Reiniciar el `stop_sequence` para el siguiente viaje

                            if porcentajeVisitadas >= porcentajeMinimoParadas
                                finRuta = datosP20.fechaHoraLecturaDato(i);  % Guardar el tiempo de fin
                                % Registrar el viaje
                                tiempos = [tiempos; {inicioRuta, finRuta}];
                                lastTime = finRuta;  % Actualizar la última hora registrada
                                % Reiniciar el estado del viaje y las paradas visitadas
                                estadoViaje = 0;
                                paradasVisitadas(:) = false;  % Reiniciar las paradas visitadas para el siguiente viaje
                                ultimoStopSequence = 0;  % Reiniciar el `stop_sequence` para el siguiente viaje
                            end

                            inicioRuta = datosP20.fechaHoraLecturaDato(i);  % Guardar el tiempo de inicio
                        end

                        paradasVisitadas(j) = true;  % Marcar la parada como visitada
                        ultimoStopSequence = stopSequence;  % Actualizar el último `stop_sequence` visitado
                    end
                end

                % Verificar si se ha pasado por el porcentaje mínimo de paradas
                porcentajeVisitadas = sum(paradasVisitadas) / height(paradas);

            end
        end


        %%
        function tiempos = RutaSensor(datosSensor, paradas, distanciaUmbral, porcentajeMinimoParadas)
            % Esta función devuelve un array con los tiempos de salida, llegada al punto de regreso,
            % y regreso al punto de inicio para cada viaje.

            % Convertir las fechas en 'datosSensor' a datetimes sin zona horaria para la comparación
            datosSensor{:, 'time'} = datetime(datosSensor{:, 'time'}, 'TimeZone', '');

            % Inicializar variables
            tiempos = [];  % Inicializar una matriz para guardar los tiempos de cada viaje
            estadoViaje = 0;  % 0 = fuera de la ruta, 1 = en la ruta
            paradasVisitadas = false(height(paradas), 1);  % Marcador para saber si se ha pasado por la parada
            ultimoStopSequence = 0;  % Inicializar el último `stop_sequence` visitado
            tiempoRecarga = minutes(1);  % Tiempo mínimo de recarga antes de iniciar una nueva ruta
            lastTime = datetime('0000-01-01', 'TimeZone', '');  % Inicializar la última hora registrada
            inicioRuta = datetime('0000-01-01', 'TimeZone', '');  % Inicializar tiempo de inicio de ruta
            porcentajeVisitadas = 0;

            % Recorrer todos los puntos de datos de datosSensor
            for i = 1:height(datosSensor)
                % Obtener la posición actual del bus
                latBus = datosSensor.lat(i);
                lonBus = datosSensor.lon(i);

                % Verificar la distancia a cada parada en orden de `stop_sequence`
                for j = 1:height(paradas)
                    latParada = paradas.lat(j);
                    lonParada = paradas.lon(j);
                    stopSequence = paradas.stop_sequence(j);  % Obtener el stop_sequence actual

                    % Calcular la distancia entre el bus y la parada actual
                    distParada = Calculos.geodist(latBus, lonBus, latParada, lonParada);

                    % Si la distancia es menor que el umbral, se marca como visitada
                    if distParada < distanciaUmbral
                        if porcentajeVisitadas == 0
                            inicioRuta = datosSensor.time(i);  % Guardar el tiempo de inicio
                        end
                        if ultimoStopSequence > stopSequence
                            estadoViaje = 0;
                            paradasVisitadas(:) = false;  % Reiniciar las paradas visitadas para el siguiente viaje
                            ultimoStopSequence = 0;  % Reiniciar el `stop_sequence` para el siguiente viaje

                            if porcentajeVisitadas >= porcentajeMinimoParadas
                                finRuta = datosSensor.time(i);  % Guardar el tiempo de fin
                                % Registrar el viaje
                                tiempos = [tiempos; {inicioRuta, finRuta}];
                                lastTime = finRuta;  % Actualizar la última hora registrada
                                % Reiniciar el estado del viaje y las paradas visitadas
                                estadoViaje = 0;
                                paradasVisitadas(:) = false;
                                ultimoStopSequence = 0;
                            end

                            inicioRuta = datosSensor.time(i);  % Guardar el tiempo de inicio
                        end

                        paradasVisitadas(j) = true;  % Marcar la parada como visitada
                        ultimoStopSequence = stopSequence;  % Actualizar el último `stop_sequence` visitado
                    end
                end

                % Verificar si se ha pasado por el porcentaje mínimo de paradas
                porcentajeVisitadas = sum(paradasVisitadas) / height(paradas);
            end
        end

        %%
        function tiempos = RutaP60(datosP60)
            % Esta función devuelve un array con los tiempos de inicio y fin de cada ruta recorrida.

            % Convertir las fechas en 'datosP60' a datetimes sin zona horaria para la comparación
            datosP60{:, 'fechaHoraLecturaDato'} = datetime(datosP60{:, 'fechaHoraLecturaDato'}, 'TimeZone', '');

            % Inicializar variables
            tiempos = [];  % Inicializar una matriz para guardar los tiempos de cada viaje
            estadoRuta = false;  % Indica si se está en una ruta
            inicioRuta = datetime('0000-01-01', 'TimeZone', '');  % Inicializar tiempo de inicio de ruta
            idRutaActual = "";  % Ruta en curso

            % Recorrer todos los puntos de datos de datosP60
            for i = 1:height(datosP60)
                idRuta = datosP60.idRuta(i);
                tiempoActual = datosP60.fechaHoraLecturaDato(i);

                if ~strcmp(idRuta, "No Disponible") % Si hay una ruta activa
                    if ~estadoRuta  % Si no estamos en una ruta, iniciamos una
                        inicioRuta = tiempoActual;
                        idRutaActual = idRuta;
                        estadoRuta = true;
                    elseif ~strcmp(idRuta, idRutaActual) % Si la ruta cambia, cerramos la ruta anterior
                        tiempos = [tiempos; {inicioRuta, tiempoActual, idRutaActual}];
                        inicioRuta = tiempoActual;
                        idRutaActual = idRuta;
                    end
                else % Si el valor es "no disponible", significa que la ruta terminó
                    if estadoRuta
                        tiempos = [tiempos; {inicioRuta, tiempoActual, idRutaActual}];
                        estadoRuta = false;
                        idRutaActual = "";
                    end
                end
            end

            % Si quedó una ruta abierta al final de los datos, cerrarla
            if estadoRuta
                tiempos = [tiempos; {inicioRuta, datosP60.fechaHoraLecturaDato(end), idRutaActual}];
            end
        end

        %%

        function tiempos = RutaOptimizada(datosP60p, datosSensor, paradas, distanciaUmbral, porcentajeMinimoParadas)
            % Esta función ajusta los tiempos de inicio y fin de una ruta basándose en el porcentaje de paradas visitadas.


            datosP60 = datosP60p;

            % Convertir las fechas a datetime sin zona horaria para la comparación
            datosP60{:, 'fechaHoraLecturaDato'} = datetime(datosP60{:, 'fechaHoraLecturaDato'}, 'TimeZone', '');
            datosP60 = sortrows(datosP60, 'fechaHoraLecturaDato', 'ascend');
            datosSensor{:, 'time'} = datetime(datosSensor{:, 'time'}, 'TimeZone', '');

            % Inicializar matriz de tiempos
            tiempos = [];

            % Recorrer las rutas en datosP60
            i = 1; % Inicializar el índice manualmente
            while i <= height(datosP60)
                idRuta = datosP60.idRuta(i);
                if strcmp(idRuta, "No Disponible")
                    i = i + 1; % Pasar al siguiente elemento
                    continue; % Saltar rutas no disponibles
                end

                % Definir inicio de la ruta
                inicioRuta = datosP60.fechaHoraLecturaDato(i);
                finRuta = inicioRuta; % Inicializar finRuta con inicioRuta

                % Buscar el último timestamp donde idRuta sigue siendo la misma
                j = i + 1;
                while j <= height(datosP60)
                    % mientras siga siendo la misma ruta
                    if strcmp(datosP60.idRuta(j), idRuta)
                        finRuta = datosP60.fechaHoraLecturaDato(j);
                        j = j + 1;

                        %En caso de que aparezca ret o des en medio de una
                        %ruta
                    elseif ismember(datosP60.idRuta(j), ["RET","DES"])
                        % mirar hacia adelante ignorando RETs consecutivos
                        k = j + 1;
                        while k <= height(datosP60) && ismember(datosP60.idRuta(k), ["RET","DES"])
                            k = k + 1;
                        end

                        %Comprobamos que sigue siendo la misma ruta
                        if k <= height(datosP60) && strcmp(datosP60.idRuta(k), idRuta)
                            % RET intermedio: continuar
                            finRuta = datosP60.fechaHoraLecturaDato(j);
                            j = k ; % saltar los RETs ya revisados
                            continue;
                        else
                            % RET terminal o fin de datos: cortar
                            finRuta = datosP60.fechaHoraLecturaDato(j);
                            break;
                        end

                    else
                        % cambio a otra ruta -> cortar
                        break;
                    end
                end

                i = j; % avanzar el índice externo al último usado


                % Filtrar datosSensor en el rango de la ruta
                indicesSensor = (datosSensor.time >= inicioRuta) & (datosSensor.time <= finRuta);
                datosSensorRuta = datosSensor(indicesSensor, :);

                % Si no hay datos en ese rango, pasar a la siguiente iteración
                if isempty(datosSensorRuta)
                    continue;
                end

                

                tiempoInicioAjustado = inicioRuta;
                tiempoFinAjustado = finRuta;

                indiceRuta = find(strcmp(string({paradas.idruta}), string(idRuta)));

                if isempty(indiceRuta)
                    % Saltar si no existe esa ruta en 'paradas'
                    disp("No se encontro: " + idRuta)
                    continue;
                end

                rutaParadas = paradas(indiceRuta).stops;

                % Inicializar variables de ajuste de tiempo
                paradasVisitadas = false(height(rutaParadas), 1);
                distMinParadas = inf(height(rutaParadas), 1);
                tiemposParadas = NaT(height(rutaParadas), 1);
                nombresParadas = strings(height(rutaParadas), 1);


                % Buscar el punto más cercano a la primera y última parada visitada
                minDistanciaInicio = inf;
                minDistanciaFin = inf;

                % Obtener la primera y última parada de la ruta
                latPrimeraParada = rutaParadas.lat(1);
                lonPrimeraParada = rutaParadas.lon(1);

                latUltimaParada = rutaParadas.lat(end);
                lonUltimaParada = rutaParadas.lon(end);

                % Recorrer datos de la ruta y verificar paradas
                for k = 1:height(rutaParadas)
                    latParada = rutaParadas.lat(k);
                    lonParada = rutaParadas.lon(k);
                    nombresParadas(k) = rutaParadas.stop_name(k);

                    for j = 1:height(datosSensorRuta)
                        latBus = datosSensorRuta.lat(j);
                        lonBus = datosSensorRuta.lon(j);
                        tiempoActual = datosSensorRuta.time(j);

                        distParada = Calculos.geodist(latBus, lonBus, latParada, lonParada);

                        if distParada < distMinParadas(k)
                            distMinParadas(k) = distParada;     % actualizar mínima distancia
                            tiemposParadas(k) = tiempoActual;   % registrar hora asociada
                        end

                        if distParada < distanciaUmbral
                            paradasVisitadas(k) = true;

                        end

                    end
                end

                tiempoPrimera = NaT(height(rutaParadas),1);
tiempoUltima  = NaT(height(rutaParadas),1);

for k = 1:height(rutaParadas)
    latParada = rutaParadas.lat(k);
    lonParada = rutaParadas.lon(k);

    % Calcular distancias de todos los puntos del bus a la parada k
    dists = arrayfun(@(j) Calculos.geodist(datosSensorRuta.lat(j), ...
                                           datosSensorRuta.lon(j), ...
                                           latParada, lonParada), ...
                                           1:height(datosSensorRuta));

    % Índices donde el bus estuvo dentro del rango
    idxDentro = find(dists < distanciaUmbral);

    if ~isempty(idxDentro)
        tiempoPrimera(k) = datosSensorRuta.time(idxDentro(1));
        tiempoUltima(k)  = datosSensorRuta.time(idxDentro(end));
    end
end

                % Calcular porcentaje de paradas cubiertas
                porcentajeVisitadas = sum(paradasVisitadas) / height(paradas(indiceRuta).stops);
                tablaParadas = table( ...
    nombresParadas, distMinParadas, tiemposParadas, ...
    tiempoPrimera, tiempoUltima, ...
    'VariableNames', {'Parada', 'DistanciaMin', 'TiempoLlegada', ...
                      'TiempoPrimeraDeteccion', 'TiempoUltimaDeteccion'});

                % Si cumple el porcentaje mínimo, guardar la ruta ajustada
                if porcentajeVisitadas >= porcentajeMinimoParadas
                    tiempos = [tiempos; {inicioRuta, finRuta, idRuta, paradasVisitadas, tablaParadas}];
                end

            end
        end


        %%

        function datosBuses = calcularVelocidadPorRutas(datosBuses)
            % Esta función calcula las velocidades para cada ruta de cada bus,
            % basándose en los tiempos de ruta y los datos del sensor.

            % Obtener los campos de los buses
            buses = fieldnames(datosBuses);

            % Iterar sobre cada bus
            for i = 1:numel(buses)
                bus = buses{i};

                % Saltar el campo 'info'
                if strcmp(bus, 'info')
                    continue;
                end

                % Obtener los campos de las fechas para el bus actual
                fechas = fieldnames(datosBuses.(bus));

                % Iterar sobre cada fecha
                for j = 1:numel(fechas)
                    fecha = fechas{j};

                    % Asegurarse de que existen datos de ruta y datos del sensor para el bus
                    if isfield(datosBuses.(bus).(fecha), 'tiempoRuta') && isfield(datosBuses.(bus).(fecha), 'datosSensor')
                        tiempoRuta = datosBuses.(bus).(fecha).tiempoRuta;
                        datosSensor = datosBuses.(bus).(fecha).datosSensor;

                        % Inicializar el campo velocidadRuta como una celda vacía
                        if ~isfield(datosBuses.(bus).(fecha), 'velocidadRuta') || isempty(datosBuses.(bus).(fecha).velocidadRuta)
                            datosBuses.(bus).(fecha).velocidadRuta = {}; % Inicializar como celda vacía si no existe
                        end

                        datosBuses.(bus).(fecha).velocidadRuta = {};


                        % Calcular la velocidad para cada ruta completa
                        for k = 1:size(tiempoRuta, 1)
                            ruta = tiempoRuta.Ruta{k}; % El nombre de la ruta está en la última columna
                            genero = tiempoRuta.Genero_Conductor{k};

                            % Trayecto de ida
                            inicioIda = tiempoRuta{k, 1};
                            finIda = tiempoRuta{k, 2};
                            datosIda = datosSensor(datosSensor{:, 'time'} >= inicioIda & datosSensor{:, 'time'} <= finIda, :);
                            [velocidadOriginal, velocidadCorregida] = Calcular.velocidadConFiltro(datosIda, 'time', 'lat', 'lon', 'pendiente');


                            % Guardar las velocidades para la ruta
                            tiempoVelocidad = {inicioIda, velocidadCorregida, ruta, genero, velocidadOriginal};

                            % Concatenar los resultados en el campo velocidadRuta
                            datosBuses.(bus).(fecha).velocidadRuta = [datosBuses.(bus).(fecha).velocidadRuta; tiempoVelocidad];

                            % Mostrar mensaje de confirmación
                            disp(['Velocidades calculadas para la ruta ' ruta ' en el bus ' bus ' en la fecha ' fecha '.']);
                        end
                    else
                        warning("No se encontraron los datos necesarios para calcular las velocidades de las rutas en el bus " + bus + " para el día " + fecha)
                    end
                end
            end
        end

        %%
        function nivelBateriaSuavizado = suavizarNivelBateria(nivelBateria)
            % Suaviza el nivel de batería usando un filtro de Savitzky-Golay.

            ordenPol = 3; % Orden del polinomio
            ventana = 65; % Longitud de la ventana, debe ser impar

            if length(nivelBateria) >= ventana
                % Aplicar filtro de Savitzky-Golay si hay suficientes datos
                nivelBateriaSuavizado = sgolayfilt(nivelBateria, ordenPol, ventana);
            else
                % Si no hay suficientes datos, mantener el nivel de batería sin cambios
                nivelBateriaSuavizado = nivelBateria;
            end
        end


        %%
        function datosBuses = aproximarNivelBateriaPorRutas(datosBuses)
            % Esta función suaviza el nivel de batería para cada ruta de cada bus en cada fecha,
            % asegurando que los datos se ajusten a la estructura de datosBuses.

            % Obtener los nombres de los buses
            buses = fieldnames(datosBuses);

            % Iterar sobre cada bus
            for i = 1:numel(buses)
                bus = buses{i};

                % Saltar el campo 'info'
                if strcmp(bus, 'info')
                    continue;
                end

                % Obtener los campos de las fechas para el bus actual
                fechas = fieldnames(datosBuses.(bus));

                % Iterar sobre cada fecha
                for j = 1:numel(fechas)
                    fecha = fechas{j};

                    % Verificar si existen datos de rutas y nivel de batería
                    if isfield(datosBuses.(bus).(fecha), 'tiempoRuta') && isfield(datosBuses.(bus).(fecha), 'P60')


                        % Inicializar el campo nivelBateriaSuavizado como celda vacía si no existe
                        if ~isfield(datosBuses.(bus).(fecha), 'nivelBateriaSuavizado') || isempty(datosBuses.(bus).(fecha).nivelBateriaSuavizado)
                            datosBuses.(bus).(fecha).nivelBateriaSuavizado = {}; % Inicializar como celda vacía
                        end

                        datosBuses.(bus).(fecha).nivelBateriaSuavizado = Calcular.suavizarNivelBateria(datosBuses.(bus).(fecha).P60.nivelRestanteEnergia);

                        rutas = datosBuses.(bus).(fecha).tiempoRuta;

                        % Calcular el nivel de batería suavizado para cada ruta
                        for k = 1:size(rutas, 1)
                            ruta = rutas.Ruta{k}; % Nombre de la ruta
                            datosP60 = datosBuses.(bus).(fecha).segmentoP60{k};
                            % Asumiendo que tienes tiempos de inicio y fin por ruta
                            t_inicio = rutas.Inicio_Ruta(k);  % datetime o datenum
                            t_fin = rutas.Fin_Ruta(k);

                            % Indices en el vector de todo el día correspondientes a la ruta
                            idx = datosBuses.(bus).(fecha).P60.fechaHoraLecturaDato >= t_inicio & ...
                                datosBuses.(bus).(fecha).P60.fechaHoraLecturaDato <= t_fin;

                            % Extraer el segmento suavizado para esta ruta
                            nivelBateriaRuta = datosBuses.(bus).(fecha).nivelBateriaSuavizado(idx);

                            % Guardar en la ruta correspondiente
                            datosBuses.(bus).(fecha).segmentoP60{k}.nivelBateriaSuavizado = nivelBateriaRuta;
                            % Mostrar mensaje de confirmación
                            disp(['Nivel de batería suavizado para la ruta ' ruta ' en el bus ' bus ' en la fecha ' fecha '.']);
                        end
                    else
                        warning("No se encontraron los datos necesarios para suavizar el nivel de batería en el bus " + bus + " para el día " + fecha);
                    end
                end
            end
        end


        %%

        function datosBuses = ConsumoPorRuta(datosBuses, capacidadBateria_kWh)
            buses = fieldnames(datosBuses);

            for i = 1:numel(buses)
                bus = buses{i};
                if strcmp(bus, 'info')
                    continue;
                end

                fechas = fieldnames(datosBuses.(bus));
                for j = 1:numel(fechas)
                    fecha = fechas{j};
                    if isfield(datosBuses.(bus).(fecha), 'segmentoP60')
                        segmentos = datosBuses.(bus).(fecha).segmentoP60;
                        for k = 1:numel(segmentos)
                            datosP60 = datosBuses.(bus).(fecha).segmentoP60{k};

                            if ismember('nivelBateriaSuavizado', datosP60.Properties.VariableNames) && ~isempty(datosP60.nivelBateriaSuavizado)
                                % Calcular consumo por intervalo
                                consumoPorcentaje = [NaN; -diff(datosP60.nivelBateriaSuavizado)];
                                % (nivel anterior - nivel actual) => -diff porque diff es actual-anterior

                                if nargin > 1 && ~isempty(capacidadBateria_kWh)
                                    consumo_kWh = (consumoPorcentaje / 100) * capacidadBateria_kWh;
                                else
                                    consumo_kWh = NaN(size(consumoPorcentaje));
                                end

                                % Asignar a la tabla
                                datosBuses.(bus).(fecha).segmentoP60{k}.consumoPorcentaje = consumoPorcentaje;
                                datosBuses.(bus).(fecha).segmentoP60{k}.consumo_kWh = consumo_kWh;
                            else
                                n = height(datosP60);
                                datosBuses.(bus).(fecha).segmentoP60{k}.consumoPorcentaje = NaN(n,1);
                                datosBuses.(bus).(fecha).segmentoP60{k}.consumo_kWh = NaN(n,1);
                            end
                        end
                    end
                end
            end
        end


        %%

        function datosBuses = RiesgoCurvaTodasRutas(datosBuses, PosCurvas)
            buses = fieldnames(datosBuses);

            for i = 1:numel(buses)
                bus = buses{i};
                if strcmp(bus, 'info')
                    continue;
                end

                fechas = fieldnames(datosBuses.(bus));
                for j = 1:numel(fechas)
                    fecha = fechas{j};
                    if isfield(datosBuses.(bus).(fecha), 'segmentoP60')
                        segmentos = datosBuses.(bus).(fecha).segmentoP60;
                        for k = 1:numel(segmentos)
                            datosSensorRuta = datosBuses.(bus).(fecha).datosSensorRuta{k,2};
                            rutas = datosBuses.(bus).(fecha).tiempoRuta;
                            t_inicio = rutas.Inicio_Ruta(k);
                            t_fin = rutas.Fin_Ruta(k);

                            % Llama a la función de riesgo de curva (sin gráfico) con try-catch
                            try
                                riesgo = Calculos.riesgoCurva2(datosSensorRuta, t_inicio, t_fin, PosCurvas);
                                datosBuses.(bus).(fecha).Curvas{k}.riesgoCurva = riesgo;
                            catch ME
                                % En caso de error, guarda NaN y el mensaje de error
                                datosBuses.(bus).(fecha).Curvas{k}.riesgoCurva = NaN;
                                datosBuses.(bus).(fecha).Curvas{k}.errorRiesgoCurva2 = ME.message;
                                continue; % pasa al siguiente segmento
                            end

                            % Calcula el percentil 90 del riesgo (por curva)
                            if ~isempty(riesgo)
                                p90 = NaN(1, numel(riesgo));
                                for m = 1:numel(riesgo)
                                    if size(riesgo{m},2) >= 3 && size(riesgo{m},1) >= 1
                                        riesgoCurvaVals = riesgo{m}(:,3); % tercera columna = "riesgo"
                                        p90(m) = prctile(riesgoCurvaVals, 90);
                                    else
                                        p90(m) = NaN;
                                    end
                                end
                                datosBuses.(bus).(fecha).Curvas{k}.riesgoCurva_p90 = p90;
                            else
                                datosBuses.(bus).(fecha).Curvas{k}.riesgoCurva_p90 = NaN;
                            end
                        end
                    end
                end
            end
        end


        %%

        function datosBuses = AceleracionPorRutas(datosBuses)
            % Esta función calcula las velocidades para cada ruta de cada bus,
            % basándose en los tiempos de ruta y los datos del sensor.

            % Obtener los campos de los buses
            buses = fieldnames(datosBuses);

            % Iterar sobre cada bus
            for i = 1:numel(buses)
                bus = buses{i};

                % Saltar el campo 'info'
                if strcmp(bus, 'info')
                    continue;
                end

                % Obtener los campos de las fechas para el bus actual
                fechas = fieldnames(datosBuses.(bus));

                % Iterar sobre cada fecha
                for j = 1:numel(fechas)
                    fecha = fechas{j};

                    % Asegurarse de que existen datos de ruta y datos del sensor para el bus
                    if isfield(datosBuses.(bus).(fecha), 'tiempoRuta') && isfield(datosBuses.(bus).(fecha), 'datosSensor')
                        tiempoRuta = datosBuses.(bus).(fecha).tiempoRuta;
                        datosSensor = datosBuses.(bus).(fecha).datosSensor;

                        % Inicializar el campo velocidadRuta como una celda vacía
                        if ~isfield(datosBuses.(bus).(fecha), 'aceleracionRuta') || isempty(datosBuses.(bus).(fecha).aceleracionRuta)
                            datosBuses.(bus).(fecha).aceleracionRuta = {}; % Inicializar como celda vacía si no existe
                        end

                        datosBuses.(bus).(fecha).aceleracionRuta = {};


                        % Calcular la velocidad para cada ruta completa (ida y vuelta)
                        for k = 1:size(tiempoRuta, 1)

                            ruta = tiempoRuta.Ruta{k}; % El nombre de la ruta está en la última columna
                            genero = tiempoRuta.Genero_Conductor{k};

                            % Trayecto de ida
                            inicioIda = tiempoRuta{k, 1};
                            velocidadIda = datosBuses.(bus).(fecha).velocidadRuta{k, 2};
                            tiempoIda = datosBuses.(bus).(fecha).datosSensorRuta{k, 2}.time;
                            aceleracionIda = Calcular.aceleracion(velocidadIda, tiempoIda);


                            % Guardar las velocidades para la ruta
                            tiempoAceleracion = {inicioIda, aceleracionIda, ruta, genero};

                            % Concatenar los resultados en el campo velocidadRuta
                            datosBuses.(bus).(fecha).aceleracionRuta = [datosBuses.(bus).(fecha).aceleracionRuta; tiempoAceleracion];

                            % Mostrar mensaje de confirmación
                            disp(['Velocidades calculadas para la ruta ' ruta ' en el bus ' bus ' en la fecha ' fecha '.']);
                        end
                    else
                        warning("No se encontraron los datos necesarios para calcular las velocidades de las rutas en el bus " + bus + " para el día " + fecha)
                    end
                end
            end
        end

        function aceleracion = aceleracion(velocidades, fechas)
            % Función para calcular la aceleración a partir de fechas y velocidades
            % donde la longitud de 'velocidades' es una unidad menos que 'fechas'.

            % Calcular las diferencias de tiempo en segundos, excluyendo el último punto de tiempo
            dt = seconds(diff(fechas(1:end-1))); % Diferencias en tiempo, en segundos

            % Calcular las diferencias de velocidad
            dv = diff(velocidades); % En este caso, no es necesario usar 'diff' ya que ya hay un dato menos

            % Calcular la aceleración (dv/dt)
            aceleracion = dv ./ dt;
        end

        %%
        function datosBuses = tiempoEntrePuntos(datosBuses)
            datosBuses = Calcular.iterarSobreBusesYFechas(datosBuses, @Calcular.tiempoEntrePuntosWrapper);
        end
        function deltaTiempo = diferenciaTiempoRuta(datos, etiquetaTiempo)
            deltaTiempo = [0; seconds(diff(datos.(etiquetaTiempo)))];
        end


        function datosBuses = tiempoEntrePuntosWrapper(datosBuses, k)
            deltaTiempo = Calcular.diferenciaTiempoRuta(datosBuses.datosSensorRuta{k, 2}, 'time');
            datosBuses.datosSensorRuta{k, 2}.deltaTiempo = deltaTiempo;

            deltaDistancia = cumsum(deltaTiempo); % Usar los tiempos del sensor
            deltaDistanciaNorm = (deltaDistancia - min(deltaDistancia)) / ...
                (max(deltaDistancia) - min(deltaDistancia));
            datosBuses.datosSensorRuta{k, 2}.deltaTiempoAcum = deltaDistancia;
            datosBuses.datosSensorRuta{k, 2}.deltaTiempoAcumNorm = deltaDistanciaNorm;

        end



        %%

        function resumenRutas = resumenRecorridosPorRuta(datosBuses)
            % Esta función recorre toda la estructura datosBuses y hace un resumen
            % del número de recorridos por cada ruta.

            % Inicializar un contenedor para contar los recorridos por ruta
            resumenRutas = containers.Map('KeyType', 'char', 'ValueType', 'double');  % Especificar tipos de clave y valor

            % Obtener los campos de los buses
            buses = fieldnames(datosBuses);

            % Iterar sobre cada bus
            for i = 1:numel(buses)
                bus = buses{i};

                % Saltar el campo 'info'
                if strcmp(bus, 'info')
                    continue;
                end

                % Obtener los campos de las fechas para el bus actual
                fechas = fieldnames(datosBuses.(bus));

                % Iterar sobre cada fecha
                for j = 1:numel(fechas)
                    fecha = fechas{j};

                    % Verificar si hay campo tiempoRuta
                    if isfield(datosBuses.(bus).(fecha), 'tiempoRuta') && ~isempty(datosBuses.(bus).(fecha).tiempoRuta)
                        % Obtener la tabla de tiempoRuta
                        tiempoRuta = datosBuses.(bus).(fecha).tiempoRuta;

                        % Iterar sobre cada fila de tiempoRuta
                        for k = 1:size(tiempoRuta, 1)
                            ruta = char(tiempoRuta.Ruta{k});  % Asegurarse de que la ruta sea de tipo 'char'

                            % Incrementar el contador para la ruta actual
                            if isKey(resumenRutas, ruta)
                                resumenRutas(ruta) = resumenRutas(ruta) + 1;
                            else
                                resumenRutas(ruta) = 1;
                            end
                        end
                    end
                end
            end

            % Convertir el contenedor a una tabla para un resumen más claro
            rutas = keys(resumenRutas);
            numRecorridos = values(resumenRutas);

            resumenRutas = table(rutas', cell2mat(numRecorridos)', 'VariableNames', {'Ruta', 'NumeroRecorridos'});
        end

        %%
        function datos = NormalizarRuta()

        end

        %%
        function datosBuses = extraerDatosSensorPorRutas(datosBuses)



            % Esta función extrae los datos del sensor para las rutas de cada bus,
            % basándose en los tiempos de ruta.

            % Obtener los campos de los buses
            buses = fieldnames(datosBuses);

            % Iterar sobre cada bus
            for i = 1:numel(buses)
                bus = buses{i};

                % Saltar el campo 'info'
                if strcmp(bus, 'info')
                    continue;
                end

                % Obtener los campos de las fechas para el bus actual
                fechas = fieldnames(datosBuses.(bus));

                % Iterar sobre cada fecha
                for j = 1:numel(fechas)
                    fecha = fechas{j};

                    % Asegurarse de que existen datos de ruta y datos del sensor para el bus
                    if isfield(datosBuses.(bus).(fecha), 'tiempoRuta') && isfield(datosBuses.(bus).(fecha), 'datosSensor')
                        tiempoRuta = datosBuses.(bus).(fecha).tiempoRuta;
                        datosSensor = datosBuses.(bus).(fecha).datosSensor;

                        % Inicializar el campo datosSensorRuta como una celda vacía
                        if ~isfield(datosBuses.(bus).(fecha), 'datosSensorRuta') || isempty(datosBuses.(bus).(fecha).datosSensorRuta)
                            datosBuses.(bus).(fecha).datosSensorRuta = {}; % Inicializar como celda vacía si no existe
                        end

                        datosBuses.(bus).(fecha).datosSensorRuta = {};

                        % Extraer los datos del sensor para cada ruta completa (ida y vuelta)
                        for k = 1:size(tiempoRuta, 1)
                            ruta = tiempoRuta{k, 3}; % El nombre de la ruta está en la última columna
                            genero = tiempoRuta{k, 4};

                            % Trayecto de ida
                            inicioIda = tiempoRuta{k, 1};
                            finIda = tiempoRuta{k, 2};
                            datosIda = datosSensor(datosSensor{:, 'time'} >= inicioIda & datosSensor{:, 'time'} <= finIda, :);

                            % Almacenar los datos del sensor extraídos
                            tiempoDatosSensor = {inicioIda, datosIda, ruta, genero};

                            % Concatenar los resultados en el campo datosSensorRuta
                            datosBuses.(bus).(fecha).datosSensorRuta = [datosBuses.(bus).(fecha).datosSensorRuta; tiempoDatosSensor];

                            % Mostrar mensaje de confirmación
                            disp(['Datos del sensor extraídos para la ruta ' ruta ' en el bus ' bus ' en la fecha ' fecha '.']);
                        end
                    else
                        warning("No se encontraron los datos necesarios para extraer los datos del sensor de las rutas en el bus " + bus + " para el día " + fecha)
                    end
                end
            end
        end


        function datosBuses = iterarSobreBusesYFechas(datosBuses, funcionAplicar, varargin)
            % Obtener los campos de los buses
            buses = fieldnames(datosBuses);

            % Iterar sobre cada bus
            for i = 1:numel(buses)
                bus = buses{i};

                % Saltar el campo 'info'
                if strcmp(bus, 'info')
                    continue;
                end

                % Obtener los campos de las fechas para el bus actual
                fechas = fieldnames(datosBuses.(bus));

                % Iterar sobre cada fecha
                for j = 1:numel(fechas)
                    fecha = fechas{j};


                    try
                        for k = 1:numel(datosBuses.(bus).(fecha).tiempoRuta(:, 1))
                            datosBuses.(bus).(fecha) = funcionAplicar(datosBuses.(bus).(fecha), k, varargin{:});  % Aplicar la función pasada como argumento

                        end
                    catch ME
                        fprintf('Error encontrado: %s\n', ME.message);
                        if ~isempty(ME.stack)
                            fprintf('Archivo: %s\n', ME.stack(1).file);
                            fprintf('Función: %s\n', ME.stack(1).name);
                            fprintf('Línea: %d\n', ME.stack(1).line);
                        end
                    end


                end
            end
        end
        function datosBuses = calcularKilometroRutasWrapper(datosBuses, k)
            datosBuses.segmentoP60{k} = sortrows(datosBuses.segmentoP60{k},'fechaHoraLecturaDato','ascend');

            kilometrosOdometro = datosBuses.segmentoP60;
            tiemposRutas = datosBuses.tiempoRuta;

            if isempty(kilometrosOdometro) || isempty(tiemposRutas)
                return;
            end

            % Verificar si las columnas de "Kilometros_Ida" y "Kilometros_Vuelta" ya existen
            if ~ismember('Kilometros_Ida', tiemposRutas.Properties.VariableNames)
                % Agregar columnas vacías con encabezados 'Kilometros_Ida' y 'Kilometros_Vuelta'
                tiemposRutas.Kilometros_Ida = nan(height(tiemposRutas), 1);
                datosBuses.tiempoRuta = tiemposRutas; % Actualizar la tabla con las nuevas columnas
            end

            % Calcular y asignar los valores para las nuevas columnas
            try
                datosBuses.tiempoRuta{k, 'Kilometros_Ida'} = datosBuses.segmentoP60{k, 1}.kilometrosOdometro(end) - datosBuses.segmentoP60{k, 1}.kilometrosOdometro(1);
            catch ME
                fprintf('Error encontrado: %s\n', ME.message);
            end
        end

        function datosBuses = calcularKilometroRutas(datosBuses)
            % Esta función iterará sobre los buses y las fechas para calcular los kilómetros recorridos
            % y agregar las columnas "Kilometros_Ida" a la tabla tiempoRuta.

            datosBuses = Calcular.iterarSobreBusesYFechas(datosBuses, @Calcular.calcularKilometroRutasWrapper);
        end

        function datosBuses = PorcentajesAceleracionW(datosBuses, k)
            acelepercent1 = sum(datosBuses.indicesAceleracionRuta{k, 1}{1}>1)/sum(datosBuses.indicesAceleracionRuta{k, 1}{1}>0);
            acelepercent2 = sum(datosBuses.indicesAceleracionRuta{k, 1}{1}>2)/sum(datosBuses.indicesAceleracionRuta{k, 1}{1}>0);

            datosBuses.tiempoRuta.PorcentajeAceleracion1(k) = acelepercent1;
            datosBuses.tiempoRuta.PorcentajeAceleracion2(k) = acelepercent2;
        end

        function datosBuses = PorcentajesAceleracion(datosBuses)
            datosBuses = Calcular.iterarSobreBusesYFechas(datosBuses, @Calcular.PorcentajesAceleracionW);
        end


        function datosBuses = AceleracionKilometrosWrapper(datosBuses, k)
            % Esta función calcula la relación entre la longitud de cada celda en indicesAceleracionRuta
            % y los kilómetros recorridos en Kilometros_Ida para la fila k.

            % Obtener los datos de índices de aceleración
            nAceleracionesPositivas = size (datosBuses.indicesAceleracionRuta{k, 1});
            nAceleracionesNegativas = size(datosBuses.indicesAceleracionRuta{k, 2});

            % Obtener los kilómetros recorridos en la ida
            kilometrosIda = datosBuses.tiempoRuta.Kilometros_Ida(k);

            % Verificar si los datos existen
            if isempty(nAceleracionesPositivas) || isempty(kilometrosIda) || isempty(nAceleracionesNegativas)
                error('No hay datos suficientes para calcular la relación.');
            end



            datosBuses.tiempoRuta.AceleKiloPosi(k) = nAceleracionesPositivas(1) / kilometrosIda;
            datosBuses.tiempoRuta.AceleKiloNega(k) = nAceleracionesNegativas(1) / kilometrosIda;
        end


        function datosBuses = aceleracionesKilometroRutas(datosBuses)

            datosBuses = Calcular.iterarSobreBusesYFechas(datosBuses, @Calcular.AceleracionKilometrosWrapper);
        end

        function datosBuses = velocidadVsDistancia(datosBuses)

            datosBuses = Calcular.iterarSobreBusesYFechas(datosBuses, @Calcular.velocidadVsDistanciaWrapper);
        end

        function datosBuses = velocidadVsDistanciaWrapper(datosBuses, k)


            % Obtener latitud y longitud
            lat = datosBuses.datosSensorRuta{k, 2}.lat;
            lon = datosBuses.datosSensorRuta{k, 2}.lon;

            % Inicializar vector de distancias
            n = length(lat);
            distancias = zeros(n, 1); % Mismo tamaño que lat/lon

            % Calcular distancia entre puntos consecutivos
            for i = 1:n - 1
                distancias(i + 1) = distance(lat(i), lon(i), lat(i+1), lon(i+1), wgs84Ellipsoid('meters'));
            end

            % Guardar el vector de distancias en la subtabla
            datosBuses.datosSensorRuta{k, 2}.distancia = distancias;

            acumuladoDistancia =  cumsum(distancias);

            datosBuses.datosSensorRuta{k, 2}.distanciaAcum = acumuladoDistancia;

            deltaDistanciaNorm = (acumuladoDistancia - min(acumuladoDistancia)) / ...
                (max(acumuladoDistancia) - min(acumuladoDistancia));

            datosBuses.datosSensorRuta{k, 2}.distanciaAcumNorm = deltaDistanciaNorm;

            deltaDistanciaNormP60 = (datosBuses.segmentoP60{k}.kilometrosOdometro - datosBuses.segmentoP60{k}.kilometrosOdometro(1))/...
                (datosBuses.segmentoP60{k}.kilometrosOdometro(numel(datosBuses.segmentoP60{k}.kilometrosOdometro)) - datosBuses.segmentoP60{k}.kilometrosOdometro(1));
            datosBuses.segmentoP60{k}.distanciaAcumNormP60 = deltaDistanciaNormP60;
        end



        function datosBuses = ClasificarHorarioRuta(datosBuses)
            datosBuses = Calcular.iterarSobreBusesYFechas(datosBuses, @Calcular.ClasificarHorarioRutaWrapper);
        end

        function datosBuses = ClasificarHorarioRutaWrapper(datosBuses, k)
            % Convierte a minutos desde medianoche
            inicio = Calcular.HoraEnMinutos(datosBuses.tiempoRuta.Inicio_Ruta(k));
            fin    = Calcular.HoraEnMinutos(datosBuses.tiempoRuta.Fin_Ruta(k));

            % Ajuste si cruza medianoche (intervalo medio-abierto [inicio, fin))
            if fin <= inicio
                fin = fin + 1440;
            end

            % Rangos diarios [min, max) en minutos
            rangos.P = [330 390; 1020 1080];   % Pico 5:30 a 8 4 a 6:30
            rangos.V = [390 1020; 1080 1320];  % Valle
            rangos.F = [0 330; 1320 1440];     % Flujo libre

            % Duración por tipo, sumando superposición con el día actual y el siguiente
            d = struct('P',0,'V',0,'F',0);
            tipos = fieldnames(d);

            for tt = 1:numel(tipos)
                t = tipos{tt};
                d.(t) = Calcular.DuracionEnRangos(inicio, fin, rangos.(t));
            end

            % Determinar horario predominante (en caso de empate: P > V > F)
            [~, idx] = max([d.P, d.V, d.F]);
            orden = ['P','V','F'];
            horarioPredominante = orden(idx);

            % Guardar
            datosBuses.tiempoRuta.HorarioRuta(k) = horarioPredominante;
        end

        function dTotal = DuracionEnRangos(inicio, fin, rangosDia)
            shifts = [0 1440];
            dTotal = 0;
            for s = shifts
                r = rangosDia + s;
                for i = 1:size(r,1)
                    dTotal = dTotal + Calcular.Overlap(inicio, fin, r(i,1), r(i,2));
                end
            end
        end

        function d = Overlap(a1, a2, b1, b2)
            s = max(a1, b1);
            e = min(a2, b2);
            d = max(0, e - s);
        end

        function datosBuses = ClasificarHorarioRutaW(datosBuses, k)
            % Convierte las horas de inicio y fin a minutos desde medianoche
            inicio = Calcular.HoraEnMinutos(datosBuses.tiempoRuta.Inicio_Ruta(k));
            fin = Calcular.HoraEnMinutos(datosBuses.tiempoRuta.Fin_Ruta(k));

            % Duraciones por tipo de horario
            duraciones = struct('P', 0, 'V', 0, 'F', 0);

            % Evaluar minuto a minuto el tipo de horario
            for t = inicio:fin-1
                tipo = Calcular.ClasificarHorario(mod(t,1440)); % mod para mantener dentro de 24h
                duraciones.(tipo) = duraciones.(tipo) + 1;
            end

            % Determinar horario predominante
            [~, idx] = max([duraciones.P, duraciones.V, duraciones.F]);
            tipos = ['P', 'V', 'F'];
            horarioPredominante = tipos(idx);

            % Guardar el resultado
            datosBuses.tiempoRuta.HorarioRuta(k) = horarioPredominante;
        end

        function minutos = HoraEnMinutos(horaStr)
            % Convierte 'HH:mm' a minutos
            tiempo = datetime(horaStr, 'InputFormat', 'HH:mm');
            minutos = hour(tiempo) * 60 + minute(tiempo);
        end

        function tipo = ClasificarHorario(minutos)
            % Clasifica según los rangos definidos
            if (minutos >= 330 && minutos < 390) || (minutos >= 1020 && minutos < 1080)
                tipo = 'P'; % Pico
            elseif (minutos >= 390 && minutos < 1020) || (minutos >= 1080 && minutos < 1320)
                tipo = 'V'; % Valle
            else
                tipo = 'F'; % Flujo libre
            end
        end


        %%


        function datosBuses = corregirAceleracionPorRutas(datosBuses)
            % Esta función corrige los valores de aceleración de cada ruta en cada bus
            % eliminando ruido y estableciendo segmentos de aceleración constantes.

            % Obtener los nombres de los buses
            buses = fieldnames(datosBuses);

            % Iterar sobre cada bus
            for i = 1:numel(buses)
                bus = buses{i};

                % Saltar el campo 'info'
                if strcmp(bus, 'info')
                    continue;
                end

                % Obtener las fechas disponibles para el bus
                fechas = fieldnames(datosBuses.(bus));

                % Iterar sobre cada fecha
                for j = 1:numel(fechas)
                    fecha = fechas{j};

                    % Verificar si existen datos de rutas en la fecha
                    if isfield(datosBuses.(bus).(fecha), 'aceleracionRuta') && isfield(datosBuses.(bus).(fecha), 'tiempoRuta')

                        % Obtener las rutas disponibles
                        numRutas = size(datosBuses.(bus).(fecha).aceleracionRuta, 1);

                        
                        datosBuses.(bus).(fecha).indicesAceleracionRuta = table([], [], [], [], ...
                            'VariableNames', {'MagnitudesPositivas', 'MagnitudesNegativas', 'TiemposPositivos', 'TiemposNegativos'});


                        % Iterar sobre cada ruta en la fecha
                        for k = 1:numRutas
                            % Extraer datos de aceleración y tiempo de la ruta actual
                            acc = datosBuses.(bus).(fecha).aceleracionRuta{k,2}; % Aceleración en la segunda columna
                            tiempo = datosBuses.(bus).(fecha).datosSensorRuta{k,2}.time; % Tiempo en la segunda columna

                            % Filtrar valores pequeños (ruido)
                            acc(abs(acc) <= 0.3) = 0;

                            % Inicializar variables
                            intervalo_inicio = 1;
                            tiempo_constante = [];
                            valor_constante = [];

                            % Arreglos para intervalos positivos y negativos
                            magnitudes_positivas = [];
                            magnitudes_negativas = [];
                            tiempos_positivos = [];
                            tiempos_negativos = [];

                            % Recorrer la señal de aceleración
                            while intervalo_inicio <= length(acc)
                                if acc(intervalo_inicio) > 0
                                    % Buscar el final del intervalo positivo
                                    intervalo_fin = find(acc(intervalo_inicio:end) <= 0, 1) + intervalo_inicio - 2;
                                    if isempty(intervalo_fin)
                                        intervalo_fin = length(acc);
                                    end
                                    altura = mean(acc(intervalo_inicio:intervalo_fin));
                                    duracion = tiempo(intervalo_fin) - tiempo(intervalo_inicio);

                                    % Guardar los valores en los arreglos
                                    magnitudes_positivas = [magnitudes_positivas; altura];
                                    tiempos_positivos = [tiempos_positivos; duracion];

                                elseif acc(intervalo_inicio) < 0
                                    % Buscar el final del intervalo negativo
                                    intervalo_fin = find(acc(intervalo_inicio:end) >= 0, 1) + intervalo_inicio - 2;
                                    if isempty(intervalo_fin)
                                        intervalo_fin = length(acc);
                                    end
                                    altura = mean(acc(intervalo_inicio:intervalo_fin));
                                    duracion = tiempo(intervalo_fin) - tiempo(intervalo_inicio);

                                    % Guardar los valores en los arreglos
                                    magnitudes_negativas = [magnitudes_negativas; altura];
                                    tiempos_negativos = [tiempos_negativos; duracion];

                                else
                                    % Intervalo con aceleración 0
                                    intervalo_fin = find(acc(intervalo_inicio:end) ~= 0, 1) + intervalo_inicio - 2;
                                    if isempty(intervalo_fin)
                                        intervalo_fin = length(acc);
                                    end
                                    altura = 0;
                                end

                                % Construir la señal corregida
                                tiempo_constante = [tiempo_constante; tiempo(intervalo_inicio:intervalo_fin)];
                                valor_constante = [valor_constante; repmat(altura, intervalo_fin - intervalo_inicio + 1, 1)];

                                % Actualizar el inicio del siguiente intervalo
                                intervalo_inicio = intervalo_fin + 1;
                            end

                            % Guardar la aceleración corregida en la estructura de datos
                            datosBuses.(bus).(fecha).aceleracionRuta{k,5} = tiempo_constante;
                            datosBuses.(bus).(fecha).aceleracionRuta{k,6} = valor_constante;

                            % Crear una nueva fila de la tabla con los datos de índices
                            nuevaFila = table({magnitudes_positivas}, {magnitudes_negativas}, {tiempos_positivos}, {tiempos_negativos}, ...
                                'VariableNames', {'MagnitudesPositivas', 'MagnitudesNegativas', 'TiemposPositivos', 'TiemposNegativos'});

                            % Agregar la nueva fila a la tabla existente
                            datosBuses.(bus).(fecha).indicesAceleracionRuta = [datosBuses.(bus).(fecha).indicesAceleracionRuta; nuevaFila];
                        end

                        % Mostrar mensaje de confirmación por fecha
                        disp(['Corrección de aceleración realizada para el bus ' bus ' en la fecha ' fecha '.']);
                    else
                        warning("No se encontraron los datos de aceleración para el bus " + bus + " en la fecha " + fecha);
                    end
                end
            end
        end




        function datosBuses = corregirAceleracionPorRutasMax(datosBuses)
            % Esta función corrige los valores de aceleración de cada ruta en cada bus
            % eliminando ruido y estableciendo segmentos de aceleración constantes.

            % Obtener los nombres de los buses
            buses = fieldnames(datosBuses);

            % Iterar sobre cada bus
            for i = 1:numel(buses)
                bus = buses{i};

                % Saltar el campo 'info'
                if strcmp(bus, 'info')
                    continue;
                end

                % Obtener las fechas disponibles para el bus
                fechas = fieldnames(datosBuses.(bus));

                % Iterar sobre cada fecha
                for j = 1:numel(fechas)
                    fecha = fechas{j};

                    % Verificar si existen datos de rutas en la fecha
                    if isfield(datosBuses.(bus).(fecha), 'aceleracionRuta') && isfield(datosBuses.(bus).(fecha), 'tiempoRuta')

                        % Obtener las rutas disponibles
                        numRutas = size(datosBuses.(bus).(fecha).aceleracionRuta, 1);



                        % Iterar sobre cada ruta en la fecha
                        for k = 1:numRutas
                            % Extraer datos de aceleración y tiempo de la ruta actual
                            acc = datosBuses.(bus).(fecha).aceleracionRuta{k,2}; % Aceleración en la segunda columna
                            tiempo = datosBuses.(bus).(fecha).datosSensorRuta{k,2}.time; % Tiempo en la segunda columna

                            % Filtrar valores pequeños (ruido)
                            acc(abs(acc) <= 0.3) = 0;

                            % Inicializar variables
                            intervalo_inicio = 1;
                            tiempo_constante = [];
                            valor_constante = [];

                            % Arreglos para intervalos positivos y negativos
                            magnitudes_positivas = [];
                            magnitudes_negativas = [];
                            tiempos_positivos = [];
                            tiempos_negativos = [];

                            % Recorrer la señal de aceleración
                            while intervalo_inicio <= length(acc)
                                if acc(intervalo_inicio) > 0
                                    % Buscar el final del intervalo positivo
                                    intervalo_fin = find(acc(intervalo_inicio:end) <= 0, 1) + intervalo_inicio - 2;
                                    if isempty(intervalo_fin)
                                        intervalo_fin = length(acc);
                                    end
                                    altura = max(acc(intervalo_inicio:intervalo_fin));
                                    duracion = tiempo(intervalo_fin) - tiempo(intervalo_inicio);

                                    % Guardar los valores en los arreglos
                                    magnitudes_positivas = [magnitudes_positivas; altura];
                                    tiempos_positivos = [tiempos_positivos; duracion];

                                elseif acc(intervalo_inicio) < 0
                                    % Buscar el final del intervalo negativo
                                    intervalo_fin = find(acc(intervalo_inicio:end) >= 0, 1) + intervalo_inicio - 2;
                                    if isempty(intervalo_fin)
                                        intervalo_fin = length(acc);
                                    end
                                    altura = min(acc(intervalo_inicio:intervalo_fin));
                                    duracion = tiempo(intervalo_fin) - tiempo(intervalo_inicio);

                                    % Guardar los valores en los arreglos
                                    magnitudes_negativas = [magnitudes_negativas; altura];
                                    tiempos_negativos = [tiempos_negativos; duracion];

                                else
                                    % Intervalo con aceleración 0
                                    intervalo_fin = find(acc(intervalo_inicio:end) ~= 0, 1) + intervalo_inicio - 2;
                                    if isempty(intervalo_fin)
                                        intervalo_fin = length(acc);
                                    end
                                    altura = 0;
                                end

                                % Construir la señal corregida
                                tiempo_constante = [tiempo_constante; tiempo(intervalo_inicio:intervalo_fin)];
                                valor_constante = [valor_constante; repmat(altura, intervalo_fin - intervalo_inicio + 1, 1)];

                                % Actualizar el inicio del siguiente intervalo
                                intervalo_inicio = intervalo_fin + 1;
                            end

                            % Guardar la aceleración corregida en la estructura de datos
                            datosBuses.(bus).(fecha).aceleracionRuta{k,7} = tiempo_constante;
                            datosBuses.(bus).(fecha).aceleracionRuta{k,8} = valor_constante;

                            datosBuses.(bus).(fecha).indicesAceleracionRuta.magnitudes_positivas_max{k} = magnitudes_positivas;
                            datosBuses.(bus).(fecha).indicesAceleracionRuta.magnitudes_negativas_max{k} = magnitudes_negativas;
                            datosBuses.(bus).(fecha).indicesAceleracionRuta.tiempos_positivos_max{k} = tiempos_positivos;
                            datosBuses.(bus).(fecha).indicesAceleracionRuta.tiempos_negativos_max{k} = tiempos_negativos;
                        end

                        % Mostrar mensaje de confirmación por fecha
                        disp(['Corrección de aceleración realizada para el bus ' bus ' en la fecha ' fecha '.']);
                    else
                        warning("No se encontraron los datos de aceleración para el bus " + bus + " en la fecha " + fecha);
                    end
                end
            end
        end



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
        end

        function [tiempo_constante, valor_constante] = aceleracionPorCuadrosProm(datos) %se recbie una tabla con valores Acc y tiempo
            %por ejemplo datos = table(datosBuses.bus_4012.f_03_07_2024.datosSensor.time(6300:10842), datosBuses.bus_4012.f_03_07_2024.aceleracionRuta{1, 3}  , 'VariableNames', {'Tiempo', 'Acc'});
            datos.Acc(abs(datos.Acc)<=0.3)=0;
            % Inicializar variables
            intervalo_inicio = 1;
            tiempo_constante = [];
            valor_constante = [];

            % Recorrer la señal para identificar intervalos positivos, negativos o 0
            while intervalo_inicio <= length(datos.Acc)
                if datos.Acc(intervalo_inicio) > 0
                    % Buscar el final del intervalo positivo
                    intervalo_fin = find(datos.Acc(intervalo_inicio:end) <= 0, 1) + intervalo_inicio - 2;
                    if isempty(intervalo_fin)
                        intervalo_fin = length(datos.Acc);
                    end
                    altura = mean(datos.Acc(intervalo_inicio:intervalo_fin));

                elseif datos.Acc(intervalo_inicio) < 0
                    % Buscar el final del intervalo negativo
                    intervalo_fin = find(datos.Acc(intervalo_inicio:end) >= 0, 1) + intervalo_inicio - 2;
                    if isempty(intervalo_fin)
                        intervalo_fin = length(datos.Acc);
                    end
                    altura = mean(datos.Acc(intervalo_inicio:intervalo_fin));

                else
                    % Para los valores de 0
                    intervalo_fin = find(datos.Acc(intervalo_inicio:end) ~= 0, 1) + intervalo_inicio - 2;
                    if isempty(intervalo_fin)
                        intervalo_fin = length(datos.Acc);
                    end
                    altura = 0; % Asignar 0 cuando el valor es 0
                end

                % Crear la señal constante
                tiempo_constante = [tiempo_constante; datos.Tiempo(intervalo_inicio:intervalo_fin)];
                valor_constante = [valor_constante; repmat(altura, intervalo_fin - intervalo_inicio + 1, 1)];

                % Actualizar el inicio del siguiente intervalo
                intervalo_inicio = intervalo_fin + 1;
            end



        end

        function datosBuses = aceleracionPorCuadrosMaximosRutas(datosBuses)
            datosBuses = Calcular.iterarSobreBusesYFechas(datosBuses, @Calcular.aceleracionPorCuadrosMaximosWraper);
        end
        function datosBuses = aceleracionPorCuadrosMaximosWraper(datosBuses, k)
            print("Holas")
        end

        function datosBuses = aceleracionPorCuadrosPromedio(datosBuses)
            datosBuses = Calcular.iterarSobreBusesYFechas(datosBuses, @Calcular.calcularKilometroRutasWrapper);
        end

        function datosBuses = llenarIndicadoresAceleracion(datosBuses)
            % Obtener los nombres de los buses
            busesNames = fieldnames(datosBuses);

            % Recorrer cada bus en la estructura datosBuses
            for i = 1:length(busesNames)
                busName = busesNames{i};  % Nombre del bus actual
                busData = datosBuses.(busName);  % Acceder a los datos del bus actual

                % Obtener los nombres de los subcampos dentro de cada bus (por ejemplo: f_03_07_2024)
                subfields = fieldnames(busData);  % Subcampos dentro del bus

                % Recorrer los subcampos
                for j = 1:length(subfields)
                    subfieldName = subfields{j};  % Nombre del subcampo
                    try
                        datosSensorRuta = datosBuses.(busName).(subfieldName).datosSensorRuta;  % Acceder a datosSensorRuta
                        numFilas = size(datosSensorRuta, 1);  % Asume que tiene filas como una tabla o matriz

                        for f = 1:numFilas
                            try
                                % Para la ida
                                % datosBuses.(BusName).(subfieldName).tiempoRuta.Ruta{f}
                                tiempoIda=datosSensorRuta{f,2}.time(3:end);
                                AccIda=datosBuses.(busName).(subfieldName).aceleracionRuta{f,2};
                                datos = table(tiempoIda, AccIda  , 'VariableNames', {'Tiempo', 'Acc'});
                                [magnitudes_positivas, magnitudes_negativas, tiempos_positivos, tiempos_negativos]=Calculos.aceleracionPorCuadrosMx(datos);
                                datosBuses.(busName).(subfieldName).tiempoRuta.aceleracionesKMIda{f}=mean(magnitudes_positivas);
                                datosBuses.(busName).(subfieldName).tiempoRuta.frenadasKMIda{f}=mean(magnitudes_negativas);
                                datosBuses.(busName).(subfieldName).tiempoRuta.cantidad_frenadasIda{f}=length(magnitudes_negativas)/datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Ida(f);
                                datosBuses.(busName).(subfieldName).tiempoRuta.cantidad_aceleracionesIda{f}=length(magnitudes_positivas)/datosBuses.(busName).(subfieldName).tiempoRuta.Kilometros_Ida(f);
                                datosBuses.(busName).(subfieldName).tiempoRuta.tiempos_positivosIda{f}=mean(seconds(tiempos_positivos));
                                datosBuses.(busName).(subfieldName).tiempoRuta.tiempos_negativosIda{f}=mean(seconds(tiempos_negativos));
                            catch
                                fprintf('Error procesando la ida para el bus %s en el subcampo %s, fila %d.\n', busName, subfieldName, f);
                            end

                        end
                    catch
                        fprintf('Error procesando el subcampo %s del bus %s.\n', subfieldName, busName);
                    end
                end
            end
        end



    end
end
