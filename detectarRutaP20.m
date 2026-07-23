function resultados = detectarRutaP20(archivosP20, opciones)

    arguments
        archivosP20 string
        opciones.MaxInterrupcion (1,1) double = 5
    end

    % Rutas auxiliares que no son recorridos reales
    rutasIgnorar = ["No Disponible", "RET", "DES", "EM", "TAP", "CAP"];

    % Leer y combinar todos los archivos P20
    datosP20 = leerArchivosP20(archivosP20);
    if isempty(datosP20)
        warning('No se encontraron datos validos en los archivos P20.');
        resultados = table();
        return;
    end

    % Ordenar por vehiculo y tiempo
    datosP20 = sortrows(datosP20, {'idVehiculo', 'fechaHoraLecturaDato'});

    % Procesar cada vehiculo por separado
    vehiculos = unique(datosP20.idVehiculo);
    resultados = table();

    for v = 1:numel(vehiculos)
        idxVeh = strcmp(datosP20.idVehiculo, vehiculos(v));
        datosVeh = datosP20(idxVeh, :);
        resVeh = detectarRutasVehiculo(datosVeh, opciones.MaxInterrupcion, rutasIgnorar);
        resultados = [resultados; resVeh]; %#ok<AGROW>
    end

    % Ordenar resultados por tiempo de inicio
    if ~isempty(resultados)
        resultados = sortrows(resultados, 'Inicio');
    end

    % Mostrar resumen
    if isempty(resultados)
        fprintf('No se detectaron rutas.\n');
    else
        fprintf('%d viaje(s) detectado(s):\n', height(resultados));
        for i = 1:height(resultados)
            fprintf('[%d] %-6s  %s  %s -> %s  (%s)\n', ...
                i, resultados.Ruta(i), ...
                resultados.Vehiculo(i), ...
                string(resultados.Inicio(i), 'HH:mm:ss'), ...
                string(resultados.Fin(i), 'HH:mm:ss'), ...
                string(resultados.Duracion(i), 'hh:mm:ss'));
        end
    end
end


%% Funciones auxiliares

function resultados = detectarRutasVehiculo(datosVeh, maxInterrupcion, rutasIgnorar)

    resultados = table();
    i = 1;

    while i <= height(datosVeh)
        idRuta = string(datosVeh.idRuta(i));

        % Saltar registros sin ruta real
        if ismember(idRuta, rutasIgnorar)
            i = i + 1;
            continue;
        end

        % Inicio de un viaje
        idxInicio = i;
        idxFin = i;

        j = i + 1;
        while j <= height(datosVeh)
            if strcmp(string(datosVeh.idRuta(j)), idRuta)
                % Misma ruta: extender el viaje
                idxFin = j;
                j = j + 1;
            else
                % Interrupcion: mirar adelante para ver si la ruta se reanuda
                k = j + 1;
                encontrado = false;
                while k <= height(datosVeh) && (k - j) < maxInterrupcion
                    if strcmp(string(datosVeh.idRuta(k)), idRuta)
                        encontrado = true;
                        break;
                    end
                    k = k + 1;
                end

                if encontrado
                    % La ruta se reanuda: saltar la interrupcion
                    idxFin = k;
                    j = k + 1;
                else
                    % La ruta no se reanuda: cortar el viaje
                    break;
                end
            end
        end

        i = j;

        % Extraer datos del segmento
        segmento = datosVeh(idxInicio:idxFin, :);

        if height(segmento) < 2
            continue;
        end

        inicio = segmento.fechaHoraLecturaDato(1);
        fin = segmento.fechaHoraLecturaDato(end);
        duracion = fin - inicio;
        vehiculo = string(segmento.idVehiculo(1));

        nueva = table(inicio, fin, duracion, idRuta, vehiculo, ...
            'VariableNames', {'Inicio','Fin','Duracion','Ruta','Vehiculo'});
        resultados = [resultados; nueva]; %#ok<AGROW>
    end
end


function datosP20 = leerArchivosP20(archivos)
    datosP20 = [];

    for i = 1:numel(archivos)
        archivo = archivos(i);
        if ~isfile(archivo)
            warning('Archivo no encontrado: %s', archivo);
            continue;
        end

        opts = delimitedTextImportOptions('NumVariables', 17);
        opts.Delimiter = ',';
        opts.DataLines = [2, Inf];
        opts.VariableNames = { ...
            'versionTrama','idRegistro','idOperador', ...
            'idVehiculo','idRuta','idConductor', ...
            'fechaHoraLecturaDato','fechaHoraEnvioDato', ...
            'tipoBus','latitud','longitud','tipoTrama', ...
            'tecnologiaMotor','tramaRetransmitida','tipoFreno', ...
            'velocidadVehiculo','aceleracionVehiculo'};
        opts.VariableTypes = { ...
            'string','string','string', ...
            'string','string','string', ...
            'datetime','datetime', ...
            'string','double','double','string', ...
            'string','string','string', ...
            'double','double'};
        opts = setvaropts(opts, 'fechaHoraLecturaDato', ...
            'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
        opts = setvaropts(opts, 'fechaHoraEnvioDato', ...
            'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
        opts = setvaropts(opts, {'latitud','longitud'}, ...
            'DecimalSeparator', '.');
        opts.ExtraColumnsRule = 'ignore';
        opts.EmptyLineRule = 'read';

        try
            datos = readtable(archivo, opts);
            if isempty(datosP20)
                datosP20 = datos;
            else
                datosP20 = [datosP20; datos];
            end
        catch e
            warning('Error leyendo %s: %s', archivo, e.message);
        end
    end
end

%% Ejemplo
% resultados = detectarRutaP20("Datos/4012-03-07-2024/P20.csv");
% resultados = detectarRutaP20(["Datos/4012-03-07-2024/P20.csv", "Datos/4020-15-04-2024/P20.csv"])
