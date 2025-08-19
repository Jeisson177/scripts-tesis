%% Resultados consolidados

%% 1- Speed vs hr de día
figure
r = hours(round(hours(minutes(minute(T.HoraIni))))); % minutes round
scatter(hours(hour(T.HoraIni))+r,T.Speed)
h_ = hours(hour(T.HoraIni))+r;
speed_hr = accumarray(hours(h_),T.Speed,[],@mean);
speed_hr(speed_hr==0) = NaN;
hold on
plot(1:numel(speed_hr),speed_hr)
% Horas de flujo libre: 4h y 22h y 23h, velocidad entre 23 y 24 km/h
% En la hora pico am de 6 - 8, las velocidades promedian 18 km/h
% Entre las 11h y 19h la velocidad está siempre por debajo de 18 km/h
% (excepto 14h).
% La peor velocidad promedio aparece a las 16h, con 16 km/h

%% 2- Speed score vs hr del día
% Muy similar con la gráfica 1, speed vs hr del día, rho = 0.96
% La dirección Inbound en AM es más lenta (6h - 10h)
% La dirección Outbound en PM es más lenta (15h - 20h)
% Ej: HA617, HA601, 
% En HL613 y HL636 H es más rápida que L en ambas horas pico


%% 3-  Cons_km vs hr del día
figure
scatter(h_,T.Cons_km)
cons_hr = accumarray(hours(h_),T.Cons_km,[],@mean);
cons_hr(cons_hr==0) = NaN;
hold on
plot(1:numel(speed_hr),cons_hr)
% No se nota ningún indicio claro. Todos los promedios entre 0.8 y 1 Wh/km
% para cualquier hora

%% 4- Cons_km vs speed
% scatter(t_.(rutas(ii)).consumoPorKilometro,speed,'DisplayName',rutas(ii))
% Tendencia clara "menor vel, mayor consumo"
% -0.3236, "A601" (18)
% -0.4131, "A617" (71)
% 0.5525, "A618" (6 datos)
% -0.8155, "H601" (18)
% -0.0490, "H613" (41) % H613 Parece ser la ruta de menor consumo
% -0.3890, "H617" (66)
% 0.2946, "H618" (4 datos)
% -0.7014, "H629" (9)
% NaN, "H635" (1)
% -0.5296, "H636" (21)
% -0.6846, "K629" (10)
% 0.2679, "K635" (3)
% -0.5072, "L613" (45) % L613 Es la ruta de mayor consumo
% -0.5671, "L636" (23)
% NaN, "T04" (1)
% Promedio de valores con muchos datos: -0.4980

% Total
% corr(T.Cons_km,T.Speed)
% ans = -0.1637

%% 5- Consumo vs bus
T_4012 = T(T.BusID=="bus_4012",:);
T_otro = T(T.BusID~="bus_4012",:);
corr(T_4012.Cons_km,T_4012.Speed)
% ans = -0.3045
corr(T_otro.Cons_km,T_otro.Speed)
% ans = -0.1385
% El consumo está principal y fuertemente explicado por la ruta, no por el
% bus

%% Consumo vs Ace/km
figure
scatter(T.Cons_km,T.Ace_km)
% Total
% corr(T.Cons_km,T.Ace_km)
% ans = 0.1746

% Tendencia clara "mayor Ace/km, mayor consumo"
% corr(t_.(rutas(ii)).consumoPorKilometro,T.Ace_km(idx)),['DisplayName',rutas(ii)]
% 0.2116, "A601" (18)
% 0.2822, "A617" (71)
% 0.2700, "A618" (6)
% 0.4785, "H601" (18)
% 0.1394, "H613" (41)
% 0.4801, "H617" (66)
% 0.4981, "H618" (4)
% 0.6989, "H629" (9)
% NaN, "H635" (1)
% 0.4570, "H636" (21)
% 0.4061, "K629" (10)
% -0.8084, "K635" (3)
% 0.4972, "L613" (45)
% 0.5671, "L636" (23)
% NaN, "T04" (1)
% Promedio de valores con muchos datos: 0.4155


%% Fre/km vs Ace/km vs Speed
% figure
% scatter(T.Fre_km,T.Ace_km)
% corr(T.Fre_km,T.Ace_km)
% ans =  0.9496

% figure
% scatter(T.Speed,T.Ace_km)
% corr(T.Speed,T.Ace_km)
% ans =  -0.7277

% figure
% scatter(T.Speed,T.Fre_km)
% corr(T.Speed,T.Fre_km)
% ans =  -0.7682

%% Riesgo vs Desv_speed_score

% -0.3455, "A601"
% 0.2341, "A617" 
% 0.1701, "A618"
% -0.2211, "H601"
% 0.2684, "H613"
% 0.2086, "H617"
% 0.6265, "H618"
% 0.4237, "H629"
% NaN, "H635"
% NaN, "H636"
% NaN, "K629"
% NaN, "K635"
% 0.4896, "L613"
% 0.1186, "L636"
% NaN, "T04"



%% Consumo vs speed (Sexo), ningún efecto 
T_H = T(T.Sexo=="H",:);
T_M = T(T.Sexo=="M",:);
figure
scatter(T_H.Cons_km,T_H.Speed)
hold on
scatter(T_M.Cons_km,T_M.Speed)

figure
scatter(t_.L613.Cons_km,t_.L613.Speed)



