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

generarDatos(Buses.bus_4104.ida.horaValle.("Hora Inicio")(1), Buses.bus_4104.ida.horaValle.("Hora Fin")(1), '4104', 'ida');

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
        dhp.("PromedioVelocidad")
        m_dhp = (cell2mat(dhp.("PromedioVelocidad")')');
        shp = dhp.Sexo;

        dhv = Rutas.(ruta).(trayecto).horaValle;
        dhv.("PromedioVelocidad")
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

function generarDatos(fechaInicio, fechaFinal, IDbus, Etiqueta)
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
Graficas.DistanciavsVelocidad3(datosCordenadasSensor,datosP60, fechaInicio, fechaFinal,Ruta4020Ida,tituloGrafica);



Graficas.analizarAceleraciones(datosCordenadasSensor, fechaInicio, fechaFinal);




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


