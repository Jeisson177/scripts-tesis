%% Estructura del paper (Datos de 4 tipos; Vel, Ace, Riesgo, Consumo) 
% Clases de 5 tipos (Sexo, Horario, Ruta, BusID, ConductorID)

%% Intro

%% Metodología
% Recolección de datos
% Descripción del conjunto de datos

%% Preprocesamiento
% Recortes de rutas (problemas de paradas (porcentaje de paradas), problemas de "RET" retorno
    % indica el bus, desvíos operacionales -frecuente-, falta de actualización en los GTFS)
% Detección de ace y desace (pulsos rectangulares)
% Filtro de velocidad (recorte por aceleración excesiva abs(acel) < 2 m/s2)
% Filtro kalman para curvas y posición/detección de curvas
% Suavizado y sobremuestreo en consumo

%% 0- Resultados iniciales (2024). Deben ser confirmados
% Magnitudes de aceleración y desaceleración H vs M muy parecidas
%%% Resultados 2025: las diferencias no son significativas entre H y M.
%%% Ver (Acc p1 per bus ID and sex.fig):
% figure, boxplot(Tsex.AceP1, categorical([string(Tsex.BusID) Tsex.Sexo]))
% ylabel 'Acc +1 ratio'

% Ace/km y desace/km mayor en M (~12) y H (~8)
%%% Las ace/km y fre/km están todas alrededor de 20 para H y M.

%% 0- Resultados iniciales (2025). Deben ser confirmados
% Mujeres ligeramente menor duración de aceleraciones y frenadas
% (Duraciones vs mMagMax)
% NO SE COMPRUEBA: figure, boxplot(milliseconds(cellfun(@mean,Tabla.DurPosMean)), categorical([string(Tabla.Bus) Tabla.Sexo]))

% Mujeres mayores y menores intensidades de aceleraciones y frenadas
% (Duraciones vs mMagMax)
% IRRELEVANTE

% NO HAY RESULTADOS SOBRE #ACE/KM o FRE/KM
% El BUS 4012 explica muy bien los dos clusters (Duraciones vs mMagMax)
    % Ver matrices de correlación de indicadores 4012 vs No 4012
% Las frenadas son más largas que las aceleraciones:
    % "Se acelera por decisión, se frena por necesidad" (COMPROBADO, Ver: mMagMean vs Duration per BusID.fig)
        figure, scatter(milliseconds(cellfun(@mean,Tabla.DurPosMean)),cellfun(@mean,Tabla.MagPosMean))
        grid
        xlabel 'Duration'
        ylabel 'mMagMean'
        hold on, scatter(milliseconds(cellfun(@mean,Tabla.DurNegMean)),cellfun(@mean,Tabla.MagNegMean))
        hold on, scatter(milliseconds(cellfun(@mean,Tabla.DurNegMean)),abs(cellfun(@mean,Tabla.MagNegMean)))
        plot(mean(milliseconds(cellfun(@mean,Tabla.DurPosMean))),mean(cellfun(@mean,Tabla.MagPosMean)))
        plot(mean(milliseconds(cellfun(@mean,Tabla.DurPosMean(Tabla.Bus=='bus_4012')))),mean(cellfun(@mean,Tabla.MagPosMean(Tabla.Bus=='bus_4012'))))
        hold on, plot(mean(milliseconds(cellfun(@mean,Tabla.DurPosMean(Tabla.Bus=='bus_4025')))),mean(cellfun(@mean,Tabla.MagPosMean(Tabla.Bus=='bus_4025'))))
        hold on, plot(mean(milliseconds(cellfun(@mean,Tabla.DurNegMean(Tabla.Bus=='bus_4012')))),mean(cellfun(@mean,Tabla.MagNegMean(Tabla.Bus=='bus_4012'))))
        hold on, plot(mean(milliseconds(cellfun(@mean,Tabla.DurNegMean(Tabla.Bus=='bus_4025')))),mean(cellfun(@mean,Tabla.MagNegMean(Tabla.Bus=='bus_4025'))))
        grid
        ax = axis
        axis(ax)
        hold on, plot(mean(milliseconds(cellfun(@mean,Tabla.DurNegMean(Tabla.Bus=='bus_4012')))),abs(mean(cellfun(@mean,Tabla.MagNegMean(Tabla.Bus=='bus_4012')))))
        hold on, plot(mean(milliseconds(cellfun(@mean,Tabla.DurNegMean(Tabla.Bus=='bus_4025')))),abs(mean(cellfun(@mean,Tabla.MagNegMean(Tabla.Bus=='bus_4025')))))
        xlabel 'Duration'
        ylabel 'mMagMean'

% Fre/km vs Ac/km se nota diferencia entre buses (4012 más alto).
 

% Resultados con MagPosMean y MagNegMean (coulmnas 12 y 13) AcPorc1 vs FrePorc1: Hay gran diferencia entre 4012 y No 4012
% Se frena más que lo que se acelera (se frena por obligación, se acelera por decisión)
% En el 4012 no se evidencia diferencias entre sexo, horarios y rutas.
% En los No 4012, se nota diferencia en la ruta A617 y H636 (promedios altos), mientras la ruta L613 presenta promedio bajos (verificar).
% En los No 4012, se nota ligera diferencia entre hombres (más altos) y mujeres (promedios más bajos).
% En los No 4012, la hora pico se nota un poco más concentrada que Valle o Flujo libre, la diferencia parece mínima.

% El indicador de Consumo/km tiene muy buenas diferencias entre rutas. No así en sexo ni en horario.
% Falta revisar consumo vs algún indicador de velocidad (promedio de ranking por segmento).

% El indicador de Acc/km es notablemente menor en Flujo Libre.

% Preguntas pendientes
% Dado que los clusters de consumo están muy bien definidos por ruta, qué explica la variación interna de cada cluster? Tres opciones: el conductor? (sexo?), el horario? el bus?


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1 - VELOCIDAD

%% 1.1- Speed vs hr de día
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

%% 1.2- Speed score vs hr del día
% Muy similar con la gráfica 1, speed vs hr del día, rho = 0.96
% La dirección Inbound en AM es más lenta (6h - 10h)
% La dirección Outbound en PM es más lenta (15h - 20h)
% Ej: HA617, HA601, 
% En HL613 y HL636 H es más rápida que L en ambas horas pico

%% 1.3- Desv Speed score vs ruta-sexo
% Se filtra la tabla solo por las rutas que tiene muchos datos de H y M
t = T(T.Ruta == 'A601' | T.Ruta == 'A617' | T.Ruta == 'H617' | T.Ruta == 'L613' | T.Ruta == 'H613' | T.Ruta == 'H636',:);

% Luego se filtran aquellos que no tienen sexo 'NA'
t1 = [t(t.Sexo == 'H',:); t(t.Sexo == 'M',:)];
t1.Sexo(t1.Sexo == 'M') = 'Female';
t1.Sexo(t1.Sexo == 'H') = 'Male';
figure
subplot(1,6,1), boxplot(t1.Desv_S_Score(t1.Ruta == 'A601'), categorical(t1.Sexo(t1.Ruta == 'A601')))
subplot(1,6,2), boxplot(t1.Desv_S_Score(t1.Ruta == 'A617'), categorical(t1.Sexo(t1.Ruta == 'A617')))
subplot(1,6,3), boxplot(t1.Desv_S_Score(t1.Ruta == 'H601'), categorical(t1.Sexo(t1.Ruta == 'H601')))
subplot(1,6,4), boxplot(t1.Desv_S_Score(t1.Ruta == 'H613'), categorical(t1.Sexo(t1.Ruta == 'H613')))
subplot(1,6,5), boxplot(t1.Desv_S_Score(t1.Ruta == 'H617'), categorical(t1.Sexo(t1.Ruta == 'H617')))
subplot(1,6,6), boxplot(t1.Desv_S_Score(t1.Ruta == 'L613'), categorical(t1.Sexo(t1.Ruta == 'L613')))
% Luego se calculan las medias de las desviaciones y luego se multiplica
% por el rango de velocidades
range(T.Speed(T.Ruta == 'H617'))*abs(mean(t1.Desv_S_Score(t1.Ruta == 'H617' & t1.Sexo == 'Female')) - mean(t1.Desv_S_Score(t1.Ruta == 'H617' & t1.Sexo == 'Male')))
range(T.Speed(T.Ruta == 'L613'))*abs(mean(t1.Desv_S_Score(t1.Ruta == 'L613' & t1.Sexo == 'Female'),'omitmissing') - mean(t1.Desv_S_Score(t1.Ruta == 'L613' & t1.Sexo == 'Male'),'omitmissing'))
range(T.Speed(T.Ruta == 'H613'))*abs(mean(t1.Desv_S_Score(t1.Ruta == 'H613' & t1.Sexo == 'Female'),'omitmissing') - mean(t1.Desv_S_Score(t1.Ruta == 'H613' & t1.Sexo == 'Male'),'omitmissing'))
range(T.Speed(T.Ruta == 'A617'))*abs(mean(t1.Desv_S_Score(t1.Ruta == 'A617' & t1.Sexo == 'Female'),'omitmissing') - mean(t1.Desv_S_Score(t1.Ruta == 'A617' & t1.Sexo == 'Male'),'omitmissing'))
range(T.Speed(T.Ruta == 'A601'))*abs(mean(t1.Desv_S_Score(t1.Ruta == 'A601' & t1.Sexo == 'Female'),'omitmissing') - mean(t1.Desv_S_Score(t1.Ruta == 'A601' & t1.Sexo == 'Male'),'omitmissing'))
mean([0.6 0.7929 0.3758 0.11 0.1697])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2- ACELERACIÓN

%% 2-1 Las frenadas son más largas que las aceleraciones:
    % "Se acelera por decisión, se frena por necesidad" (COMPROBADO, Ver: mMagMean vs Duration per BusID.fig)
load Tabla.mat

figure, scatter(milliseconds(cellfun(@mean,Tabla.DurPosMean)),cellfun(@mean,Tabla.MagPosMean))
grid
xlabel 'Duration'
ylabel 'mMagMean'
hold on, scatter(milliseconds(cellfun(@mean,Tabla.DurNegMean)),cellfun(@mean,Tabla.MagNegMean))
hold on, scatter(milliseconds(cellfun(@mean,Tabla.DurNegMean)),abs(cellfun(@mean,Tabla.MagNegMean)))
plot(mean(milliseconds(cellfun(@mean,Tabla.DurPosMean))),mean(cellfun(@mean,Tabla.MagPosMean)))
plot(mean(milliseconds(cellfun(@mean,Tabla.DurPosMean(Tabla.Bus=='bus_4012')))),mean(cellfun(@mean,Tabla.MagPosMean(Tabla.Bus=='bus_4012'))))
hold on, plot(mean(milliseconds(cellfun(@mean,Tabla.DurPosMean(Tabla.Bus=='bus_4025')))),mean(cellfun(@mean,Tabla.MagPosMean(Tabla.Bus=='bus_4025'))))
hold on, plot(mean(milliseconds(cellfun(@mean,Tabla.DurNegMean(Tabla.Bus=='bus_4012')))),mean(cellfun(@mean,Tabla.MagNegMean(Tabla.Bus=='bus_4012'))))
hold on, plot(mean(milliseconds(cellfun(@mean,Tabla.DurNegMean(Tabla.Bus=='bus_4025')))),mean(cellfun(@mean,Tabla.MagNegMean(Tabla.Bus=='bus_4025'))))
grid
ax = axis
axis(ax)
hold on, plot(mean(milliseconds(cellfun(@mean,Tabla.DurNegMean(Tabla.Bus=='bus_4012')))),abs(mean(cellfun(@mean,Tabla.MagNegMean(Tabla.Bus=='bus_4012')))))
hold on, plot(mean(milliseconds(cellfun(@mean,Tabla.DurNegMean(Tabla.Bus=='bus_4025')))),abs(mean(cellfun(@mean,Tabla.MagNegMean(Tabla.Bus=='bus_4025')))))
xlabel 'Duration'
ylabel 'mMagMean'

%% 2-2 El BUS 4012 explica muy bien los dos clusters (Duraciones vs mMagMax)
    % Ver matrices de correlación de indicadores 4012 vs No 4012
% Graficamos todos los pares de variables numéricas, contra una categórica elegida (colores)
% T_num = T(:,[8:13 15 16]);
T_num = T(:,[8:13]);
varNames = T_num.Properties.VariableNames;
% T_num = table2array(T(:,[8:13 15 16]));
T_num = table2array(T(:,[8:13]));
figure
gplotmatrix(T_num,[],T.BusID,['c' 'b' 'm' 'g' 'r'],[],[],false);
% text([.08 .24 .43 .66 .83], repmat(-.1,1,5), varNames, 'FontSize',8);
% text(repmat(-.12,1,5), [.86 .62 .41 .25 .02], varNames, 'FontSize',8, 'Rotation',90);
v =6;
text(linspace(.08,.93,v), repmat(-.1,1,v), varNames, 'FontSize',8);
text(repmat(-.12,1,v), linspace(.96,.02,v), varNames, 'FontSize',8, 'Rotation',90);

%% 2-3 No hay diferencias entre sexo, al revisar bus 4012 vs bus 4025
Tsex = T(T.Sexo~='NA',:);

Tb = Tsex(Tsex.BusID=='bus_4025',[8:13 15 16]);
varNames = Tb.Properties.VariableNames;
Tb = Tsex(Tsex.BusID=='bus_4025',[4 8:13 15 16]);
Tb_num = table2array(Tsex(Tsex.BusID=='bus_4025',[8:13 15 16]));
figure
gplotmatrix(Tb_num,[],Tb.Sexo,['b' 'r'],[],[],false);
% text([.08 .24 .43 .66 .83], repmat(-.1,1,5), varNames, 'FontSize',8);
% text(repmat(-.12,1,5), [.86 .62 .41 .25 .02], varNames, 'FontSize',8, 'Rotation',90);
v = 8;
text(linspace(.08,.93,v), repmat(-.1,1,v), varNames, 'FontSize',8);
text(repmat(-.12,1,v), linspace(.96,.02,v), varNames, 'FontSize',8, 'Rotation',90);

% load TablaLast.mat
mMagPos_H_4012 = cellfun(@mean,TablaLast.MagPosMean(TablaLast.Sexo =="H" & TablaLast.Bus == "bus_4012"));
mMagPos_M_4012 = cellfun(@mean,TablaLast.MagPosMean(TablaLast.Sexo =="M" & TablaLast.Bus == "bus_4012"));
% mMagPos_H_4025 = cellfun(@mean,TablaLast.MagPosMean(TablaLast.Sexo =="H" & TablaLast.Bus == "bus_4025"));
% mMagPos_M_4025 = cellfun(@mean,TablaLast.MagPosMean(TablaLast.Sexo =="M" & TablaLast.Bus == "bus_4025"));
mMagPos_H_4025 = cellfun(@mean,TablaLast.MagPosMean(TablaLast.Sexo =="H" & TablaLast.Bus ~= "bus_4012"));
mMagPos_M_4025 = cellfun(@mean,TablaLast.MagPosMean(TablaLast.Sexo =="M" & TablaLast.Bus ~= "bus_4012"));
[mean(mMagPos_M_4025) mean(mMagPos_H_4025)]
[mean(mMagPos_M_4012) mean(mMagPos_H_4012)]

mMagNeg_H_4012 = cellfun(@mean,TablaLast.MagNegMean(TablaLast.Sexo =="H" & TablaLast.Bus == "bus_4012"));
mMagNeg_M_4012 = cellfun(@mean,TablaLast.MagNegMean(TablaLast.Sexo =="M" & TablaLast.Bus == "bus_4012"));
mMagNeg_H_4025 = cellfun(@mean,TablaLast.MagNegMean(TablaLast.Sexo =="H" & TablaLast.Bus == "bus_4025"));
mMagNeg_M_4025 = cellfun(@mean,TablaLast.MagNegMean(TablaLast.Sexo =="M" & TablaLast.Bus == "bus_4025"));
[mean(mMagNeg_M_4012) mean(mMagNeg_H_4012)]
[mean(mMagNeg_M_4025) mean(mMagNeg_H_4025)]

mDurPos_H_4012 = cellfun(@mean,TablaLast.DurPosMean(TablaLast.Sexo =="H" & TablaLast.Bus == "bus_4012"));
mDurPos_M_4012 = cellfun(@mean,TablaLast.DurPosMean(TablaLast.Sexo =="M" & TablaLast.Bus == "bus_4012"));
mDurPos_H_4025 = cellfun(@mean,TablaLast.DurPosMean(TablaLast.Sexo =="H" & TablaLast.Bus == "bus_4025"));
mDurPos_M_4025 = cellfun(@mean,TablaLast.DurPosMean(TablaLast.Sexo =="M" & TablaLast.Bus == "bus_4025"));
milliseconds([mean(mDurPos_M_4025) mean(mDurPos_H_4025)])
milliseconds([mean(mDurPos_M_4012) mean(mDurPos_H_4012)])

mDurNeg_H_4012 = cellfun(@mean,TablaLast.DurNegMean(TablaLast.Sexo =="H" & TablaLast.Bus == "bus_4012"));
mDurNeg_M_4012 = cellfun(@mean,TablaLast.DurNegMean(TablaLast.Sexo =="M" & TablaLast.Bus == "bus_4012"));
mDurNeg_H_4025 = cellfun(@mean,TablaLast.DurNegMean(TablaLast.Sexo =="H" & TablaLast.Bus == "bus_4025"));
mDurNeg_M_4025 = cellfun(@mean,TablaLast.DurNegMean(TablaLast.Sexo =="M" & TablaLast.Bus == "bus_4025"));
milliseconds([mean(mDurNeg_M_4012) mean(mDurNeg_H_4012)])
milliseconds([mean(mDurNeg_M_4025) mean(mDurNeg_H_4025)])

%% 2-4 # fre/km vs Duración de frenadas
% Tampoco se diferencian H vs M
figure, scatter(Tsex.DurFre(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4012' & Tsex.Ruta == 'A617'),Tsex.Fre_km(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4012' & Tsex.Ruta == 'A617'))
hold on, scatter(Tsex.DurFre(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4012' & Tsex.Ruta == 'H617'),Tsex.Fre_km(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4012' & Tsex.Ruta == 'H617'))
hold on, scatter(Tsex.DurFre(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4012' & Tsex.Ruta == 'A617'),Tsex.Fre_km(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4012' & Tsex.Ruta == 'A617'))
hold on, scatter(Tsex.DurFre(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4012' & Tsex.Ruta == 'H617'),Tsex.Fre_km(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4012' & Tsex.Ruta == 'H617'))
hold on, scatter(Tsex.DurFre(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4025' & Tsex.Ruta == 'H613'),Tsex.Fre_km(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4025' & Tsex.Ruta == 'H613'),"Marker",'.')
hold on, scatter(Tsex.DurFre(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4025' & Tsex.Ruta == 'L613'),Tsex.Fre_km(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4025' & Tsex.Ruta == 'L613'),"Marker",'.')
hold on, scatter(Tsex.DurFre(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4025' & Tsex.Ruta == 'H613'),Tsex.Fre_km(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4025' & Tsex.Ruta == 'H613'),"Marker",'.')
hold on, scatter(Tsex.DurFre(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4025' & Tsex.Ruta == 'L613'),Tsex.Fre_km(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4025' & Tsex.Ruta == 'L613'),"Marker",'.')

%% 2-5 Los IDs de los conductores
% Explican mejor la "personalidad", especialmente en hombres hay clusters
% muy claros. Ejemplos:
figure, scatter(Tsex.DurFre(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4012'),Tsex.Fre_km(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4012'))
hold on, scatter(Tsex.DurFre(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4025'),Tsex.Fre_km(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4025'))
grid
summary(categorical(Tsex.CondID(Tsex.BusID == 'bus_4012' & Tsex.Sexo == 'H')))
summary(categorical(Tsex.CondID(Tsex.BusID == 'bus_4025' & Tsex.Sexo == 'H')))
% Además, los (2) hombres conservan el # fre/km entre los buses
cID = 370168;
hold on, scatter(Tsex.DurFre(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4012'& Tsex.CondID==cID),Tsex.Fre_km(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4012' & Tsex.CondID==cID),'Marker','*')
%hold on, scatter(Tsex.DurFre(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4012'& Tsex.CondID==cID),Tsex.Fre_km(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4012' & Tsex.CondID==cID),'Marker','*')
cID = 370673;
hold on, scatter(Tsex.DurFre(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4025'& Tsex.CondID==cID),Tsex.Fre_km(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4025' & Tsex.CondID==cID),'Marker','*')

% Las mujeres tienen clusters menos fuertes y no conservan valores al pasar
% de un bus al otros (2 mujeres)
summary(categorical(Tsex.CondID(Tsex.BusID == 'bus_4012' & Tsex.Sexo == 'M')))
summary(categorical(Tsex.CondID(Tsex.BusID == 'bus_4025' & Tsex.Sexo == 'M')))
cID = 370599;
hold on, scatter(Tsex.DurFre(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4025'& Tsex.CondID==cID),Tsex.Fre_km(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4025' & Tsex.CondID==cID),'Marker','*')
hold on, scatter(Tsex.DurFre(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4012'& Tsex.CondID==cID),Tsex.Fre_km(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4012' & Tsex.CondID==cID),'Marker','*')
cID = 370644;
hold on, scatter(Tsex.DurFre(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4025'& Tsex.CondID==cID),Tsex.Fre_km(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4025' & Tsex.CondID==cID),'Marker','*')
hold on, scatter(Tsex.DurFre(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4012'& Tsex.CondID==cID),Tsex.Fre_km(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4012' & Tsex.CondID==cID),'Marker','*')

%%
% ESTOS RESULTADOS DEBERÍAN COMPROBARSE EN LAS OTRAS VARIABLES DONDE HAY
% ALTA CORRELACIÓN POSITIVA O NEGATIVA: CLUSTERS SEGÚN ID DEL CONDUCTOR

% Varianza promedio de grupo aleatorio en H o M
idx_H = Tsex.Sexo == 'H' & Tsex.BusID=='bus_4012' & (Tsex.Ruta == 'A617' | Tsex.Ruta == 'H617');
idx_M = Tsex.Sexo == 'M' & Tsex.BusID=='bus_4012' & (Tsex.Ruta == 'A617' | Tsex.Ruta == 'H617');
CIDs_H_4012 = cell2table(tabulate(categorical(Tsex.CondID(idx_H))));
CIDs_M_4012 = cell2table(tabulate(categorical(Tsex.CondID(idx_M))));

idx_H = Tsex.Sexo == 'H' & Tsex.BusID=='bus_4025' & (Tsex.Ruta == 'L613' | Tsex.Ruta == 'H613');
idx_M = Tsex.Sexo == 'M' & Tsex.BusID=='bus_4025' & (Tsex.Ruta == 'L613' | Tsex.Ruta == 'H613');
CIDs_H_4025 = cell2table(tabulate(categorical(Tsex.CondID(idx_H))));
CIDs_M_4025 = cell2table(tabulate(categorical(Tsex.CondID(idx_M))));

H_4012 = [Tsex.DurFre(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4012' & (Tsex.Ruta == 'A617' | Tsex.Ruta == 'H617')), Tsex.Fre_km(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4012' & (Tsex.Ruta == 'A617' | Tsex.Ruta == 'H617')), Tsex.CondID(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4012' & (Tsex.Ruta == 'A617' | Tsex.Ruta == 'H617'))];
M_4012 = [Tsex.DurFre(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4012' & (Tsex.Ruta == 'A617' | Tsex.Ruta == 'H617')), Tsex.Fre_km(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4012' & (Tsex.Ruta == 'A617' | Tsex.Ruta == 'H617')), Tsex.CondID(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4012' & (Tsex.Ruta == 'A617' | Tsex.Ruta == 'H617'))];

H_4025 = [Tsex.DurFre(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4025' & (Tsex.Ruta == 'L613' | Tsex.Ruta == 'H613')), Tsex.Fre_km(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4025' & (Tsex.Ruta == 'L613' | Tsex.Ruta == 'H613')), Tsex.CondID(Tsex.Sexo == 'H' & Tsex.BusID=='bus_4025' & (Tsex.Ruta == 'L613' | Tsex.Ruta == 'H613'))];
M_4025 = [Tsex.DurFre(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4025' & (Tsex.Ruta == 'L613' | Tsex.Ruta == 'H613')), Tsex.Fre_km(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4025' & (Tsex.Ruta == 'L613' | Tsex.Ruta == 'H613')), Tsex.CondID(Tsex.Sexo == 'M' & Tsex.BusID=='bus_4025' & (Tsex.Ruta == 'L613' | Tsex.Ruta == 'H613'))];

% Clústers aleatorios
CDI_size = 8; % escoger de 2 a 5 + [8]
sz = size(M_4025,1); % Número de elementos en el cluster Sexo|BusID|Ruta
n = 10000;
std_ = NaN*ones(n,2);
for i = 1:n
    rnd_idx = randi(sz,1,CDI_size); % índices aleatorios
    std_(i,:) = std(M_4025(rnd_idx,1:2));
end
% Desv. estándar promedio para CDI_size = 2;
mean(std_,'omitmissing')
% Para H_4012
% ans =  140.9393    3.0515, CDI_size = 2
% ans =  158.7031    3.4530, CDI_size = 3
% ans =  164.8241    3.5951, CDI_size = 4
% std(H_4012(:,1:2)) =  179.9435    3.9082
std_rnd_H_4012 = [NaN NaN;...
140.9393    3.0515; ...
158.7031    3.4530; ...
164.8241    3.5951];
% Para M_4012
% ans =  258.9063    3.8506, CDI_size = 2
% ans =  292.7795    4.3325, CDI_size = 3
% ans =  307.6334    4.3998, CDI_size = 4
% ans =  313.4257    4.5234, CDI_size = 5
% std(M_4012(:,1:2)) =  348.5171    4.8042
std_rnd_M_4012 = [NaN NaN;...
258.9063    3.8506; ...
292.7795    4.3325; ...
307.6334    4.3998; ...
313.4257    4.5234];
% Para H_4025
% ans =  270.1856    3.0835, CDI_size = 2
% ans =  304.4461    3.5181, CDI_size = 3
% ans =  323.0925    3.6726, CDI_size = 4
% std(H_4025(:,1:2)) =  379.8060    4.1191
std_rnd_H_4025 = [NaN NaN;...
270.1856    3.0835; ...
304.4461    3.5181; ...
323.0925    3.6726];
% Para M_4025
% ans =  215.4936    1.9596, CDI_size = 2
% ans =  237.6392    2.1740, CDI_size = 3
% ans =  247.3555    2.2715, CDI_size = 4
% std(M_4025(:,1:2)) =  272.5045    2.6186
std_rnd_M_4025 = [NaN NaN;...
215.4936    1.9596; ...
237.6392    2.1740; ...
247.3555    2.2715; ...
NaN NaN; ...
NaN NaN; ...
NaN NaN; ...
260.1100    2.4265];


% Desv. estándar de cada individuo con + de 1 trayecto
IDs = CIDs_M_4025;
data = M_4025;
std_rnd_data = std_rnd_M_4025;

std_ = NaN*ones(length(IDs.Var3),2);
for i = 1:length(IDs.Var3)
    if IDs.Var2(i) > 1 % Si tiene solo 1 trayecto queda NaN
        idx = data(:,3) == str2double(IDs.Var1{i});
        std_(i,:) = std(data(idx,1:2));
    end
end
% STD para cada CID vs STD_RND según # de muestras
tmp = [std_ IDs.Var2 std_rnd_data(IDs.Var2,:)];
s_srnd_M_4025 = [tmp(:,1)./tmp(:,4) tmp(:,2)./tmp(:,5)] % división debe dar < 1
pause
% s_srnd_H_4012 = [
%     1.1473    0.9301; ...
%     0.1415    0.3836; ...
%     0.5465    0.2527; ...
%        NaN       NaN; ...
%     0.7079    0.5057; ...
%     0.0253    0.5725; ...
%     1.5223    0.7069; ...
%        NaN       NaN; ...
%     0.0371    0.1604; ...
%     0.6430    0.0361; ...
%     0.7686    0.2433];
% 
% s_srnd_M_4012 = [
%     0.7841    0.6089; ...
%     0.4856    0.1471; ...
%     0.1477    0.0788; ...
%     0.2847    0.0037; ...
%     0.2007    0.1528; ...
%     0.0332    0.2772; ...
%     1.0966    0.3186; ...
%     0.2300    0.4751; ...
%     0.5982    0.6631; ...
%     0.7273    1.0206; ...
%     0.2750    0.0731; ...
%     0.0183    0.1693; ...
%     1.2418    0.9908; ...
%     0.8238    0.8089; ...
%     0.2658    0.4014; ...
%     0.1649    0.4775; ...
%     0.7130    0.8341; ...
%     0.0996    0.3812; ...
%     0.1860    0.4184; ...
%     0.5070    0.2876; ...
%     0.9015    0.8948; ...
%     0.4389    0.1372; ...
%     2.7305    1.0917; ...
%     0.4465    0.8373; ...
%     0.2711    0.0594; ...
%     0.4997    0.2527];
% 
% s_srnd_H_4025 = [NaN       NaN; ...
%     0.7269    0.3267; ...
%     0.4196    0.5475; ...
%     0.4623    0.4835; ...
%     0.0313    0.6471; ...
%     0.9689    0.4538; ...
%        NaN       NaN; ...
%     0.2397    0.6194; ...
%        NaN       NaN];
% 
% s_srnd_M_4025 = [NaN       NaN; ...
%     0.0884    1.1343; ...
%     1.4209    0.8724; ...
%     0.0759    0.6424; ...
%        NaN       NaN; ...
%     0.4148    0.3574; ...
%     0.2559    1.1071; ...
%     0.3980    1.3751; ...
%     0.6049    0.4722; ...
%     0.8973    0.2106; ...
%     1.0405    0.6463; ...
%     1.0988    0.5959; ...
%     0.8329    0.4944];

%% 2-6 Indicadores de aceleración por bus y por sexo:
% NO HAY DIFERENCIAS SIGNIFICATIVAS EN NINGUNO
load Tabla2.mat
Tsex = T(T.Sexo~='NA',:);

figure, boxplot(Tsex.AceP1, categorical([string(Tsex.BusID) Tsex.Sexo]))
ylabel 'Acc +1 ratio'
figure, boxplot(Tsex.AceP2, categorical([string(Tsex.BusID) Tsex.Sexo]))
ylabel 'Acc +2 ratio'
grid
figure, boxplot(Tsex.FreP1, categorical([string(Tsex.BusID) Tsex.Sexo]))
ylabel 'Acc -1 ratio'
grid
figure, boxplot(Tsex.FreP2, categorical([string(Tsex.BusID) Tsex.Sexo]))
ylabel 'Acc -2 ratio'
grid
figure, boxplot(Tsex.DurAc, categorical([string(Tsex.BusID) Tsex.Sexo]))
ylabel 'Acc+ duration'
grid
figure, boxplot(Tsex.DurFre, categorical([string(Tsex.BusID) Tsex.Sexo]))
ylabel 'Acc- duration'
grid
figure, boxplot(Tsex.Ace_km, categorical([string(Tsex.BusID) Tsex.Sexo]))
ylabel '#Acc+/km'
grid
figure, boxplot(Tsex.Fre_km, categorical([string(Tsex.BusID) Tsex.Sexo]))
ylabel '#Acc-/km'
grid
load Tabla
figure, boxplot(milliseconds(cellfun(@mean,Tabla.DurPosMean)), categorical([string(Tabla.Bus) Tabla.Sexo]))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3- RIESGO

%% 3-1 Riesgo vs Riesgo Kalman
% Graficamos todos los pares de variables numéricas, contra una categórica elegida (colores)
% Ver: Risk multivariable gplotmatrix per sex.fig
T.Riesgo(T.Riesgo>3) = NaN;
Tt = T(:,[17 23 18:22]);
varNames = Tt.Properties.VariableNames;
Tt_num = table2array(T(:,[17 23 18:22]));
figure
gplotmatrix(Tt_num,[],T.Sexo,['b' 'r' 'k'],[],[],false);
v =7;
text(linspace(.08,.93,v), repmat(-.1,1,v), varNames, 'FontSize',8);
text(repmat(-.12,1,v), linspace(.96,.02,v), varNames, 'FontSize',8, 'Rotation',90);

% El Riesgo Kalman parece mejor porque tiene mayor correlación con las variables de velocidad,
% que el Riesgo (curvas fijas).
% No hay correlación con el consumo
corr(T.Riesgo_kalman,T.Cons_km,'rows','pairwise')
% ans =  -0.1606
% Pero sí con la velocidad, como se esperaba
corr(T.Riesgo_kalman,T.Desv_S_Score,'rows','pairwise')
% ans =  0.5643
corr(T.Riesgo_kalman,T.Speed,'rows','pairwise')
% ans =  0.6259
corr(T.Riesgo_kalman,T.S_Score,'rows','pairwise')
% ans =  0.6538
figure, scatter(T.Riesgo_kalman,T.S_Score)
xlabel 'Riesgo kalman'
ylabel 'Normalized speed'
grid
hold on, scatter(T.Riesgo_kalman(T.Sexo=='H'),T.S_Score(T.Sexo=='H'))
hold on, scatter(T.Riesgo_kalman(T.Sexo=='M'),T.S_Score(T.Sexo=='M'))
% No hay diferencias evidentes entre sexos en este scatter


%% 3-1 Riesgo kalman por sexo y por ruta
Tsex = T(T.Sexo~='NA',:);
% Se filtra la tabla solo por las rutas que tiene muchos datos de H y M
t = Tsex(Tsex.Ruta == 'A601' | Tsex.Ruta == 'A617' | Tsex.Ruta == 'H617' | Tsex.Ruta == 'L613' | Tsex.Ruta == 'H613' | Tsex.Ruta == 'H636',:);

figure, boxplot(t.Riesgo_kalman, categorical([string(t.Ruta) t.Sexo]))
% En las medianas no se ven diferencias significativas entre los sexos, 

[mean(t.Riesgo_kalman(t.Sexo=='H' & t.Ruta=='A601')) mean(t.Riesgo_kalman(t.Sexo=='M' & t.Ruta=='A601'))]
[mean(t.Riesgo_kalman(t.Sexo=='H' & t.Ruta=='A617')) mean(t.Riesgo_kalman(t.Sexo=='M' & t.Ruta=='A617'))]
[mean(t.Riesgo_kalman(t.Sexo=='H' & t.Ruta=='H617')) mean(t.Riesgo_kalman(t.Sexo=='M' & t.Ruta=='H617'))]
[mean(t.Riesgo_kalman(t.Sexo=='H' & t.Ruta=='L613')) mean(t.Riesgo_kalman(t.Sexo=='M' & t.Ruta=='L613'))]
[mean(t.Riesgo_kalman(t.Sexo=='H' & t.Ruta=='H613')) mean(t.Riesgo_kalman(t.Sexo=='M' & t.Ruta=='H613'))]

    % 0.9443    0.9749
    % 1.0151    1.0175
    % 1.0443    1.0174
    % 1.0021    0.9676
    % 1.0884    1.0405
% En las medias (ligeramente inferior en mujeres) tampoco se ven diferencias significativas entre los sexos, 
% Totales
[mean(t.Riesgo_kalman(t.Sexo=='H')), mean(t.Riesgo_kalman(t.Sexo=='M'))]
    % 1.0259    1.0089

%% 3-2 Riesgo kalman vs Speed
corr(T.Riesgo_kalman, T.Speed)
% ans =   0.6259
[corr(T.Riesgo_kalman(T.Ruta=='A617' & T.Sexo=='H'), T.Speed(T.Ruta=='A617' & T.Sexo=='H')) corr(T.Riesgo_kalman(T.Ruta=='A617' & T.Sexo=='M'), T.Speed(T.Ruta=='A617' & T.Sexo=='M'));...
    corr(T.Riesgo_kalman(T.Ruta=='H617' & T.Sexo=='H'), T.Speed(T.Ruta=='H617' & T.Sexo=='H')) corr(T.Riesgo_kalman(T.Ruta=='H617' & T.Sexo=='M'), T.Speed(T.Ruta=='H617' & T.Sexo=='M'));...
    corr(T.Riesgo_kalman(T.Ruta=='L613' & T.Sexo=='H'), T.Speed(T.Ruta=='L613' & T.Sexo=='H')) corr(T.Riesgo_kalman(T.Ruta=='L613' & T.Sexo=='M'), T.Speed(T.Ruta=='L613' & T.Sexo=='M'));...
    corr(T.Riesgo_kalman(T.Ruta=='H613' & T.Sexo=='H'), T.Speed(T.Ruta=='H613' & T.Sexo=='H')) corr(T.Riesgo_kalman(T.Ruta=='H613' & T.Sexo=='M'), T.Speed(T.Ruta=='H613' & T.Sexo=='M'));...
    corr(T.Riesgo_kalman(T.Ruta=='A601' & T.Sexo=='H'), T.Speed(T.Ruta=='A601' & T.Sexo=='H')) corr(T.Riesgo_kalman(T.Ruta=='A601' & T.Sexo=='M'), T.Speed(T.Ruta=='A601' & T.Sexo=='M'))]
% ans =
    % 0.7626    0.6899
    % 0.7134    0.8879
    % 0.8958    0.6447
    % 0.4671    0.7216
    % 0.7853    0.8233
% La correlación Speed|R.Kalman crece un poco cuando se revisa por ruta|sexo

%% 3.3 Riesgo kalman vs fre_km o acc_km

figure, scatter(T.Riesgo_kalman(T.Sexo=='H'),T.Fre_km(T.Sexo=='H'))
hold on, scatter(T.Riesgo_kalman(T.Sexo=='M'),T.Fre_km(T.Sexo=='M'))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4- CONSUMO
%% 4.1-  Cons_km vs hr del día
rutas = unique(Tabla.NombreRuta);
t_ = struct();
figure
for ii = 1:length(rutas)
    t_.(rutas(ii)) = Tabla(Tabla.NombreRuta == rutas(ii),:);
    r = hours(round(hours(minutes(minute(t_.(rutas(ii)).HoraInicio))))); % minutes round
end
h_ = hours(hour(T.HoraIni))+r;
figure
scatter(h_,T.Cons_km)
cons_hr = accumarray(hours(h_),T.Cons_km,[],@mean);
cons_hr(cons_hr==0) = NaN;
hold on
speed_hr = accumarray(hours(h_),T.Speed,[],@mean);
plot(1:numel(speed_hr),cons_hr)
% No se nota ningún indicio claro. Todos los promedios entre 0.8 y 1 Wh/km
% para cualquier hora (falta info de regeneración para detectar verdadero consumo)

%% 4- Cons_km vs speed
% Correlación negativa entre velocidad promedio en movimiento (speed) y
% consumo
% Correlación negativa entre velocidad comercial (3.6*cellfun(@mean,t_.(rutas(ii)).Velocidad) y
% consumo
% Revisar gráfica: Vel mov y Vel com vs Ef Consumo.fig
% Ver en procesamiento_DJR.m
% % points = scatter(t_.(rutas(ii)).consumoPorKilometro,speed,'DisplayName',rutas(ii));
% % points = scatter(t_.(rutas(ii)).consumoPorKilometro,3.6*cellfun(@mean,t_.(rutas(ii)).Velocidad),'DisplayName',dipsN);

% % Tendencia clara "menor vel prom, mayor consumo"
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

%% Consumo, diferencias entre sexos
load Tabla2.mat
T = T(T.Ruta == 'A601' | T.Ruta == 'H601' | T.Ruta == 'A617' | T.Ruta == 'H617' | T.Ruta == 'L613' | T.Ruta == 'H613' | T.Ruta == 'H636',:);
Tsex = T(T.Sexo~='NA',:);

figure, boxplot(Tsex.Cons_km, categorical([string(Tsex.Ruta) Tsex.Sexo]))

%% Regeneración
load TablaLast.mat
T = T(T.Sexo~='NA',:);
t = T(T.Ruta == 'A601' | T.Ruta == 'A617' | T.Ruta == 'H601' | T.Ruta == 'H617' | T.Ruta == 'L613' | T.Ruta == 'H613' | T.Ruta == 'H636',:);
% Luego se filtran aquellos que no tienen sexo 'NA'
t1 = [t(t.Sexo == 'H',:); t(t.Sexo == 'M',:)];
t1.Sexo(t1.Sexo == 'M') = 'Female';
t1.Sexo(t1.Sexo == 'H') = 'Male';
figure
subplot(1,6,1), boxplot(t1.Regen(t1.Ruta == 'A601')./t1.kmRuta(t1.Ruta == 'A601'), categorical(t1.Sexo(t1.Ruta == 'A601')))
subplot(1,6,2), boxplot(t1.Regen(t1.Ruta == 'A617')./t1.kmRuta(t1.Ruta == 'A617'), categorical(t1.Sexo(t1.Ruta == 'A617')))
subplot(1,6,3), boxplot(t1.Regen(t1.Ruta == 'H601')./t1.kmRuta(t1.Ruta == 'H601'), categorical(t1.Sexo(t1.Ruta == 'H601')))
subplot(1,6,4), boxplot(t1.Regen(t1.Ruta == 'H613')./t1.kmRuta(t1.Ruta == 'H613'), categorical(t1.Sexo(t1.Ruta == 'H613')))
subplot(1,6,5), boxplot(t1.Regen(t1.Ruta == 'H617')./t1.kmRuta(t1.Ruta == 'H617'), categorical(t1.Sexo(t1.Ruta == 'H617')))
subplot(1,6,6), boxplot(t1.Regen(t1.Ruta == 'L613')./t1.kmRuta(t1.Ruta == 'L613'), categorical(t1.Sexo(t1.Ruta == 'L613')))
% Luego se calculan las medias de las desviaciones y luego se multiplica
% por el rango de velocidades

plot([1,2],[mean(t1.Regen(t1.Ruta == 'A601' & t1.Sexo == 'Female')./t1.kmRuta(t1.Ruta == 'A601' & t1.Sexo == 'Female'),'omitmissing') mean(t1.Regen(t1.Ruta == 'A601' & t1.Sexo == 'Male')./t1.kmRuta(t1.Ruta == 'A601' & t1.Sexo == 'Male'),'omitmissing')],'p--')
plot([1,2],[mean(t1.Regen(t1.Ruta == 'A617' & t1.Sexo == 'Female')./t1.kmRuta(t1.Ruta == 'A617' & t1.Sexo == 'Female'),'omitmissing') mean(t1.Regen(t1.Ruta == 'A617' & t1.Sexo == 'Male')./t1.kmRuta(t1.Ruta == 'A617' & t1.Sexo == 'Male'),'omitmissing')],'p--')
plot([1,2],[mean(t1.Regen(t1.Ruta == 'H601' & t1.Sexo == 'Female')./t1.kmRuta(t1.Ruta == 'H601' & t1.Sexo == 'Female'),'omitmissing') mean(t1.Regen(t1.Ruta == 'H601' & t1.Sexo == 'Male')./t1.kmRuta(t1.Ruta == 'H601' & t1.Sexo == 'Male'),'omitmissing')],'p--')
plot([1,2],[mean(t1.Regen(t1.Ruta == 'H613' & t1.Sexo == 'Female')./t1.kmRuta(t1.Ruta == 'H613' & t1.Sexo == 'Female'),'omitmissing') mean(t1.Regen(t1.Ruta == 'H613' & t1.Sexo == 'Male')./t1.kmRuta(t1.Ruta == 'H613' & t1.Sexo == 'Male'),'omitmissing')],'p--')
plot([1,2],[mean(t1.Regen(t1.Ruta == 'H617' & t1.Sexo == 'Female')./t1.kmRuta(t1.Ruta == 'H617' & t1.Sexo == 'Female'),'omitmissing') mean(t1.Regen(t1.Ruta == 'H617' & t1.Sexo == 'Male')./t1.kmRuta(t1.Ruta == 'H617' & t1.Sexo == 'Male'),'omitmissing')],'p--')
plot([1,2],[mean(t1.Regen(t1.Ruta == 'L613' & t1.Sexo == 'Female')./t1.kmRuta(t1.Ruta == 'L613' & t1.Sexo == 'Female'),'omitmissing') mean(t1.Regen(t1.Ruta == 'L613' & t1.Sexo == 'Male')./t1.kmRuta(t1.Ruta == 'L613' & t1.Sexo == 'Male'),'omitmissing')],'p--')

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

