% crearTablaExtendida.m
% Crea TablaExtendida.mat: Tabla.mat (337x36) mas las 6 ultimas columnas de
% TablaLast.mat (Paradas, Porcentaje paradas, PromedioDuracionApertura,
% PromedioDuracionParadas, regeneracionEnergia, consumoEnergia), traidas por
% cruce. No modifica Tabla.mat ni TablaLast.mat.
%
% Emparejamiento:
%   1) Exacto: Bus + Fecha + HoraInicio (331 filas)
%   2) Respaldo: Bus + Fecha + NombreRuta + HoraFin, para los recorridos cuya
%      hora de inicio cambio con la re-segmentacion (5 filas)
%   3) Sin contraparte en TablaLast: columnas quedan NaN / celda vacia
%      (1 fila: bus_4025 f_12_06_2024 ruta T04, 15:05-22:07)

S1 = load('Tabla.mat');
S2 = load('TablaLast.mat');
T1 = S1.Tabla;
T2 = S2.Tabla;

n = height(T1);
colsNuevas = {'Paradas', 'Porcentaje paradas', 'PromedioDuracionApertura', ...
    'PromedioDuracionParadas', 'regeneracionEnergia', 'consumoEnergia'};

% 1) Cruce exacto por hora de inicio
k1 = string(T1.Bus) + "|" + string(T1.Fecha) + "|" + string(T1.HoraInicio);
k2 = string(T2.Bus) + "|" + string(T2.Fecha) + "|" + string(T2.HoraInicio);
[tf, loc] = ismember(k1, k2);

% 2) Respaldo por hora de fin (solo si el match es unico)
f1 = string(T1.Bus) + "|" + string(T1.Fecha) + "|" + string(T1.NombreRuta) + "|" + string(T1.HoraFin);
f2 = string(T2.Bus) + "|" + string(T2.Fecha) + "|" + string(T2.NombreRuta) + "|" + string(T2.HoraFin);
pendientes = find(~tf);
for r = pendientes'
    c = find(f2 == f1(r));
    if numel(c) == 1
        tf(r) = true;
        loc(r) = c;
    end
end

fprintf('Emparejadas %d de %d filas; sin contraparte: %d\n', sum(tf), n, sum(~tf));
for r = find(~tf)'
    fprintf('  sin contraparte: %s %s %s ini=%s\n', string(T1.Bus(r)), ...
        string(T1.Fecha(r)), string(T1.NombreRuta(r)), string(T1.HoraInicio(r)));
end

% 3) Anexar las columnas nuevas en el mismo orden que TablaLast
TablaExtendida = T1;
paradas = cell(n, 1);
paradas(tf) = T2.Paradas(loc(tf));
TablaExtendida.Paradas = paradas;
for c = 2:numel(colsNuevas)
    col = NaN(n, 1);
    col(tf) = T2.(colsNuevas{c})(loc(tf));
    TablaExtendida.(colsNuevas{c}) = col;
end

TablaExtendida.Properties.Description = sprintf( ...
    ['Tabla.mat + 6 columnas de TablaLast.mat por cruce (Bus+Fecha+HoraInicio; ' ...
    'respaldo Bus+Fecha+NombreRuta+HoraFin). Generada por crearTablaExtendida.m el %s.'], ...
    char(datetime('now', 'Format', 'yyyy-MM-dd')));

save('TablaExtendida.mat', 'TablaExtendida');
fprintf('Guardado TablaExtendida.mat: %d filas x %d columnas\n', ...
    height(TablaExtendida), width(TablaExtendida));
