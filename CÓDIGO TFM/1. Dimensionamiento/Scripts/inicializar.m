% inicializar.m
% Carga los parametros (si no estan ya en el workspace) y importa los datos
% del emplazamiento seleccionado.

if ~exist('potenciaNominalFV', 'var')
    parametros;
end

% Fichero de datos meteorologicos segun el emplazamiento
switch localizacion
    case "Islas Feroe", ficheroPVGIS = "PVGIS_islasferoe.csv";
    case "Cabo Verde",  ficheroPVGIS = "PVGIS_caboverde.csv";
    case "Asuan",       ficheroPVGIS = "PVGIS_asuan.csv";
    otherwise
        error('Localizacion "%s" no reconocida.', localizacion);
end

importar_PVGIS;
importar_consumos;
importar_TTFTTR;
importar_eolica;
