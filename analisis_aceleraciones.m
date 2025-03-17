%% Gráfico de magnitudes vs duraciones de aceleraciones y desaceleraciones
for i = [2 3 5 6 7 8]
    figure
    scatter(datosBuses.bus_4012.f_04_07_2024.indicesAceleracionRuta{i, 3},datosBuses.bus_4012.f_04_07_2024.indicesAceleracionRuta{i, 1})
    hold on, grid
end


scatter(datosBuses.bus_4012.f_04_07_2024.indicesAceleracionRuta{i, 4},datosBuses.bus_4012.f_04_07_2024.indicesAceleracionRuta{i, 2})
scatter(datosBuses.bus_4012.f_04_07_2024.indicesAceleracionRuta{i, 7},datosBuses.bus_4012.f_04_07_2024.indicesAceleracionRuta{i, 5})
scatter(datosBuses.bus_4012.f_04_07_2024.indicesAceleracionRuta{i, 8},datosBuses.bus_4012.f_04_07_2024.indicesAceleracionRuta{i, 6})

%% Cálculo de aceleraciones y desaceleraciones por km
cellfun(@length,datosBuses.bus_4012.f_04_07_2024.indicesAceleracionRuta)./repmat(datosBuses.bus_4012.f_04_07_2024.tiempoRuta.Kilometros_Ida,1,8)