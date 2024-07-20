%%

function clasificarKNNGeneral(Rutas)
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
    fprintf('Precisión del modelo KNN: %.2f%%\n', accuracy * 100);

    % Calcular precisión, sensibilidad y especificidad
    TP = sum((y_pred == 1) & (y_test == 1));
    TN = sum((y_pred == 0) & (y_test == 0));
    FP = sum((y_pred == 1) & (y_test == 0));
    FN = sum((y_pred == 0) & (y_test == 1));

    precision = TP / (TP + FP);
    recall = TP / (TP + FN); % También conocida como sensibilidad
    specificity = TN / (TN + FP);
    f1_score = 2 * (precision * recall) / (precision * recall);

    fprintf('Precisión: %.2f%%\n', precision * 100);
    fprintf('Sensibilidad: %.2f%%\n', recall * 100);
    fprintf('Especificidad: %.2f%%\n', specificity * 100);
    fprintf('F1-Score: %.2f\n', f1_score);

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

% Llamar a la función con la estructura Rutas
%clasificarKNNGeneral(Rutas);


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
    num_components = find(cumulative_variance >= 80, 1);

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
    title('Clasificación KNN en el Espacio de los Componentes Principales - Hora Pico');
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
    xlabel('Componentes Principales');
    ylabel('Valor Promedio');
    legend('Hombre', 'Mujer');
    grid on;
end

%clasificarSexoYGraficar(Rutas)

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

%clasificarSexoSinPCA(Rutas);


%% Kmeans

datos_pca = prepararDatosPCA(Rutas);


% Verificar y limpiar datos para asegurarse de que no haya NaN o inf
%datos_pca(any(isnan(datos_pca), 2), :) = [];
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


%clasificarKMeansSinPCA(Rutas);


%% PCA preparacion

function [datos_pca, sexos, horarios] = prepararDatosPCA(Rutas)
% Inicializar listas para almacenar las filas de la matriz de datos, sexo y horario
datos = [];
sexos = [];
horarios = [];

rutas = fieldnames(Rutas);
for i = 1:numel(rutas)
    ruta = rutas{i};
    trayectos = fieldnames(Rutas.(ruta));
    for j = 1:numel(trayectos)
        trayecto = trayectos{j};
        generalTable = Rutas.(ruta).(trayecto).horaValle;

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

            % Añadir el sexo y el horario a sus listas correspondientes
            sexos = [sexos; generalTable.Sexo(k)];
            horarios = [horarios; generalTable.Horario(k)];
        end
    end
end

% Convertir las listas en matrices
datos_pca = datos;
sexos = sexos;
horarios = horarios;
end


[matriz_Data, Msexo, Mhorario] = prepararDatosPCA(Rutas);

Matriz_DB = [matriz_Data, Msexo, Mhorario];
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
%clasificarKMeansSinPCAComparar(Rutas);
%%

function clasificarKMeansCompararSexoYHorario(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];
    sexo_labels = [];
    horario_labels = [];

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

                % Añadir las etiquetas (sexo y horario)
                sexo_labels = [sexo_labels; generalTable.Sexo(k)];
                horario_labels = [horario_labels; generalTable.Horario(k)];
            end
        end
    end

    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];
    sexo_labels(any(isnan(sexo_labels), 2)) = [];
    sexo_labels(any(isinf(sexo_labels), 2)) = [];
    horario_labels(any(isnan(horario_labels), 2)) = [];
    horario_labels(any(isinf(horario_labels), 2)) = [];

    % Normalizar los datos si es necesario
    datos_normalizados = zscore(datos);

    % Definir el número de clusters deseado
    num_clusters = 2; % Asumimos dos clusters para hombres y mujeres

    % Aplicar K-means clustering
    [idx, centroids] = kmeans(datos_normalizados, num_clusters);

    % Comparar con las etiquetas de sexo
    pred_sexo_labels = zeros(size(sexo_labels));

    % Calcular el mapeo correcto de los clusters a las etiquetas de sexo
    if mean(sexo_labels(idx == 1)) < 0.5
        % Cluster 1 corresponde a hombres (0), Cluster 2 corresponde a mujeres (1)
        pred_sexo_labels(idx == 1) = 0;
        pred_sexo_labels(idx == 2) = 1;
    else
        % Cluster 1 corresponde a mujeres (1), Cluster 2 corresponde a hombres (0)
        pred_sexo_labels(idx == 1) = 1;
        pred_sexo_labels(idx == 2) = 0;
    end

    % Comparar con las etiquetas de horario
    pred_horario_labels = zeros(size(horario_labels));

    % Calcular el mapeo correcto de los clusters a las etiquetas de horario
    if mean(horario_labels(idx == 1)) < 1
        % Cluster 1 corresponde a hora pico (0), Cluster 2 corresponde a hora valle (1) o flujo libre (2)
        pred_horario_labels(idx == 1) = 0;
        pred_horario_labels(idx == 2) = 1;
    else
        % Cluster 1 corresponde a hora valle (1) o flujo libre (2), Cluster 2 corresponde a hora pico (0)
        pred_horario_labels(idx == 1) = 1;
        pred_horario_labels(idx == 2) = 0;
    end

    % Matriz de Confusión para sexo
    figure;
    cm_sexo = confusionchart(sexo_labels, pred_sexo_labels);
    cm_sexo.Title = 'Matriz de Confusión para la Clasificación K-means (Sexo)';
    cm_sexo.RowSummary = 'row-normalized';
    cm_sexo.ColumnSummary = 'column-normalized';

    % Calcular precisión, sensibilidad y especificidad para sexo
    TP = sum((pred_sexo_labels == 1) & (sexo_labels == 1));
    TN = sum((pred_sexo_labels == 0) & (sexo_labels == 0));
    FP = sum((pred_sexo_labels == 1) & (sexo_labels == 0));
    FN = sum((pred_sexo_labels == 0) & (sexo_labels == 1));

    precision_sexo = TP / (TP + FP);
    sensibilidad_sexo = TP / (TP + FN); % También conocida como recall
    especificidad_sexo = TN / (TN + FP);

    % Mostrar las métricas para sexo
    fprintf('Precisión (Sexo): %.2f%%\n', precision_sexo * 100);
    fprintf('Sensibilidad (Sexo): %.2f%%\n', sensibilidad_sexo * 100);
    fprintf('Especificidad (Sexo): %.2f%%\n', especificidad_sexo * 100);

    % Matriz de Confusión para horario
    figure;
    cm_horario = confusionchart(horario_labels, pred_horario_labels);
    cm_horario.Title = 'Matriz de Confusión para la Clasificación K-means (Horario)';
    cm_horario.RowSummary = 'row-normalized';
    cm_horario.ColumnSummary = 'column-normalized';

    % Calcular precisión, sensibilidad y especificidad para horario
    TP_horario = sum((pred_horario_labels == 1) & (horario_labels == 1));
    TN_horario = sum((pred_horario_labels == 0) & (horario_labels == 0));
    FP_horario = sum((pred_horario_labels == 1) & (horario_labels == 0));
    FN_horario = sum((pred_horario_labels == 0) & (horario_labels == 1));

    precision_horario = TP_horario / (TP_horario + FP_horario);
    sensibilidad_horario = TP_horario / (TP_horario + FN_horario); % También conocida como recall
    especificidad_horario = TN_horario / (TN_horario + FP_horario);

    % Mostrar las métricas para horario
    fprintf('Precisión (Horario): %.2f%%\n', precision_horario * 100);
    fprintf('Sensibilidad (Horario): %.2f%%\n', sensibilidad_horario * 100);
    fprintf('Especificidad (Horario): %.2f%%\n', especificidad_horario * 100);

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
%clasificarKMeansCompararSexoYHorario(Rutas);


%% Hora valle sin pca 2 clusters comparacion con horario y sexo

function kmeansSinPCAHoraValle(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];
    sexo_labels = [];
    horario_labels = [];

    % Definir nombres de características
    nombres_caracteristicas = {
        'Promedio Consumo', ...
        'Promedio Velocidad', ...
        'Aceleraciones por Km', ...
        'Desaceleraciones por Km', ...
        'Aceleración Promedio', ...
        'Desaceleracion Promedio', ...
        'Riesgo Curva Promedio'
        };

    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};
            generalTable = Rutas.(ruta).(trayecto).horaValle; % Usar horaValle

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

                % Añadir las etiquetas (sexo y horario)
                sexo_labels = [sexo_labels; generalTable.Sexo(k)];
                horario_labels = [horario_labels; generalTable.Horario(k)];
            end
        end
    end

    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];
    sexo_labels(any(isnan(sexo_labels), 2)) = [];
    sexo_labels(any(isinf(sexo_labels), 2)) = [];
    horario_labels(any(isnan(horario_labels), 2)) = [];
    horario_labels(any(isinf(horario_labels), 2)) = [];

    % Normalizar los datos si es necesario
    datos_normalizados = zscore(datos);

    % Definir el número de clusters deseado
    num_clusters = 2; % Asumimos dos clusters para hombres y mujeres

    % Aplicar K-means clustering
    [idx, centroids] = kmeans(datos_normalizados, num_clusters);

    % Comparar con las etiquetas de sexo
    pred_sexo_labels = zeros(size(sexo_labels));

    % Calcular el mapeo correcto de los clusters a las etiquetas de sexo
    if mean(sexo_labels(idx == 1)) < 0.5
        % Cluster 1 corresponde a hombres (0), Cluster 2 corresponde a mujeres (1)
        pred_sexo_labels(idx == 1) = 0;
        pred_sexo_labels(idx == 2) = 1;
    else
        % Cluster 1 corresponde a mujeres (1), Cluster 2 corresponde a hombres (0)
        pred_sexo_labels(idx == 1) = 1;
        pred_sexo_labels(idx == 2) = 0;
    end

    % Comparar con las etiquetas de horario
    pred_horario_labels = zeros(size(horario_labels));

    % Calcular el mapeo correcto de los clusters a las etiquetas de horario
    if mean(horario_labels(idx == 1)) < 1
        % Cluster 1 corresponde a hora pico (0), Cluster 2 corresponde a hora valle (1) o flujo libre (2)
        pred_horario_labels(idx == 1) = 0;
        pred_horario_labels(idx == 2) = 1;
    else
        % Cluster 1 corresponde a hora valle (1) o flujo libre (2), Cluster 2 corresponde a hora pico (0)
        pred_horario_labels(idx == 1) = 1;
        pred_horario_labels(idx == 2) = 0;
    end

    % Matriz de Confusión para sexo
    figure;
    cm_sexo = confusionchart(sexo_labels, pred_sexo_labels);
    cm_sexo.Title = 'Matriz de Confusión para la Clasificación K-means (Sexo)';
    cm_sexo.RowSummary = 'row-normalized';
    cm_sexo.ColumnSummary = 'column-normalized';

    % Calcular precisión, sensibilidad y especificidad para sexo
    TP = sum((pred_sexo_labels == 1) & (sexo_labels == 1));
    TN = sum((pred_sexo_labels == 0) & (sexo_labels == 0));
    FP = sum((pred_sexo_labels == 1) & (sexo_labels == 0));
    FN = sum((pred_sexo_labels == 0) & (sexo_labels == 1));

    precision_sexo = TP / (TP + FP);
    sensibilidad_sexo = TP / (TP + FN); % También conocida como recall
    especificidad_sexo = TN / (TN + FP);

    % Mostrar las métricas para sexo
    fprintf('Precisión (Sexo): %.2f%%\n', precision_sexo * 100);
    fprintf('Sensibilidad (Sexo): %.2f%%\n', sensibilidad_sexo * 100);
    fprintf('Especificidad (Sexo): %.2f%%\n', especificidad_sexo * 100);

    % Matriz de Confusión para horario
    figure;
    cm_horario = confusionchart(horario_labels, pred_horario_labels);
    cm_horario.Title = 'Matriz de Confusión para la Clasificación K-means (Horario)';
    cm_horario.RowSummary = 'row-normalized';
    cm_horario.ColumnSummary = 'column-normalized';

    % Calcular precisión, sensibilidad y especificidad para horario
    TP_horario = sum((pred_horario_labels == 1) & (horario_labels == 1));
    TN_horario = sum((pred_horario_labels == 0) & (horario_labels == 0));
    FP_horario = sum((pred_horario_labels == 1) & (horario_labels == 0));
    FN_horario = sum((pred_horario_labels == 0) & (horario_labels == 1));

    precision_horario = TP_horario / (TP_horario + FP_horario);
    sensibilidad_horario = TP_horario / (TP_horario + FN_horario); % También conocida como recall
    especificidad_horario = TN_horario / (TN_horario + FP_horario);

    % Mostrar las métricas para horario
    fprintf('Precisión (Horario): %.2f%%\n', precision_horario * 100);
    fprintf('Sensibilidad (Horario): %.2f%%\n', sensibilidad_horario * 100);
    fprintf('Especificidad (Horario): %.2f%%\n', especificidad_horario * 100);

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
kmeansSinPCAHoraValle(Rutas);


%%


function kmeansPCAHoraValle(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];
    sexo_labels = [];

    % Definir nombres de características
    nombres_caracteristicas = {
        'Promedio Consumo', ...
        'Promedio Velocidad', ...
        'Aceleraciones por Km', ...
        'Desaceleraciones por Km', ...
        'Aceleración Promedio', ...
        'Desaceleracion Promedio', ...
        'Riesgo Curva Promedio'
        };

    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};
            generalTable = Rutas.(ruta).(trayecto).horaValle; % Usar horaValle

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

                % Añadir las etiquetas (sexo)
                sexo_labels = [sexo_labels; generalTable.Sexo(k)];
            end
        end
    end

    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];
    sexo_labels(any(isnan(sexo_labels), 2)) = [];
    sexo_labels(any(isinf(sexo_labels), 2)) = [];

    % Normalizar los datos
    datos_normalizados = zscore(datos);

    % Aplicar PCA
    [coeff, score, ~, ~, explained] = pca(datos_normalizados);

    % Determinar cuántos componentes principales retener (por ejemplo, 90% de varianza explicada)
    cumulative_variance = cumsum(explained);
    num_components = find(cumulative_variance >= 90, 1);

    % Proyectar los datos en el espacio de los componentes principales retenidos
    datos_pca_reducidos = score(:, 1:num_components);

    % Definir el número de clusters deseado
    num_clusters = 2; % Asumimos dos clusters para hombres y mujeres

    % Aplicar K-means clustering
    [idx, centroids] = kmeans(datos_pca_reducidos, num_clusters);

    % Comparar con las etiquetas de sexo
    pred_sexo_labels = zeros(size(sexo_labels));

    % Calcular el mapeo correcto de los clusters a las etiquetas de sexo
    if mean(sexo_labels(idx == 1)) < 0.5
        % Cluster 1 corresponde a hombres (0), Cluster 2 corresponde a mujeres (1)
        pred_sexo_labels(idx == 1) = 0;
        pred_sexo_labels(idx == 2) = 1;
    else
        % Cluster 1 corresponde a mujeres (1), Cluster 2 corresponde a hombres (0)
        pred_sexo_labels(idx == 1) = 1;
        pred_sexo_labels(idx == 2) = 0;
    end

    % Matriz de Confusión para sexo
    figure;
    cm_sexo = confusionchart(sexo_labels, pred_sexo_labels);
    cm_sexo.Title = 'Matriz de Confusión para la Clasificación K-means (Sexo)';
    cm_sexo.RowSummary = 'row-normalized';
    cm_sexo.ColumnSummary = 'column-normalized';

    % Calcular precisión, sensibilidad y especificidad para sexo
    TP = sum((pred_sexo_labels == 1) & (sexo_labels == 1));
    TN = sum((pred_sexo_labels == 0) & (sexo_labels == 0));
    FP = sum((pred_sexo_labels == 1) & (sexo_labels == 0));
    FN = sum((pred_sexo_labels == 0) & (sexo_labels == 1));

    precision_sexo = TP / (TP + FP);
    sensibilidad_sexo = TP / (TP + FN); % También conocida como recall
    especificidad_sexo = TN / (TN + FP);

    % Mostrar las métricas para sexo
    fprintf('Precisión (Sexo): %.2f%%\n', precision_sexo * 100);
    fprintf('Sensibilidad (Sexo): %.2f%%\n', sensibilidad_sexo * 100);
    fprintf('Especificidad (Sexo): %.2f%%\n', especificidad_sexo * 100);

    % Visualización de los clusters en el espacio de las dos primeras componentes principales
    figure;
    gscatter(datos_pca_reducidos(:, 1), datos_pca_reducidos(:, 2), idx, 'br', 'xo');
    title('Clustering con K-means después de PCA');
    xlabel('Componente Principal 1');
    ylabel('Componente Principal 2');
    legend('Cluster 1', 'Cluster 2');

    % Visualización 3D de los clusters si hay al menos 3 componentes principales
    if size(datos_pca_reducidos, 2) >= 3
        figure;
        scatter3(datos_pca_reducidos(:, 1), datos_pca_reducidos(:, 2), datos_pca_reducidos(:, 3), 10, idx, 'filled');
        title('Clustering con K-means después de PCA (3D)');
        xlabel('Componente Principal 1');
        ylabel('Componente Principal 2');
        zlabel('Componente Principal 3');
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
    title('Promedio de Características por Clúster después de PCA');
    xlabel('Características');
    ylabel('Valor Promedio');
    xticklabels(nombres_caracteristicas);
    legend('Cluster 1', 'Cluster 2');
    grid on;
end

% Llamar a la función con la estructura Rutas
%kmeansPCAHoraValle(Rutas);

%%


function kmeansHoraPico3Clusters(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];

    % Definir nombres de características
    nombres_caracteristicas = {
        'Promedio Consumo', ...
        'Promedio Velocidad', ...
        'Aceleraciones por Km', ...
        'Desaceleraciones por Km', ...
        'Aceleración Promedio', ...
        'Desaceleracion Promedio', ...
        'Riesgo Curva Promedio'
        };

    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};
            generalTable = Rutas.(ruta).(trayecto).horaPico; % Usar horaPico

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

    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];

    % Normalizar los datos
    datos_normalizados = zscore(datos);

    % Definir el número de clusters deseado
    num_clusters = 3; % Tres clusters para horaPico

    % Aplicar K-means clustering
    [idx, centroids] = kmeans(datos_normalizados, num_clusters);

    % Visualización de los clusters en el espacio de las dos primeras características
    figure;
    gscatter(datos_normalizados(:, 1), datos_normalizados(:, 2), idx, 'rgb', 'ox+');
    title('Clustering con K-means sin PCA - Hora Pico');
    xlabel(nombres_caracteristicas{1});
    ylabel(nombres_caracteristicas{2});
    legend('Cluster 1', 'Cluster 2', 'Cluster 3');

    % Visualización 3D de los clusters si hay al menos 3 características
    if size(datos_normalizados, 2) >= 3
        figure;
        scatter3(datos_normalizados(:, 1), datos_normalizados(:, 2), datos_normalizados(:, 3), 10, idx, 'filled');
        title('Clustering con K-means sin PCA (3D) - Hora Pico');
        xlabel(nombres_caracteristicas{1});
        ylabel(nombres_caracteristicas{2});
        zlabel(nombres_caracteristicas{3});
        legend('Cluster 1', 'Cluster 2', 'Cluster 3');
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
    title('Promedio de Características por Clúster sin PCA - Hora Pico');
    xlabel('Características');
    ylabel('Valor Promedio');
    xticklabels(nombres_caracteristicas);
    legend('Cluster 1', 'Cluster 2', 'Cluster 3');
    grid on;
end

% Llamar a la función con la estructura Rutas
%kmeansHoraPico3Clusters(Rutas);


%%

function clasificarKMeansConPCAComparar(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];
    sexo_labels = [];
    horario_labels = [];

    % Definir nombres de características
    nombres_caracteristicas = {
        'Promedio Consumo', ...
        'Promedio Velocidad', ...
        'Aceleraciones por Km', ...
        'Desaceleraciones por Km', ...
        'Aceleración Promedio', ...
        'Desaceleracion Promedio', ...
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

                % Añadir las etiquetas (sexo y horario)
                sexo_labels = [sexo_labels; generalTable.Sexo(k)];
                horario_labels = [horario_labels; generalTable.Horario(k)];
            end
        end
    end

    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];
    sexo_labels(any(isnan(sexo_labels), 2)) = [];
    sexo_labels(any(isinf(sexo_labels), 2)) = [];
    horario_labels(any(isnan(horario_labels), 2)) = [];
    horario_labels(any(isinf(horario_labels), 2)) = [];

    % Normalizar los datos
    datos_normalizados = zscore(datos);

    % Aplicar PCA
    [coeff, score, ~, ~, explained] = pca(datos_normalizados);

    % Determinar cuántos componentes principales retener (por ejemplo, 90% de varianza explicada)
    cumulative_variance = cumsum(explained);
    num_components = find(cumulative_variance >= 90, 1);

    % Proyectar los datos en el espacio de los componentes principales retenidos
    datos_pca_reducidos = score(:, 1:num_components);

    % Definir el número de clusters deseado
    num_clusters = 2; % Asumimos dos clusters para hombres y mujeres

    % Aplicar K-means clustering
    [idx, centroids] = kmeans(datos_pca_reducidos, num_clusters);

    % Comparar con las etiquetas de sexo
    pred_sexo_labels = zeros(size(sexo_labels));

    % Calcular el mapeo correcto de los clusters a las etiquetas de sexo
    if mean(sexo_labels(idx == 1)) < 0.5
        % Cluster 1 corresponde a hombres (0), Cluster 2 corresponde a mujeres (1)
        pred_sexo_labels(idx == 1) = 0;
        pred_sexo_labels(idx == 2) = 1;
    else
        % Cluster 1 corresponde a mujeres (1), Cluster 2 corresponde a hombres (0)
        pred_sexo_labels(idx == 1) = 1;
        pred_sexo_labels(idx == 2) = 0;
    end

    % Comparar con las etiquetas de horario
    pred_horario_labels = zeros(size(horario_labels));

    % Calcular el mapeo correcto de los clusters a las etiquetas de horario
    if mean(horario_labels(idx == 1)) < 1
        % Cluster 1 corresponde a hora pico (0), Cluster 2 corresponde a hora valle (1) o flujo libre (2)
        pred_horario_labels(idx == 1) = 0;
        pred_horario_labels(idx == 2) = 1;
    else
        % Cluster 1 corresponde a hora valle (1) o flujo libre (2), Cluster 2 corresponde a hora pico (0)
        pred_horario_labels(idx == 1) = 1;
        pred_horario_labels(idx == 2) = 0;
    end

    % Matriz de Confusión para sexo
    figure;
    cm_sexo = confusionchart(sexo_labels, pred_sexo_labels);
    cm_sexo.Title = 'Matriz de Confusión para la Clasificación K-means (Sexo)';
    cm_sexo.RowSummary = 'row-normalized';
    cm_sexo.ColumnSummary = 'column-normalized';

    % Calcular precisión, sensibilidad y especificidad para sexo
    TP = sum((pred_sexo_labels == 1) & (sexo_labels == 1));
    TN = sum((pred_sexo_labels == 0) & (sexo_labels == 0));
    FP = sum((pred_sexo_labels == 1) & (sexo_labels == 0));
    FN = sum((pred_sexo_labels == 0) & (sexo_labels == 1));

    precision_sexo = TP / (TP + FP);
    sensibilidad_sexo = TP / (TP + FN); % También conocida como recall
    especificidad_sexo = TN / (TN + FP);

    % Mostrar las métricas para sexo
    fprintf('Precisión (Sexo): %.2f%%\n', precision_sexo * 100);
    fprintf('Sensibilidad (Sexo): %.2f%%\n', sensibilidad_sexo * 100);
    fprintf('Especificidad (Sexo): %.2f%%\n', especificidad_sexo * 100);

    % Matriz de Confusión para horario
    figure;
    cm_horario = confusionchart(horario_labels, pred_horario_labels);
    cm_horario.Title = 'Matriz de Confusión para la Clasificación K-means (Horario)';
    cm_horario.RowSummary = 'row-normalized';
    cm_horario.ColumnSummary = 'column-normalized';

    % Calcular precisión, sensibilidad y especificidad para horario
    TP_horario = sum((pred_horario_labels == 1) & (horario_labels == 1));
    TN_horario = sum((pred_horario_labels == 0) & (horario_labels == 0));
    FP_horario = sum((pred_horario_labels == 1) & (horario_labels == 0));
    FN_horario = sum((pred_horario_labels == 0) & (horario_labels == 1));

    precision_horario = TP_horario / (TP_horario + FP_horario);
    sensibilidad_horario = TP_horario / (TP_horario + FN_horario); % También conocida como recall
    especificidad_horario = TN_horario / (TN_horario + FP_horario);

    % Mostrar las métricas para horario
    fprintf('Precisión (Horario): %.2f%%\n', precision_horario * 100);
    fprintf('Sensibilidad (Horario): %.2f%%\n', sensibilidad_horario * 100);
    fprintf('Especificidad (Horario): %.2f%%\n', especificidad_horario * 100);

    % Visualización de los clusters en el espacio de las dos primeras componentes principales
    figure;
    gscatter(datos_pca_reducidos(:, 1), datos_pca_reducidos(:, 2), idx, 'br', 'xo');
    title('Clustering con K-means después de PCA');
    xlabel('Componente Principal 1');
    ylabel('Componente Principal 2');
    legend('Cluster 1', 'Cluster 2');

    % Visualización 3D de los clusters si hay al menos 3 componentes principales
    if size(datos_pca_reducidos, 2) >= 3
        figure;
        scatter3(datos_pca_reducidos(:, 1), datos_pca_reducidos(:, 2), datos_pca_reducidos(:, 3), 10, idx, 'filled');
        title('Clustering con K-means después de PCA (3D)');
        xlabel('Componente Principal 1');
        ylabel('Componente Principal 2');
        zlabel('Componente Principal 3');
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
    title('Promedio de Características por Clúster después de PCA');
    xlabel('Características');
    ylabel('Valor Promedio');
    xticklabels(nombres_caracteristicas);
    legend('Cluster 1', 'Cluster 2');
    grid on;
end

% Llamar a la función con la estructura Rutas
%clasificarKMeansConPCAComparar(Rutas);


%%

function analizarContribucionesPCA(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];
    sexo_labels = [];
    horario_labels = [];

    % Definir nombres de características
    nombres_caracteristicas = {
        'Promedio Consumo', ...
        'Promedio Velocidad', ...
        'Aceleraciones por Km', ...
        'Desaceleraciones por Km', ...
        'Aceleración Promedio', ...
        'Desaceleracion Promedio', ...
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

                % Añadir las etiquetas (sexo y horario)
                sexo_labels = [sexo_labels; generalTable.Sexo(k)];
                horario_labels = [horario_labels; generalTable.Horario(k)];
            end
        end
    end

    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];

    % Normalizar los datos
    datos_normalizados = zscore(datos);

    % Aplicar PCA
    [coeff, score, ~, ~, explained] = pca(datos_normalizados);

    % Mostrar los coeficientes de los componentes principales
    disp('Coeficientes de los componentes principales:');
    disp(array2table(coeff, 'VariableNames', nombres_caracteristicas));

    % Graficar la varianza explicada por cada componente principal
    figure;
    pareto(explained);
    xlabel('Componentes principales');
    ylabel('Varianza explicada (%)');
    title('Varianza explicada por cada componente principal');

    % Graficar los coeficientes de los componentes principales
    figure;
    num_components = size(coeff, 2);
    for i = 1:num_components
        subplot(num_components, 1, i);
        bar(coeff(:, i));
        ylabel(['PC', num2str(i)]);
        if i == num_components
            xticks(1:numel(nombres_caracteristicas));
            xticklabels(nombres_caracteristicas);
            xtickangle(45);
        else
            set(gca, 'XTick', []);
        end
    end

    % Añadir un título general a la figura
    sgtitle('Coeficientes de los componentes principales');
end

% Llamar a la función con la estructura Rutas
%analizarContribucionesPCA(Rutas);


%%

function analizarContribucionesPCAHoraPico(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];
    nombres_caracteristicas = {
        'Promedio Consumo', ...
        'Promedio Velocidad', ...
        'Aceleraciones por Km', ...
        'Desaceleraciones por Km', ...
        'Aceleración Promedio', ...
        'Desaceleracion Promedio', ...
        'Riesgo Curva Promedio'
    };

    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};
            generalTable = Rutas.(ruta).(trayecto).horaPico; % Solo horaPico

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

    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];

    % Normalizar los datos
    datos_normalizados = zscore(datos);

    % Aplicar PCA
    [coeff, score, ~, ~, explained] = pca(datos_normalizados);

    % Mostrar los coeficientes de los componentes principales
    disp('Coeficientes de los componentes principales:');
    disp(array2table(coeff, 'VariableNames', nombres_caracteristicas));

    % Graficar la varianza explicada por cada componente principal
    figure;
    pareto(explained);
    xlabel('Componentes principales');
    ylabel('Varianza explicada (%)');
    title('Varianza explicada por cada componente principal');

    % Graficar los coeficientes de los componentes principales
    figure;
    num_components = size(coeff, 2);
    for i = 1:num_components
        subplot(num_components, 1, i);
        bar(coeff(:, i));
        ylabel(['PC', num2str(i)]);
        if i == num_components
            xticks(1:numel(nombres_caracteristicas));
            xticklabels(nombres_caracteristicas);
            xtickangle(45);
        else
            set(gca, 'XTick', []);
        end
    end

    % Añadir un título general a la figura
    sgtitle('Coeficientes de los componentes principales');
end

% Llamar a la función con la estructura Rutas
%analizarContribucionesPCAHoraPico(Rutas);



%%

function clasificarKMeansCompararSexo(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];
    sexo_labels = [];

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
            generalTable = Rutas.(ruta).(trayecto).horaPico; % Solo horaPico

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

                % Añadir las etiquetas (sexo)
                sexo_labels = [sexo_labels; generalTable.Sexo(k)];
            end
        end
    end

    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];
    sexo_labels(any(isnan(sexo_labels), 2)) = [];
    sexo_labels(any(isinf(sexo_labels), 2)) = [];

    % Normalizar los datos si es necesario
    datos_normalizados = zscore(datos);

    % Definir el número de clusters deseado
    num_clusters = 3; % Ajuste para cuatro clusters

    % Aplicar K-means clustering
    [idx, centroids] = kmeans(datos_normalizados, num_clusters);

    % Comparar con las etiquetas de sexo
    pred_sexo_labels = zeros(size(sexo_labels));

    % Calcular el mapeo correcto de los clusters a las etiquetas de sexo
    % Dado que ahora tenemos 4 clusters, debemos asignar de manera más compleja
    % Aquí simplemente se asigna en base a la media, pero puede requerir más lógica
    for c = 1:num_clusters
        if mean(sexo_labels(idx == c)) < 0.5
            pred_sexo_labels(idx == c) = 0;
        else
            pred_sexo_labels(idx == c) = 1;
        end
    end

    % Matriz de Confusión para sexo
    figure;
    cm_sexo = confusionchart(sexo_labels, pred_sexo_labels);
    cm_sexo.Title = 'Matriz de Confusión para la Clasificación K-means (Sexo)';
    cm_sexo.RowSummary = 'row-normalized';
    cm_sexo.ColumnSummary = 'column-normalized';

    % Calcular precisión, sensibilidad y especificidad para sexo
    TP = sum((pred_sexo_labels == 1) & (sexo_labels == 1));
    TN = sum((pred_sexo_labels == 0) & (sexo_labels == 0));
    FP = sum((pred_sexo_labels == 1) & (sexo_labels == 0));
    FN = sum((pred_sexo_labels == 0) & (sexo_labels == 1));

    precision_sexo = TP / (TP + FP);
    sensibilidad_sexo = TP / (TP + FN); % También conocida como recall
    especificidad_sexo = TN / (TN + FP);

    % Mostrar las métricas para sexo
    fprintf('Precisión (Sexo): %.2f%%\n', precision_sexo * 100);
    fprintf('Sensibilidad (Sexo): %.2f%%\n', sensibilidad_sexo * 100);
    fprintf('Especificidad (Sexo): %.2f%%\n', especificidad_sexo * 100);

    % Visualización de los clusters en el espacio de las dos primeras características
    figure;
    gscatter(datos_normalizados(:, 1), datos_normalizados(:, 2), idx, 'brgy', 'xo+*');
    title('Clustering con K-means sin PCA');
    xlabel(nombres_caracteristicas{1});
    ylabel(nombres_caracteristicas{2});
    legend('Cluster 1', 'Cluster 2', 'Cluster 3', 'Cluster 4');

    % Visualización 3D de los clusters si hay al menos 3 características
    if size(datos_normalizados, 2) >= 3
        figure;
        scatter3(datos_normalizados(:, 1), datos_normalizados(:, 2), datos_normalizados(:, 3), 10, idx, 'filled');
        title('Clustering con K-means sin PCA (3D)');
        xlabel(nombres_caracteristicas{1});
        ylabel(nombres_caracteristicas{2});
        zlabel(nombres_caracteristicas{3});
        legend('Cluster 1', 'Cluster 2', 'Cluster 3', 'Cluster 4');
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
    legend('Cluster 1', 'Cluster 2', 'Cluster 3', 'Cluster 4');
    grid on;
end

% Llamar a la función con la estructura Rutas
%clasificarKMeansCompararSexo(Rutas);



%%


function clasificarKMeansConPCA(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];
    sexo_labels = [];
    horario_labels = [];

    % Definir nombres de características
    nombres_caracteristicas = {
        'Promedio Consumo', ...
        'Promedio Velocidad', ...
        'Aceleraciones por Km', ...
        'Desaceleraciones por Km', ...
        'Aceleración Promedio', ...
        'Desaceleracion Promedio', ...
        'Riesgo Curva Promedio'
    };

    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};
            generalTable = Rutas.(ruta).(trayecto).horaPico; % Solo horaPico

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

    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];

    % Normalizar los datos
    datos_normalizados = zscore(datos);

    % Aplicar PCA
    [coeff, score, ~, ~, explained] = pca(datos_normalizados);

    % Determinar cuántos componentes principales retener (por ejemplo, 90% de varianza explicada)
    cumulative_variance = cumsum(explained);
    num_components = find(cumulative_variance >= 90, 1);

    % Proyectar los datos en el espacio de los componentes principales retenidos
    datos_pca_reducidos = score(:, 1:num_components);

    % Definir el número de clusters deseado
    num_clusters = 4; % Ajuste para cuatro clusters

    % Aplicar K-means clustering
    [idx, centroids] = kmeans(datos_pca_reducidos, num_clusters);

    % Visualización de los clusters en el espacio de las dos primeras componentes principales
    figure;
    gscatter(datos_pca_reducidos(:, 1), datos_pca_reducidos(:, 2), idx, 'brgy', 'xo+*');
    title('Clustering con K-means después de PCA');
    xlabel('Componente Principal 1');
    ylabel('Componente Principal 2');
    legend('Cluster 1', 'Cluster 2', 'Cluster 3', 'Cluster 4');

    % Visualización 3D de los clusters si hay al menos 3 componentes principales
    if size(datos_pca_reducidos, 2) >= 3
        figure;
        scatter3(datos_pca_reducidos(:, 1), datos_pca_reducidos(:, 2), datos_pca_reducidos(:, 3), 10, idx, 'filled');
        title('Clustering con K-means después de PCA (3D)');
        xlabel('Componente Principal 1');
        ylabel('Componente Principal 2');
        zlabel('Componente Principal 3');
        legend('Cluster 1', 'Cluster 2', 'Cluster 3', 'Cluster 4');
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
    title('Promedio de Características por Clúster después de PCA');
    xlabel('Características');
    ylabel('Valor Promedio');
    xticklabels(nombres_caracteristicas);
    legend('Cluster 1', 'Cluster 2', 'Cluster 3', 'Cluster 4');
    grid on;
end

% Llamar a la función con la estructura Rutas
%clasificarKMeansConPCA(Rutas);



%%

function determinarNumeroOptimoClustersSinPCA(Rutas)
    % Preparar los datos
    datos = prepararDatosParaClustering(Rutas);
    
    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];

    % Normalizar los datos
    datos_normalizados = zscore(datos);

    % Definir el rango de k a probar
    k_range = 2:10;

    % Inicializar variables para almacenar los valores silhouette
    silh_values = zeros(max(k_range), 1);

    for k = k_range
        % Aplicar K-means clustering
        [idx, ~] = kmeans(datos_normalizados, k, 'Replicates', 5);
        
        % Calcular los valores silhouette para los clusters
        s = silhouette(datos_normalizados, idx);
        
        % Almacenar el promedio de los valores silhouette
        silh_values(k) = mean(s);
    end

    % Determinar el número óptimo de clusters (el valor de k con el silhouette más alto)
    [max_silhouette, opt_k] = max(silh_values);

    % Mostrar el número óptimo de clusters
    fprintf('Número óptimo de clusters: %d\n', opt_k);
    fprintf('Valor de silhouette para %d clusters: %.2f\n', opt_k, max_silhouette);

    % Graficar los valores silhouette promedio para cada k
    figure;
    plot(k_range, silh_values(k_range), 'o-', 'LineWidth', 2);
    xlabel('Número de clusters (k)');
    ylabel('Valor promedio de silhouette');
    title('Determinar el número óptimo de clusters usando el método del silhouette');
    grid on;
end

function datos = prepararDatosParaClustering(Rutas)
    % Inicializar una lista para almacenar las filas de la matriz de datos
    datos = [];

    rutas = fieldnames(Rutas);
    for i = 1:numel(rutas)
        ruta = rutas{i};
        trayectos = fieldnames(Rutas.(ruta));
        for j = 1:numel(trayectos)
            trayecto = trayectos{j};
            generalTable = Rutas.(ruta).(trayecto).horaValle;

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
    datos = (datos);
end

% Ejemplo de uso:
%determinarNumeroOptimoClustersSinPCA(Rutas);


%% Siluette con PCA

function determinarNumeroOptimoClusters(Rutas)
    % Preparar los datos para PCA
    [datos, ~, ~] = prepararDatosPCA(Rutas);
    
    % Verificar y limpiar datos para asegurarse de que no haya NaN o inf
    datos(any(isnan(datos), 2), :) = [];
    datos(any(isinf(datos), 2), :) = [];

    % Normalizar los datos
    datos_normalizados = zscore(datos);

    % Aplicar PCA
    [coeff, score, latent, ~, explained] = pca(datos_normalizados);

    % Determinar cuántos componentes principales retener (por ejemplo, 90% de varianza explicada)
    cumulative_variance = cumsum(explained);
    num_components = find(cumulative_variance >= 90, 1);

    % Proyectar los datos en el espacio de los componentes principales retenidos
    datos_pca_reducidos = score(:, 1:num_components);

    % Definir el rango de k a probar
    k_range = 2:10;

    % Inicializar variables para almacenar los valores silhouette
    silh_values = zeros(max(k_range), 1);

    for k = k_range
        % Aplicar K-means clustering
        [idx, ~] = kmeans(datos_pca_reducidos, k, 'Replicates', 5);
        
        % Calcular los valores silhouette para los clusters
        s = silhouette(datos_pca_reducidos, idx);
        
        % Almacenar el promedio de los valores silhouette
        silh_values(k) = mean(s);
    end

    % Determinar el número óptimo de clusters (el valor de k con el silhouette más alto)
    [~, opt_k] = max(silh_values);

    % Mostrar el número óptimo de clusters
    fprintf('Número óptimo de clusters: %d\n', opt_k);

    % Graficar los valores silhouette promedio para cada k
    figure;
    plot(k_range, silh_values(k_range), 'o-', 'LineWidth', 2);
    xlabel('Número de clusters (k)');
    ylabel('Valor promedio de silhouette');
    title('Determinar el número óptimo de clusters usando el método del silhouette');
    grid on;
end

% Ejemplo de uso:
%determinarNumeroOptimoClusters(Rutas);


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
%clasificarKMeansHoraPico(Rutas);


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
