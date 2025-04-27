% % Lista de conductores únicos
% ids = unique(Tabla.ID);
% 
% % Variables de interés para graficar
% xVars = {'AcelePorcen1', 'Velocidad', 'DurPosMean', 'Velocidad', 'MagPosMean', 'DurPosMax', 'Velocidad', 'MagPosMax'};
% yVars = {'AcelePorcen2', 'meanMagPosMax', 'DurNegMean', 'KilometrosRuta', 'MagNegMean', 'DurNegMax', 'MagPosMean', 'MagNegMax'};
% 
% % Preparar datos: calcular el promedio por conductor
% numConductores = length(ids);
% dataX = zeros(numConductores, length(xVars));
% dataY = zeros(numConductores, length(yVars));
% rutas = cell(numConductores, 1); % Almacenar la ruta de cada conductor
% 
% for i = 1:numConductores
%     id = ids(i);
% 
%     % Filtrar la tabla por ese conductor
%     T_c = Tabla(Tabla.ID == id, :);
% 
%     % Guardar la ruta del conductor (usamos la primera, asumiendo que es la misma para todas las filas del conductor)
%     rutas{i} = T_c.NombreRuta{1};
% 
%     % Procesar cada variable
%     for j = 1:length(xVars)
%         x = T_c.(xVars{j});
%         % Si la columna contiene arreglos (como Nx1 double), calcular el mean
%         if iscell(x) && all(cellfun(@(v) isnumeric(v) && isvector(v), x))
%             x = cellfun(@(v) mean(v, 'omitnan'), x);
%         end
%         % Convertir si es duration
%         if isduration(x), x = seconds(x); end
%         % Convertir si es cell (usamos solo valores escalares)
%         if iscell(x)
%             x = cellfun(@(v) extractScalarOrNaN(v), x, 'UniformOutput', false);
%             x = cell2mat(x);
%         end
%         % Convertir si es categorical
%         if iscategorical(x), x = double(x); end
%         % Convertir si aún no es double
%         if ~isnumeric(x), x = double(x); end
%         % Calcular el promedio para este conductor
%         dataX(i, j) = mean(x, 'omitnan');
%     end
% 
%     for j = 1:length(yVars)
%         y = T_c.(yVars{j});
%         % Si la columna contiene arreglos (como Nx1 double), calcular el mean
%         if iscell(y) && all(cellfun(@(v) isnumeric(v) && isvector(v), y))
%             y = cellfun(@(v) mean(v, 'omitnan'), y);
%         end
%         % Convertir si es duration
%         if isduration(y), y = seconds(y); end
%         % Convertir si es cell (usamos solo valores escalares)
%         if iscell(y)
%             y = cellfun(@(v) extractScalarOrNaN(v), y, 'UniformOutput', false);
%             y = cell2mat(y);
%         end
%         % Convertir si es categorical
%         if iscategorical(y), y = double(y); end
%         % Convertir si aún no es double
%         if ~isnumeric(y), y = double(y); end
%         % Calcular el promedio para este conductor
%         dataY(i, j) = mean(y, 'omitnan');
%     end
% end
% 
% % Obtener rutas únicas y asignar colores
% uniqueRutas = unique(rutas);
% numRutas = length(uniqueRutas);
% colors = jet(numRutas); % Usamos el colormap 'jet' para generar colores
% 
% % Crear una sola figura con todos los conductores
% figure('Name', 'Scatter Plots for All Conductors by Route', 'NumberTitle', 'off');
% tiledlayout(2, 4, 'Padding', 'compact');
% 
% for j = 1:8
%     nexttile;
%     hold on; % Permitir múltiples scatter en el mismo subplot
% 
%     x = dataX(:, j);
%     y = dataY(:, j);
% 
%     % Eliminar pares con NaN en x o y
%     validIdx = ~isnan(x) & ~isnan(y);
%     x = x(validIdx);
%     y = y(validIdx);
%     rutasValid = rutas(validIdx);
% 
%     % Verificar si hay datos válidos para graficar
%     if isempty(x) || isempty(y)
%         title(sprintf('%s vs %s (No valid data)', yVars{j}, xVars{j}), 'Interpreter', 'none');
%         continue;
%     end
% 
%     % Graficar un scatter por cada ruta
%     for r = 1:numRutas
%         ruta = uniqueRutas{r};
%         idxRuta = strcmp(rutasValid, ruta);
%         if any(idxRuta)
%             scatter(x(idxRuta), y(idxRuta), 30, colors(r, :), 'filled', 'DisplayName', ruta);
%         end
%     end
% 
%     xlabel(xVars{j}, 'Interpreter', 'none');
%     ylabel(yVars{j}, 'Interpreter', 'none');
%     title(sprintf('%s vs %s', yVars{j}, xVars{j}), 'Interpreter', 'none');
%     grid on;
%     hold off;
% 
%     % Añadir leyenda solo si hay datos
%     if j == 1 % Añadir la leyenda solo en el primer subplot para evitar redundancia
%         legend('Location', 'bestoutside');
%     end
% end
% 
% % Función auxiliar mejorada
% function out = extractScalarOrNaN(val)
%     try
%         if isnumeric(val) && isscalar(val)
%             out = double(val);
%         elseif isduration(val)
%             out = seconds(val);
%         elseif ischar(val) || isstring(val)
%             out = str2double(val);
%             if isnan(out)
%                 out = NaN;
%             end
%         else
%             out = NaN;
%         end
%     catch
%         out = NaN;
%     end
% end

%%

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

% Función auxiliar mejorada
function out = extractScalarOrNaN(val)
    try
        if isnumeric(val) && isscalar(val)
            out = double(val);
        elseif isduration(val)
            out = seconds(val);
        elseif ischar(val) || isstring(val)
            out = str2double(val);
            if isnan(out)
                out = NaN;
            end
        else
            out = NaN;
        end
    catch
        out = NaN;
    end
end