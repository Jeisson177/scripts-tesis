% Script para comparación de conductores
% load('Tabla.mat')

meanMagPosMax = cellfun(@mean, Tabla.MagPosMax);
meanMagNegMax = cellfun(@mean, Tabla.MagNegMax);
meanMagPosMean = cellfun(@mean, Tabla.MagPosMean);
meanMagNegMean = cellfun(@mean, Tabla.MagNegMean);

figure, axes
% Figura 1
scatter(meanMagPosMax,Tabla.AcelePorcen1)
hold on
scatter(meanMagNegMax,Tabla.FrePorcen1)
scatter(meanMagPosMean,Tabla.AcelePorcen1)
scatter(meanMagNegMean,Tabla.FrePorcen1)

figure, axes
% Figura 2
scatter(meanMagPosMax,Tabla.AcelePorcen2)
hold on
scatter(meanMagNegMax,Tabla.FrePorcen2)
scatter(meanMagPosMean,Tabla.AcelePorcen2)
scatter(meanMagNegMean,Tabla.FrePorcen2)

figure, axes
scatter(meanMagPosMax,meanMagNegMax)
hold on
scatter(meanMagPosMean,meanMagNegMean)

meanDurPosMean = cellfun(@mean, Tabla.DurPosMean);
meanDurNegMean = cellfun(@mean, Tabla.DurNegMean);
meanVel = cellfun(@mean, Tabla.Velocidad);
figure, axes
scatter(meanDurPosMean,meanVel)
hold on
scatter(meanDurNegMean,meanVel)

% MagAccFre vs Duraciones
figure, axes
scatter(meanDurPosMean,meanMagPosMax)
hold on
scatter(meanDurNegMean,meanMagNegMax)
scatter(meanDurPosMean,meanMagPosMean)
scatter(meanDurNegMean,meanMagNegMean)
% Bus 4012
Tabla_4012 = Tabla(strcmp(Tabla.Bus,"bus_4012"),:);
Tabla_no_4012 = Tabla(~strcmp(Tabla.Bus,"bus_4012"),:);
meanDurPosMean_4012 = cellfun(@mean, Tabla_4012.DurPosMean);
meanDurNegMean_4012 = cellfun(@mean, Tabla_4012.DurNegMean);
meanMagPosMax_4012 = cellfun(@mean, Tabla_4012.MagPosMax);
meanMagNegMax_4012 = cellfun(@mean, Tabla_4012.MagNegMax);
scatter(meanDurPosMean_4012,meanMagPosMax_4012)
scatter(meanDurNegMean_4012,meanMagNegMax_4012)
% H vs M
Tabla_H = Tabla(strcmp(Tabla.Sexo,"H"),:);
Tabla_M = Tabla(strcmp(Tabla.Sexo,"M"),:);
meanDurPosMean_H = cellfun(@mean, Tabla_H.DurPosMean);
meanDurNegMean_H = cellfun(@mean, Tabla_H.DurNegMean);
meanMagPosMax_H = cellfun(@mean, Tabla_H.MagPosMax);
meanMagNegMax_H = cellfun(@mean, Tabla_H.MagNegMax);
scatter(meanDurPosMean_H,meanMagPosMax_H)
scatter(meanDurNegMean_H,meanMagNegMax_H)
meanDurPosMean_M = cellfun(@mean, Tabla_M.DurPosMean);
meanDurNegMean_M = cellfun(@mean, Tabla_M.DurNegMean);
meanMagPosMax_M = cellfun(@mean, Tabla_M.MagPosMax);
meanMagNegMax_M = cellfun(@mean, Tabla_M.MagNegMax);
scatter(meanDurPosMean_M,meanMagPosMax_M)
scatter(meanDurNegMean_M,meanMagNegMax_M)




figure, axes
scatter(meanMagPosMax,meanVel)
hold on
scatter(meanMagNegMax,meanVel)


figure, axes
scatter(meanMagPosMax,Tabla.Acc_km)
hold on
scatter(meanMagNegMax,Tabla.Fre_km)


%% Gráfica por ID conductor
IDs_ = unique(Tabla.ID); % Arreglo de IDs de cada conductor
% IDs_(IDs_==0)=[]; % Borrar IDs == 0 

% Ciclo
for i = 1:numel(IDs_)
    idx = Tabla.ID == IDs_(i);
    scatter(Tabla.meanMagPosMax(idx),Tabla.AcelePorcen1(idx))
    % % Extraer las coordenadas (x, y) de ese ID
    xData = Tabla.meanMagPosMax(idx);
    yData = Tabla.AcelePorcen1(idx);

    % Calcular extremos
    xMin = min(xData);
    xMax = max(xData);
    yMin = min(yData);
    yMax = max(yData);

    % Calcular ancho y alto
    ancho = xMax - xMin;
    alto  = yMax - yMin;

    % Trazar un rectángulo
    rectangle('Position', [xMin, yMin, ancho, alto], ...
              'EdgeColor', 'r', ...
              'LineWidth', 2);

     % scatter(Tabla.meanMagPosMax(idx),cellfun(@numel,Tabla.MagPosMax(idx))./Tabla.KilometrosRuta(idx))
    
    % disp(IDs_(i))
    % pause
end
grid
% xlabel 'Mean MagPosMax'
% ylabel 'Porctaje de Acel > 1 m/s2'

xlabel 'Mean MagPosMax'
ylabel 'AccPos por km'

% Al final del ciclo, se ven dos clusters claros


% Figura 2
% figure, axes
% idx = Tabla.ID == 370762; % El ID que en la figura 1 se veía con menores valores
% scatter(Tabla.meanMagPosMax(idx),cellfun(@numel,Tabla.MagPosMax(idx))./Tabla.KilometrosRuta(idx))
% hold on, grid
% idx = Tabla.ID == 370632; % El ID que en la figura 1 se veía con mayores valores
% scatter(Tabla.meanMagPosMax(idx),cellfun(@numel,Tabla.MagPosMax(idx))./Tabla.KilometrosRuta(idx))