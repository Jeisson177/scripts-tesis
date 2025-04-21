% Script para comparación de conductores
% load('Tabla.mat')

%% Figura 1
% figure, axes
% scatter(mean(Tabla.MagPosMax{1}),Tabla.AcelePorcen1(1))
% hold on

IDs_ = unique(Tabla.ID); % Arreglo de IDs de cada conductor
IDs_(IDs_==0)=[]; % Borrar IDs == 0 

%% Agregar promedios de MagPosMax y otros, a la tabla
for i = 1:size(Tabla,1)
    Tabla.meanMagPosMax(i) = mean(Tabla.MagPosMax{i});
end

%% Ciclo
for i = 1:numel(IDs_)
    % idx = Tabla.ID == IDs_(i);
    idx = find(Tabla.ID == IDs_(i)); %

    figure, axes, grid, hold on
    title(strcat(Tabla.NombreRuta(i), " ", Tabla.Sexo(i), " ", string(Tabla.HoraInicio(i))))
    for j = 1:numel(idx)        
        scatter(seconds(Tabla.DurPosMax{idx(j)}),Tabla.MagPosMax{idx(j)})
        scatter(seconds(Tabla.DurNegMax{idx(j)}),Tabla.MagNegMax{idx(j)})
    end

    % scatter(Tabla.meanMagPosMax(idx),Tabla.AcelePorcen2(idx))
    % scatter(Tabla.meanMagPosMax(idx),Tabla.AcelePorcen2(idx))
    % scatter(Tabla.meanMagPosMax(idx),Tabla.AcelePorcen1(idx))

    % scatter(Tabla.meanMagPosMax(idx),cellfun(@numel,Tabla.MagPosMax(idx))./Tabla.KilometrosRuta(idx))
    
    % disp(IDs_(i))
    pause
end
grid

% xlabel 'Mean MagPosMax'
% ylabel 'Porctaje de Acel > 2 m/s2'

% xlabel 'Mean MagNegMax'
% ylabel 'Porctaje de Acel < -1 m/s2'

% 
% xlabel 'Mean MagPosMax'
% ylabel 'AccPos por km'

% Al final del ciclo, se ven dos clusters claros


% Figura 2
% figure, axes
% idx = Tabla.ID == 370762; % El ID que en la figura 1 se veía con menores valores
% scatter(Tabla.meanMagPosMax(idx),cellfun(@numel,Tabla.MagPosMax(idx))./Tabla.KilometrosRuta(idx))
% hold on, grid
% idx = Tabla.ID == 370632; % El ID que en la figura 1 se veía con mayores valores
% scatter(Tabla.meanMagPosMax(idx),cellfun(@numel,Tabla.MagPosMax(idx))./Tabla.KilometrosRuta(idx))