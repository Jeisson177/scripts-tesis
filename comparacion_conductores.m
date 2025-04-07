% Script para comparación de conductores
% load('Tabla.mat')

figure, axes
% Figura 1
% scatter(mean(Tabla.MagPosMax{1}),Tabla.AcelePorcen1(1))
hold on

IDs_ = unique(Tabla.ID); % Arreglo de IDs de cada conductor
IDs_(IDs_==0)=[]; % Borrar IDs == 0 

% Ciclo
for i = 1:numel(IDs_)
    idx = Tabla.ID == IDs_(i);
    % scatter(Tabla.meanMagPosMax(idx),Tabla.AcelePorcen1(idx))

    scatter(Tabla.meanMagPosMax(idx),cellfun(@numel,Tabla.MagPosMax(idx))./Tabla.KilometrosRuta(idx))
    
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