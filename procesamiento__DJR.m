% Ranking de conductores por segmentos
% Segmentos arbitrarios buscando velocidades similares en gráfica de Vel vs
% distancia en una misma ruta.

% load('Tabla.mat')

rutas = unique(Tabla.NombreRuta);
t_ = struct();
figure
for ii = 1:length(rutas)
    % t_.(rutas(ii)) = Tabla(Tabla.NombreRuta == rutas(ii),:);
    t_.(rutas(ii)) = TablaLast(TablaLast.NombreRuta == rutas(ii),:);

% t_ = 
% 
%   struct with fields:
% 
%     A617: [71×34 table]
%     H617: [66×34 table]
%     A601: [18×34 table]
%     H601: [18×34 table]
%     L613: [45×34 table]
%     H613: [41×34 table]
%     A618: [6×34 table]
%     H618: [4×34 table]
%     K629: [10×34 table]
%     H629: [9×34 table]
%     K635: [3×34 table]
%     H635: [1×34 table]
%      T04: [1×34 table]
%     L636: [23×34 table]
%     H636: [21×34 table]


    nSegments = 10;
    d_ = (1e3)*(1:9)*mean(t_.(rutas(ii)).KilometrosRuta)/nSegments;
    vel_ = nan*ones(size(t_.(rutas(ii)),1),nSegments-1);
    % La matriz vel_ guarda el promedio de las velocidades no-cero de cada
    % recorrido (i) en cada segmento (j) para cada ruta (ii), en km/h

    % Para cada recorrido (i) de cada ruta (ii)
    for i = 1:size(t_.(rutas(ii)),1)
        lim_ = nan*ones(nSegments-1,1); lim_(1) = 1;
        % Para cada segmento (j) de cada recorrido (i)
        for j = 1:nSegments-1
            lim_(j+1) = find(cumsum(t_.(rutas(ii)).Distancia{i}) < d_(j),1,'last');
            if lim_(j+1) < numel(t_.(rutas(ii)).Velocidad{i})
                vel_(i,j) = mean(nonzeros(3.6*t_.(rutas(ii)).Velocidad{i}(lim_(j):lim_(j+1))));
            else
                vel_(i,j) = nan;
            end
        end
        % plot(cumsum(t_.A617.Distancia{i}(1:lim_(1))), 3.6*t_.A617.Velocidad{i}(1:lim_(1)))
        % plot(cumsum(t_.A617.Distancia{i}(1:end-1)), 3.6*t_.A617.Velocidad{i})
    end
    
    %% Speed score
    % 1- Se normaliza por el rango del segmento (formado por todos los
    % recorridos de una ruta en ese segmento)
    % 2- Se promedia el valor normalizado, entre todos los 9 segmentos
    speed = mean(vel_,2,'omitmissing'); % velocidad promedio en movimiento
    speed_score = mean((vel_ - min(vel_))./range(vel_),2,'omitmissing');
    idx = find(T.Ruta == rutas(ii));
    % T.Speed(idx) = speed;
    % T.S_Score(idx) = speed_score;

    % Gráfica de speed score vs hora de inicio
    r = hours(round(hours(minutes(minute(t_.(rutas(ii)).HoraInicio))))); % minutes round
    % scatter(hours(hour(t_.(rutas(ii)).HoraInicio))+r,speed_score,'DisplayName',rutas(ii))

    % Gráfica de speed vs hora de inicio
    % scatter(hours(hour(t_.(rutas(ii)).HoraInicio))+r,speed,'DisplayName',rutas(ii))
    % Es claro que la velocidad neta y el speed_score, dependen de la hora
    % de inicio
    
    %% Cum_score
    % 1- Se separan todos los recorridos por hora de inicio
    % 2- Se ordenan en orden ascendente: primero el de menor speed_score 
    % 3- Por cada hora de inicio: Se encuentra la diferencia de cada
    % recorrido vs el de menor speed_score
    % - El cum_score "castiga" (o aumenta) a un recorrido que tenga un
    % speed_score por encima del mínimo de su misma hora de inicio.
    % - Si solo hay un recorrido en esa hora de inicio, cum_score = nan;

    % Se crea un arreglo [hora de inicio, speed_score, 1:rutas], ordenado
    % por speed_score ascendente
    tmp = sortrows([hours(hours(hour(t_.(rutas(ii)).HoraInicio))+r)  speed_score  (1:numel(t_.(rutas(ii)).HoraInicio))'],2);
    % Se crea un arreglo [hora de inicio, speed, 1:rutas], ordenado
    % por speed ascendente
    tmp2 = sortrows([hours(hours(hour(t_.(rutas(ii)).HoraInicio))+r)  speed  (1:numel(t_.(rutas(ii)).HoraInicio))'],2);
    hrs = unique(tmp(:,1));
    % Se calcula por cada hora del día, el promedio del speed_score
    avg_speed_sco_hr = accumarray(tmp(:,1),tmp(:,2),[],@mean);
    avg_speed_hr = accumarray(tmp2(:,1),tmp2(:,2),[],@mean);
    tmp(:,4) = nan*ones(size(tmp,1),1);
    for jj = 1:numel(hrs)        
        % El cum_score es el acumulado de la diff de speed_score de cada
        % hora del día, en la tabla ordenada.
        % Es decir, se aumenta con: mayor diff de speed_score y mayor
        % número de muestras en cada hora
        cum_score = cumsum([0; diff(tmp(tmp(:,1)==hrs(jj),2))]);
        tmp(tmp(:,1)==hrs(jj),4) = cum_score;
        tmp(tmp(:,1)==hrs(jj),5) = avg_speed_sco_hr(hrs(jj));
    end
    tmp = sortrows(tmp,3); % organizar según orden inicial en la columna 3
    % T.Cum_S_Score(idx) = tmp(:,4); % Cumulative speed score (compared to other scores in the same route, same start hour)
    % El cum_score, castiga estar lejos de mínimo en cada hora de inicio.
    % Pero cuando hay pocas muestras, puede ser muy sesgado.

    %% Desv_S_Score
    % Puede ser mejor revisar la desviación del speed_score de un
    % recorrido vs la media del speed_score para esa hora de inicio.
    % Eso es el Desv_s_score.
    % T.Desv_S_Score(idx) = speed_score - tmp(:,5); % Desviación respecto la media de la hora inicial

    % s = scatter(hours(hour(t_.(rutas(ii)).HoraInicio))+r,speed_score,'DisplayName',rutas(ii));
    % plot(hours(unique(tmp(:,1))),nonzeros(avg_speed_hr),'DisplayName',rutas(ii),'Color',s.CData,'LineStyle','-')

    % hold on
    % s = scatter(hours(hour(t_.(rutas(ii)).HoraInicio))+r,speed,'DisplayName',rutas(ii));
    % plot(hours(unique(tmp(:,1))),nonzeros(avg_speed_hr),'DisplayName',rutas(ii),'Color',s.CData,'LineStyle','-')


    %% Gráficas de análisis preliminares
    hold on

    % points = scatter(t_.(rutas(ii)).consumoPorKilometro,speed,'DisplayName',rutas(ii));
    % scatter(mean(t_.(rutas(ii)).consumoPorKilometro),mean(speed),'Marker','pentagram','MarkerFaceColor',points.CData); %,'HandleVisibility','off'
    % x = t_.(rutas(ii)).consumoPorKilometro;
    % y = speed;
    % A = [x(:) ones(length(x),1)];
    % coeff = A \ y(:);
    % m = coeff(1);   % slope
    % b = coeff(2);   % intercept
    % y_fit = m*x + b; % Aproximación lineal de los puntos del scatter
    % plot(x,y_fit)

    % cons = t_.(rutas(ii)).consumoPorKilometro; 
    % v_c = 3.6*cellfun(@mean,t_.(rutas(ii)).Velocidad); v_c(cons<0.4) = [];
    % cons(cons<0.4) = [];    
    % rho = corr(cons,v_c);
    % dipsN = [char(rutas(ii)) ', \rho = ' num2str(round(rho,2)) ', v_{com} = ' num2str(round(mean(v_c),1))];
    % points = scatter(cons,v_c,'DisplayName',dipsN);
    % scatter(mean(t_.(rutas(ii)).consumoPorKilometro),mean(v_c),'Marker','pentagram','MarkerFaceColor',points.CData,'MarkerEdgeColor',points.CData); %,'HandleVisibility','off'
    % x = cons;
    % y = v_c;
    % A = [x(:) ones(length(x),1)];
    % coeff = A \ y(:);
    % m = coeff(1);   % slope
    % b = coeff(2);   % intercept
    % y_fit = m*x + b; % Aproximación lineal de los puntos del scatter
    % plot(x,y_fit,'Color',points.CData)
    
    % rho = corr(t_.(rutas(ii)).consumoPorKilometro,T.Ace_km(idx));
    % dispN = [char(rutas(ii)) ', \rho = ' num2str(round(rho,2)) ', Acc+/km = ' num2str(round(mean(T.Ace_km(idx)),1))];
    % points = scatter(t_.(rutas(ii)).consumoPorKilometro,T.Ace_km(idx),'DisplayName',dispN);
    % x = t_.(rutas(ii)).consumoPorKilometro;
    % y = T.Ace_km(idx);
    % A = [x(:) ones(length(x),1)];
    % coeff = A \ y(:);
    % m = coeff(1);   % slope
    % b = coeff(2);   % intercept
    % y_fit = m*x + b; % Aproximación lineal de los puntos del scatter
    % plot(x,y_fit,'Color',points.CData)

    cons = t_.(rutas(ii)).consumoPorKilometro; 
    reg = t_.(rutas(ii)).regeneracionEnergia./t_.(rutas(ii)).KilometrosRuta;
    v_c = 3.6*cellfun(@mean,t_.(rutas(ii)).Velocidad); v_c(cons<0.4) = [];
    reg(cons<0.4) = [];    cons(cons<0.4) = [];
    E_t = cons + reg; % Total energy
    rho = corr(E_t,v_c);
    dipsN = [char(rutas(ii)) ', \rho = ' num2str(round(rho,2)) ', v_{com} = ' num2str(round(mean(v_c),1))];
    points = scatter(E_t,v_c,'DisplayName',dipsN);
    scatter(mean(E_t),mean(v_c),'Marker','pentagram','MarkerFaceColor',points.CData,'MarkerEdgeColor',points.CData); %,'HandleVisibility','off'
    x = E_t;
    y = v_c;
    A = [x(:) ones(length(x),1)];
    coeff = A \ y(:);
    m = coeff(1);   % slope
    b = coeff(2);   % intercept
    y_fit = m*x + b; % Aproximación lineal de los puntos del scatter
    plot(x,y_fit,'Color',points.CData)

    % scatter(t_.(rutas(ii)).PromRiesgo,T.Cum_S_Score(idx),'DisplayName',rutas(ii))
    % scatter(t_.(rutas(ii)).consumoPorKilometro,T.Desv_S_Score(idx),'DisplayName',rutas(ii))
    % scatter(t_.(rutas(ii)).Promedio_riesgo_kalman,T.Desv_S_Score(idx),'DisplayName',rutas(ii))
    % hold on
    % scatter(t_.(rutas(ii)).PromRiesgo,T.Desv_S_Score(idx),'DisplayName',rutas(ii))
    % corr(t_.(rutas(ii)).PromRiesgo,T.Desv_S_Score(idx)),['DisplayName',rutas(ii)]
    
end
T.Cum_S_Score(T.Cum_S_Score==0) = NaN;
T.Desv_S_Score(T.Desv_S_Score==0) = NaN;