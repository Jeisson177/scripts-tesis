

% Filtrar la tabla para excluir el Bus "bus_4012"
Tabla = Tabla(~strcmp(Tabla.Bus, 'bus_4012'), :);

% Lista de conductores únicos
ids = unique(Tabla.ID);

% Variables de interés para graficar
xVars = {'AcelePorcen1', 'Velocidad', 'DurPosMean', 'MagPosMax', 'DurNegMean', 'DurNegMax', 'DurPosMean', ''};
yVars = {'AcelePorcen2', 'MagPosMax', 'DurNegMean', 'AcelePorcen2', 'MagNegMean', 'MagNegMax', 'MagPosMean', ''};

% Preparar datos: calcular el promedio por conductor
numConductores = length(ids);
dataX = zeros(numConductores, length(xVars));
dataY = zeros(numConductores, length(yVars));
sexos = cell(numConductores, 1); % Almacenar el sexo de cada conductor

for i = 1:numConductores
    id = ids(i);
    
    % Filtrar la tabla por ese conductor
    T_c = Tabla(Tabla.ID == id, :);
    
    % Guardar el sexo del conductor (usamos el primero, asumiendo que es el mismo para todas las filas del conductor)
    sexoConductor = T_c.Sexo{1};
    % Validar que el sexo sea "M" o "H", si no, asignar un valor por defecto
    if ~ismember(sexoConductor, {'M', 'H'})
        sexoConductor = 'M'; % Valor por defecto si hay algo inesperado
    end
    sexos{i} = sexoConductor;
    
    % Procesar cada variable
    for j = 1:length(xVars)
        if isempty(xVars{j}) % Saltar si la variable está vacía (octavo subplot)
            continue;
        end
        x = T_c.(xVars{j});
        % Si la columna contiene arreglos (como Nx1 double), calcular el mean
        if iscell(x) && all(cellfun(@(v) isnumeric(v) && isvector(v), x))
            x = cellfun(@(v) mean(v, 'omitnan'), x);
        end
        % Convertir si es duration
        if isduration(x), x = seconds(x); end
        % Convertir si es cell (usamos solo valores escalares)
        if iscell(x)
            x = cellfun(@(v) extractScalarOrNaN(v), x, 'UniformOutput', false);
            x = cell2mat(x);
        end
        % Convertir si es categorical
        if iscategorical(x), x = double(x); end
        % Convertir si aún no es double
        if ~isnumeric(x), x = double(x); end
        % Calcular el promedio para este conductor
        dataX(i, j) = mean(x, 'omitnan');
    end
    
    for j = 1:length(yVars)
        if isempty(yVars{j}) % Saltar si la variable está vacía (octavo subplot)
            continue;
        end
        y = T_c.(yVars{j});
        % Si la columna contiene arreglos (como Nx1 double), calcular el mean
        if iscell(y) && all(cellfun(@(v) isnumeric(v) && isvector(v), y))
            y = cellfun(@(v) mean(v, 'omitnan'), y);
        end
        % Convertir si es duration
        if isduration(y), y = seconds(y); end
        % Convertir si es cell (usamos solo valores escalares)
        if iscell(y)
            y = cellfun(@(v) extractScalarOrNaN(v), y, 'UniformOutput', false);
            y = cell2mat(y);
        end
        % Convertir si es categorical
        if iscategorical(y), y = double(y); end
        % Convertir si aún no es double
        if ~isnumeric(y), y = double(y); end
        % Calcular el promedio para este conductor
        dataY(i, j) = mean(y, 'omitnan');
    end
end

% Obtener sexos únicos y asignar colores
uniqueSexos = unique(sexos); % Debería ser {'H', 'M'}
numSexos = length(uniqueSexos);

% Validar que solo haya "M" y "H"
if numSexos > 2
    warning('Se encontraron más valores de sexo de los esperados: %s', strjoin(uniqueSexos, ', '));
    % Filtrar solo "M" y "H"
    uniqueSexos = uniqueSexos(ismember(uniqueSexos, {'M', 'H'}));
    numSexos = length(uniqueSexos);
end

% Asignar colores: azul para "H", rojo para "M"
colors = zeros(numSexos, 3);
for s = 1:numSexos
    if strcmp(uniqueSexos{s}, 'H')
        colors(s, :) = [0 0 1]; % Azul para H
    elseif strcmp(uniqueSexos{s}, 'M')
        colors(s, :) = [1 0 0]; % Rojo para M
    end
end

% Crear una sola figura con todos los conductores
figure('Name', 'Scatter Plots for All Conductors by Sex', 'NumberTitle', 'off');
tiledlayout(2, 4, 'Padding', 'compact');

for j = 1:8
    nexttile;
    hold on; % Permitir múltiples scatter en el mismo subplot

    % Saltar el octavo subplot
    if j == 8
        title('Nulo', 'Interpreter', 'none');
        hold off;
        continue;
    end

    x = dataX(:, j);
    y = dataY(:, j);

    % Eliminar pares con NaN en x o y
    validIdx = ~isnan(x) & ~isnan(y);
    x = x(validIdx);
    y = y(validIdx);
    sexosValid = sexos(validIdx);

    % Verificar si hay datos válidos para graficar
    if isempty(x) || isempty(y)
        title(sprintf('%s vs %s (No valid data)', yVars{j}, xVars{j}), 'Interpreter', 'none');
        hold off;
        continue;
    end

    % Graficar un scatter por cada sexo
    for s = 1:numSexos
        sexo = uniqueSexos{s};
        idxSexo = strcmp(sexosValid, sexo);
        if any(idxSexo)
            scatter(x(idxSexo), y(idxSexo), 30, colors(s, :), 'filled', 'DisplayName', sexo);
        end
    end

    xlabel(xVars{j}, 'Interpreter', 'none');
    ylabel(yVars{j}, 'Interpreter', 'none');
    title(sprintf('%s vs %s', yVars{j}, xVars{j}), 'Interpreter', 'none');
    grid on;
    hold off;

    % Añadir leyenda solo si hay datos
    if j == 1 % Añadir la leyenda solo en el primer subplot para evitar redundancia
        legend('Location', 'bestoutside');
    end
end

function out = extractScalarOrNaN(val)
    try
        if isnumeric(val) && isscalar(val)
            out = double(val);
        elseif isduration(val)
            out = seconds(val);
        elseif ischar(val) || isstring(val)
            out = str2double(val);
            if isnan(out), out = NaN; end
        elseif isnumeric(val) && isvector(val)
            out = mean(val, 'omitnan'); % Tomar la media si es un vector
        else
            out = NaN;
        end
    catch
        out = NaN;
    end
end

%% grafico importante, correlación entre variables
numericVars = {'AcelePorcen1', 'AcelePorcen2', 'MagPosMean', 'MagNegMean', ...
               'DurPosMean', 'DurNegMean', 'MagPosMax', 'MagNegMax', ...
               'DurPosMax', 'DurNegMax', 'Velocidad', 'meanMagPosMax'};
numNumericVars = length(numericVars);
dataMatrix = zeros(height(Tabla), numNumericVars);

% Convertir y procesar datos
for i = 1:numNumericVars
    varData = Tabla.(numericVars{i});
    if iscell(varData)
        if all(cellfun(@(x) isnumeric(x) && isvector(x), varData))
            varData = cellfun(@(x) mean(x, 'omitnan'), varData, 'UniformOutput', false);
        else
            varData = cellfun(@(x) extractScalarOrNaN(x), varData, 'UniformOutput', false);
        end
        varData = cellfun(@(x) double(x(1)), varData, 'UniformOutput', false); % Asegurar escalar
        dataMatrix(:, i) = cell2mat(varData);
    else
        if isnumeric(varData)
            dataMatrix(:, i) = varData;
        elseif isduration(varData)
            dataMatrix(:, i) = seconds(varData);
        else
            dataMatrix(:, i) = double(varData);
        end
    end
end

% Calcular matriz de correlación
corrMatrix = corr(dataMatrix, 'rows', 'pairwise');

% Crear heatmap
figure('Name', 'Heatmap de Correlación entre Variables', 'NumberTitle', 'off');
h = heatmap(numericVars, numericVars, corrMatrix);
h.Title = 'Correlación entre Variables Numéricas';
h.XLabel = 'Variables';
h.YLabel = 'Variables';
h.ColorLimits = [-1 1];
colormap('jet');
colorbar;

%%
% Preparar datos
magPosMean = Tabla.MagPosMean;
if iscell(magPosMean)
    magPosMean = cellfun(@(x) mean(x, 'omitnan'), magPosMean, 'UniformOutput', false);
    magPosMean = cell2mat(magPosMean);
else
    magPosMean = double(magPosMean);
end

% Crear gráfico
figure('Name', 'Cajas Agrupadas: MagPosMean por HorarioRuta y Recorrido', 'NumberTitle', 'off');
boxplot(magPosMean, {Tabla.HorarioRuta, Tabla.Recorrido}, 'Notch', 'on');
xlabel('HorarioRuta y Recorrido');
ylabel('MagPosMean');
title('Distribución de MagPosMean por HorarioRuta y Recorrido');
grid on;
%%
% Preparar datos
kmRuta = Tabla.KilometrosRuta;
velocidad = Tabla.Velocidad;
magPosMax = Tabla.MagPosMax;
if iscell(kmRuta)
    kmRuta = cellfun(@(x) mean(x, 'omitnan'), kmRuta, 'UniformOutput', false);
    kmRuta = cell2mat(kmRuta);
else
    kmRuta = double(kmRuta);
end
if iscell(velocidad)
    velocidad = cellfun(@(x) mean(x, 'omitnan'), velocidad, 'UniformOutput', false);
    velocidad = cell2mat(velocidad);
else
    velocidad = double(velocidad);
end
if iscell(magPosMax)
    magPosMax = cellfun(@(x) mean(x, 'omitnan'), magPosMax, 'UniformOutput', false);
    magPosMax = cell2mat(magPosMax);
else
    magPosMax = double(magPosMax);
end

% Crear malla para interpolación
[X, Y] = meshgrid(linspace(min(kmRuta), max(kmRuta), 20), linspace(min(velocidad), max(velocidad), 20));
Z = griddata(kmRuta, velocidad, magPosMax, X, Y);

% Crear gráfico
figure('Name', 'Superficie: MagPosMax vs KilometrosRuta y Velocidad', 'NumberTitle', 'off');
surf(X, Y, Z, 'EdgeColor', 'none');
xlabel('KilometrosRuta');
ylabel('Velocidad');
zlabel('MagPosMax');
title('Relación Interpolada: MagPosMax vs KilometrosRuta y Velocidad');
colorbar;
colormap('jet');
grid on;
%% boxplot por horas
varsToPlot = {'MagPosMax', 'MagNegMax'};
uniqueRutas = unique(Tabla.NombreRuta);
uniqueSexos = unique(Tabla.Sexo);

figure('Name', 'Boxplots de Aceleraciones por Ruta y Sexo', 'NumberTitle', 'off');
tiledlayout(2, length(varsToPlot), 'Padding', 'compact');

for v = 1:length(varsToPlot)
    nexttile;
    varData = Tabla.(varsToPlot{v});
    if iscell(varData)
        varData = cellfun(@(x) mean(x, 'omitnan'), varData, 'UniformOutput', false);
        varData = cell2mat(varData);
    else
        varData = double(varData);
    end
    boxplot(varData, {Tabla.NombreRuta, Tabla.Sexo}, 'Notch', 'on');
    title(sprintf('Distribución de %s', varsToPlot{v}));
    xlabel('Ruta y Sexo');
    ylabel(varsToPlot{v});
    grid on;
end
%% 
uniqueHorarios = unique(Tabla.HorarioRuta);
uniqueBuses = unique(Tabla.Bus);
acele1Data = zeros(length(uniqueHorarios), length(uniqueBuses));
acele2Data = zeros(length(uniqueHorarios), length(uniqueBuses));

for h = 1:length(uniqueHorarios)
    for b = 1:length(uniqueBuses)
        idx = strcmp(Tabla.HorarioRuta, uniqueHorarios{h}) & strcmp(Tabla.Bus, uniqueBuses{b});
        acele1 = Tabla.AcelePorcen1(idx);
        acele2 = Tabla.AcelePorcen2(idx);
        if iscell(acele1)
            acele1 = cellfun(@(x) mean(x, 'omitnan'), acele1, 'UniformOutput', false);
            acele1 = cellfun(@(x) double(x), acele1, 'UniformOutput', false);
            acele1 = cell2mat(acele1);
        else
            acele1 = double(acele1);
        end
        if iscell(acele2)
            acele2 = cellfun(@(x) mean(x, 'omitnan'), acele2, 'UniformOutput', false);
            acele2 = cellfun(@(x) double(x), acele2, 'UniformOutput', false);
            acele2 = cell2mat(acele2);
        else
            acele2 = double(acele2);
        end
        acele1Data(h, b) = mean(acele1, 'omitnan');
        acele2Data(h, b) = mean(acele2, 'omitnan');
    end
end

% Crear gráfico
figure('Name', 'Aceleraciones por Horario y Bus', 'NumberTitle', 'off');
for h = 1:length(uniqueHorarios)
    subplot(length(uniqueHorarios), 1, h);
    bar([acele1Data(h, :); acele2Data(h, :)]', 'grouped');
    set(gca, 'XTick', 1:length(uniqueBuses), 'XTickLabel', uniqueBuses);
    ylabel('Porcentaje de Aceleración');
    title(['Horario: ', uniqueHorarios{h}]);
    legend({'AcelePorcen1', 'AcelePorcen2'}, 'Location', 'best');
    grid on;
end
%%
