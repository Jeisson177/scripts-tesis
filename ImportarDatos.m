
classdef ImportarDatos


    properties (Constant)
        CommonVars = {'versionTrama','idRegistro','idOperador','idVehiculo','idRuta','idConductor',...
            'fechaHoraLecturaDato','fechaHoraEnvioDato','tipoBus','latitud','longitud','tipoTrama',...
            'tecnologiaMotor','tramaRetransmitida','tipoFreno'};

        CommonTypes = {'string','string','string','string','string','string','datetime','datetime','string','double','double','string','logical','string','string'};
        DateVars = {'fechaHoraLecturaDato','fechaHoraEnvioDato'};
        DecimalVars = {'latitud', 'longitud'};
    end


    methods (Static)



        function opts = createImportOptions(numVariables, variableNames, variableTypes, dateVars, decimalVars, initLine)
            opts = delimitedTextImportOptions("NumVariables", numVariables);
            opts.DataLines = [initLine, Inf];
            opts.Delimiter = ",";
            opts.VariableNames = variableNames;
            opts.VariableTypes = variableTypes;
            opts.ExtraColumnsRule = "ignore";
            opts.EmptyLineRule = "read";
            opts = setvaropts(opts, dateVars, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
            opts = setvaropts(opts, decimalVars, 'DecimalSeparator', '.');
        end

        function data = importData(folder, fileName, numVariables, variableNames, variableTypes, dateVars, decimalVars, initLine)
            if nargin < 1
                folder = pwd; % Directorio actual por defecto
            end
            filePath = fullfile(folder, fileName);


            fid = fopen(filePath, 'rt');
            if fid == -1
                error('No se pudo abrir el archivo: %s', filePath);
            end
            lineCount = 0;
            while ~feof(fid)
                line = fgetl(fid);
                if ischar(line)
                    lineCount = lineCount + 1;
                end
            end
            fclose(fid);

            % Si el archivo contiene solo encabezados y un salto de línea, devolver una tabla vacía
            if lineCount <= 1
                warning('El archivo %s está vacío o solo contiene encabezados.', filePath);
                data = array2table(zeros(0, numVariables), 'VariableNames', variableNames);
                return;
            end

            % Leer el archivo usando las opciones de importación
            opts = ImportarDatos.createImportOptions(numVariables, variableNames, variableTypes, dateVars, decimalVars, initLine);
            data = readtable(filePath, opts);
        end



        function datos = Sensor(nombreCarpeta)
            if nargin < 1
                nombreCarpeta = pwd; % Directorio actual por defecto
            end
            archivos = dir(fullfile(nombreCarpeta, '*.txt'));
            datos = cell(1, numel(archivos));
            for i = 1:numel(archivos)
                datos{i} = ImportarDatos.importData(nombreCarpeta, archivos(i).name, 15, ...
                    ["time", "ax", "ay", "az", "mx", "my", "mz", "gx", "gy", "gz", "orx", "oy", "or", "lat", "lon"], ...
                    ["datetime", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"], ...
                    "time", ["ax", "ay", "az", "mx", "my", "mz", "gx", "gy", "gz", "orx", "oy", "or", "lat", "lon"], 1);
            end

            datos = vertcat(datos{:}); % Concatenar todas las tablas en una sola

        end



        function mar = P20(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombre_archivo = 'P20.csv';
            specificVars = {'velocidadVehiculo','aceleracionVehiculo'};
            specificTypes = {'double','double'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            % Utilizar la función auxiliar importData
            mar = ImportarDatos.importData(carpeta, nombre_archivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        %%

        function datosFiltrados = filtrarDatosPorFechas(datos, fechaInicio, fechaFin)
            % FILTRARDATOSPORFECHAS Filtra los datos en un rango de fechas específico.
            %   datosFiltrados = FILTRARDATOSPORFECHAS(datos, fechaInicio, fechaFin)
            %   filtra las filas de la tabla de datos según el rango de fechas
            %   especificado por fechaInicio y fechaFin.
            %
            %   Inputs:
            %       datos - Tabla que contiene los datos a filtrar. La primera columna debe ser de tipo datetime.
            %       fechaInicio - Fecha de inicio del rango. Puede ser de tipo datetime, char o string.
            %       fechaFin - Fecha de fin del rango. Puede ser de tipo datetime, char o string.
            %
            %   Outputs:
            %       datosFiltrados - Tabla que contiene las filas de datos que están dentro del rango de fechas especificado.
            %
            %   Example:
            %       % Suponiendo que 'datos' es una tabla y la primera columna es de tipo datetime:
            %       datosFiltrados = filtrarDatosPorFechas(datos, '2023-01-01 00:00:00.000', '2023-12-31 23:59:59.999');
            %
            %   See also: datetime

            % Convertir fechas de inicio y fin a datetime si son strings o char
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

        function mar = P60(carpeta)
            if nargin < 1
                carpeta = '4001_15_02'; % Carpeta predeterminada
            end

            nombreArchivo = 'P60.csv';
            specificVars = {'temperaturaMotor', 'presionAceiteMotor', 'velocidadVehiculo', 'aceleracionVehiculo', 'revolucionesMotor', 'estadoDesgasteFrenos', 'kilometrosOdometro', 'consumoCombustible', 'nivelTanqueCombustible', 'consumoEnergia', 'regeneracionEnergia', 'nivelRestanteEnergia', 'porcentajeEnergiaGenerada', 'temperaturaSts', 'usoCpuSts', 'memRamSts', 'memDiscoSts', 'temperaturaBaterias', 'sentidoMarcha'};
            specificTypes = {'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            % Utilizar la función auxiliar importData
            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end



        function mar = Evento1(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'EV1.csv';
            specificVars = {'codigoEvento', 'peso', 'temperaturaCabina', 'estimacionOcupacionSuben', 'estimacionOcupacionBajan', 'estimacionOcupacionAbordo'};
            specificTypes = {'string', 'double', 'double', 'double', 'double', 'double'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            % Utilizar la función auxiliar importData
            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end


        function mar = Evento2(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'EV2.csv';
            specificVars = {'codigoEvento', 'estadoAperturaCierrePuertas'};
            specificTypes = {'string', 'string'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Evento19(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'EV19.csv';
            specificVars = {'codigoEvento', 'codigoComportamientoAnomalo'};
            specificTypes = {'string', 'string'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Evento18(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'EV18.csv';
            specificVars = {'codigoEvento'};
            specificTypes = {'string'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Evento13(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'EV13.csv';
            specificVars = {'codigoEvento'};
            specificTypes = {'string'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Evento6(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'EV6.csv';
            specificVars = {'codigoEvento'};
            specificTypes = {'string'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Evento15(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'EV15.csv';
            specificVars = {'codigoEvento'};
            specificTypes = {'string'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Evento14(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'EV14.csv';
            specificVars = {'codigoEvento'};
            specificTypes = {'string'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Evento12(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'EV12.csv';
            specificVars = {'codigoEvento'};
            specificTypes = {'string'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Evento7(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'EV7.csv';
            specificVars = {'codigoEvento'};
            specificTypes = {'string'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Evento8(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'EV8.csv';
            specificVars = {'codigoEvento'};
            specificTypes = {'string'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Evento16(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'EV16.csv';
            specificVars = {'codigoEvento'};
            specificTypes = {'string'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Evento17(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'EV17.csv';
            specificVars = {'codigoEvento'};
            specificTypes = {'string'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Evento20(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'EV20.csv';
            specificVars = {'codigoEvento', 'porcentajeCargaBaterias'};
            specificTypes = {'string', 'double'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Evento21(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'EV21.csv';
            specificVars = {'codigoEvento', 'porcentajeCargaBaterias'};
            specificTypes = {'string', 'double'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Alarma10(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'ALA10.csv';
            specificVars = {'codigoAlarma', 'nivelAlarma', 'estadoDesgasteFrenos'};
            specificTypes = {'string', 'double', 'double'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Alarma2(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'ALA2.csv';
            specificVars = {'codigoAlarma', 'nivelAlarma', 'aceleracionVehiculo'};
            specificTypes = {'string', 'double', 'double'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Alarma3(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'ALA3.csv';
            specificVars = {'codigoAlarma', 'nivelAlarma', 'velocidadVehiculo'};
            specificTypes = {'string', 'double', 'double'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Alarma5(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'ALA5.csv';
            specificVars = {'codigoAlarma', 'nivelAlarma', 'codigoCamara'};
            specificTypes = {'string', 'double', 'string'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Alarma8(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'ALA8.csv';
            specificVars = {'codigoAlarma', 'nivelAlarma', 'estadoCinturonSeguridad'};
            specificTypes = {'string', 'double', 'string'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end


        function mar = Alarma9(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'ALA9.csv';
            specificVars = {'codigoAlarma', 'nivelAlarma', 'estadoInfoEntretenimiento'};
            specificTypes = {'string', 'double', 'string'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
        end

        function mar = Alarma1(carpeta)
            if nargin < 1
                carpeta = pwd; % Carpeta predeterminada
            end

            nombreArchivo = 'ALA1.csv';
            specificVars = {'codigoAlarma', 'nivelAlarma', 'aceleracionVehiculo'};
            specificTypes = {'string', 'double', 'double'};
            variableNames = [ImportarDatos.CommonVars, specificVars];
            variableTypes = [ImportarDatos.CommonTypes, specificTypes];

            mar = ImportarDatos.importData(carpeta, nombreArchivo, numel(variableNames), variableNames, variableTypes, ImportarDatos.DateVars, ImportarDatos.DecimalVars, 2);
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
            clc;
            % Esta función importa todos los datos de sensores para cada bus en cada fecha disponible bajo la carpeta base.
            % basePath es la ruta a la carpeta 'Datos'.
            % busesDatos es una estructura opcional de entrada que contiene datos previos.

            % Verificar si se proporcionó la estructura busesDatos
            if nargin < 2
                busesDatos = struct(); % Crear una nueva estructura si no se proporcionó
            end

            % Obtener la lista de carpetas de buses con fechas
            carpetas = ImportarDatos.getFolderList(basePath);

            % Iterar sobre cada carpeta
            for i = 1:length(carpetas)
                carpetaPath = fullfile(basePath, carpetas{i});
                partes = strsplit(carpetas{i}, '-');
                busID = partes{1};
                fecha = strjoin(partes(2:end), '-');

                busFieldName = ['bus_' busID];  % Añadir 'bus_' para hacer el nombre válido
                fechaFieldName = ['f_' strrep(fecha, '-', '_')];

                % Inicializar la estructura si no existe
                if ~isfield(busesDatos, busFieldName)
                    busesDatos.(busFieldName) = struct();
                end
                if ~isfield(busesDatos.(busFieldName), fechaFieldName)
                    busesDatos.(busFieldName).(fechaFieldName) = struct();
                end

                % Inicializar tablas para datos
                datosCordenadasSensor = table([], [], [], 'VariableNames', {'time', 'lat', 'lon'});
                datosP20 = table(); datosP60 = table();
                datosEV1 = table(); datosEV2 = table(); datosEV6 = table();
                datosEV7 = table(); datosEV8 = table(); datosEV12 = table();
                datosEV13 = table(); datosEV14 = table(); datosEV15 = table();
                datosEV16 = table(); datosEV17 = table(); datosEV18 = table();
                datosEV19 = table(); datosEV20 = table(); datosEV21 = table();
                datosALA1 = table(); datosALA2 = table(); datosALA3 = table();
                datosALA5 = table(); datosALA8 = table(); datosALA9 = table(); datosALA10 = table();

                % Telefono
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosSensor = ImportarDatos.Sensor(carpetaPath);
                    % Verificar si las columnas necesarias existen
                    if all(ismember({'time', 'lat', 'lon'}, datosSensor.Properties.VariableNames))
                        datosCordenadasSensor = datosSensor(:, {'time', 'lat', 'lon'});
                    else
                        warning('La carpeta %s no contiene las variables requeridas.', carpetaPath);
                    end
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del telefono de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end
                % P20
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosP20 = ImportarDatos.P20(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la trama P20 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end
                % P60
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosP60 = ImportarDatos.P60(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la trama P60 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end
                % EV1
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV1 = ImportarDatos.Evento1(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento 1 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV2
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV2 = ImportarDatos.Evento2(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento 2 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV6
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV6 = ImportarDatos.Evento6(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento 6 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV7
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV7 = ImportarDatos.Evento7(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento7 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV8
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV8 = ImportarDatos.Evento8(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento8 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV12
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV12 = ImportarDatos.Evento12(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento12 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV13
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV13 = ImportarDatos.Evento13(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento13 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV14
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV14 = ImportarDatos.Evento14(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento14 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV15
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV15 = ImportarDatos.Evento15(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento15 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV16
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV16 = ImportarDatos.Evento16(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento16 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV17
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV17 = ImportarDatos.Evento17(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento17 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV18
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV18 = ImportarDatos.Evento18(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento18 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV19
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV19 = ImportarDatos.Evento19(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento19 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV20
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV20 = ImportarDatos.Evento20(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento20 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV21
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV21 = ImportarDatos.Evento21(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento21 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % ALA1
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosALA1 = ImportarDatos.Alarma1(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la alarma 1 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % ALA2
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosALA2 = ImportarDatos.Alarma2(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la alarma 2 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % ALA3
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosALA3 = ImportarDatos.Alarma3(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la alarma 3 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % ALA5
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosALA5 = ImportarDatos.Alarma5(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la alarma 5 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % ALA8
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosALA8 = ImportarDatos.Alarma8(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la alarma 8 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % ALA9
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosALA9 = ImportarDatos.Alarma9(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la alarma 9 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % ALA10
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosALA10 = ImportarDatos.Alarma10(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la alarma 10 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % Guardar los datos en la estructura organizada por bus y fecha
                busesDatos.(busFieldName).(fechaFieldName).datosSensor = datosCordenadasSensor;
                busesDatos.(busFieldName).(fechaFieldName).P20 = datosP20;
                busesDatos.(busFieldName).(fechaFieldName).P60 = datosP60;

                busesDatos.(busFieldName).(fechaFieldName).EV1 = datosEV1;
                busesDatos.(busFieldName).(fechaFieldName).EV2 = datosEV2;
                busesDatos.(busFieldName).(fechaFieldName).EV6 = datosEV6;
                busesDatos.(busFieldName).(fechaFieldName).EV7 = datosEV7;
                busesDatos.(busFieldName).(fechaFieldName).EV8 = datosEV8;
                busesDatos.(busFieldName).(fechaFieldName).EV12 = datosEV12;
                busesDatos.(busFieldName).(fechaFieldName).EV13 = datosEV13;
                busesDatos.(busFieldName).(fechaFieldName).EV14 = datosEV14;
                busesDatos.(busFieldName).(fechaFieldName).EV15 = datosEV15;
                busesDatos.(busFieldName).(fechaFieldName).EV16 = datosEV16;
                busesDatos.(busFieldName).(fechaFieldName).EV17 = datosEV17;
                busesDatos.(busFieldName).(fechaFieldName).EV18 = datosEV18;
                busesDatos.(busFieldName).(fechaFieldName).EV19 = datosEV19;
                busesDatos.(busFieldName).(fechaFieldName).EV20 = datosEV20;
                busesDatos.(busFieldName).(fechaFieldName).EV21 = datosEV21;

                busesDatos.(busFieldName).(fechaFieldName).ALA1 = datosALA1;
                busesDatos.(busFieldName).(fechaFieldName).ALA2 = datosALA2;
                busesDatos.(busFieldName).(fechaFieldName).ALA3 = datosALA3;
                busesDatos.(busFieldName).(fechaFieldName).ALA5 = datosALA5;
                busesDatos.(busFieldName).(fechaFieldName).ALA8 = datosALA8;
                busesDatos.(busFieldName).(fechaFieldName).ALA9 = datosALA9;
                busesDatos.(busFieldName).(fechaFieldName).ALA10 = datosALA10;


            end
        end


%%

function busesDatos = importarMuestra(basePath, numero, busesDatos)
            clc;
            % Esta función importa todos los datos de sensores para cada bus en cada fecha disponible bajo la carpeta base.
            % basePath es la ruta a la carpeta 'Datos'.
            % busesDatos es una estructura opcional de entrada que contiene datos previos.

            % Verificar si se proporcionó la estructura busesDatos
            if nargin < 3
                busesDatos = struct(); % Crear una nueva estructura si no se proporcionó
            end

            % Obtener la lista de carpetas de buses con fechas
            carpetas = ImportarDatos.getFolderList(basePath);

            % Iterar sobre cada carpeta
            for i = 1:numero
                carpetaPath = fullfile(basePath, carpetas{i});
                partes = strsplit(carpetas{i}, '-');
                busID = partes{1};
                fecha = strjoin(partes(2:end), '-');

                busFieldName = ['bus_' busID];  % Añadir 'bus_' para hacer el nombre válido
                fechaFieldName = ['f_' strrep(fecha, '-', '_')];

                % Inicializar la estructura si no existe
                if ~isfield(busesDatos, busFieldName)
                    busesDatos.(busFieldName) = struct();
                end
                if ~isfield(busesDatos.(busFieldName), fechaFieldName)
                    busesDatos.(busFieldName).(fechaFieldName) = struct();
                end

                % Inicializar tablas para datos
                datosCordenadasSensor = table([], [], [], 'VariableNames', {'time', 'lat', 'lon'});
                % Telefono
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosSensor = ImportarDatos.Sensor(carpetaPath);
                    % Verificar si las columnas necesarias existen
                    if all(ismember({'time', 'lat', 'lon'}, datosSensor.Properties.VariableNames))
                        datosCordenadasSensor = datosSensor(:, {'time', 'lat', 'lon'});
                    else
                        warning('La carpeta %s no contiene las variables requeridas.', carpetaPath);
                    end
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del telefono de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end
                % P20
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosP20 = ImportarDatos.P20(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la trama P20 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end
                % P60
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosP60 = ImportarDatos.P60(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la trama P60 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end
                % EV1
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV1 = ImportarDatos.Evento1(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento 1 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV2
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV2 = ImportarDatos.Evento2(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento 2 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV6
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV6 = ImportarDatos.Evento6(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento 6 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV7
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV7 = ImportarDatos.Evento7(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento7 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV8
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV8 = ImportarDatos.Evento8(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento8 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV12
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV12 = ImportarDatos.Evento12(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento12 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV13
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV13 = ImportarDatos.Evento13(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento13 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV14
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV14 = ImportarDatos.Evento14(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento14 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV15
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV15 = ImportarDatos.Evento15(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento15 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV16
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV16 = ImportarDatos.Evento16(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento16 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV17
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV17 = ImportarDatos.Evento17(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento17 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV18
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV18 = ImportarDatos.Evento18(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento18 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV19
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV19 = ImportarDatos.Evento19(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento19 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV20
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV20 = ImportarDatos.Evento20(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento20 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % EV21
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosEV21 = ImportarDatos.Evento21(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos del Evento21 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % ALA1
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosALA1 = ImportarDatos.Alarma1(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la alarma 1 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % ALA2
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosALA2 = ImportarDatos.Alarma2(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la alarma 2 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % ALA3
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosALA3 = ImportarDatos.Alarma3(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la alarma 3 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % ALA5
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosALA5 = ImportarDatos.Alarma5(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la alarma 5 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % ALA8
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosALA8 = ImportarDatos.Alarma8(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la alarma 8 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % ALA9
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosALA9 = ImportarDatos.Alarma9(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la alarma 9 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % ALA10
                try
                    % Importar los datos del sensor de la carpeta completa
                    datosALA10 = ImportarDatos.Alarma10(carpetaPath);
                catch Me
                    % Si ocurre un error, mostrar advertencia y el mensaje de error
                    warning('No se pudieron importar datos de la alarma 10 de %s.', carpetaPath);
                    disp(getReport(Me, 'extended'));
                end

                % Guardar los datos en la estructura organizada por bus y fecha
                busesDatos.(busFieldName).(fechaFieldName).datosSensor = datosCordenadasSensor;
                busesDatos.(busFieldName).(fechaFieldName).P20 = datosP20;
                busesDatos.(busFieldName).(fechaFieldName).P60 = datosP60;

                busesDatos.(busFieldName).(fechaFieldName).EV1 = datosEV1;
                busesDatos.(busFieldName).(fechaFieldName).EV2 = datosEV2;
                busesDatos.(busFieldName).(fechaFieldName).EV6 = datosEV6;
                busesDatos.(busFieldName).(fechaFieldName).EV7 = datosEV7;
                busesDatos.(busFieldName).(fechaFieldName).EV8 = datosEV8;
                busesDatos.(busFieldName).(fechaFieldName).EV12 = datosEV12;
                busesDatos.(busFieldName).(fechaFieldName).EV13 = datosEV13;
                busesDatos.(busFieldName).(fechaFieldName).EV14 = datosEV14;
                busesDatos.(busFieldName).(fechaFieldName).EV15 = datosEV15;
                busesDatos.(busFieldName).(fechaFieldName).EV16 = datosEV16;
                busesDatos.(busFieldName).(fechaFieldName).EV17 = datosEV17;
                busesDatos.(busFieldName).(fechaFieldName).EV18 = datosEV18;
                busesDatos.(busFieldName).(fechaFieldName).EV19 = datosEV19;
                busesDatos.(busFieldName).(fechaFieldName).EV20 = datosEV20;
                busesDatos.(busFieldName).(fechaFieldName).EV21 = datosEV21;

                busesDatos.(busFieldName).(fechaFieldName).ALA1 = datosALA1;
                busesDatos.(busFieldName).(fechaFieldName).ALA2 = datosALA2;
                busesDatos.(busFieldName).(fechaFieldName).ALA3 = datosALA3;
                busesDatos.(busFieldName).(fechaFieldName).ALA5 = datosALA5;
                busesDatos.(busFieldName).(fechaFieldName).ALA8 = datosALA8;
                busesDatos.(busFieldName).(fechaFieldName).ALA9 = datosALA9;
                busesDatos.(busFieldName).(fechaFieldName).ALA10 = datosALA10;


            end
        end


        %%

        function datosBuses = agregarCodigoConductor(datosBuses)
            % Esta función crea y agrega una tabla con columnas 'IDConductor' y 'Sexo' a cada bus en la estructura de datos proporcionada.
            % Además, agrega una fila inicial con los valores 0 para ambas columnas.

            % Crear una tabla con una fila inicial con los valores 0 para 'IDConductor' y 'Sexo'
            tablaInicial = table(0, 0, 'VariableNames', {'IDConductor', 'Sexo'});

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
                                datosBuses.(fecha).(bus).picosAceleracion(:,1),...
                                datosBuses.(fecha).(bus).segmentoEV1(:,1),...
                                datosBuses.(fecha).(bus).segmentoEV2(:,1),...
                                datosBuses.(fecha).(bus).segmentoEV8(:,1),...
                                datosBuses.(fecha).(bus).segmentoEV18(:,1),...
                                datosBuses.(fecha).(bus).segmentoEV19_1(:,1),...
                                datosBuses.(fecha).(bus).segmentoEV19_2(:,1),...
                                datosBuses.(fecha).(bus).segmentoEV19_3(:,1),...
                                datosBuses.(fecha).(bus).segmentoEV19_4(:,1)...
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
                            tabla1.Properties.VariableNames{10} = 'Evento 1';
                            tabla1.Properties.VariableNames{11} = 'Evento 2';
                            tabla1.Properties.VariableNames{12} = 'Evento 8';
                            tabla1.Properties.VariableNames{13} = 'Evento 18';
                            tabla1.Properties.VariableNames{14} = 'Evento 19_1';
                            tabla1.Properties.VariableNames{15} = 'Evento 19_2';
                            tabla1.Properties.VariableNames{16} = 'Evento 19_3';
                            tabla1.Properties.VariableNames{17} = 'Evento 19_4';

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



                        catch ME
                            % Manejo de errores con un mensaje descriptivo
                            fprintf('Error al crear y configurar la tabla: %s\n', ME.message);
                        end





                        try

                            tabla2 = [...
                                datosBuses.(fecha).(bus).PromediosVuelta, ...
                                datosBuses.(fecha).(bus).PromediosConsumoVuelta, ...
                                datosBuses.(fecha).(bus).velocidadRuta(:,2),...
                                datosBuses.(fecha).(bus).tiempoRuta(:, [2, 3])...
                                datosBuses.(fecha).(bus).codigoConductor,...
                                datosBuses.(fecha).(bus).aceleracionRuta(:,2),...
                                datosBuses.(fecha).(bus).picosAceleracion(:,2)...
                                datosBuses.(fecha).(bus).segmentoEV1(:,2)

                                ];


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


                            % Asigna este cell array a la estructura
                            datosReorganizados.(bus).vuelta.(fecha) = tabla2;

                            datosReorganizados.(bus).vuelta.General = [datosReorganizados.(bus).vuelta.General; datosReorganizados.(bus).vuelta.(fecha)];


                            datosReorganizados.(bus).vuelta.horaPico = [datosReorganizados.(bus).vuelta.horaPico; datosReorganizados.(bus).vuelta.(fecha)(indicesPico, :)];

                            datosReorganizados.(bus).vuelta.horaValle = [datosReorganizados.(bus).vuelta.horaValle; datosReorganizados.(bus).vuelta.(fecha)(indicesValle, :)];

                            datosReorganizados.(bus).vuelta.horaLibre = [datosReorganizados.(bus).vuelta.horaLibre; datosReorganizados.(bus).vuelta.(fecha)(indicesFlujoLibre, :)];


                        catch ME
                            % Manejo de errores con un mensaje descriptivo
                            fprintf('Error al crear y configurar la tabla: %s\n', ME.message);
                        end





                    end
                end
            end
        end

        %%

        function datosReorganizados = reorganizarDatosRutas(datosBuses)
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
                    if isstruct(datosBuses.(fecha).(bus)) && isfield(datosBuses.(fecha).(bus), 'tiempoRuta')
                        tiempoRuta = datosBuses.(fecha).(bus).tiempoRuta;

                        % Iterar sobre cada entrada en tiempoRuta
                        for k = 1:size(tiempoRuta, 1)
                            ruta = tiempoRuta{k, 4}; % Nombre de la ruta
                            datos = tiempoRuta(k, :); % Datos de la fila actual

                            % Inicializar la estructura para la ruta si no existe
                            if ~isfield(datosReorganizados, ruta)
                                datosReorganizados.(ruta) = struct('ida', [], 'vuelta', []);
                            end

                            % Determinar si es ida o vuelta (suponiendo que esto está determinado por alguna lógica específica)




                            if ~isfield(datosReorganizados.(ruta), 'ida')
                                datosReorganizados.(ruta).ida = struct();
                            end
                            if ~isfield(datosReorganizados.(ruta).ida, 'General')
                                datosReorganizados.(ruta).ida.General = [];  % Asegura que el campo General esté inicializado.
                            end
                            % Inicializar campos de hora pico y hora valle si no existen
                            if ~isfield(datosReorganizados.(ruta).ida, 'horaPico')
                                datosReorganizados.(ruta).ida.horaPico = [];  % Asegura que el campo horaPico esté inicializado.
                            end
                            if ~isfield(datosReorganizados.(ruta).ida, 'horaValle')
                                datosReorganizados.(ruta).ida.horaValle = [];  % Asegura que el campo horaValle esté inicializado.
                            end
                            if ~isfield(datosReorganizados.(ruta).ida, 'horaLibre')
                                datosReorganizados.(ruta).ida.horaLibre = [];  % Asegura que el campo horaValle esté inicializado.
                            end



                            try


                                tabla1 = table(...
                                    datosBuses.(fecha).(bus).PromediosIda(k), ...
                                    datosBuses.(fecha).(bus).PromediosConsumoIda(k), ...
                                    datosBuses.(fecha).(bus).velocidadRuta(k, 1), ...
                                    datosBuses.(fecha).(bus).tiempoRuta(k, 1), ...
                                    datosBuses.(fecha).(bus).tiempoRuta(k, 2), ...
                                    datosBuses.(fecha).(bus).codigoConductor(k, :).IDConductor, ...
                                    datosBuses.(fecha).(bus).codigoConductor(k, :).Sexo, ...
                                    datosBuses.(fecha).(bus).aceleracionRuta(k, 1), ...
                                    datosBuses.(fecha).(bus).picosAceleracion(k, 1), ...
                                    datosBuses.(fecha).(bus).segmentoEV1(k, 1), ...
                                    datosBuses.(fecha).(bus).segmentoEV2(k, 1), ...
                                    datosBuses.(fecha).(bus).segmentoEV8(k, 1), ...
                                    datosBuses.(fecha).(bus).segmentoEV18(k, 1), ...
                                    datosBuses.(fecha).(bus).segmentoEV19_1(k, 1), ...
                                    datosBuses.(fecha).(bus).segmentoEV19_2(k, 1), ...
                                    datosBuses.(fecha).(bus).segmentoEV19_3(k, 1), ...
                                    datosBuses.(fecha).(bus).segmentoEV19_4(k, 1), ...
                                    datosBuses.(fecha).(bus).segmentosDatos(k, 1), ...
                                    0, ...
                                    'VariableNames', {'PromedioVelocidad', 'PromedioConsumo', 'Velocidad', 'HoraInicio', 'HoraFin', ...
                                    'CodigoConductor', 'Sexo', 'Aceleracion', 'PicosAceleracion', 'EventoUno', 'EventoDos', ...
                                    'EventoOcho', 'EventoDieciocho', 'EventoMicrosueño', 'EventoFumando', 'EventoCelular',...
                                    'EventoDistraido', 'DatosSensor', 'Horario'});




                                horaInicioPico1 = 5.5;   % Hora de inicio del primer rango de hora pico
                                horaFinPico1 = 6.5;      % Hora de fin del primer rango de hora pico

                                horaInicioPico2 = 17;    % Hora de inicio del segundo rango de hora pico (5 PM)
                                horaFinPico2 = 18;       % Hora de fin del segundo rango de hora pico (6 PM)

                                horaInicioFlujoLibre1 = 1;  % Hora de inicio del primer rango de hora de flujo libre
                                horaFinFlujoLibre1 = 5;     % Hora de fin del primer rango de hora de flujo libre

                                horaInicioFlujoLibre2 = 21;  % Hora de inicio del segundo rango de hora de flujo libre
                                horaFinFlujoLibre2 = 23;     % Hora de fin del segundo rango de hora de flujo libre


                                % Calcular horas de inicio y fin en formato decimal
                                horasInicio = hour(datetime([datosBuses.(fecha).(bus).tiempoRuta{k, 1}], 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) + ...
                                    (minute(datetime([datosBuses.(fecha).(bus).tiempoRuta{k, 1}], 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) / 60);
                                horasFin = hour(datetime([datosBuses.(fecha).(bus).tiempoRuta{k, 2}], 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) + ...
                                    (minute(datetime([datosBuses.(fecha).(bus).tiempoRuta{k, 2}], 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) / 60);

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
                                % Si hay índices válidos para horaPico, agregar los datos correspondientes
                                % Asignar los valores específicos al campo "Horario"
                                if any(indicesPico)
                                    tabla1.Horario = 0; % Hora Pico
                                    datosReorganizados.(ruta).ida.horaPico = [datosReorganizados.(ruta).ida.horaPico; tabla1];
                                end

                                if any(indicesFlujoLibre)
                                    tabla1.Horario = 2; % Hora Libre
                                    datosReorganizados.(ruta).ida.horaLibre = [datosReorganizados.(ruta).ida.horaLibre; tabla1];
                                end

                                if any(indicesValle)
                                    tabla1.Horario = 1; % Hora Valle
                                    datosReorganizados.(ruta).ida.horaValle = [datosReorganizados.(ruta).ida.horaValle; tabla1];
                                end


                                % Asigna este cell array a la estructura
                                if ~isfield(datosReorganizados.(ruta).ida, fecha)
                                    datosReorganizados.(ruta).ida.(fecha) = tabla1;
                                else
                                    %ImportarDatos.compareTables(datosReorganizados.(ruta).ida.(fecha), tabla1)
                                    datosReorganizados.(ruta).ida.(fecha) = vertcat(datosReorganizados.(ruta).ida.(fecha), tabla1);

                                end

                                datosReorganizados.(ruta).ida.General = [datosReorganizados.(ruta).ida.General; tabla1];




                            catch ME
                                % Manejo de errores con un mensaje descriptivo
                                fprintf('Error al crear y configurar la tabla: %s\n', ME.message);
                                fprintf('Error ID: %s\n', ME.identifier);
                                fprintf('Error Stack:\n');
                                for k = 1:length(ME.stack)
                                    fprintf('    En %s (línea %d)\n', ME.stack(k).file, ME.stack(k).line);
                                end
                            end




                            try



                                % Reorganizar los datos para la ruta de vuelta
                                if ~isfield(datosReorganizados.(ruta), 'vuelta')
                                    datosReorganizados.(ruta).vuelta = struct();
                                end

                                if ~isfield(datosReorganizados.(ruta).vuelta, 'General')
                                    datosReorganizados.(ruta).vuelta.General = [];  % Asegura que el campo General esté inicializado.
                                end
                                % Inicializar campos de hora pico y hora valle si no existen
                                if ~isfield(datosReorganizados.(ruta).vuelta, 'horaPico')
                                    datosReorganizados.(ruta).vuelta.horaPico = [];  % Asegura que el campo horaPico esté inicializado.
                                end
                                if ~isfield(datosReorganizados.(ruta).vuelta, 'horaValle')
                                    datosReorganizados.(ruta).vuelta.horaValle = [];  % Asegura que el campo horaValle esté inicializado.
                                end
                                if ~isfield(datosReorganizados.(ruta).vuelta, 'horaLibre')
                                    datosReorganizados.(ruta).vuelta.horaLibre = [];  % Asegura que el campo horaValle esté inicializado.
                                end



                                tabla2 = table(...
                                    datosBuses.(fecha).(bus).PromediosVuelta(k), ...
                                    datosBuses.(fecha).(bus).PromediosConsumoVuelta(k), ...
                                    datosBuses.(fecha).(bus).velocidadRuta(k, 2), ...
                                    datosBuses.(fecha).(bus).tiempoRuta(k, 2), ...
                                    datosBuses.(fecha).(bus).tiempoRuta(k, 3), ...
                                    datosBuses.(fecha).(bus).codigoConductor(k, :).IDConductor, ...
                                    datosBuses.(fecha).(bus).codigoConductor(k, :).Sexo, ...
                                    datosBuses.(fecha).(bus).aceleracionRuta(k, 2), ...
                                    datosBuses.(fecha).(bus).picosAceleracion(k, 2), ...
                                    datosBuses.(fecha).(bus).segmentoEV1(k, 2), ...
                                    datosBuses.(fecha).(bus).segmentoEV2(k, 2), ...
                                    datosBuses.(fecha).(bus).segmentoEV8(k, 2), ...
                                    datosBuses.(fecha).(bus).segmentoEV18(k, 2), ...
                                    datosBuses.(fecha).(bus).segmentoEV19_1(k, 2), ...
                                    datosBuses.(fecha).(bus).segmentoEV19_2(k, 2), ...
                                    datosBuses.(fecha).(bus).segmentoEV19_3(k, 2), ...
                                    datosBuses.(fecha).(bus).segmentoEV19_4(k, 2), ...
                                    datosBuses.(fecha).(bus).segmentosDatos(k, 2), ...
                                    'VariableNames', {'PromedioVelocidad', 'PromedioConsumo', 'Velocidad', 'HoraInicio', 'HoraFin', ...
                                    'CodigoConductor', 'Sexo', 'Aceleracion', 'PicosAceleracion', 'EventoUno', 'EventoDos', ...
                                    'EventoOcho', 'EventoDieciocho', 'EventoMicrosueño', 'EventoFumando', 'EventoCelular', 'EventoDistraido', 'DatosSensor'});







                                % Calcular horas de inicio y fin en formato decimal
                                horasInicio = hour(datetime([datosBuses.(fecha).(bus).tiempoRuta{k, 2}], 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) + ...
                                    (minute(datetime([datosBuses.(fecha).(bus).tiempoRuta{k, 2}], 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) / 60);
                                horasFin = hour(datetime([datosBuses.(fecha).(bus).tiempoRuta{k, 3}], 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) + ...
                                    (minute(datetime([datosBuses.(fecha).(bus).tiempoRuta{k, 3}], 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) / 60);

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
                                % Si hay índices válidos para horaPico, agregar los datos correspondientes
                                % Asignar los valores específicos al campo "Horario"
                                if any(indicesPico)
                                    tabla2.Horario = 0; % Hora Pico
                                    datosReorganizados.(ruta).vuelta.horaPico = [datosReorganizados.(ruta).vuelta.horaPico; tabla2];
                                end

                                if any(indicesFlujoLibre)
                                    tabla2.Horario = 2; % Hora Libre
                                    datosReorganizados.(ruta).vuelta.horaLibre = [datosReorganizados.(ruta).vuelta.horaLibre; tabla2];
                                end

                                if any(indicesValle)
                                    tabla2.Horario = 1; % Hora Valle
                                    datosReorganizados.(ruta).vuelta.horaValle = [datosReorganizados.(ruta).vuelta.horaValle; tabla2];
                                end

                                if ~isfield(datosReorganizados.(ruta).vuelta, fecha)
                                    datosReorganizados.(ruta).vuelta.(fecha) = tabla2;
                                else
                                    %ImportarDatos.compareTables(datosReorganizados.(ruta).ida.(fecha), tabla1)
                                    datosReorganizados.(ruta).vuelta.(fecha) = vertcat(datosReorganizados.(ruta).vuelta.(fecha), tabla2);

                                end

                                datosReorganizados.(ruta).vuelta.General = [datosReorganizados.(ruta).vuelta.General; tabla2];






                            catch ME
                                % Manejo de errores con un mensaje descriptivo
                                fprintf('Error al crear y configurar la tabla: %s\n', ME.message);
                            end




                        end

                    end
                end
            end
        end

        function [indicesPico, indicesValle, indicesLibre] = clasificarHoras(datos)
            % Define los rangos de horas pico y flujo libre
            horaInicioPico1 = 5.5;   % Hora de inicio del primer rango de hora pico
            horaFinPico1 = 6.5;      % Hora de fin del primer rango de hora pico
            horaInicioPico2 = 17;    % Hora de inicio del segundo rango de hora pico (5 PM)
            horaFinPico2 = 18;       % Hora de fin del segundo rango de hora pico (6 PM)
            horaInicioFlujoLibre1 = 1;  % Hora de inicio del primer rango de hora de flujo libre
            horaFinFlujoLibre1 = 5;     % Hora de fin del primer rango de hora de flujo libre
            horaInicioFlujoLibre2 = 21;  % Hora de inicio del segundo rango de hora de flujo libre
            horaFinFlujoLibre2 = 23;     % Hora de fin del segundo rango de hora de flujo libre

            % Calcular horas de inicio y fin en formato decimal
            horasInicio = hour(datetime(datos{:, 1}, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) + ...
                (minute(datetime(datos{:, 1}, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) / 60);
            horasFin = hour(datetime(datos{:, 3}, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) + ...
                (minute(datetime(datos{:, 3}, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss')) / 60);

            % Crear un vector con intervalos de tiempo desde horasInicio hasta horasFin
            intervalosTiempo = arrayfun(@(inicio, fin) linspace(inicio, fin, 100), horasInicio, horasFin, 'UniformOutput', false);

            % Inicializar índices
            indicesPico = false(size(horasInicio));
            indicesValle = false(size(horasInicio));
            indicesLibre = false(size(horasInicio));

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
                    indicesLibre(i) = true;
                else
                    indicesValle(i) = true;
                end
            end
        end

        function esIda = isIda(datos)
            % Implementa la lógica para determinar si los datos corresponden a ida o vuelta
            % Aquí puedes basarte en algún criterio específico, como la comparación de coordenadas.
            % Por ejemplo:
            % esIda = true si la ruta es de ida y false si es de vuelta.
            % Puedes cambiar la lógica según tus necesidades.
            esIda = true; % Placeholder, ajusta según tu lógica
        end


        % Función para comparar dos tablas y encontrar diferencias
        function compareTables(tabla1, tabla2)
            % Verificar si tienen el mismo número de columnas
            if width(tabla1) ~= width(tabla2)
                fprintf('Diferente número de columnas: tabla1 tiene %d, tabla2 tiene %d.\n', width(tabla1), width(tabla2));
                return;
            end

            % Verificar si tienen los mismos nombres de columnas
            nombres1 = tabla1.Properties.VariableNames;
            nombres2 = tabla2.Properties.VariableNames;
            if ~isequal(nombres1, nombres2)
                fprintf('Los nombres de las columnas son diferentes.\n');
                disp('Nombres en tabla1:');
                disp(nombres1);
                disp('Nombres en tabla2:');
                disp(nombres2);
                return;
            end

            % Verificar si tienen el mismo tipo de datos en cada columna
            for i = 1:width(tabla1)
                tipo1 = class(tabla1{:, i});
                tipo2 = class(tabla2{:, i});
                if ~strcmp(tipo1, tipo2)
                    fprintf('Diferente tipo de datos en la columna %s: tabla1 tiene %s, tabla2 tiene %s.\n', nombres1{i}, tipo1, tipo2);
                end
            end

            % Verificar diferencias en el contenido de las tablas
            diferencia = find(~ismember(table2cell(tabla1), table2cell(tabla2)));
            if isempty(diferencia)
                disp('Las tablas son iguales en contenido.');
            else
                disp('Las tablas tienen diferencias en contenido.');
                % Mostrar diferencias específicas
                [fila, columna] = ind2sub(size(tabla1), diferencia);
                for idx = 1:length(diferencia)
                    fprintf('Diferencia en fila %d, columna %s: tabla1 tiene %s, tabla2 tiene %s.\n', ...
                        fila(idx), nombres1{columna(idx)}, tabla1{fila(idx), columna(idx)}, tabla2{fila(idx), columna(idx)});
                end
            end
        end




    end
end
