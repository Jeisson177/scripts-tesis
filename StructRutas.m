rutas = struct();
rutas.Ruta4020.Ida = [4.593216, -74.178910];
rutas.Ruta4020.Vuelta = [4.6096941, -74.0738544];

rutas.Ruta4104.Ida = [4.587917000000000, -74.149976900000000];
rutas.Ruta4104.Vuelta = [4.562243400000000, -74.083503800000000];

rutas.Ruta4104S2.Ida = [4.587954800000000, -74.172482000000000];
rutas.Ruta4104S2.Vuelta = [4.652558600000000, -74.061468400000000];

rutas.Ruta4020S2.Ida = [4.575836400000000, -74.168218100000000];
rutas.Ruta4020S2.Vuelta = [4.676501100000000, -74.141395100000000];

%%
clc
% Parámetros de conexión
datasource = "PostgreSQLDataSource";  % Nombre de tu fuente de datos configurada
username = "postgres";                % Usuario
password = "rody2601";                % Contraseña

% Crear la conexión a PostgreSQL
conn = postgresql(datasource, username, password);

% Definir la consulta SQL para obtener rutas distintas
sqlquery = "SELECT DISTINCT idruta FROM P60";

% Ejecutar la consulta y obtener los resultados
result = fetch(conn, sqlquery);

% Cerrar la conexión
close(conn);

% Inicializar un struct para almacenar las rutas y las paradas
rutas = struct();

% Contador para controlar la cantidad de rutas válidas
valid_route_count = 1;

% Iterar sobre cada ruta y buscar las paradas asociadas
for i = 1:size(result, 1)
    % Almacenar el id de la ruta
    idruta = result{i, 1};
    
    % Buscar las paradas asociadas a esta ruta
    stops = buscarParadasConCoordenadas(idruta);
    
    % Si no se encuentran paradas, saltar la ruta
    if isempty(stops)
        continue;  % Saltar esta iteración si no hay paradas
    end
    
    % Si hay paradas, almacenar la ruta y sus paradas en el struct
    rutas(valid_route_count).idruta = idruta;
    rutas(valid_route_count).stops = stops;
    
    % Incrementar el contador de rutas válidas
    valid_route_count = valid_route_count + 1;
end

% Mostrar el struct con rutas y paradas válidas
disp(rutas);

%%

function result = buscarParadasConCoordenadas(route_short_name)
    % Conectar a la base de datos PostgreSQL y buscar las paradas asociadas a la ruta específica

    % Parámetros de conexión
    datasource = "PostgreSQLDataSource";  % Nombre de tu fuente de datos configurada
    username = "postgres";                % Usuario
    password = "rody2601";           % Contraseña

    % Crear la conexión a PostgreSQL
    conn = postgresql(datasource, username, password);

    if ~isopen(conn)
        error('No se pudo conectar a la base de datos.');
    end

    % Definir la consulta SQL
    sqlquery = "SELECT stop_code, stop_name, ST_X(stop_loc::geometry) AS lon, ST_Y(stop_loc::geometry) AS lat FROM stops WHERE stop_id IN (SELECT stop_id FROM stop_times WHERE trip_id IN (SELECT trip_id FROM (SELECT trip_id FROM trips WHERE route_id IN (SELECT route_id FROM routes WHERE route_short_name = '" + route_short_name + "') ORDER BY RANDOM() LIMIT 1  ) AS subquery  ) );";


    % Ejecutar la consulta
    result = fetch(conn, sqlquery);

    % Cerrar la conexión
    close(conn);
end
