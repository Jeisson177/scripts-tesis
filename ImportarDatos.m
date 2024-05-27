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
                carpeta = '4001_15_02'; % Carpeta predeterminada
            end
            
            nombre_archivo = 'p20.csv';
            ruta_archivo = fullfile(carpeta, nombre_archivo);
            
            opts = delimitedTextImportOptions("NumVariables", 17);
            opts.DataLines = [1, Inf];
            opts.Delimiter = ",";
            opts.VariableNames = {'versionTrama','idRegistro','idOperador','idVehiculo','idRuta','idConductor','fechaHoraLecturaDato','fechaHoraEnvioDato','tipoBus','tipoTrama','tecnologiaMotor','tramaRetransmitida','tipoFreno','velocidadVehiculo','aceleracionVehiculo','lat','lon'};
            opts.VariableTypes = {'double','double','double','double','double','double','datetime','datetime','double','double','double','double','logical','double','double','double','double'};
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            opts = setvaropts(opts, {'fechaHoraLecturaDato','fechaHoraEnvioDato'}, 'InputFormat', "yyyy-MM-dd HH:mm:ss.SSS");
            opts = setvaropts(opts, {'lat','lon'}, 'DecimalSeparator', ".");
            
            sts = readtable(ruta_archivo, opts);
        end
        %%
        function datosVelocidad = P20Velocidad(carpeta)
            % Verificar si se ha proporcionado el argumento de la carpeta
            if nargin < 1
                carpeta = 'sts'; % Carpeta predeterminada
            end
            
            nombre_archivo = 'p20.csv';
            ruta_archivo = fullfile(carpeta, nombre_archivo);
            
            % Opciones para la importación de datos
            opts = delimitedTextImportOptions("NumVariables", 17);
            opts.DataLines = [1, Inf];
            opts.Delimiter = ",";
            opts.VariableNames = {'versionTrama','idRegistro','idOperador','idVehiculo','idRuta','idConductor','fechaHoraLecturaDato','fechaHoraEnvioDato','tipoBus','tipoTrama','tecnologiaMotor','tramaRetransmitida','tipoFreno','velocidadVehiculo','aceleracionVehiculo','latitud','longitud'};
            opts.VariableTypes = {'double','double','double','double','double','double','datetime','datetime','double','double','double','double','logical','double','double','double','double'};
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            opts = setvaropts(opts, {'fechaHoraLecturaDato','fechaHoraEnvioDato'}, 'InputFormat', "yyyy-MM-dd HH:mm:ss.SSS");
            opts = setvaropts(opts, {'latitud','longitud'}, 'DecimalSeparator', ".");
            
            % Leer el archivo CSV
            sts = readtable(ruta_archivo, opts);
            
            % Seleccionar solo las columnas de fecha de lectura y velocidad del vehículo
            datosVelocidad = sts(:, {'fechaHoraLecturaDato', 'velocidadVehiculo'});
        end
        %%

        function datosFiltrados = filtrarDatosPorFechas(datos, fechaInicio, fechaFin)
    % Convertir fechas de inicio y fin a datetime si son strings
    if ischar(fechaInicio) || isstring(fechaInicio)
        fechaInicio = datetime(fechaInicio, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    end
    if ischar(fechaFin) || isstring(fechaFin)
        fechaFin = datetime(fechaFin, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    end

    % Filtrar los datos por el rango de fechas
    datosFiltrados = datos(datos{:, 1} >= fechaInicio & datos{:, 1} <= fechaFin, :);
end

        
        %%
        function resultado = P20Cordenadas(sts)
            % Verificar que la entrada sts sea una tabla
            if ~istable(sts)
                error('La entrada debe ser una tabla.');
            end
            
            % Verificar que las columnas necesarias existen en sts
            requiredColumns = {'fechaHoraLecturaDato', 'lat', 'lon'};
            if ~all(ismember(requiredColumns, sts.Properties.VariableNames))
                error('La tabla de entrada no contiene las columnas necesarias.');
            end
            
            % Extraer solo las columnas de interés
            resultado = sts(:, requiredColumns);
            
            % Ordenar los datos por la columna 'fechaHoraLecturaDato'
            resultado = sortrows(resultado, 'fechaHoraLecturaDato');
        end
        
        function mar = P60(carpeta)
            if nargin < 1
                carpeta = '4001_15_02'; % Carpeta predeterminada
            end
            
            nombre_archivo = 'P60.csv'; % Nombre del archivo a leer
            ruta_archivo = fullfile(carpeta, nombre_archivo);
            
            % Opciones para la importación de datos
            opts = delimitedTextImportOptions("NumVariables", 34); % Ajuste el número de variables
            opts.DataLines = [1, Inf];
            opts.Delimiter = ",";
            opts.VariableNames = {'versionTrama', 'idRegistro', 'idOperador', 'idVehiculo', 'idRuta', 'idConductor', 'fechaHoraLecturaDato', 'fechaHoraEnvioDato', 'tipoBus', 'lat', 'lon', 'tipoTrama', 'tecnologiaMotor', 'tramaRetransmitida', 'tipoFreno', 'temperaturaMotor', 'presionAceiteMotor', 'velocidadVehiculo', 'aceleracionVehiculo', 'revolucionesMotor', 'estadoDesgasteFrenos', 'kilometrosOdometro', 'consumoCombustible', 'nivelTanqueCombustible', 'consumoEnergia', 'regeneracionEnergia', 'nivelRestanteEnergia', 'porcentajeEnergiaGenerada', 'temperaturaSts', 'usoCpuSts', 'memRamSts', 'memDiscoSts', 'temperaturaBaterias', 'sentidoMarcha'}; % Añadir las nuevas variables
            opts.VariableTypes = {'string'       ,'string'     ,'string'     ,'string'     ,'string' ,'string'      ,'datetime'             ,'datetime'           ,'string'  ,'double'  ,'double'   ,'string'    ,'double'         ,'string'              ,'string'   ,'double'           ,'double'             ,'double'            ,'double'              ,'double'            ,'double'               ,'double'             ,'double'             ,'double'                 ,'double'         ,'double'              ,'double'               ,'double'                    ,'double'         ,'double'    ,'double'    ,'double'      ,'double'              ,'double'};
            
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            opts = setvaropts(opts, {'fechaHoraLecturaDato','fechaHoraEnvioDato'}, 'InputFormat', "yyyy-MM-dd HH:mm:ss.SSS");
            
            % Leer el archivo CSV
            mar = readtable(ruta_archivo, opts);
        end
        
        
        function mar = Evento1(carpeta)
            if nargin < 1
                carpeta = '4001_15_02'; % Carpeta predeterminada
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
        
        
        function mar = Evento2(carpeta)
            if nargin < 1
                carpeta = '4001_15_02'; % Carpeta predeterminada
            end
            
            nombre_archivo = 'EV2.csv'; % Nombre del archivo a leer
            ruta_archivo = fullfile(carpeta, nombre_archivo);
            
            % Opciones para la importación de datos
            opts = delimitedTextImportOptions("NumVariables", 18);
            opts.DataLines = [1, Inf];
            opts.Delimiter = ",";
            opts.VariableNames = {'versionTrama', 'idRegistro', 'idOperador', 'idVehiculo', 'idRuta', 'idConductor', 'fechaHoraLecturaDato', 'fechaHoraEnvioDato', 'tipoBus', 'latitud', 'longitud', 'tipoTrama', 'tecnologiaMotor', 'tramaRetransmitida', 'tipoFreno', 'codigoEvento', 'estadoAperturaCierrePuertas'};
            opts.VariableTypes = {'string','string','string','string','string','string','datetime','datetime','string','double','double','string','logical','string','string','string','logical'};
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            opts = setvaropts(opts, {'fechaHoraLecturaDato','fechaHoraEnvioDato'}, 'InputFormat', "yyyy-MM-dd HH:mm:ss.SSS");
            
            % Leer el archivo CSV
            mar = readtable(ruta_archivo, opts);
        end
        
        function mar = Evento8(carpeta)
            if nargin < 1
                carpeta = '4001_15_02'; % Carpeta predeterminada
            end
            
            nombre_archivo = 'EV8.csv'; % Nombre del archivo a leer
            ruta_archivo = fullfile(carpeta, nombre_archivo);
            
            % Opciones para la importación de datos
            opts = delimitedTextImportOptions("NumVariables", 18); % Ajuste el número de variables
            opts.DataLines = [1, Inf];
            opts.Delimiter = ",";
            opts.VariableNames = {'versionTrama', 'idRegistro', 'idOperador', 'idVehiculo', 'idRuta', 'idConductor', 'fechaHoraLecturaDato', 'fechaHoraEnvioDato', 'tipoBus', 'latitud', 'longitud', 'tipoTrama', 'tecnologiaMotor', 'tramaRetransmitida', 'tipoFreno', 'codigoEvento', 'fotoConductor'}; % Añadir la nueva variable
            opts.VariableTypes = {'string','string','string','string','string','string','datetime','datetime','string','double','double','string','logical','string','string','string','string'}; % Ajustar los tipos de variables
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            opts = setvaropts(opts, {'fechaHoraLecturaDato','fechaHoraEnvioDato'}, 'InputFormat', "yyyy-MM-dd HH:mm:ss.SSS");
            
            % Leer el archivo CSV
            mar = readtable(ruta_archivo, opts);
        end
        
        function mar = Evento18(carpeta)
            if nargin < 1
                carpeta = '4001_15_02'; % Carpeta predeterminada
            end
            
            nombre_archivo = 'EV18.csv'; % Nombre del archivo a leer
            ruta_archivo = fullfile(carpeta, nombre_archivo);
            
            % Opciones para la importación de datos
            opts = delimitedTextImportOptions("NumVariables", 18); % Ajuste el número de variables
            opts.DataLines = [1, Inf];
            opts.Delimiter = ",";
            opts.VariableNames = {'versionTrama', 'idRegistro', 'idOperador', 'idVehiculo', 'idRuta', 'idConductor', 'fechaHoraLecturaDato', 'fechaHoraEnvioDato', 'tipoBus', 'latitud', 'longitud', 'tipoTrama', 'tecnologiaMotor', 'tramaRetransmitida', 'tipoFreno', 'codigoEvento', 'fotoConductor'}; % Añadir la nueva variable
            opts.VariableTypes = {'string','string','string','string','string','string','datetime','datetime','string','double','double','string','logical','string','string','string','string'}; % Ajustar los tipos de variables
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            opts = setvaropts(opts, {'fechaHoraLecturaDato','fechaHoraEnvioDato'}, 'InputFormat', "yyyy-MM-dd HH:mm:ss.SSS");
            
            % Leer el archivo CSV
            mar = readtable(ruta_archivo, opts);
        end
        
        function mar = Evento20(carpeta)
            if nargin < 1
                carpeta = '4001_15_02'; % Carpeta predeterminada
            end
            
            nombre_archivo = 'EV20.csv'; % Nombre del archivo a leer
            ruta_archivo = fullfile(carpeta, nombre_archivo);
            
            % Opciones para la importación de datos
            opts = delimitedTextImportOptions("NumVariables", 18); % Ajuste el número de variables
            opts.DataLines = [1, Inf];
            opts.Delimiter = ",";
            opts.VariableNames = {'versionTrama', 'idRegistro', 'idOperador', 'idVehiculo', 'idRuta', 'idConductor', 'fechaHoraLecturaDato', 'fechaHoraEnvioDato', 'tipoBus', 'latitud', 'longitud', 'tipoTrama', 'tecnologiaMotor', 'tramaRetransmitida', 'tipoFreno', 'codigoEvento', 'porcentajeCargaBaterias'}; % Añadir la nueva variable
            opts.VariableTypes = {'string','string','string','string','string','string','datetime','datetime','string','double','double','string','logical','string','string','string','double'}; % Ajustar los tipos de variables
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            opts = setvaropts(opts, {'fechaHoraLecturaDato','fechaHoraEnvioDato'}, 'InputFormat', "yyyy-MM-dd HH:mm:ss.SSS");
            
            % Leer el archivo CSV
            mar = readtable(ruta_archivo, opts);
        end
        
        function mar = Evento21(carpeta)
            if nargin < 1
                carpeta = '4001_15_02'; % Carpeta predeterminada
            end
            
            nombre_archivo = 'EV21.csv'; % Nombre del archivo a leer
            ruta_archivo = fullfile(carpeta, nombre_archivo);
            
            % Opciones para la importación de datos
            opts = delimitedTextImportOptions("NumVariables", 18); % Ajuste el número de variables
            opts.DataLines = [1, Inf];
            opts.Delimiter = ",";
            opts.VariableNames = {'versionTrama', 'idRegistro', 'idOperador', 'idVehiculo', 'idRuta', 'idConductor', 'fechaHoraLecturaDato', 'fechaHoraEnvioDato', 'tipoBus', 'latitud', 'longitud', 'tipoTrama', 'tecnologiaMotor', 'tramaRetransmitida', 'tipoFreno', 'codigoEvento', 'porcentajeCargaBaterias'}; % Añadir la nueva variable
            opts.VariableTypes = {'string','string','string','string','string','string','datetime','datetime','string','double','double','string','logical','string','string','string','double'}; % Ajustar los tipos de variables
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            opts = setvaropts(opts, {'fechaHoraLecturaDato','fechaHoraEnvioDato'}, 'InputFormat', "yyyy-MM-dd HH:mm:ss.SSS");
            
            % Leer el archivo CSV
            mar = readtable(ruta_archivo, opts);
        end
        
        %%
        function mar = Evento19(carpeta)
            % Comprueba si se ha proporcionado el argumento 'carpeta'; si no, usa un valor predeterminado
            if nargin < 1
                carpeta = '4001_15_02'; % Carpeta predeterminada
            end
            
            nombre_archivo = 'EV19.csv'; % Nombre del archivo a leer
            ruta_archivo = fullfile(carpeta, nombre_archivo); % Construye la ruta completa del archivo
            
            % Opciones para la importación de datos desde un archivo CSV
            opts = delimitedTextImportOptions("NumVariables", 17); % Número de variables esperadas en el archivo
            opts.DataLines = [1, Inf]; % Líneas del archivo que contienen datos
            opts.Delimiter = ","; % Delimitador de campos en el archivo CSV
            % Nombres de las variables correspondientes a las columnas del archivo
            opts.VariableNames = {'versionTrama', 'idRegistro', 'idOperador', 'idVehiculo', 'idRuta', 'idConductor', 'fechaHoraLecturaDato', 'fechaHoraEnvioDato', 'tipoBus', 'latitud', 'longitud', 'tipoTrama', 'tecnologiaMotor', 'tramaRetransmitida', 'tipoFreno', 'codigoEvento', 'codigoComportamientoAnomalo'};
            % Tipos de datos para cada columna
            opts.VariableTypes = {'string', 'string', 'string', 'string', 'string', 'string', 'datetime', 'datetime', 'string', 'double', 'double', 'string', 'string', 'logical', 'string', 'string', 'string'};
            opts.ExtraColumnsRule = "ignore"; % Instrucción sobre cómo manejar columnas adicionales
            opts.EmptyLineRule = "read"; % Instrucción sobre cómo manejar líneas vacías
            % Especifica el formato de las columnas de fecha y hora
            opts = setvaropts(opts, {'fechaHoraLecturaDato', 'fechaHoraEnvioDato'}, 'InputFormat', "yyyy-MM-dd HH:mm:ss.SSS");
            
            % Leer el archivo CSV en una tabla de MATLAB
            mar = readtable(ruta_archivo, opts);
        end


        %%

        function mar = Evento10(carpeta)
    if nargin < 1
        carpeta = '4001_15_02'; % Carpeta predeterminada
    end

    nombre_archivo = 'EV10.csv'; % Nombre del archivo a leer
    ruta_archivo = fullfile(carpeta, nombre_archivo);

    % Opciones para la importación de datos
    opts = delimitedTextImportOptions("NumVariables", 21);
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

        %%
        function [tabla1, tabla2, tabla3, tabla4] = Evento19Coordenadas(datos)
            % Verificar que los datos sean una tabla
            if ~istable(datos)
                error('La entrada debe ser una tabla.');
            end
            
            % Verificar que las columnas requeridas existan
            columnasRequeridas = {'fechaHoraLecturaDato', 'latitud', 'longitud', 'codigoEvento', 'codigoComportamientoAnomalo'};
            if ~all(ismember(columnasRequeridas, datos.Properties.VariableNames))
                error('La tabla de entrada no contiene las columnas necesarias.');
            end
            
            % Filtrar solo los datos del evento 19
            datosEvento19 = datos(datos.codigoEvento == "EV19", :);
            
            % Inicializar tablas de salida
            tabla1 = table();
            tabla2 = table();
            tabla3 = table();
            tabla4 = table();
            
            % Verificar y asignar datos para cada código de comportamiento anómalo
            for codigo = 1:4
                datosFiltrados = datosEvento19(datosEvento19.codigoComportamientoAnomalo == string(codigo), {'fechaHoraLecturaDato', 'latitud', 'longitud', 'codigoComportamientoAnomalo'});
                switch codigo
                    case 1
                        tabla1 = datosFiltrados;
                    case 2
                        tabla2 = datosFiltrados;
                    case 3
                        tabla3 = datosFiltrados;
                    case 4
                        tabla4 = datosFiltrados;
                end
            end
        end
        
        
        
        function folders = getFolderList(baseFolder)
            % Esta función devuelve una lista de carpetas dentro de la carpeta especificada.
            if ~exist(baseFolder, 'dir')
                error('La ruta especificada no existe.');
            end
            items = dir(baseFolder);
            isFolder = [items.isdir];
            folderNames = {items(isFolder).name};
            folders = folderNames(~ismember(folderNames, {'.', '..'}));
        end
        
        %%
        
        
        function busesDatos = importarTodosLosDatos(basePath, busesDatos)
    % Esta función importa todos los datos de sensores para cada bus en cada fecha disponible bajo la carpeta base.
    % basePath es la ruta a la carpeta 'Datos'.
    % busesDatos es una estructura opcional de entrada que contiene datos previos.

    % Verificar si se proporcionó la estructura busesDatos
    if nargin < 2
        busesDatos = struct(); % Crear una nueva estructura si no se proporcionó
    end

    % Obtener la lista de carpetas de fechas
    fechas = ImportarDatos.getFolderList(basePath);

    % Iterar sobre cada fecha
    for i = 1:length(fechas)
        fechaPath = fullfile(basePath, fechas{i});

        % Normalizar nombre de campo para fecha (añadir 'f_' y reemplazar guiones con guiones bajos)
        fechaFieldName = ['f_' strrep(fechas{i}, '-', '_')];

        % Obtener la lista de buses en esta fecha
        buses = ImportarDatos.getFolderList(fechaPath);

        % Iterar sobre cada bus
        for j = 1:length(buses)
            busPath = fullfile(fechaPath, buses{j});
            busFieldName = ['bus_' buses{j}];  % Añadir 'bus_' para hacer el nombre válido

            rutalogs = fullfile(fechaPath, strrep(buses{j}, 'bus_', ''), 'log');

            try 
                datosP20 = ImportarDatos.P20(rutalogs);
                datosP60 = ImportarDatos.P60(rutalogs);

                datosE19 = ImportarDatos.Evento19(rutalogs);
                datosE1 = ImportarDatos.Evento1(rutalogs);
                datosE2 = ImportarDatos.Evento2(rutalogs);
                datosE8 = ImportarDatos.Evento8(rutalogs);
                datosE18 = ImportarDatos.Evento18(rutalogs);
            catch Me


                % Mostrar el mensaje de error
    disp('Ocurrió un error durante la importación de datos:');
    disp(getReport(Me, 'extended'));

                datosP20 = {};
                datosP60 = {};

                datosE19 = {};
                datosE1 =  {};
                datosE2 =  {};
                datosE8 =  {};
                datosE18 =  {};
            end

            % Importar los datos del sensor
            datosSensor = ImportarDatos.Sensor(busPath);
            datosCordenadasSensor = ImportarDatos.SensorCordenadas(datosSensor);

            % Guardar los datos en una estructura organizada por fecha y bus
            if ~isfield(busesDatos, fechaFieldName)
                busesDatos.(fechaFieldName) = struct();
            end
            if ~isfield(busesDatos.(fechaFieldName), busFieldName)
                busesDatos.(fechaFieldName).(busFieldName) = struct();
            end

            % Inicializar la estructura del bus con una subestructura para los datos del sensor
            % y un campo adicional para datos extras
            busesDatos.(fechaFieldName).(busFieldName).datosSensor = datosCordenadasSensor;
            busesDatos.(fechaFieldName).(busFieldName).P20 = datosP20;
            busesDatos.(fechaFieldName).(busFieldName).P60 = datosP60;

            busesDatos.(fechaFieldName).(busFieldName).EV19 = datosE19;
            busesDatos.(fechaFieldName).(busFieldName).EV1 = datosE1;
            busesDatos.(fechaFieldName).(busFieldName).EV2 = datosE2;
            busesDatos.(fechaFieldName).(busFieldName).EV8 = datosE8;
            busesDatos.(fechaFieldName).(busFieldName).EV18 = datosE18;
        end
    end
        end




        %%

        function mar = Evento9(carpeta)
    if nargin < 1
        carpeta = '4001_15_02'; % Carpeta predeterminada
    end

    nombre_archivo = 'EV9.csv'; % Nombre del archivo a leer
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




        
        %%

function datosBuses = agregarCodigoConductor(datosBuses)
    % Esta función crea y agrega una tabla con columnas 'IDConductor' y 'Sexo' a cada bus en la estructura de datos proporcionada.
    % Además, agrega una fila inicial con los valores 0 para ambas columnas.
    
    % Crear una tabla con una fila inicial con los valores 0 para 'IDConductor' y 'Sexo'
    tablaInicial = table([0], [0], 'VariableNames', {'IDConductor', 'Sexo'});
    
    % Fechas disponibles en los datos
    fechas = fieldnames(datosBuses);
    
    % Iterar sobre cada fecha
    for i = 1:numel(fechas)
        fecha = fechas{i};
        buses = fieldnames(datosBuses.(fecha));
        
        % Iterar sobre cada bus en la fecha actual
        for j = 1:numel(buses)
            bus = buses{j};
            
            % Agregar la tabla con la fila inicial a cada bus
            datosBuses.(fecha).(bus).codigoConductor = tablaInicial;
        end
    end
    
    return;
end



        %%


        function datosReorganizados = reorganizarDatosBuses(datosBuses)
    % Inicializar la nueva estructura
    datosReorganizados = struct();
    
    % Obtener todas las fechas disponibles en datosBuses
    fechas = fieldnames(datosBuses);
    
    % Iterar sobre cada fecha para acceder a los datos de cada bus
    for i = 1:numel(fechas)
        fecha = fechas{i};
        buses = fieldnames(datosBuses.(fecha));
        
        % Iterar sobre cada bus en la fecha dada
        for j = 1:numel(buses)
            bus = buses{j};

            
            
            % Asegurarse de que cada bus sea una estructura y contenga las rutas de ida y vuelta
            if isstruct(datosBuses.(fecha).(bus)) && isfield(datosBuses.(fecha).(bus), 'PromediosIda') && isfield(datosBuses.(fecha).(bus), 'PromediosVuelta')
                % Reorganizar los datos para la ruta de ida
                if ~isfield(datosReorganizados, bus)
                    datosReorganizados.(bus) = struct();
                end
                if ~isfield(datosReorganizados.(bus), 'ida')
                    datosReorganizados.(bus).ida = struct();
                end
                if ~isfield(datosReorganizados.(bus).ida, 'General')
                    datosReorganizados.(bus).ida.General = [];  % Asegura que el campo General esté inicializado.
                end
                % Inicializar campos de hora pico y hora valle si no existen
                if ~isfield(datosReorganizados.(bus).ida, 'horaPico')
                    datosReorganizados.(bus).ida.horaPico = [];  % Asegura que el campo horaPico esté inicializado.
                end
                if ~isfield(datosReorganizados.(bus).ida, 'horaValle')
                    datosReorganizados.(bus).ida.horaValle = [];  % Asegura que el campo horaValle esté inicializado.
                end
                if ~isfield(datosReorganizados.(bus).ida, 'horaLibre')
                    datosReorganizados.(bus).ida.horaLibre = [];  % Asegura que el campo horaValle esté inicializado.
                end


try
 
    tabla1 = [...
                    datosBuses.(fecha).(bus).PromediosIda, ...
                    datosBuses.(fecha).(bus).PromediosConsumoIda...
                    datosBuses.(fecha).(bus).velocidadRuta(:,1),...
                    datosBuses.(fecha).(bus).tiempoRuta(:, [1, 2])...
                    datosBuses.(fecha).(bus).codigoConductor,...
                    datosBuses.(fecha).(bus).aceleracionRuta(:,1),...
                    datosBuses.(fecha).(bus).picosAceleracion(:,1)
                    ];

                tabla1.Properties.VariableNames{1} = 'Promedio velocidad';
                tabla1.Properties.VariableNames{2} = 'Promedio consumo';
                tabla1.Properties.VariableNames{3} = 'Velocidad';
                tabla1.Properties.VariableNames{4} = 'Hora Inicio';
                tabla1.Properties.VariableNames{5} = 'Hora Fin';
                tabla1.Properties.VariableNames{6} = 'Codigo conductor';
                tabla1.Properties.VariableNames{7} = 'Sexo';
                tabla1.Properties.VariableNames{8} = 'Aceleracion';
                tabla1.Properties.VariableNames{9} = 'Picos Aceleracion';

catch ME
    % Manejo de errores con un mensaje descriptivo
    fprintf('Error al crear y configurar la tabla: %s\n', ME.message);
end

                
                % Asigna este cell array a la estructura
                datosReorganizados.(bus).ida.(fecha) = tabla1;
                
                datosReorganizados.(bus).ida.General = [datosReorganizados.(bus).ida.General; datosReorganizados.(bus).ida.(fecha)];


                horaInicioPico1 = 5.5;   % Hora de inicio del primer rango de hora pico
                horaFinPico1 = 6.5;      % Hora de fin del primer rango de hora pico
                
                horaInicioPico2 = 17;    % Hora de inicio del segundo rango de hora pico (5 PM)
                horaFinPico2 = 18;       % Hora de fin del segundo rango de hora pico (6 PM)
                
                horaInicioFlujoLibre1 = 1;  % Hora de inicio del primer rango de hora de flujo libre
                horaFinFlujoLibre1 = 5;     % Hora de fin del primer rango de hora de flujo libre
                
                horaInicioFlujoLibre2 = 21;  % Hora de inicio del segundo rango de hora de flujo libre
                horaFinFlujoLibre2 = 23;     % Hora de fin del segundo rango de hora de flujo libre


                % Calcular horas de inicio y fin en formato decimal
                horasInicio = hour(datetime([datosBuses.(fecha).(bus).tiempoRuta{:, 1}], 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) + ...
                              (minute(datetime([datosBuses.(fecha).(bus).tiempoRuta{:, 1}], 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) / 60);
                horasFin = hour(datetime([datosBuses.(fecha).(bus).tiempoRuta{:, 3}], 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) + ...
                           (minute(datetime([datosBuses.(fecha).(bus).tiempoRuta{:, 3}], 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) / 60);
                
              % Crear un vector con intervalos de tiempo desde horasInicio hasta horasFin
                intervalosTiempo = arrayfun(@(inicio, fin) linspace(inicio, fin, 100), horasInicio, horasFin, 'UniformOutput', false);
                
                % Inicializar índices
                indicesPico = false(size(horasInicio));
                indicesFlujoLibre = false(size(horasInicio));
                
                % Verificar si alguno de los puntos en los intervalos está en las horas pico o flujo libre
                for i = 1:length(intervalosTiempo)
                    intervalo = intervalosTiempo{i};
                    % Verificar para los intervalos de hora pico
                    if any((intervalo >= horaInicioPico1 & intervalo <= horaFinPico1)) || ...
                       any((intervalo >= horaInicioPico2 & intervalo <= horaFinPico2))
                        indicesPico(i) = true;
                    % Verificar para los intervalos de hora de flujo libre
                    elseif any((intervalo >= horaInicioFlujoLibre1 & intervalo <= horaFinFlujoLibre1)) || ...
                           any((intervalo >= horaInicioFlujoLibre2 & intervalo <= horaFinFlujoLibre2))
                        indicesFlujoLibre(i) = true;
                    end
                end

                % Los índices restantes son hora valle
                indicesValle = ~(indicesPico | indicesFlujoLibre);
                
                % Reorganizar los datos en las categorías correspondientes
                datosReorganizados.(bus).ida.horaPico = [datosReorganizados.(bus).ida.horaPico; datosReorganizados.(bus).ida.(fecha)(indicesPico, :)];
                datosReorganizados.(bus).ida.horaLibre = [datosReorganizados.(bus).ida.horaLibre; datosReorganizados.(bus).ida.(fecha)(indicesFlujoLibre, :)];
                datosReorganizados.(bus).ida.horaValle = [datosReorganizados.(bus).ida.horaValle; datosReorganizados.(bus).ida.(fecha)(indicesValle, :)];


                % Reorganizar los datos para la ruta de vuelta
                if ~isfield(datosReorganizados.(bus), 'vuelta')
                    datosReorganizados.(bus).vuelta = struct();
                end

                if ~isfield(datosReorganizados.(bus).vuelta, 'General')
                    datosReorganizados.(bus).vuelta.General = [];  % Asegura que el campo General esté inicializado.
                end
                % Inicializar campos de hora pico y hora valle si no existen
                if ~isfield(datosReorganizados.(bus).vuelta, 'horaPico')
                    datosReorganizados.(bus).vuelta.horaPico = [];  % Asegura que el campo horaPico esté inicializado.
                end
                if ~isfield(datosReorganizados.(bus).vuelta, 'horaValle')
                    datosReorganizados.(bus).vuelta.horaValle = [];  % Asegura que el campo horaValle esté inicializado.
                end
                if ~isfield(datosReorganizados.(bus).vuelta, 'horaLibre')
                    datosReorganizados.(bus).vuelta.horaLibre = [];  % Asegura que el campo horaValle esté inicializado.
                end

try

                tabla2 = [...
                    datosBuses.(fecha).(bus).PromediosVuelta, ...
                    datosBuses.(fecha).(bus).PromediosConsumoVuelta, ...
                    datosBuses.(fecha).(bus).velocidadRuta(:,2),...
                    datosBuses.(fecha).(bus).tiempoRuta(:, [2, 3])...
                    datosBuses.(fecha).(bus).codigoConductor,...
                    datosBuses.(fecha).(bus).aceleracionRuta(:,2),...
                    datosBuses.(fecha).(bus).picosAceleracion(:,2)];


                datosBuses.(fecha).(bus).aceleracionRuta(:,1)

                tabla2.Properties.VariableNames{1} = 'Promedio velocidad';
                tabla2.Properties.VariableNames{2} = 'Promedio consumo';
                tabla2.Properties.VariableNames{3} = 'Velocidad';
                tabla2.Properties.VariableNames{4} = 'Hora Inicio';
                tabla2.Properties.VariableNames{5} = 'Hora Fin';
                tabla2.Properties.VariableNames{6} = 'Codigo conductor';
                tabla2.Properties.VariableNames{7} = 'Sexo';
                tabla2.Properties.VariableNames{8} = 'Aceleracion';
                tabla2.Properties.VariableNames{9} = 'Picos Aceleracion';

catch ME
    % Manejo de errores con un mensaje descriptivo
    fprintf('Error al crear y configurar la tabla: %s\n', ME.message);
end


                % Asigna este cell array a la estructura
                datosReorganizados.(bus).vuelta.(fecha) = tabla2;

                datosReorganizados.(bus).vuelta.General = [datosReorganizados.(bus).vuelta.General; datosReorganizados.(bus).vuelta.(fecha)];
            

                datosReorganizados.(bus).vuelta.horaPico = [datosReorganizados.(bus).vuelta.horaPico; datosReorganizados.(bus).vuelta.(fecha)(indicesPico, :)];
                
                datosReorganizados.(bus).vuelta.horaValle = [datosReorganizados.(bus).vuelta.horaValle; datosReorganizados.(bus).vuelta.(fecha)(indicesValle, :)];

                datosReorganizados.(bus).vuelta.horaLibre = [datosReorganizados.(bus).vuelta.horaLibre; datosReorganizados.(bus).vuelta.(fecha)(indicesFlujoLibre, :)];
                
            
            
            end
        end
    end
end
        
        
        
        
    end
end
