classdef ImportarDatos
    methods (Static)
        function datos = Sensor(nombreCarpeta)
            if nargin < 1
                nombreCarpeta = pwd; % Directorio actual por defecto
            end

            archivos = dir(fullfile(nombreCarpeta, '*.txt'));
            datos = cell(1, numel(archivos));

            opts = delimitedTextImportOptions("NumVariables", 15);
            opts.DataLines = [1, Inf];
            opts.Delimiter = ",";
            opts.VariableNames = ["time", "ax", "ay", "az", "mx", "my", "mz", "gx", "gy", "gz", "orx", "oy", "or", "lat", "lon"];
            opts.VariableTypes = ["datetime", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            opts = setvaropts(opts, "time", "InputFormat", "yyyy-MM-dd HH:mm:ss.SSS");
            opts = setvaropts(opts, ["ax", "ay", "az", "mx", "my", "mz", "gx", "gy", "gz", "orx", "oy", "or", "lat", "lon"], "TrimNonNumeric", true);
            opts = setvaropts(opts, ["ax", "ay", "az", "mx", "my", "mz", "gx", "gy", "gz", "orx", "oy", "or", "lat", "lon"], "DecimalSeparator", ".");

            for i = 1:numel(archivos)
                nombreArchivo = archivos(i).name;
                rutaArchivo = fullfile(nombreCarpeta, nombreArchivo);
                datos{i} = readtable(rutaArchivo, opts);
            end
        end

        function datos = SensorCordenadas(datosArchivos)
    % Verificar que los datos de entrada sean un arreglo de celdas
    if ~iscell(datosArchivos)
        error('La entrada debe ser un arreglo de celdas con tablas.');
    end
    
    % Calcular el número total de filas para la preasignación
    numTotalFilas = sum(cellfun(@(x) size(x, 1), datosArchivos));
    
    % Preasignar la tabla con el número total de filas
    datosConcatenados = table('Size', [numTotalFilas, 3], ...
                              'VariableTypes', {'datetime', 'double', 'double'}, ...
                              'VariableNames', {'time', 'lat', 'lon'});
    
    contadorFilas = 0; % Iniciar un contador de filas
    
    for i = 1:length(datosArchivos)
        datosActuales = datosArchivos{i};
        % Asumiendo que datosActuales es una tabla con las columnas correctas
        numFilas = size(datosActuales, 1); % Obtener el número de filas de la tabla actual
        datosConcatenados(contadorFilas + (1:numFilas), :) = datosActuales(:, {'time', 'lat', 'lon'});
        contadorFilas = contadorFilas + numFilas; % Actualizar el contador de filas
    end
    
    % Ordenar los datos concatenados por la columna 'time'
    datos = sortrows(datosConcatenados, 'time');
end


        function sts = P20(carpeta)

            if nargin < 1
                carpeta = 'sts'; % Carpeta predeterminada
            end

            nombre_archivo = 'p20.csv';
            ruta_archivo = fullfile(carpeta, nombre_archivo);

            opts = delimitedTextImportOptions("NumVariables", 17);
            opts.DataLines = [1, Inf];
            opts.Delimiter = ",";
            opts.VariableNames = {'versionTrama','idRegistro','idOperador','idVehiculo','idRuta','idConductor','fechaHoraLecturaDato','fechaHoraEnvioDato','tipoBus','tipoTrama','tecnologiaMotor','tramaRetransmitida','tipoFreno','velocidadVehiculo','aceleracionVehiculo','latitud','longitud'};
            opts.VariableTypes = {'double','double','double','double','double','double','datetime','datetime','double','double','double','double','logical','double','double','double','double'};
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            opts = setvaropts(opts, {'fechaHoraLecturaDato','fechaHoraEnvioDato'}, 'InputFormat', "yyyy-MM-dd HH:mm:ss.SSS");
            opts = setvaropts(opts, {'latitud','longitud'}, 'DecimalSeparator', ".");
            
            sts = readtable(ruta_archivo, opts);
        end
    
        function resultado = P20Cordenadas(sts)
    % Verificar que la entrada sts sea una tabla
    if ~istable(sts)
        error('La entrada debe ser una tabla.');
    end
    
    % Verificar que las columnas necesarias existen en sts
    requiredColumns = {'fechaHoraLecturaDato', 'latitud', 'longitud'};
    if ~all(ismember(requiredColumns, sts.Properties.VariableNames))
        error('La tabla de entrada no contiene las columnas necesarias.');
    end
    
    % Extraer solo las columnas de interés
    resultado = sts(:, requiredColumns);
    
    % Ordenar los datos por la columna 'fechaHoraLecturaDato'
    resultado = sortrows(resultado, 'fechaHoraLecturaDato');
end


        function mar = Evento1(carpeta)
            if nargin < 1
                carpeta = 'sts'; % Carpeta predeterminada
            end

            nombre_archivo = 'EV1.csv'; % Nombre del archivo a leer
            ruta_archivo = fullfile(carpeta, nombre_archivo);

            % Opciones para la importación de datos
            opts = delimitedTextImportOptions("NumVariables", 17);
            opts.DataLines = [1, Inf];
            opts.Delimiter = ",";
            opts.VariableNames = {'versionTrama', 'idRegistro', 'idOperador', 'idVehiculo', 'idRuta', 'idConductor', 'fechaHoraLecturaDato', 'fechaHoraEnvioDato', 'tipoBus', 'latitud', 'longitud', 'tipoTrama', 'tecnologiaMotor', 'tramaRetransmitida', 'tipoFreno', 'codigoEvento', 'peso', 'temperaturaCabina', 'estimacionOcupacionSuben', 'estimacionOcupacionBajan', 'estimacionOcupacionAbordo'};
            opts.VariableTypes = {'string','string','string','string','string','string','datetime','datetime','string','double','double','string','logical','string','string','string','double','double','double','double','double'};
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            opts = setvaropts(opts, {'fechaHoraLecturaDato','fechaHoraEnvioDato'}, 'InputFormat', "yyyy-MM-dd HH:mm:ss.SSS");
            
            % Leer el archivo CSV
            mar = readtable(ruta_archivo, opts);
        end
    
        function resultado = Evento1Coordenadas(datos)
    % Verificar que los datos sean una tabla
    if ~istable(datos)
        error('La entrada debe ser una tabla.');
    end
    
    % Verificar que las columnas requeridas existan
    if ~all(ismember({'fechaHoraLecturaDato', 'latitud', 'longitud'}, datos.Properties.VariableNames))
        error('La tabla de entrada no contiene las columnas necesarias.');
    end
    
    % Extraer solo las columnas necesarias
    resultado = datos(:, {'fechaHoraLecturaDato', 'latitud', 'longitud'});
end

    end
end
