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


%% KNN

function clasificarSexoYGraficar(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];
    labels = [];

    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};
            generalTable = Rutas.(ruta).(trayecto).General;

            % Recorrer cada fila de la tabla General
            for k = 1:height(generalTable)
                % Calcular el promedio de riesgoCurva
                riesgo_curva = generalTable.riesgoCurva{k};
                if iscell(riesgo_curva)
                    promedio_riesgo_curva = mean(cell2mat(riesgo_curva));
                else
                    promedio_riesgo_curva = mean(riesgo_curva);
                end

                % Calcular el promedio de PorcentajesConsumo
                porcentajes_consumo = generalTable.PorcentajesConsumo{k};
                if iscell(porcentajes_consumo)
                    promedio_consumo = mean(cell2mat(porcentajes_consumo));
                else
                    promedio_consumo = mean(porcentajes_consumo);
                end

                % Calcular el promedio de PorcentajesVelocidad
                porcentajes_velocidad = generalTable.PorcentajesVelocidad{k};
                if iscell(porcentajes_velocidad)
                    promedio_velocidad = mean(cell2mat(porcentajes_velocidad));
                else
                    promedio_velocidad = mean(porcentajes_velocidad);
                end

                % Extraer datos de aceleración calculados previamente
                num_aceleraciones_por_km = generalTable.NumAceleracionesPorKm(k);
                num_desaceleraciones_por_km = generalTable.NumDesaceleracionesPorKm(k);
                aceleracion_promedio = generalTable.AceleracionPromedio(k);
                desaceleracion_promedio = generalTable.DesaceleracionPromedio(k);

                % Crear una fila con todas las características
                fila = [
                    promedio_consumo, ...
                    promedio_velocidad, ...
                    num_aceleraciones_por_km, ...
                    num_desaceleraciones_por_km, ...
                    aceleracion_promedio, ...
                    desaceleracion_promedio, ...
                    promedio_riesgo_curva
                ];

                % Añadir la fila a la lista de datos
                datos = [datos; fila];

                % Añadir la etiqueta (sexo)
                labels = [labels; generalTable.Sexo(k)];
            end
        end
    end

    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];
    labels(any(isnan(labels), 2)) = [];
    labels(any(isinf(labels), 2)) = [];

    % Normalizar los datos
    datos_normalizados = zscore(datos);

    % Aplicar PCA
    [coeff, score, latent, ~, explained] = pca(datos_normalizados);

    % Determinar cuántos componentes principales retener (por ejemplo, 90% de varianza explicada)
    cumulative_variance = cumsum(explained);
    num_components = find(cumulative_variance >= 90, 1);

    % Proyectar los datos en el espacio de los componentes principales retenidos
    if isempty(num_components)
        error('No se pueden retener componentes principales. Verifique los datos de entrada.');
    end
    datos_pca_reducidos = score(:, 1:num_components);

    % Dividir en 70% entrenamiento y 30% prueba
    cv = cvpartition(size(datos_pca_reducidos, 1), 'HoldOut', 0.3);
    idx = cv.test;

    % Crear conjuntos de entrenamiento y prueba
    X_train = datos_pca_reducidos(~idx, :);
    X_test = datos_pca_reducidos(idx, :);
    y_train = labels(~idx);
    y_test = labels(idx);

    % Entrenar el modelo KNN
    Mdl = fitcknn(X_train, y_train, 'NumNeighbors', 5);

    % Hacer predicciones en el conjunto de prueba
    y_pred = predict(Mdl, X_test);

    % Evaluar el rendimiento del modelo
    accuracy = sum(y_pred == y_test) / numel(y_test);
    disp(['Precisión del modelo KNN: ', num2str(accuracy * 100), '%']);

    % Visualización de los resultados
    figure;
    gscatter(X_test(:, 1), X_test(:, 2), y_pred, 'rb', 'xo');
    title('Clasificación KNN en el Espacio de los Componentes Principales');
    xlabel('Componente Principal 1');
    ylabel('Componente Principal 2');
    legend('Hombre', 'Mujer');

    % Gráfico de Varianza Explicada por los Componentes Principales
    figure;
    plot(cumulative_variance, 'o-');
    title('Varianza Acumulada Explicada por los Componentes Principales');
    xlabel('Número de Componentes Principales');
    ylabel('Varianza Explicada Acumulada (%)');
    grid on;

    % Gráfico de Dispersión 3D (si se retienen tres componentes principales)
    if num_components >= 3
        % Convertir las etiquetas a colores para el conjunto de prueba
        colores_test = zeros(length(y_test), 3);
        colores_test(y_test == 0, :) = repmat([1, 0, 0], sum(y_test == 0), 1); % Rojo para hombres
        colores_test(y_test == 1, :) = repmat([0, 0, 1], sum(y_test == 1), 1); % Azul para mujeres

        figure;
        scatter3(X_test(:, 1), X_test(:, 2), X_test(:, 3), 10, colores_test, 'filled');
        title('Datos en el Espacio de los Tres Primeros Componentes Principales');
        xlabel('Componente Principal 1');
        ylabel('Componente Principal 2');
        zlabel('Componente Principal 3');
        legend('Hombre', 'Mujer');
    end

    % Matriz de Confusión
    figure;
    cm = confusionchart(y_test, y_pred);
    cm.Title = 'Matriz de Confusión para la Clasificación KNN';
    cm.RowSummary = 'row-normalized';
    cm.ColumnSummary = 'column-normalized';

    % Gráfico de Barras para Promedio de Características por Clúster
    figure;
    cluster_means = [];
    for c = 0:1 % Asumiendo dos clusters: hombres (0) y mujeres (1)
        cluster_means = [cluster_means; mean(X_train(y_train == c, :))];
    end
    bar(cluster_means');
    title('Promedio de Características por Clúster');
    xlabel('Características');
    ylabel('Valor Promedio');
    legend('Hombre', 'Mujer');
    grid on;
end


clasificarSexoYGraficar(Rutas)


%% KNN sin pca

function clasificarSexoSinPCA(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];
    labels = [];

    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};
            generalTable = Rutas.(ruta).(trayecto).General;

            % Recorrer cada fila de la tabla General
            for k = 1:height(generalTable)
                % Calcular el promedio de riesgoCurva
                riesgo_curva = generalTable.riesgoCurva{k};
                if iscell(riesgo_curva)
                    promedio_riesgo_curva = mean(cell2mat(riesgo_curva));
                else
                    promedio_riesgo_curva = mean(riesgo_curva);
                end

                % Calcular el promedio de PorcentajesConsumo
                porcentajes_consumo = generalTable.PorcentajesConsumo{k};
                if iscell(porcentajes_consumo)
                    promedio_consumo = mean(cell2mat(porcentajes_consumo));
                else
                    promedio_consumo = mean(porcentajes_consumo);
                end

                % Calcular el promedio de PorcentajesVelocidad
                porcentajes_velocidad = generalTable.PorcentajesVelocidad{k};
                if iscell(porcentajes_velocidad)
                    promedio_velocidad = mean(cell2mat(porcentajes_velocidad));
                else
                    promedio_velocidad = mean(porcentajes_velocidad);
                end

                % Extraer datos de aceleración calculados previamente
                num_aceleraciones_por_km = generalTable.NumAceleracionesPorKm(k);
                num_desaceleraciones_por_km = generalTable.NumDesaceleracionesPorKm(k);
                aceleracion_promedio = generalTable.AceleracionPromedio(k);
                desaceleracion_promedio = generalTable.DesaceleracionPromedio(k);

                % Crear una fila con todas las características
                fila = [
                    promedio_consumo, ...
                    promedio_velocidad, ...
                    num_aceleraciones_por_km, ...
                    num_desaceleraciones_por_km, ...
                    aceleracion_promedio, ...
                    desaceleracion_promedio, ...
                    promedio_riesgo_curva
                ];

                % Añadir la fila a la lista de datos
                datos = [datos; fila];

                % Añadir la etiqueta (sexo)
                labels = [labels; generalTable.Sexo(k)];
            end
        end
    end

    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];
    labels(any(isnan(labels), 2)) = [];
    labels(any(isinf(labels), 2)) = [];

    % Normalizar los datos
    datos_normalizados = zscore(datos);

    % Dividir en 70% entrenamiento y 30% prueba
    cv = cvpartition(size(datos_normalizados, 1), 'HoldOut', 0.3);
    idx = cv.test;

    % Crear conjuntos de entrenamiento y prueba
    X_train = datos_normalizados(~idx, :);
    X_test = datos_normalizados(idx, :);
    y_train = labels(~idx);
    y_test = labels(idx);

    % Entrenar el modelo KNN
    Mdl = fitcknn(X_train, y_train, 'NumNeighbors', 5);

    % Hacer predicciones en el conjunto de prueba
    y_pred = predict(Mdl, X_test);

    % Evaluar el rendimiento del modelo
    accuracy = sum(y_pred == y_test) / numel(y_test);
    disp(['Precisión del modelo KNN: ', num2str(accuracy * 100), '%']);

    % Visualización de los resultados
    figure;
    gscatter(X_test(:, 1), X_test(:, 2), y_pred, 'rb', 'xo');
    title('Clasificación KNN sin PCA');
    xlabel('Característica 1');
    ylabel('Característica 2');
    legend('Hombre', 'Mujer');

    % Matriz de Confusión
    figure;
    cm = confusionchart(y_test, y_pred);
    cm.Title = 'Matriz de Confusión para la Clasificación KNN sin PCA';
    cm.RowSummary = 'row-normalized';
    cm.ColumnSummary = 'column-normalized';

    % Gráfico de Barras para Promedio de Características por Clúster
    figure;
    cluster_means = [];
    for c = 0:1 % Asumiendo dos clusters: hombres (0) y mujeres (1)
        cluster_means = [cluster_means; mean(X_train(y_train == c, :))];
    end
    bar(cluster_means');
    title('Promedio de Características por Clúster sin PCA');
    xlabel('Características');
    ylabel('Valor Promedio');
    legend('Hombre', 'Mujer');
    grid on;
end

clasificarSexoSinPCA(Rutas);

%% Grafica general de aceleraciones

function graficarAceleracionesPorConductor(Rutas)
    % Inicializar listas para almacenar los datos
    aceleracion_promedio_positiva = [];
    aceleracion_promedio_negativa = [];
    num_aceleraciones_por_km = [];
    num_desaceleraciones_por_km = [];
    sexos = [];

    % Recorrer todas las rutas y trayectos
    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};
            generalTable = Rutas.(ruta).(trayecto).General;

            % Verificar si la tabla general está vacía, si es así, continuar
            if isempty(generalTable)
                continue;
            end

            % Recoger los datos de cada conductor
            for k = 1:height(generalTable)
                aceleracion_promedio_positiva = [aceleracion_promedio_positiva; generalTable.AceleracionPromedio(k)];
                aceleracion_promedio_negativa = [aceleracion_promedio_negativa; generalTable.DesaceleracionPromedio(k)];
                num_aceleraciones_por_km = [num_aceleraciones_por_km; generalTable.NumAceleracionesPorKm(k)];
                num_desaceleraciones_por_km = [num_desaceleraciones_por_km; generalTable.NumDesaceleracionesPorKm(k)];
                sexos = [sexos; generalTable.Sexo(k)];
            end
        end
    end

    % Graficar los datos
    figure;

    % Graficar aceleraciones positivas y negativas en la misma gráfica
    hold on;
    scatter(num_aceleraciones_por_km(sexos == 0), aceleracion_promedio_positiva(sexos == 0), 'r', 'DisplayName', 'Aceleraciones Hombres');
    scatter(num_aceleraciones_por_km(sexos == 1), aceleracion_promedio_positiva(sexos == 1), 'b', 'DisplayName', 'Aceleraciones Mujeres');
    scatter(num_desaceleraciones_por_km(sexos == 0), aceleracion_promedio_negativa(sexos == 0), 'ro', 'DisplayName', 'Desaceleraciones Hombres');
    scatter(num_desaceleraciones_por_km(sexos == 1), aceleracion_promedio_negativa(sexos == 1), 'bo', 'DisplayName', 'Desaceleraciones Mujeres');
    title('Aceleraciones y Desaceleraciones por Kilómetro');
    xlabel('Número de Aceleraciones/Desaceleraciones por Km');
    ylabel('Aceleración/Desaceleración Promedio');
    legend;
    hold off;

    % Calcular los promedios para cada grupo
    promedio_aceleracion_hombres = mean(aceleracion_promedio_positiva(sexos == 0));
    promedio_aceleracion_mujeres = mean(aceleracion_promedio_positiva(sexos == 1));
    promedio_desaceleracion_hombres = mean(aceleracion_promedio_negativa(sexos == 0));
    promedio_desaceleracion_mujeres = mean(aceleracion_promedio_negativa(sexos == 1));
    promedio_num_aceleraciones_hombres = mean(num_aceleraciones_por_km(sexos == 0));
    promedio_num_aceleraciones_mujeres = mean(num_aceleraciones_por_km(sexos == 1));
    promedio_num_desaceleraciones_hombres = mean(num_desaceleraciones_por_km(sexos == 0));
    promedio_num_desaceleraciones_mujeres = mean(num_desaceleraciones_por_km(sexos == 1));

    % Mostrar los promedios
    fprintf('Promedio Aceleración Hombres: %.2f\n', promedio_aceleracion_hombres);
    fprintf('Promedio Aceleración Mujeres: %.2f\n', promedio_aceleracion_mujeres);
    fprintf('Promedio Desaceleración Hombres: %.2f\n', promedio_desaceleracion_hombres);
    fprintf('Promedio Desaceleración Mujeres: %.2f\n', promedio_desaceleracion_mujeres);
    fprintf('Promedio Número de Aceleraciones por Km Hombres: %.2f\n', promedio_num_aceleraciones_hombres);
    fprintf('Promedio Número de Aceleraciones por Km Mujeres: %.2f\n', promedio_num_aceleraciones_mujeres);
    fprintf('Promedio Número de Desaceleraciones por Km Hombres: %.2f\n', promedio_num_desaceleraciones_hombres);
    fprintf('Promedio Número de Desaceleraciones por Km Mujeres: %.2f\n', promedio_num_desaceleraciones_mujeres);
end

% Llamar a la función con la estructura Rutas
graficarAceleracionesPorConductor(Rutas);




%% Kmeans

datos_pca = prepararDatosPCA(Rutas);


% Verificar y limpiar datos para asegurarse de que no haya NaN o inf
datos_pca(any(isnan(datos_pca), 2), :) = [];
datos_pca(any(isinf(datos_pca), 2), :) = [];



% Normalizar los datos si es necesario
datos_normalizados = zscore(datos_pca);

% Aplicar PCA
[coeff, score, latent, ~, explained] = pca(datos_normalizados);

% Determinar cuántos componentes principales retener (por ejemplo, 90% de varianza explicada)
cumulative_variance = cumsum(explained);
num_components = find(cumulative_variance >= 50, 1);

% Proyectar los datos en el espacio de los componentes principales retenidos
datos_pca_reducidos = score(:, 1:num_components);


% Definir el número de clusters deseado
num_clusters = 3;

% Aplicar K-means clustering
[idx, centroids] = kmeans(datos_pca_reducidos, num_clusters);

% Visualización de los clusters en el espacio de los dos primeros componentes principales
figure;
scatter(datos_pca_reducidos(:, 1), datos_pca_reducidos(:, 2), 10, idx, 'filled');
title('Clustering después de PCA');
xlabel('Componente Principal 1');
ylabel('Componente Principal 2');
legend(num2str((1:num_clusters)'));


%%

function clasificarKMeansSinPCA(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];
    labels = [];

    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};
            generalTable = Rutas.(ruta).(trayecto).General;

            % Recorrer cada fila de la tabla General
            for k = 1:height(generalTable)
                % Calcular el promedio de riesgoCurva
                riesgo_curva = generalTable.riesgoCurva{k};
                if iscell(riesgo_curva)
                    promedio_riesgo_curva = mean(cell2mat(riesgo_curva));
                else
                    promedio_riesgo_curva = mean(riesgo_curva);
                end

                % Calcular el promedio de PorcentajesConsumo
                porcentajes_consumo = generalTable.PorcentajesConsumo{k};
                if iscell(porcentajes_consumo)
                    promedio_consumo = mean(cell2mat(porcentajes_consumo));
                else
                    promedio_consumo = mean(porcentajes_consumo);
                end

                % Calcular el promedio de PorcentajesVelocidad
                porcentajes_velocidad = generalTable.PorcentajesVelocidad{k};
                if iscell(porcentajes_velocidad)
                    promedio_velocidad = mean(cell2mat(porcentajes_velocidad));
                else
                    promedio_velocidad = mean(porcentajes_velocidad);
                end

                % Extraer datos de aceleración calculados previamente
                num_aceleraciones_por_km = generalTable.NumAceleracionesPorKm(k);
                num_desaceleraciones_por_km = generalTable.NumDesaceleracionesPorKm(k);
                aceleracion_promedio = generalTable.AceleracionPromedio(k);
                desaceleracion_promedio = generalTable.DesaceleracionPromedio(k);

                % Crear una fila con todas las características
                fila = [
                    promedio_consumo, ...
                    promedio_velocidad, ...
                    num_aceleraciones_por_km, ...
                    num_desaceleraciones_por_km, ...
                    aceleracion_promedio, ...
                    desaceleracion_promedio, ...
                    promedio_riesgo_curva
                ];

                % Añadir la fila a la lista de datos
                datos = [datos; fila];

                % Añadir la etiqueta (sexo)
                labels = [labels; generalTable.Sexo(k)];
            end
        end
    end

    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];

    % Normalizar los datos si es necesario
    datos_normalizados = zscore(datos);

    % Definir el número de clusters deseado
    num_clusters = 2;

    % Aplicar K-means clustering
    [idx, centroids] = kmeans(datos_normalizados, num_clusters);

    % Visualización de los clusters en el espacio de los dos primeros componentes principales
    figure;
    scatter(datos_normalizados(:, 1), datos_normalizados(:, 2), 10, idx, 'filled');
    title('Clustering con K-means sin PCA');
    xlabel('Característica 1');
    ylabel('Característica 2');
    legend(num2str((1:num_clusters)'));

    % Visualización 3D de los clusters si hay al menos 3 componentes
    if size(datos_normalizados, 2) >= 3
        figure;
        scatter3(datos_normalizados(:, 1), datos_normalizados(:, 2), datos_normalizados(:, 3), 10, idx, 'filled');
        title('Clustering con K-means sin PCA (3D)');
        xlabel('Característica 1');
        ylabel('Característica 2');
        zlabel('Característica 3');
        legend(num2str((1:num_clusters)'));
    end

    % Gráfico de Barras para Promedio de Características por Clúster
    figure;
    cluster_means = [];
    for c = 1:num_clusters
        cluster_means = [cluster_means; mean(datos_normalizados(idx == c, :))];
    end
    bar(cluster_means');
    title('Promedio de Características por Clúster sin PCA');
    xlabel('Características');
    ylabel('Valor Promedio');
    legend(num2str((1:num_clusters)'));
    grid on;
end


clasificarKMeansSinPCA(Rutas);


%% PCA preparacion

function datos_pca = prepararDatosPCA(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];

    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};
            generalTable = Rutas.(ruta).(trayecto).General;

            % Recorrer cada fila de la tabla General
            for k = 1:height(generalTable)
                % Calcular el promedio de riesgoCurva
                riesgo_curva = generalTable.riesgoCurva{k};
                if iscell(riesgo_curva)
                    promedio_riesgo_curva = mean(cell2mat(riesgo_curva));
                else
                    promedio_riesgo_curva = mean(riesgo_curva);
                end

                % Calcular el promedio de PorcentajesConsumo
                porcentajes_consumo = generalTable.PorcentajesConsumo{k};
                if iscell(porcentajes_consumo)
                    promedio_consumo = mean(cell2mat(porcentajes_consumo));
                else
                    promedio_consumo = mean(porcentajes_consumo);
                end

                % Calcular el promedio de PorcentajesVelocidad
                porcentajes_velocidad = generalTable.PorcentajesVelocidad{k};
                if iscell(porcentajes_velocidad)
                    promedio_velocidad = mean(cell2mat(porcentajes_velocidad));
                else
                    promedio_velocidad = mean(porcentajes_velocidad);
                end

                % Extraer datos de aceleración calculados previamente
                num_aceleraciones_por_km = generalTable.NumAceleracionesPorKm(k);
                num_desaceleraciones_por_km = generalTable.NumDesaceleracionesPorKm(k);
                aceleracion_promedio = generalTable.AceleracionPromedio(k);
                desaceleracion_promedio = generalTable.DesaceleracionPromedio(k);

                % Crear una fila con todas las características
                fila = [
                    promedio_consumo, ...
                    promedio_velocidad, ...
                    num_aceleraciones_por_km, ...
                    num_desaceleraciones_por_km, ...
                    aceleracion_promedio, ...
                    desaceleracion_promedio, ...
                    promedio_riesgo_curva
                ];

                % Añadir la fila a la lista de datos
                datos = [datos; fila];
            end
        end
    end

    % Convertir la lista de datos en una matriz
    datos_pca = (datos);
end


%%

function clasificarKMeansSinPCAComparar(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];
    labels = [];
    
    % Definir nombres de características
    nombres_caracteristicas = {
        'Promedio Consumo', ...
        'Promedio Velocidad', ...
        'Aceleraciones por Km', ...
        'Desaceleraciones por Km', ...
        'Aceleración Promedio', ...
        'Desaceleración Promedio', ...
        'Riesgo Curva Promedio'
    };

    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};
            generalTable = Rutas.(ruta).(trayecto).General;

            % Recorrer cada fila de la tabla General
            for k = 1:height(generalTable)
                % Calcular el promedio de riesgoCurva
                riesgo_curva = generalTable.riesgoCurva{k};
                if iscell(riesgo_curva)
                    promedio_riesgo_curva = mean(cell2mat(riesgo_curva));
                else
                    promedio_riesgo_curva = mean(riesgo_curva);
                end

                % Calcular el promedio de PorcentajesConsumo
                porcentajes_consumo = generalTable.PorcentajesConsumo{k};
                if iscell(porcentajes_consumo)
                    promedio_consumo = mean(cell2mat(porcentajes_consumo));
                else
                    promedio_consumo = mean(porcentajes_consumo);
                end

                % Calcular el promedio de PorcentajesVelocidad
                porcentajes_velocidad = generalTable.PorcentajesVelocidad{k};
                if iscell(porcentajes_velocidad)
                    promedio_velocidad = mean(cell2mat(porcentajes_velocidad));
                else
                    promedio_velocidad = mean(porcentajes_velocidad);
                end

                % Extraer datos de aceleración calculados previamente
                num_aceleraciones_por_km = generalTable.NumAceleracionesPorKm(k);
                num_desaceleraciones_por_km = generalTable.NumDesaceleracionesPorKm(k);
                aceleracion_promedio = generalTable.AceleracionPromedio(k);
                desaceleracion_promedio = generalTable.DesaceleracionPromedio(k);

                % Crear una fila con todas las características
                fila = [
                    promedio_consumo, ...
                    promedio_velocidad, ...
                    num_aceleraciones_por_km, ...
                    num_desaceleraciones_por_km, ...
                    aceleracion_promedio, ...
                    desaceleracion_promedio, ...
                    promedio_riesgo_curva
                ];

                % Añadir la fila a la lista de datos
                datos = [datos; fila];

                % Añadir la etiqueta (sexo)
                labels = [labels; generalTable.Sexo(k)];
            end
        end
    end

    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];
    labels(any(isnan(labels), 2)) = [];
    labels(any(isinf(labels), 2)) = [];

    % Normalizar los datos si es necesario
    datos_normalizados = zscore(datos);

    % Definir el número de clusters deseado
    num_clusters = 2; % Asumimos dos clusters para hombres y mujeres

    % Aplicar K-means clustering
    [idx, centroids] = kmeans(datos_normalizados, num_clusters);

    % Comparar con las etiquetas verdaderas
    % Etiquetas predichas (idx) pueden no coincidir directamente con 0 y 1, así que debemos mapearlas
    % Suponemos que los clusters pueden ser 0/1 o 1/0 para hombres/mujeres

    % Inicializar las etiquetas predichas
    pred_labels = zeros(size(labels));

    % Calcular el mapeo correcto de los clusters a las etiquetas
    if mean(labels(idx == 1)) < 0.5
        % Cluster 1 corresponde a hombres (0), Cluster 2 corresponde a mujeres (1)
        pred_labels(idx == 1) = 0;
        pred_labels(idx == 2) = 1;
    else
        % Cluster 1 corresponde a mujeres (1), Cluster 2 corresponde a hombres (0)
        pred_labels(idx == 1) = 1;
        pred_labels(idx == 2) = 0;
    end

    % Matriz de Confusión
    figure;
    cm = confusionchart(labels, pred_labels);
    cm.Title = 'Matriz de Confusión para la Clasificación K-means';
    cm.RowSummary = 'row-normalized';
    cm.ColumnSummary = 'column-normalized';

    % Calcular precisión, sensibilidad y especificidad
    TP = sum((pred_labels == 1) & (labels == 1));
    TN = sum((pred_labels == 0) & (labels == 0));
    FP = sum((pred_labels == 1) & (labels == 0));
    FN = sum((pred_labels == 0) & (labels == 1));

    precision = TP / (TP + FP);
    sensibilidad = TP / (TP + FN); % También conocida como recall
    especificidad = TN / (TN + FP);

    % Mostrar las métricas
    fprintf('Precisión: %.2f%%\n', precision * 100);
    fprintf('Sensibilidad: %.2f%%\n', sensibilidad * 100);
    fprintf('Especificidad: %.2f%%\n', especificidad * 100);

    % Visualización de los clusters en el espacio de las dos primeras características
    figure;
    gscatter(datos_normalizados(:, 1), datos_normalizados(:, 2), idx, 'br', 'xo');
    title('Clustering con K-means sin PCA');
    xlabel(nombres_caracteristicas{1});
    ylabel(nombres_caracteristicas{2});
    legend('Cluster 1', 'Cluster 2');

    % Visualización 3D de los clusters si hay al menos 3 características
    if size(datos_normalizados, 2) >= 3
        figure;
        scatter3(datos_normalizados(:, 1), datos_normalizados(:, 2), datos_normalizados(:, 3), 10, idx, 'filled');
        title('Clustering con K-means sin PCA (3D)');
        xlabel(nombres_caracteristicas{1});
        ylabel(nombres_caracteristicas{2});
        zlabel(nombres_caracteristicas{3});
        legend('Cluster 1', 'Cluster 2');
    end

    % Gráfico de Barras para Promedio de Características por Clúster
    figure;
    cluster_means = [];
    for c = 1:num_clusters
        if sum(idx == c) > 0 % Asegurarse de que el cluster no esté vacío
            cluster_means = [cluster_means; mean(datos_normalizados(idx == c, :), 1)];
        else
            cluster_means = [cluster_means; zeros(1, size(datos_normalizados, 2))]; % Añadir fila de ceros si el cluster está vacío
        end
    end
    bar(cluster_means');
    title('Promedio de Características por Clúster sin PCA');
    xlabel('Características');
    ylabel('Valor Promedio');
    xticklabels(nombres_caracteristicas);
    legend('Cluster 1', 'Cluster 2');
    grid on;
end

% Llamar a la función con la estructura Rutas
clasificarKMeansSinPCAComparar(Rutas);

%%

function clasificarKMeansHoraPico(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];
    labels = [];
    
    % Definir nombres de características
    nombres_caracteristicas = {
        'Promedio Consumo', ...
        'Promedio Velocidad', ...
        'Aceleraciones por Km', ...
        'Desaceleraciones por Km', ...
        'Aceleración Promedio', ...
        'Desaceleración Promedio', ...
        'Riesgo Curva Promedio'
    };

    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};
            horaPicoTable = Rutas.(ruta).(trayecto).horaPico;

            % Recorrer cada fila de la tabla horaPico
            for k = 1:height(horaPicoTable)
                % Calcular el promedio de riesgoCurva
                riesgo_curva = horaPicoTable.riesgoCurva{k};
                if iscell(riesgo_curva)
                    promedio_riesgo_curva = mean(cell2mat(riesgo_curva));
                else
                    promedio_riesgo_curva = mean(riesgo_curva);
                end

                % Calcular el promedio de PorcentajesConsumo
                porcentajes_consumo = horaPicoTable.PorcentajesConsumo{k};
                if iscell(porcentajes_consumo)
                    promedio_consumo = mean(cell2mat(porcentajes_consumo));
                else
                    promedio_consumo = mean(porcentajes_consumo);
                end

                % Calcular el promedio de PorcentajesVelocidad
                porcentajes_velocidad = horaPicoTable.PorcentajesVelocidad{k};
                if iscell(porcentajes_velocidad)
                    promedio_velocidad = mean(cell2mat(porcentajes_velocidad));
                else
                    promedio_velocidad = mean(porcentajes_velocidad);
                end

                % Extraer datos de aceleración calculados previamente
                num_aceleraciones_por_km = horaPicoTable.NumAceleracionesPorKm(k);
                num_desaceleraciones_por_km = horaPicoTable.NumDesaceleracionesPorKm(k);
                aceleracion_promedio = horaPicoTable.AceleracionPromedio(k);
                desaceleracion_promedio = horaPicoTable.DesaceleracionPromedio(k);

                % Crear una fila con todas las características
                fila = [
                    promedio_consumo, ...
                    promedio_velocidad, ...
                    num_aceleraciones_por_km, ...
                    num_desaceleraciones_por_km, ...
                    aceleracion_promedio, ...
                    desaceleracion_promedio, ...
                    promedio_riesgo_curva
                ];

                % Añadir la fila a la lista de datos
                datos = [datos; fila];

                % Añadir la etiqueta (sexo)
                labels = [labels; horaPicoTable.Sexo(k)];
            end
        end
    end

    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];
    labels(any(isnan(labels), 2)) = [];
    labels(any(isinf(labels), 2)) = [];

    % Normalizar los datos si es necesario
    datos_normalizados = zscore(datos);

    % Definir el número de clusters deseado
    num_clusters = 2; % Asumimos dos clusters para hombres y mujeres

    % Aplicar K-means clustering
    [idx, centroids] = kmeans(datos_normalizados, num_clusters);

    % Comparar con las etiquetas verdaderas
    % Etiquetas predichas (idx) pueden no coincidir directamente con 0 y 1, así que debemos mapearlas
    % Suponemos que los clusters pueden ser 0/1 o 1/0 para hombres/mujeres

    % Inicializar las etiquetas predichas
    pred_labels = zeros(size(labels));

    % Calcular el mapeo correcto de los clusters a las etiquetas
    if mean(labels(idx == 1)) < 0.5
        % Cluster 1 corresponde a hombres (0), Cluster 2 corresponde a mujeres (1)
        pred_labels(idx == 1) = 0;
        pred_labels(idx == 2) = 1;
    else
        % Cluster 1 corresponde a mujeres (1), Cluster 2 corresponde a hombres (0)
        pred_labels(idx == 1) = 1;
        pred_labels(idx == 2) = 0;
    end

    % Matriz de Confusión
    figure;
    cm = confusionchart(labels, pred_labels);
    cm.Title = 'Matriz de Confusión para la Clasificación K-means (Hora Pico)';
    cm.RowSummary = 'row-normalized';
    cm.ColumnSummary = 'column-normalized';

    % Calcular precisión, sensibilidad y especificidad
    TP = sum((pred_labels == 1) & (labels == 1));
    TN = sum((pred_labels == 0) & (labels == 0));
    FP = sum((pred_labels == 1) & (labels == 0));
    FN = sum((pred_labels == 0) & (labels == 1));

    precision = TP / (TP + FP);
    sensibilidad = TP / (TP + FN); % También conocida como recall
    especificidad = TN / (TN + FP);

    % Mostrar las métricas
    fprintf('Precisión: %.2f%%\n', precision * 100);
    fprintf('Sensibilidad: %.2f%%\n', sensibilidad * 100);
    fprintf('Especificidad: %.2f%%\n', especificidad * 100);

    % Visualización de los clusters en el espacio de las dos primeras características
    figure;
    gscatter(datos_normalizados(:, 1), datos_normalizados(:, 2), idx, 'br', 'xo');
    title('Clustering con K-means sin PCA (Hora Pico)');
    xlabel(nombres_caracteristicas{1});
    ylabel(nombres_caracteristicas{2});
    legend('Cluster 1', 'Cluster 2');

    % Visualización 3D de los clusters si hay al menos 3 características
    if size(datos_normalizados, 2) >= 3
        figure;
        scatter3(datos_normalizados(:, 1), datos_normalizados(:, 2), datos_normalizados(:, 3), 10, idx, 'filled');
        title('Clustering con K-means sin PCA (Hora Pico, 3D)');
        xlabel(nombres_caracteristicas{1});
        ylabel(nombres_caracteristicas{2});
        zlabel(nombres_caracteristicas{3});
        legend('Cluster 1', 'Cluster 2');
    end

    % Gráfico de Barras para Promedio de Características por Clúster
    figure;
    cluster_means = [];
    for c = 1:num_clusters
        if sum(idx == c) > 0 % Asegurarse de que el cluster no esté vacío
            cluster_means = [cluster_means; mean(datos_normalizados(idx == c, :), 1)];
        else
            cluster_means = [cluster_means; zeros(1, size(datos_normalizados, 2))]; % Añadir fila de ceros si el cluster está vacío
        end
    end
    bar(cluster_means');
    title('Promedio de Características por Clúster sin PCA (Hora Pico)');
    xlabel('Características');
    ylabel('Valor Promedio');
    xticklabels(nombres_caracteristicas);
    legend('Cluster 1', 'Cluster 2');
    grid on;
end

% Llamar a la función con la estructura Rutas
clasificarKMeansHoraPico(Rutas);


%% pruebas knn


% Picos de aceleración y su frecuencia (datos de ejemplo)
picos_aceleracion = [2.5, 3; 2.0, 4; 3.0, 2; 2.8, 5; 2.2, 3];

% Vectores de velocidad para cada conductor (datos de ejemplo)
velocidades_conductores = {
    [60, 65, 70, 75, 80];
    [55, 60, 63, 65];
    [70, 72, 75, 78, 80, 82];
    [65, 68, 70, 72, 75];
    [58, 60, 62, 64, 66]
};

% Calcular estadísticas resumen para cada conductor
num_conductores = numel(velocidades_conductores);
estadisticas_velocidad = zeros(num_conductores, 4); % matriz para almacenar [media, std, max, min]

for i = 1:num_conductores
    velocidades = velocidades_conductores{i};
    estadisticas_velocidad(i, 1) = mean(velocidades);
    estadisticas_velocidad(i, 2) = std(velocidades);
    estadisticas_velocidad(i, 3) = max(velocidades);
    estadisticas_velocidad(i, 4) = min(velocidades);
end

% Combinar datos en una sola matriz
datos = [picos_aceleracion, estadisticas_velocidad];


% Normalizar los datos si es necesario
datos_normalizados = zscore(datos);

% Aplicar PCA
[coeff, score, latent, ~, explained] = pca(datos_normalizados);

% Coeficientes de carga (vectores propios)
coeficientes_carga = coeff;

% Puntajes (nuevas coordenadas)
nuevas_coordenadas = score;

% Varianza explicada por cada componente principal
varianza_explicada = explained;

% Mostrar los resultados
disp('Varianza explicada por cada componente principal:');
disp(varianza_explicada);
disp('Componentes principales:');
disp(nuevas_coordenadas);


%% KNN

% X es una matriz donde cada fila es una observación y cada columna una característica
% Y es un vector de etiquetas de clase correspondientes a cada observación
%se dividen los datos en xtrain ytrain, xtest ytest 

%yo opino que como hay pocos hombres hacerlo con 80-20

%la funcion para el knn es, "fitcknn"
numNeighbors = 5;%vecinos  
nuestroKnn=fitcknn(XTrain, YTrain, 'NumNeighbors', numNeighbors);
%ahi ya esa vaina ya se entrena entonces ahora

prediccion=predict(knnModel, XTest);

%ya ahi predice pero ahora pa evaluar el modelo dice que hay algo que se
%llama matriz de confusión
confusionMat = confusionmat(YTest, YPred);

%y pa la precision se usa como un promedio 
accuracy = sum(diag(confusionMat)) / sum(confusionMat(:));
%seria evaluar los accuracy de cada intento , es decir con horas ,sin horas
%con sin pca 


%ahora el pca es 
[coeff, score, ~, ~, explained] = pca(XTrain);
%coef devuelve los coeficientes de componentes principales, también conocidos como cargas
%score puntuaciones de los componentes principales
%el tercero es la desviaciones de los componentes principales en .scorelatent
%el cuarto la estadística T cuadrada del Hotelling para cada observación en .X
% explained el porcentaje de la varianza total explicado por cada componente principal y 
% tambien puede devolver la media como quinto parametro


% Elegir el número de componentes principales que explican al menos el 95% de la varianza
explainedVariance = 0.95;%siempre se hace el 95, o 90 pero yo creo que mejor 95
numComponents = find(cumsum(explained) >= explainedVariance * 100, 1);

% Transformar los datos de entrenamiento y prueba usando los componentes principales
XTrainPCA = score(:, 1:numComponents);
XTestPCA = XTest * coeff(:, 1:numComponents);
% en la documentacion de pc hay algp que se llama biplot, ahi se puede ver
% como.... como la importancia que tiene cada caracteristica de forma mas
% visible, yo diria usar scatter3 y quitar alguna variable, la que nos diga
% el pca que tiene menos importancia



%% importar solo un dato
Sensor=ImportarDatos.Sensor('Datos\2024-04-18\4104');
datosCordenadasSensor=ImportarDatos.SensorCordenadas(Sensor);
% fechaInicio="2024-04-23 6:39:00.434";
%  fechaFin="2024-04-23 7:50:00.434";
% r=Calculos.riesgoCurva(datosCordenadasSensor,fechaInicio, fechaFin);

tiempoR=Calculos.Ruta(datosCordenadasSensor,Ida4104,Vuelta4104,20);
T=size(tiempoR);

% Ccurvas1=Calculos.Lcurvasida4020();
% Ccurvas2=Calculos.LcurvasVuelta4020();
% Ccurvas3=Calculos.Lcurvasida4104();
% Ccurvas=Calculos.LcurvasVuelta4104();
% for i=1:T(1)
% array2(:,i)=Calculos.riesgoCurva2(datosCordenadasSensor,tiempoR{i,2},tiempoR{i,3},Ccurvas);
% end
% for i=1:T(1)
%     m{i}=Map.Ruta(datosCordenadasSensor,tiempoR{i,1},tiempoR{i,2},'r','ida','ida');
%     m2{i}=Map.Ruta(datosCordenadasSensor,tiempoR{i,2},tiempoR{i,3},'b','vuelta','vuelta');
%     
% end
%%
m=Map.Ruta(datosCordenadasSensor,tiempoR{1,1},tiempoR{1,2},'r','ida','ida');
hold on
marcador=Pcurvas.s4104_1.ida{1,1};
marcador2=Pcurvas.s4104_1.ida{1,2};
geoscatter(marcador(:, 1), marcador(:, 2), 'Filled', 'Marker', 'x', 'MarkerEdgeColor', 'red', 'DisplayName', 'Posiciones', 'SizeData', 200);
geoscatter(marcador2(:, 1), marcador2(:, 2), 'Filled', 'Marker', 'o', 'MarkerEdgeColor', 'blue', 'DisplayName', 'Posiciones', 'SizeData', 100);
            
%     

%%
nombres = fieldnames(datosBuses);
narray = 1;
Ccurvas = Calculos.Lcurvasida4020();
%Ccurvas = Calculos.LcurvasVuelta4020();
%Ccurvas = Calculos.Lcurvasida4104();
% Ccurvas = Calculos.LcurvasVuelta4104();

for i = 1:5
    Na = nombres{i}; 
    data = datosBuses.(Na).bus_4020.datosSensor;
    tiempos=datosBuses.(Na).bus_4020.tiempoRuta;
    T = size(datosBuses.(Na).bus_4020.tiempoRuta);
    for j = 1:T(1)
        array3(:, narray) = Calculos.riesgoCurva2(data, tiempos{j, 1}, tiempos{j, 2}, Ccurvas);
        narray = narray + 1;
    end
end



%%
nombres = fieldnames(datosBuses);
narray = 1;
for i=6:10
    Na = nombres{i};  % Asegurarse de que Na sea una cadena de texto
    data=datosBuses.(Na).bus_4020.EV1;
    tiempos=datosBuses.(Na).bus_4020.tiempoRuta;
    Ti = size(datosBuses.(Na).bus_4020.tiempoRuta);
    for j=1:Ti(1)
        fechaInicio= tiempos{j, 1};
        fechaFin=tiempos{j, 3};
        
            if ischar(fechaInicio) || isstring(fechaInicio)
                fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
            end
            if ischar(fechaFin) || isstring(fechaFin)
                fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
            end
        Filtrados =data(data.fechaHoraLecturaDato >= fechaInicio & data.fechaHoraLecturaDato <= fechaFin, :);%se filtran por fecha
%         F1 = Filtrados(Filtrados.codigoComportamientoAnomalo == '1', :);
% F2 = Filtrados(Filtrados.codigoComportamientoAnomalo == '2', :);
% F3 = Filtrados(Filtrados.codigoComportamientoAnomalo == '3', :);
% F4 = Filtrados(Filtrados.codigoComportamientoAnomalo == '4', :);

        Evento18=size(Filtrados);
            
             E1(1,narray)=Evento18(1);
%             Evento18=size(F2);
%             
%             E2(1,narray)=Evento18(1);
%             
%             Evento18=size(F3);
%             
%             E3(1,narray)=Evento18(1);
%             Evento18=size(F4);
%             
%             E4(1,narray)=Evento18(1);
            
%             E(:,narray)=sum(Filtrados.estadoAperturaCierrePuertas);
            
            narray=narray+1;
    end
end

%% Importar todos los datos tomados por el movil

datosBuses = ImportarDatos.importarTodosLosDatos('Datos');

%%
% Calculo de todos los tiempos para cada ruta

datosBuses = Calculos.calcularTiemposRutas(datosBuses);

%% calcula la velocidad

datosBuses = Calculos.calcularVelocidadRutas(datosBuses);

%%
datosBuses = Calculos.aproximarNivelBateria(datosBuses);

%% calcula la velocidad

datosBuses = Calculos.calcularAceleracionRutas(datosBuses);

%%
datosBuses = Calculos.calcularAceleracionRutas2(datosBuses);

%%

datosBuses = Calculos.calcularPorcentajeBateriaRutas(datosBuses);

%%
datosBuses = Calculos.calcularConsumoEnergiaRutas(datosBuses);

%%

datosBuses = Calculos.calcularPicosAceleracionRutas(datosBuses);
%%

datosBuses = Calculos.calcularPosAceleracion(datosBuses);

%%

datosBuses = Calculos.extraerP60(datosBuses);

%%

datosBuses = Calculos.extraerSegmentosDatos(datosBuses);

%%

datosBuses = Calculos.extraerEV1(datosBuses);

%%

datosBuses = Calculos.extraerEV19(datosBuses);

%%

datosBuses = Calculos.extraerEV2(datosBuses);

%%

datosBuses = Calculos.extraerEV8(datosBuses);

%%

datosBuses = Calculos.extraerEV18(datosBuses);

%% Calcula los promedios por segmentos

datosBuses = Calculos.calcularPromedioVelocidadRutas(datosBuses);

%%

datosBuses = Calculos.calcularPromedioConsumoRutas(datosBuses);

%% Organiza la estructura por bus y ruta

Buses = ImportarDatos.reorganizarDatosBuses(datosBuses);

%% Organiza la estructura por bus y ruta

Rutas = ImportarDatos.reorganizarDatosRutas(datosBuses);

%%

%%plot(Buses.bus_4020.ida.f_2024_04_16.,datosBuses.f_2024_04_16.bus_4020.segmentoP60{1,1}.velocidadVehiculo)


%%

generarDatos(Buses.bus_4104.ida.horaValle.("Hora Inicio")(1), Buses.bus_4104.ida.horaValle.("Hora Fin")(1), '4104', 'ida', Pcurvas);

%%
generarDatos(Buses.bus_4020.ida.horaPico.("Hora Inicio")(3), Buses.bus_4020.ida.horaPico.("Hora Fin")(3), '4020', 'ida');
%%
generarDatos(Buses.bus_4020.ida.f_2024_04_15.("Hora Inicio")(3), Buses.bus_4020.ida.f_2024_04_15.("Hora Fin")(3), '4020', 'ida');

%%





%% Graficar eventos

% Obtener la celda de "Evento 1"
eventos = Buses.bus_4104.ida.horaPico.("Evento 19_2");

% Inicializar un arreglo para almacenar los tamaños de los sub-arreglos
tamanos = zeros(numel(eventos), 1);

% Iterar sobre cada elemento de la celda y obtener el tamaño del sub-arreglo
for i = 1:numel(eventos)
    subArreglo = eventos{i};
    tamanos(i) = size(subArreglo, 1); % O puedes usar size(subArreglo, 1) para obtener el tamaño en la primera dimensión
end

% Mostrar los tamaños de los sub-arreglos
disp(tamanos);
bar(tamanos);
title('Numero de eventos 1 por conductor'); % Asegúrate de concatenar correctamente
xlabel('Conductor');
ylabel('Numero de repeticiones');

%%

distancia=datosBuses.f_2024_04_16.bus_4020.segmentoP60{1, 1}.kilometrosOdometro - datosBuses.f_2024_04_16.bus_4020.segmentoP60{1, 1}.kilometrosOdometro(1);
consumo = datosBuses.f_2024_04_16.bus_4020.consumoEnergiaRuta{1, 1};

plot(distancia(1:end-1),consumo);

title('Conductor '); % Asegúrate de concatenar correctamente
xlabel('Distancia');
ylabel('Porcentaje de energía');
%%

% ordenpico = Calculos.ordenarTablaPorElementoVector(Buses.bus_4020.ida.horaValle, 'Promedio velocidad', 1, 'ascend' );
%ordenpico = [ordenpico, array2table(cell2mat(ordenpico.("Picos Aceleracion")')')];

% ordenValler = Calculos.ordenarTablaPorElementoVector(Buses.bus_4020.ida.horaValle, 'Promedio velocidad', 1, 'ascend' );

aa= (cell2mat(ordenpico.("Promedio velocidad")')');

figure;
bar(percentages');
xlabel('Grupo');
ylabel('Promedio velocidad');
title('Diagrama de barras de Promedio velocidad por Ruta');

figure;
boxplot(percentages);
xlabel('Grupo');
ylabel('Promedio velocidad');
title('Boxplot de Promedio velocidad por Ruta');

%%

Rutas = calcularRiesgoCurvaPorEstructura(Rutas, Pcurvas);

%% Calcula los porcentajes y los deja en la estructura

rutas = fieldnames(Rutas);
for i = 1:numel(rutas)
    ruta = rutas{i};
    trayectos = fieldnames(Rutas.(ruta));
    for j = 1:numel(trayectos)
        trayecto = trayectos{j};

        dhg = Rutas.(ruta).(trayecto).horaValle;

        if isempty(dhg)
                continue;
            end

        dhg.("PromedioVelocidad")
        try
            m_dhg = (cell2mat(dhg.("PromedioVelocidad")')');
        catch ME
            error = dhg;
        end
        shg = dhg.Sexo;

        tm = size(m_dhg);
        for k = 1:tm(2)
            sg = m_dhg(:, k);

            min_val = min(sg) * 0.9;
            max_val = max(sg) * 1.1;

            % Escalar los valores del segmento al rango [0, 1]
            scaled_segment = (sg - min_val) / (max_val - min_val);

            % Convertir los valores escalados a porcentajes
            percentages = scaled_segment * 100;

            % Inicializar la columna "PorcentajesVelocidad" si no existe
            if ~ismember("PorcentajesVelocidad", Rutas.(ruta).(trayecto).horaValle.Properties.VariableNames)
                Rutas.(ruta).(trayecto).horaValle.("PorcentajesVelocidad") = cell(height(Rutas.(ruta).(trayecto).horaValle), 1);
            end
            
            % Limpiar los datos existentes en la primera iteración del trayecto
            if k == 1
                for idx = 1:height(Rutas.(ruta).(trayecto).horaValle)
                    Rutas.(ruta).(trayecto).horaValle.("PorcentajesVelocidad"){idx} = [];
                end
            end
            
            % Agregar el nuevo dato a cada cell array en la columna existente
            for idx = 1:height(Rutas.(ruta).(trayecto).horaValle)
                Rutas.(ruta).(trayecto).horaValle.("PorcentajesVelocidad"){idx} = [Rutas.(ruta).(trayecto).horaValle.("PorcentajesVelocidad"){idx}, percentages(idx)];
            end
        end
    end
end
%%

Rutas = calcularAceleraciones(Rutas);


%% Calcular las aceleraciones

function Rutas = calcularAceleraciones(Rutas)
    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};
            generalTable = Rutas.(ruta).(trayecto).horaValle;

             % Verificar si generalTable está vacío, si es así, continuar con el siguiente trayecto
            if isempty(generalTable)
                continue;
            end
            
            % Inicializar las columnas si no existen
            if ~ismember('NumAceleracionesPorKm', generalTable.Properties.VariableNames)
                generalTable.NumAceleracionesPorKm = zeros(height(generalTable), 1);
            end
            if ~ismember('NumDesaceleracionesPorKm', generalTable.Properties.VariableNames)
                generalTable.NumDesaceleracionesPorKm = zeros(height(generalTable), 1);
            end
            if ~ismember('AceleracionPromedio', generalTable.Properties.VariableNames)
                generalTable.AceleracionPromedio = zeros(height(generalTable), 1);
            end
            if ~ismember('DesaceleracionPromedio', generalTable.Properties.VariableNames)
                generalTable.DesaceleracionPromedio = zeros(height(generalTable), 1);
            end

            % Recorrer cada fila de la tabla General
            for k = 1:height(generalTable)
                datosSensor = generalTable.DatosSensor{k};
                
                % Calcular la distancia total para cada conductor
                total_distancia = sum(Calculos.CalcularDistancia(datosSensor));  % Asumiendo que la función acepta los datos de cada conductor
                
                % Filtrar las aceleraciones y desaceleraciones mayores a 0.8 m/s²
                aceleraciones = generalTable.Aceleracion{k};
                aceleraciones_mayores_08 = aceleraciones(aceleraciones > 0.8);
                desaceleraciones_mayores_08 = aceleraciones(aceleraciones < -0.8);

                % Calcular el número de aceleraciones y desaceleraciones por kilómetro
                num_aceleraciones_por_km = numel(aceleraciones_mayores_08) / (total_distancia / 1000);
                num_desaceleraciones_por_km = numel(desaceleraciones_mayores_08) / (total_distancia / 1000);

                % Calcular las aceleraciones y desaceleraciones promedio mayores a 0.8 m/s²
                if isempty(aceleraciones_mayores_08)
                    aceleracion_promedio = 0;
                else
                    aceleracion_promedio = mean(aceleraciones_mayores_08);
                end

                if isempty(desaceleraciones_mayores_08)
                    desaceleracion_promedio = 0;
                else
                    desaceleracion_promedio = mean(desaceleraciones_mayores_08);
                end

                % Almacenar los resultados en la tabla General para cada conductor
                generalTable.NumAceleracionesPorKm(k) = num_aceleraciones_por_km;
                generalTable.NumDesaceleracionesPorKm(k) = num_desaceleraciones_por_km;
                generalTable.AceleracionPromedio(k) = aceleracion_promedio;
                generalTable.DesaceleracionPromedio(k) = desaceleracion_promedio;
            end
            
            % Actualizar la tabla General en la estructura Rutas
            Rutas.(ruta).(trayecto).horaValle = generalTable;
        end
    end
    return;
end


%% Calcula los datos de riesgo curvas

function Rutas = calcularRiesgoCurvaPorEstructura(Rutas, Pcurvas)
    % Iterar sobre todas las rutas en la estructura
    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        
        % Iterar sobre todos los trayectos en la ruta actual
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};

            % Obtener la tabla General del trayecto actual
            generalTable = Rutas.(ruta).(trayecto).horaValle;


             % Verificar si generalTable está vacío, si es así, continuar con el siguiente trayecto
            if isempty(generalTable)
                continue;
            end


            % Obtener los datos relevantes del trayecto desde la tabla General
            datosSensor = generalTable.DatosSensor;
            fechaInicio = generalTable.HoraInicio;
            fechaFinal = generalTable.HoraFin;
            ida = Pcurvas.(ruta).(trayecto);

            % Calcular el riesgo de curva para el trayecto actual
            
            % Recorrer los datos de DatosSensor y calcular el riesgo de curva para cada punto
            for k = 1:size(datosSensor, 1)
                % Calcular el riesgo de curva para el punto actual
                riesgoCurva = Calculos.riesgoCurva2(datosSensor{k}, fechaInicio{k}, fechaFinal{k}, ida);


                % Actualizar la tabla General en la estructura Rutas
                Rutas.(ruta).(trayecto).horaValle.riesgoCurva(k) = {riesgoCurva};
            end


        end
    end
    return;
end

%% Calcula los porcentajes del consumo

rutas = fieldnames(Rutas);
for i = 1:numel(rutas)
    ruta = rutas{i};
    trayectos = fieldnames(Rutas.(ruta));
    for j = 1:numel(trayectos)
        trayecto = trayectos{j};

        dhg = Rutas.(ruta).(trayecto).horaValle;
        try
            m_dhg = (cell2mat(dhg.("PromedioConsumo")')');
        catch ME
            error = dhg;
        end
        % Verificar si generalTable está vacío, si es así, continuar con el siguiente trayecto
            if isempty(dhg)
                continue;
            end
        shg = dhg.Sexo;

        

        tm = size(m_dhg);
        for k = 1:tm(2)
            sg = m_dhg(:, k);

            min_val = min(sg) * 0.9;
            max_val = max(sg) * 1.1;

            % Escalar los valores del segmento al rango [0, 1]
            scaled_segment = (sg - min_val) / (max_val - min_val);

            % Convertir los valores escalados a porcentajes
            percentages = scaled_segment * 100;

            % Inicializar la columna "PorcentajesConsumo" si no existe
            if ~ismember("PorcentajesConsumo", Rutas.(ruta).(trayecto).horaValle.Properties.VariableNames)
                Rutas.(ruta).(trayecto).horaValle.("PorcentajesConsumo") = cell(height(Rutas.(ruta).(trayecto).horaValle), 1);
            end
            
            % Limpiar los datos existentes en la primera iteración del trayecto
            if k == 1
                for idx = 1:height(Rutas.(ruta).(trayecto).horaValle)
                    Rutas.(ruta).(trayecto).horaValle.("PorcentajesConsumo"){idx} = [];
                end
            end
            
            % Agregar el nuevo dato a cada cell array en la columna existente
            for idx = 1:height(Rutas.(ruta).(trayecto).horaValle)
                try
                Rutas.(ruta).(trayecto).horaValle.("PorcentajesConsumo"){idx} = [Rutas.(ruta).(trayecto).horaValle.("PorcentajesConsumo"){idx}, percentages(idx)];
                catch ME
                    ME
                end
                end
        end
    end
end

%% Grafica general de porcentajes

promedioConductorH = [];
promedioConductorM = [];

rutas = fieldnames(Rutas);
for i = 1:numel(rutas)
    ruta = rutas{i};
    trayectos = fieldnames(Rutas.(ruta));
    for j = 1:numel(trayectos)
        trayecto = trayectos{j};

        dhg = Rutas.(ruta).(trayecto).General;
        try
            m_dhg = (cell2mat(dhg.("PorcentajesVelocidad"))');
        catch ME
            error = dhg;
        end
        shg = dhg.Sexo;

        tm = size(m_dhg);
        for k = 1:tm(2)
            conductor = m_dhg(:, k);
            
            % Omitir datos NaN
            conductor = conductor(~isnan(conductor));
            
            % Acumular los datos por sexo
            if shg(k) == 0
                promedioConductorH = [promedioConductorH; mean(conductor)];
            else
                promedioConductorM = [promedioConductorM; mean(conductor)];
            end
        end
    end
end

% Omitir promedios NaN
promedioConductorH = promedioConductorH(~isnan(promedioConductorH));
promedioConductorM = promedioConductorM(~isnan(promedioConductorM));

% Generar la gráfica acumulada
figure;

% Gráfica de promedios para hombres y mujeres en la misma figura
scatter(promedioConductorH, zeros(1, length(promedioConductorH)), 'r', 'DisplayName', 'Hombres');
hold on;
scatter(promedioConductorM, zeros(1, length(promedioConductorM)), 'b', 'DisplayName', 'Mujeres');

% Calcular y graficar la distribución para hombres
if ~isempty(promedioConductorH)
    mu_h = mean(promedioConductorH);
    sig_h = std(promedioConductorH);
    x_h = linspace(mu_h-3*sig_h, mu_h+3*sig_h, 100);
    y_h = pdf('Normal', x_h, mu_h, sig_h);
    plot(x_h, y_h, 'r')
end

% Calcular y graficar la distribución para mujeres
if ~isempty(promedioConductorM)
    mu_m = mean(promedioConductorM);
    sig_m = std(promedioConductorM);
    x_m = linspace(mu_m-3*sig_m, mu_m+3*sig_m, 100);
    y_m = pdf('Normal', x_m, mu_m, sig_m);
    plot(x_m, y_m, 'b')
end

title('Promedio Velocidad - Hombres y Mujeres');
xlabel('Promedio de porcentajes por segmento de velocidad');
ylabel('Frecuencia');
legend;
hold off;

%% Grafica general de riesgo curva

promedioConductorH = [];
promedioConductorM = [];

rutas = fieldnames(Rutas);
for i = 1:numel(rutas)
    ruta = rutas{i};
    trayectos = fieldnames(Rutas.(ruta));
    for j = 1:numel(trayectos)
        trayecto = trayectos{j};

        dhg = Rutas.(ruta).(trayecto).General;
        try
            m_dhg = (cell2mat(dhg.("riesgoCurva")')');
        catch ME
            error = dhg;
        end
        shg = dhg.Sexo;

        tm = size(m_dhg);
        for k = 1:tm(1)
            conductor = m_dhg(k, :);
            
            % Omitir datos NaN
            conductor = conductor(~isnan(conductor));
            
            % Acumular los datos por sexo
            if shg(k) == 0
                promedioConductorH = [promedioConductorH; mean(conductor)];
            else
                promedioConductorM = [promedioConductorM; mean(conductor)];
            end
        end
    end
end

% Omitir promedios NaN
promedioConductorH = promedioConductorH(~isnan(promedioConductorH));
promedioConductorM = promedioConductorM(~isnan(promedioConductorM));

% Generar la gráfica acumulada
figure;

% Gráfica de promedios para hombres y mujeres en la misma figura
scatter(promedioConductorH, zeros(1, length(promedioConductorH)), 'r', 'DisplayName', 'Hombres');
hold on;
scatter(promedioConductorM, zeros(1, length(promedioConductorM)), 'b', 'DisplayName', 'Mujeres');

% Calcular y graficar la distribución para hombres
if ~isempty(promedioConductorH)
    mu_h = mean(promedioConductorH);
    sig_h = std(promedioConductorH);
    x_h = linspace(mu_h-3*sig_h, mu_h+3*sig_h, 100);
    y_h = pdf('Normal', x_h, mu_h, sig_h);
    plot(x_h, y_h, 'b')
end

% Calcular y graficar la distribución para mujeres
if ~isempty(promedioConductorM)
    mu_m = mean(promedioConductorM);
    sig_m = std(promedioConductorM);
    x_m = linspace(mu_m-3*sig_m, mu_m+3*sig_m, 100);
    y_m = pdf('Normal', x_m, mu_m, sig_m);
    plot(x_m, y_m, 'r')
end

title('Indice riesgo - Hombres y Mujeres');
xlabel('Indice riesgo por conductor');
ylabel('Frecuencia');
legend;
hold off;

%% Debug hombres

promedioConductorH = [];

rutas = fieldnames(Rutas);
for i = 1:numel(rutas)
    ruta = rutas{i};
    trayectos = fieldnames(Rutas.(ruta));
    for j = 1:numel(trayectos)
        trayecto = trayectos{j};

        dhg = Rutas.(ruta).(trayecto).General;
        try
            m_dhg = (cell2mat(dhg.("PorcentajesVelocidad"))');
        catch ME
            error = dhg;
        end
        shg = dhg.Sexo;

        tm = size(m_dhg);
        for k = 1:tm(2)
            conductor = m_dhg(:, k);
            
            % Acumular los datos por sexo, omitiendo NaN
            if shg(k) == 0
                promedioConductorH = [promedioConductorH; nanmean(conductor)];
            end
        end
    end
end

% Generar la gráfica acumulada
figure;

% Calcular y graficar la distribución para hombres, omitiendo NaN
if ~isempty(promedioConductorH)
    mu_h = nanmean(promedioConductorH);
    sig_h = nanstd(promedioConductorH);
    x_h = linspace(mu_h-3*sig_h, mu_h+3*sig_h, 100);
    y_h = pdf('Normal', x_h, mu_h, sig_h);
    plot(x_h, y_h, 'r')
end

title('Distribución Normal - Hombres');
xlabel('Promedio Velocidad');
ylabel('Frecuencia');
legend('Hombres');
hold off;

%% Grafica general consumo


promedioConductorH = [];
promedioConductorM = [];

rutas = fieldnames(Rutas);
for i = 1:numel(rutas)
    ruta = rutas{i};
    trayectos = fieldnames(Rutas.(ruta));
    for j = 1:numel(trayectos)
        trayecto = trayectos{j};

        dhg = Rutas.(ruta).(trayecto).General;
        try
            m_dhg = (cell2mat(dhg.("PorcentajesConsumo"))');
        catch ME
            error = dhg;
        end
        shg = dhg.Sexo;

        tm = size(m_dhg);
        for k = 1:tm(2)
            conductor = m_dhg(:, k);
            
            % Omitir datos NaN
            conductor = conductor(~isnan(conductor));
            
            % Acumular los datos por sexo
            if shg(k) == 0
                promedioConductorH = [promedioConductorH; mean(conductor)];
            else
                promedioConductorM = [promedioConductorM; mean(conductor)];
            end
        end
    end
end

% Omitir promedios NaN
promedioConductorH = promedioConductorH(~isnan(promedioConductorH));
promedioConductorM = promedioConductorM(~isnan(promedioConductorM));

% Generar la gráfica acumulada
figure;

% Gráfica de promedios para hombres y mujeres en la misma figura
scatter(promedioConductorH, zeros(1, length(promedioConductorH)), 'r', 'DisplayName', 'Hombres');
hold on;
scatter(promedioConductorM, zeros(1, length(promedioConductorM)), 'b', 'DisplayName', 'Mujeres');

% Calcular y graficar la distribución para hombres
if ~isempty(promedioConductorH)
    mu_h = mean(promedioConductorH);
    sig_h = std(promedioConductorH);
    x_h = linspace(mu_h-3*sig_h, mu_h+3*sig_h, 100);
    y_h = pdf('Normal', x_h, mu_h, sig_h);
    plot(x_h, y_h, 'r')
end

% Calcular y graficar la distribución para mujeres
if ~isempty(promedioConductorM)
    mu_m = mean(promedioConductorM);
    sig_m = std(promedioConductorM);
    x_m = linspace(mu_m-3*sig_m, mu_m+3*sig_m, 100);
    y_m = pdf('Normal', x_m, mu_m, sig_m);
    plot(x_m, y_m, 'b')
end

title('Promedio Consumo - Hombres y Mujeres');
xlabel('Promedio de porcentajes por segmento de consumo');
ylabel('Frecuencia');
legend;
hold off;
%%
plotAceleracionPorSexo(Rutas)

%% Grafica picos aceleracion

function plotAceleracionPorSexo(Rutas)

    % Definir colores para hombres y mujeres
    colorHombres = 'r';
    colorMujeres = 'b';
    
    % Inicializar arreglos para frecuencias y magnitudes
    aceleracionHombres = [];
    aceleracionMujeres = [];
    frecuenciaHombres = [];
    frecuenciaMujeres = [];
    
    % Definir los límites y el tamaño de los bins
    binEdges = -5:0.1:5; % Por ejemplo, bins de 0.1 en el rango [-3, 3]
    
    % Iterar sobre todas las rutas y trayectos
    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};
            
            % Obtener la tabla General
            dhg = Rutas.(ruta).(trayecto).General;
            
            % Verificar que existan las columnas necesarias
            if ismember("Aceleracion", dhg.Properties.VariableNames) && ismember("Sexo", dhg.Properties.VariableNames)
                aceleraciones = dhg.Aceleracion;
                sexo = dhg.Sexo;
                
                % Calcular frecuencia y magnitud para cada aceleración
                for k = 1:numel(aceleraciones)
                    aceleracion = aceleraciones{k};
                    if isempty(aceleracion)
                        continue; % Omitir si no hay datos de aceleración
                    end
                    
                    % Filtrar las aceleraciones en el rango -0.8 a 0.8
                    aceleracion = aceleracion(aceleracion < -0.8 | aceleracion > 0.8);
                    
                    % Bin the accelerations
                    [binCounts, binEdges] = histcounts(aceleracion, binEdges);
                    binCenters = binEdges(1:end-1) + diff(binEdges)/2;
                    
                    for n = 1:numel(binCenters)
                        if binCounts(n) > 0
                            if sexo(k) == 0
                                aceleracionHombres = [aceleracionHombres, binCenters(n)];
                                frecuenciaHombres = [frecuenciaHombres, binCounts(n)];
                            else
                                aceleracionMujeres = [aceleracionMujeres, binCenters(n)];
                                frecuenciaMujeres = [frecuenciaMujeres, binCounts(n)];
                            end
                        end
                    end
                end
            end
        end
    end
    
    % Crear la figura
    figure;
    hold on;
    
    % Plotear puntos para hombres
    scatter(frecuenciaHombres, aceleracionHombres, 'MarkerEdgeColor', colorHombres, 'DisplayName', 'Hombres');
    
    % Plotear puntos para mujeres
    scatter(frecuenciaMujeres, aceleracionMujeres, 'MarkerEdgeColor', colorMujeres, 'DisplayName', 'Mujeres');
    
    % Configurar el título y etiquetas de los ejes
    title('Frecuencia de Aceleraciones por Sexo');
    xlabel('Frecuencia de Aceleración');
    ylabel('Magnitud de Aceleración');
    legend;
    
    hold off;
end


%% Graficar segmento

% obtenemos los valores del segmento
% hay que obtener una grafica para cada segmento la idea es recorrer cada
% ruta, luego en todos los datos todos los segmento

rutas = fieldnames(Rutas);
for i = 1:numel(rutas)
    ruta = rutas{i};
    trayectos = fieldnames(Rutas.(ruta));
    for j = 1:numel(trayectos)
        trayecto = trayectos{j};

        dhp = Rutas.(ruta).(trayecto).horaPico;
        dhp.("PromedioConsumo")
        m_dhp = (cell2mat(dhp.("PromedioVelocidad")')');
        shp = dhp.Sexo;

        dhv = Rutas.(ruta).(trayecto).horaValle;
        dhv.("PromedioConsumo")
        m_dhv = (cell2mat(dhv.("PromedioVelocidad")')');
        shv = dhv.Sexo;

        tm = size(m_dhv);
        for k = 1:tm(2)
            sv = m_dhv(:, k);
            sp = m_dhp(:, k);

            figure;

            % Primer subplot para horaValle
            subplot(2, 2, 1);
            scatter(sv, zeros(1, length(sv)))
            mu_sv = mean(sv);
            sig_sv = var(sv);
            y_sv = pdf('Normal', mu_sv-3*sig_sv:0.1:mu_sv+3*sig_sv, mu_sv, sig_sv);
            hold on;
            plot(mu_sv-3*sig_sv:0.1:mu_sv+3*sig_sv, y_sv)
            title('Hora Valle');
            xlabel('Promedio Velocidad');
            ylabel('Frecuencia');
            hold off;

            % Segundo subplot para horaPico
            subplot(2, 2, 2);
            scatter(sp, zeros(1, length(sp)))
            mu_sp = mean(sp);
            sig_sp = var(sp);
            y_sp = pdf('Normal', mu_sp-3*sig_sp:0.1:mu_sp+3*sig_sp, mu_sp, sig_sp);
            hold on;
            plot(mu_sp-3*sig_sp:0.1:mu_sp+3*sig_sp, y_sp)
            title('Hora Pico');
            xlabel('Promedio Velocidad');
            ylabel('Frecuencia');
            hold off;

            % Subplot para hombres y mujeres en Hora Valle
            subplot(2, 2, 3);
            sv_hombres = sv(shv == 0);
            sv_mujeres = sv(shv == 1);
            scatter(sv_hombres, zeros(1, length(sv_hombres)), 'r', 'DisplayName', 'Hombres');
            hold on;
            scatter(sv_mujeres, zeros(1, length(sv_mujeres)), 'b', 'DisplayName', 'Mujeres');
            mu_sv_hombres = mean(sv_hombres);
            sig_sv_hombres = var(sv_hombres);
            y_sv_hombres = pdf('Normal', mu_sv_hombres-3*sig_sv_hombres:0.1:mu_sv_hombres+3*sig_sv_hombres, mu_sv_hombres, sig_sv_hombres);
            plot(mu_sv_hombres-3*sig_sv_hombres:0.1:mu_sv_hombres+3*sig_sv_hombres, y_sv_hombres, 'r')
            mu_sv_mujeres = mean(sv_mujeres);
            sig_sv_mujeres = var(sv_mujeres);
            y_sv_mujeres = pdf('Normal', mu_sv_mujeres-3*sig_sv_mujeres:0.1:mu_sv_mujeres+3*sig_sv_mujeres, mu_sv_mujeres, sig_sv_mujeres);
            plot(mu_sv_mujeres-3*sig_sv_mujeres:0.1:mu_sv_mujeres+3*sig_sv_mujeres, y_sv_mujeres, 'b')
            title('Hora Valle - Hombres y Mujeres');
            xlabel('Promedio Velocidad');
            ylabel('Frecuencia');
            legend;
            hold off;

            % Subplot para hombres y mujeres en Hora Pico
            subplot(2, 2, 4);
            sp_hombres = sp(shp == 0);
            sp_mujeres = sp(shp == 1);
            scatter(sp_hombres, zeros(1, length(sp_hombres)), 'r', 'DisplayName', 'Hombres');
            hold on;
            scatter(sp_mujeres, zeros(1, length(sp_mujeres)), 'b', 'DisplayName', 'Mujeres');
            mu_sp_hombres = mean(sp_hombres);
            sig_sp_hombres = var(sp_hombres);
            y_sp_hombres = pdf('Normal', mu_sp_hombres-3*sig_sp_hombres:0.1:mu_sp_hombres+3*sig_sp_hombres, mu_sp_hombres, sig_sp_hombres);
            plot(mu_sp_hombres-3*sig_sp_hombres:0.1:mu_sp_hombres+3*sig_sp_hombres, y_sp_hombres, 'r')
            mu_sp_mujeres = mean(sp_mujeres);
            sig_sp_mujeres = var(sp_mujeres);
            y_sp_mujeres = pdf('Normal', mu_sp_mujeres-3*sig_sp_mujeres:0.1:mu_sp_mujeres+3*sig_sp_mujeres, mu_sp_mujeres, sig_sp_mujeres);
            plot(mu_sp_mujeres-3*sig_sp_mujeres:0.1:mu_sp_mujeres+3*sig_sp_mujeres, y_sp_mujeres, 'b')
            title('Hora Pico - Hombres y Mujeres');
            xlabel('Promedio Velocidad');
            ylabel('Frecuencia');
            legend;
            hold off;

            % Añadir título general a la figura
            sgtitle(sprintf('Ruta: %s, Segmento: %d', ruta, k));
        end
    end
end


%%


% obtenemos los valores del segmento
% hay que obtener una grafica para cada segmento la idea es recorrer cada
% ruta, luego en todos los datos todos los segmento

rutas = fieldnames(Rutas);
for i = 1:numel(rutas)
    ruta = rutas{i};
    trayectos = fieldnames(Rutas.(ruta));
    for j = 1:numel(trayectos)
        trayecto = trayectos{j};

        dhp = Rutas.(ruta).(trayecto).horaPico;
        m_dhp = (cell2mat(dhp.("PromedioConsumo")')');
        shp = dhp.Sexo;

        dhv = Rutas.(ruta).(trayecto).horaValle;
        m_dhv = (cell2mat(dhv.("PromedioConsumo")')');
        shv = dhv.Sexo;

        tm = size(m_dhv);
        for k = 1:tm(2)
            sv = m_dhv(:, k);
            sp = m_dhp(:, k);

            figure;

            % Primer subplot para horaValle
            subplot(2, 2, 1);
            scatter(sv, zeros(1, length(sv)))
            mu_sv = mean(sv);
            sig_sv = var(sv);
            y_sv = pdf('Normal', mu_sv-3*sig_sv:0.1:mu_sv+3*sig_sv, mu_sv, sig_sv);
            hold on;
            plot(mu_sv-3*sig_sv:0.1:mu_sv+3*sig_sv, y_sv)
            title('Hora Valle');
            xlabel('Promedio Consumo');
            ylabel('Frecuencia');
            hold off;

            % Segundo subplot para horaPico
            subplot(2, 2, 2);
            scatter(sp, zeros(1, length(sp)))
            mu_sp = mean(sp);
            sig_sp = var(sp);
            y_sp = pdf('Normal', mu_sp-3*sig_sp:0.1:mu_sp+3*sig_sp, mu_sp, sig_sp);
            hold on;
            plot(mu_sp-3*sig_sp:0.1:mu_sp+3*sig_sp, y_sp)
            title('Hora Pico');
            xlabel('Promedio Consumo');
            ylabel('Frecuencia');
            hold off;

            % Subplot para hombres y mujeres en Hora Valle
            subplot(2, 2, 3);
            sv_hombres = sv(shv == 0);
            sv_mujeres = sv(shv == 1);
            scatter(sv_hombres, zeros(1, length(sv_hombres)), 'r', 'DisplayName', 'Hombres');
            hold on;
            scatter(sv_mujeres, zeros(1, length(sv_mujeres)), 'b', 'DisplayName', 'Mujeres');
            mu_sv_hombres = mean(sv_hombres);
            sig_sv_hombres = var(sv_hombres);
            y_sv_hombres = pdf('Normal', mu_sv_hombres-3*sig_sv_hombres:0.1:mu_sv_hombres+3*sig_sv_hombres, mu_sv_hombres, sig_sv_hombres);
            plot(mu_sv_hombres-3*sig_sv_hombres:0.1:mu_sv_hombres+3*sig_sv_hombres, y_sv_hombres, 'r')
            mu_sv_mujeres = mean(sv_mujeres);
            sig_sv_mujeres = var(sv_mujeres);
            y_sv_mujeres = pdf('Normal', mu_sv_mujeres-3*sig_sv_mujeres:0.1:mu_sv_mujeres+3*sig_sv_mujeres, mu_sv_mujeres, sig_sv_mujeres);
            plot(mu_sv_mujeres-3*sig_sv_mujeres:0.1:mu_sv_mujeres+3*sig_sv_mujeres, y_sv_mujeres, 'b')
            title('Hora Valle - Hombres y Mujeres');
            xlabel('Promedio Consumo');
            ylabel('Frecuencia');
            legend;
            hold off;

            % Subplot para hombres y mujeres en Hora Pico
            subplot(2, 2, 4);
            sp_hombres = sp(shp == 0);
            sp_mujeres = sp(shp == 1);
            scatter(sp_hombres, zeros(1, length(sp_hombres)), 'r', 'DisplayName', 'Hombres');
            hold on;
            scatter(sp_mujeres, zeros(1, length(sp_mujeres)), 'b', 'DisplayName', 'Mujeres');
            mu_sp_hombres = mean(sp_hombres);
            sig_sp_hombres = var(sp_hombres);
            y_sp_hombres = pdf('Normal', mu_sp_hombres-3*sig_sp_hombres:0.1:mu_sp_hombres+3*sig_sp_hombres, mu_sp_hombres, sig_sp_hombres);
            plot(mu_sp_hombres-3*sig_sp_hombres:0.1:mu_sp_hombres+3*sig_sp_hombres, y_sp_hombres, 'r')
            mu_sp_mujeres = mean(sp_mujeres);
            sig_sp_mujeres = var(sp_mujeres);
            y_sp_mujeres = pdf('Normal', mu_sp_mujeres-3*sig_sp_mujeres:0.1:mu_sp_mujeres+3*sig_sp_mujeres, mu_sp_mujeres, sig_sp_mujeres);
            plot(mu_sp_mujeres-3*sig_sp_mujeres:0.1:mu_sp_mujeres+3*sig_sp_mujeres, y_sp_mujeres, 'b')
            title('Hora Pico - Hombres y Mujeres');
            xlabel('Promedio Consumo');
            ylabel('Frecuencia');
            legend;
            hold off;

            % Añadir título general a la figura
            sgtitle(sprintf('Ruta: %s, Segmento: %d', ruta, k));
        end
    end
end




%% Porcentaje

% Obtener el número de filas (conductores)
n = size(aa, 1);

% Obtener el número de columnas (segmentos)
s = size(aa, 2);

% Crear una nueva matriz para los porcentajes
percentages = zeros(n, s);

% Recorrer los segmentos
for i = 1:s
    % Obtener el segmento (columna i) de la matriz aa
    segmento = aa(:, i);
    
    % Obtener el valor mínimo y máximo del segmento
    min_val = min(segmento)*0.9;
    max_val = max(segmento)*1.1;
    
    % Escalar los valores del segmento al rango [0, 1]
    scaled_segment = (segmento - min_val) / (max_val - min_val);
    
    % Convertir los valores escalados a porcentajes
    percentages(:, i) = scaled_segment * 100;
end

% Mostrar la nueva matriz de porcentajes
disp(percentages);

%%

consumo = datosBuses.f_2024_04_18.bus_4104.consumoEnergiaRuta{4,1};
tiempo = datosBuses.f_2024_04_18.bus_4104.segmentoP60{4,1}.fechaHoraLecturaDato(1:end-1);
plot(tiempo, consumo);

hold on;
velocidad = datosBuses.f_2024_04_18.bus_4104.velocidadRuta{4,1};
tiempo = linspace(datosBuses.f_2024_04_18.bus_4104.tiempoRuta{4, 1}, datosBuses.f_2024_04_18.bus_4104.tiempoRuta{4, 2}, length(velocidad));
plot(tiempo, velocidad);

%%

%ordenpico = Calculos.ordenarTablaPorElementoVector(Buses.bus_4020.ida.horaValle, 'Promedio consumo', 1, 'ascend' );
%ordenpico = [ordenpico, array2table(cell2mat(ordenpico.("Picos Aceleracion")')')];

% ordenValler = Calculos.ordenarTablaPorElementoVector(Buses.bus_4020.ida.horaValle, 'Promedio velocidad', 1, 'ascend' );

aa= (cell2mat(ordenpico.("Promedio consumo")')');

figure;
bar(aa');
xlabel('Grupo');
ylabel('Promedio consumo');
title('Bar de Promedio consumo por Ruta');

figure;
boxplot(aa');
xlabel('Grupo');
ylabel('Promedio consumo');
title('Boxplot de Promedio consumo por Ruta');

%%
ordenpico = Calculos.ordenarTablaPorElementoVector(Buses.bus_4104.ida.horaPico, 'Picos Aceleracion', 1, 'ascend' );
% Extraer los picos de aceleración
picosAceleracion = ordenpico.("Picos Aceleracion");

% Concatenar todos los datos en un solo vector
concatenatedData = cell2mat(picosAceleracion);

% Crear un vector de agrupación
group = cellfun(@(x, idx) repmat(idx, size(x)), picosAceleracion, num2cell(1:numel(picosAceleracion))', 'UniformOutput', false);
group = cell2mat(group);

% Hacer el boxplot
figure;
boxplot(concatenatedData, group);
xlabel('Grupo');
ylabel('Picos de Aceleración');
title('Boxplot de Picos de Aceleración por Ruta');



%%

% Datos de prueba
datosPrueba = struct('latitud', [4.65, 4.66, 4.67], 'longitud', [-74.05, -74.06, -74.07], 'velocidad', [20, 30, 25]);

% Calcular distancia y velocidad
distanciaPrueba = Calculos.CalcularDistancia(datosPrueba);
velocidadPrueba = Calculos.calcularVelocidadKH(datosPrueba);

% Mostrar las longitudes
disp('--- Verificación de Datos de Prueba ---');
disp(['Longitud de distanciaPrueba: ', num2str(length(distanciaPrueba))]);
disp(['Longitud de velocidadPrueba: ', num2str(length(velocidadPrueba))]);

% Llamar a la función con datos de prueba
puntosSegmentosPrueba = [0.85, 2.1, 4.1, 4.5, 5.2, 8.0, 8.6, 10.5, 13.9];
promediosPrueba = calcularPromedioVelocidadPorSegmentos(datosPrueba, puntosSegmentosPrueba);

% Verificar la longitud de los promedios
disp('Longitud de promediosPrueba:');
disp(length(promediosPrueba));
disp('Valores de promediosPrueba:');
disp(promediosPrueba);


%%

a = ans.("Promedio velocidad")
dataMatrix = cell2mat(a');


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

                

                arrayI(:,k)=Calculos.riesgoCurva2(datosCordenadasSensor,inicio,retorno,ida);

 
                
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

arrayV(:,k)=Calculos.riesgoCurva2(datosCordenadasSensor,retorno,fin,vuelta);

 
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

generarDatos('2024-04-23 12:27:21.434', '2024-04-23 15:36:04.434', '4020', 'Ida')

%%
%Tramas de p20 recolectadas del bus
datosP20 = ImportarDatos.P60("Datos\2024-04-15\4020\log");

%%
% Trama de los eventos del bus
datosEventos = ImportarDatos.Evento19();
[tabla1, tabla2, tabla3, tabla4] = ImportarDatos.Evento19Coordenadas(datosEventos);


%% Graficar ruta
datosSensor = ImportarDatos.Sensor("Datos\2024-04-23\4020");% Importar los datos del telefono
datosCordenadasSensor = ImportarDatos.SensorCordenadas(datosSensor);%Importar coordenadas y stampas de tiempo del telefono

HoraInicio = '2024-04-23 4:47:23.434';
HoraFinal  = '2024-04-23 6sae:40:00.434';

%mis = Map.Ruta(datosCordenadasSensor, HoraInicio, HoraFinal, 'b-',"titulo","ruta");
a=Calculos.riesgoCurva(datosCordenadasSensor, HoraInicio, HoraFinal);
%mis = Map.Ruta(datosCordenadasSensor, HoraFinal, '2024-04-22 6:20:45.434','r-', mis)

%%
d=datosBuses.f_2024_04_22.bus_4104.datosSensor;
t1=datosBuses.f_2024_04_22.bus_4104.tiempoRuta{1, 1};
t2=datosBuses.f_2024_04_22.bus_4104.tiempoRuta{1, 2};
map=Map.Ruta(d,t1,t2,'b-',"titulo4020 semana 1","ruta");


%%

Pcurvas.s4020_2.ida = m;
%%
% marcador=Pcurvas.s4020_1.ida{1,1};
% marcador2=Pcurvas.s4020_1.ida{1,2};
m=Calculos.LcurvasVuelta4020s2();
marcador=m{1,1};
marcador2=m{1,2};
HoraInicio = '2024-04-23 4:25:23.434';
HoraFinal  = '2024-04-23 4:47:00.434';
mapita=Map.Curvatura(datosCordenadasSensor, HoraInicio, HoraFinal,'titulo');

geoscatter(marcador(:, 1), marcador(:, 2), 'Filled', 'Marker', 'x', 'MarkerEdgeColor', 'red', 'DisplayName', 'Posiciones', 'SizeData', 200);
hold on
geoscatter(marcador2(:, 1), marcador2(:, 2), 'Filled', 'Marker', 'o', 'MarkerEdgeColor', 'blue', 'DisplayName', 'Posiciones', 'SizeData', 100);


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

function generarDatos(fechaInicio, fechaFinal, IDbus, Etiqueta, Pcurvas)
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
MapaRuta = Map.Ruta(datosCordenadasSensor, fechaInicio, fechaFinal, 'r-', tituloGrafica, 'Celular');
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

tituloGrafica = [Etiqueta sprintf(' Velocidad filtrada y sin filtar ') General];
% grafica Velocidad celular sin correccion y con correccion
graficaVelocidad = Graficas.velocidadTiempo(datosCordenadasSensor, fechaInicio, fechaFinal, 'MS', tituloGrafica, 'b-' , 'sin filtrar' );
Graficas.velocidadTiempo(datosCordenadasSensor, fechaInicio, fechaFinal,'filtrar', tituloGrafica, 'y-','filtrada', graficaVelocidad);

% tituloGrafica = [Etiqueta sprintf(' Velocidad coordenadas p20 ') General];
% Grafica sts velocidad
% Graficas.velocidadTiempo(datosCordenadasP20, fechaInicio, fechaFinal, 'MS', tituloGrafica, 'b-', 'P20 coordenadas');

%tituloGrafica = [Etiqueta sprintf(' Velocidad  P20 Trama ') General];
% Grafico sts velocidad trama
%Graficas.graficarVelocidadSts(datosP20, fechaInicio, fechaFinal, tituloGrafica, 'b-', 'P20');

tituloGrafica = [Etiqueta sprintf(' Aceleracion Celular ') General];
%Grafica aceleracion celular
graficaAce = Graficas.aceleracionTiempo(datosCordenadasSensor, fechaInicio, fechaFinal, 'normal', tituloGrafica, 'b-', 'sin filtrar');
Graficas.aceleracionTiempo(datosCordenadasSensor, fechaInicio, fechaFinal, 'filtrar', tituloGrafica, 'r-', 'filtrada', graficaAce);


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

hold off;
tituloGrafica = [Etiqueta sprintf(' Aceleracion Celular ') General];
dataFiltrada = ImportarDatos.filtrarDatosPorFechas(datosCordenadasSensor, fechaInicio, fechaFinal);
Map.graficarSegmentosEnMapa(dataFiltrada, Ruta4020Ida, tituloGrafica);

% Grafica giros
tituloGrafica = [Etiqueta sprintf(' Riesgo curvatura ') General];
% Graficas.riesgoVsCurva(datosCordenadasSensor, fechaInicio, fechaFinal, tituloGrafica);

tituloGrafica = [Etiqueta sprintf(' Distancia vs velocidad y segmentos ') General];
% Grafica de distancia vs velocidad
%Graficas.DistanciavsVelocidad3(datosCordenadasSensor,datosP60, fechaInicio, fechaFinal,Ruta4020Ida,tituloGrafica);



%Graficas.analizarAceleraciones(datosCordenadasSensor, fechaInicio, fechaFinal);

curvao = Calculos.riesgoCurva2(datosCordenadasSensor, fechaInicio, fechaFinal, Pcurvas.s4104_1.ida);


%Grafica de distancia vs energia
% Graficas.DistanciavsEnergia(datosP60, fechaInicio, fechaFinal, '1', '2');

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


