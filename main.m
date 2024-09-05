datos.Acc(abs(datos.Acc)<=0.3)=0;
% Inicializar variables
intervalo_inicio = 1;
tiempo_constante = [];
valor_constante = [];

% Recorrer la señal para identificar intervalos positivos, negativos o 0
while intervalo_inicio <= length(datos.Acc)
    if datos.Acc(intervalo_inicio) > 0
        % Buscar el final del intervalo positivo
        intervalo_fin = find(datos.Acc(intervalo_inicio:end) <= 0, 1) + intervalo_inicio - 2;
        if isempty(intervalo_fin)
            intervalo_fin = length(datos.Acc);
        end
        altura = max(datos.Acc(intervalo_inicio:intervalo_fin));
        
    elseif datos.Acc(intervalo_inicio) < 0
        % Buscar el final del intervalo negativo
        intervalo_fin = find(datos.Acc(intervalo_inicio:end) >= 0, 1) + intervalo_inicio - 2;
        if isempty(intervalo_fin)
            intervalo_fin = length(datos.Acc);
        end
        altura = min(datos.Acc(intervalo_inicio:intervalo_fin));
        
    else
        % Para los valores de 0
        intervalo_fin = find(datos.Acc(intervalo_inicio:end) ~= 0, 1) + intervalo_inicio - 2;
        if isempty(intervalo_fin)
            intervalo_fin = length(datos.Acc);
        end
        altura = 0; % Asignar 0 cuando el valor es 0
    end
    
    % Crear la señal constante
    tiempo_constante = [tiempo_constante; datos.Tiempo(intervalo_inicio:intervalo_fin)];
    valor_constante = [valor_constante; repmat(altura, intervalo_fin - intervalo_inicio + 1, 1)];
    
    % Actualizar el inicio del siguiente intervalo
    intervalo_inicio = intervalo_fin + 1;
end

% Ploteo de la señal constante
plot(tiempo_constante, valor_constante, 'r-', 'LineWidth', 2);

% Ajustar el eje x para que se vea como datetime
datetick('x', 'HH:MM:SS', 'keeplimits', 'keepticks');
xlabel('Tiempo');
ylabel('Valores de Acc');
title('Comparación de la Señal y la Señal Constante por Intervalos');
legend('Señal Original', 'Señal Constante');
grid on;
hold off;

%%
datosBuses = ImportarDatos.importarTodosLosDatos('Datos');
%%
datosBuses = ImportarDatos.importarMuestra('Datos', 4);
%% Calculo de todos los tiempos para cada ruta

datosBuses = Calcular.tiemposRutas(datosBuses, rutas);

%% Muestra un resumen de los datos totales a procesar

Calcular.resumenRecorridosPorRuta(datosBuses)

%% calcula la velocidad por fecha
% Recomendado no usar, salvo para debug, procesa TODOS lo datos, cosume
% mucho tiempo y recursos
% datosBuses = Calcular.velocidadTotal(datosBuses, 'km/h', 'pendiente');

%% Calcular velocidad por ruta
% Calcula la velocidad, solo durante el tiempo de la ruta
datosBuses = Calcular.calcularVelocidadPorRutas(datosBuses);

%% Calcular aceleracion por ruta
% Calcula la velocidad, solo durante el tiempo de la ruta
datosBuses = Calcular.AceleracionPorRutas(datosBuses);

%% Extrer datos sensor por ruta:
datosBuses = Calcular.extraerDatosSensorPorRutas(datosBuses);


%% Graficar
%Graficar.graficarVelocidadPorRutas(datosBuses, "bus_4020", "f_15_04_2024")
Graficar.graficarVelocidadPorRutas(datosBuses, "bus_4012", "f_04_07_2024", 1)

%% Aceleracion
Graficar.aceleracionPorRutas(datosBuses, "bus_4012", "f_03_07_2024", 1)

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

datosBuses = Calculos.extraerSegmentosDatos(datosBuses);

%%

datosBuses = Calculos.extraerEV1(datosBuses);

%%

datosBuses = Calculos.extraerEV19(datosBuses);

%%

