% importar_consumos_cooperacion.m
% Construye la matriz de demanda de todas las viviendas (dataConsumos,
% 8760 x nViviendas, en Wh horarios). Para cada vivienda usa su perfil real
% (demanda_viviendaN.csv) si el fichero existe; si no, sintetiza el perfil a
% partir del de la vivienda 1. El pico de cada perfil se ajusta al valor de
% params.PdmaxObjetivo (un pico objetivo de 0 conserva el pico real del CSV).
%
% La reproducibilidad se controla con la semilla global fijada en
% main_cooperacion.m, no aqui.

archivoV1 = fullfile(dataFolder, "demanda_vivienda1.csv");
if ~isfile(archivoV1)
    error("No se encuentra demanda_vivienda1.csv en la carpeta Data.");
end

if ~isfield(params, 'nViviendas') || params.nViviendas < 1
    params.nViviendas = 2;
    warning('params.nViviendas no definido; se asume 2.');
end
nV = params.nViviendas;

opts = delimitedTextImportOptions("NumVariables", 2, "Encoding", "UTF-8");
opts.DataLines        = [1, Inf];
opts.Delimiter        = ";";
opts.VariableNames    = ["FechaHora", "Consumo"];
opts.VariableTypes    = ["datetime", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule    = "read";
opts = setvaropts(opts, "FechaHora", "InputFormat", "dd/MM/yyyy HH:mm");

% Vivienda 1: perfil real (obligatorio)
demanda1 = readtable(archivoV1, opts).Consumo(:);
if numel(demanda1) ~= 8760 || any(demanda1 < 0) || any(isnan(demanda1))
    error("demanda_vivienda1.csv debe tener 8760 valores horarios no negativos.");
end
picoV1_real = max(demanda1);

% Completar el vector de picos objetivo si es mas corto que nViviendas
if ~isfield(params, 'PdmaxObjetivo') || isempty(params.PdmaxObjetivo)
    params.PdmaxObjetivo = repmat(picoV1_real, 1, nV);
elseif numel(params.PdmaxObjetivo) < nV
    params.PdmaxObjetivo(end+1:nV) = picoV1_real;
end

% Reescalar la V1 al pico objetivo si se ha indicado uno positivo distinto
if params.PdmaxObjetivo(1) > 0 && abs(params.PdmaxObjetivo(1) - picoV1_real) > 1
    demanda1 = round(demanda1 * (params.PdmaxObjetivo(1) / picoV1_real));
end

% Construir la matriz: perfil real por vivienda si existe, si no sintetico
dataConsumos = zeros(8760, nV);
dataConsumos(:,1) = demanda1;
for j = 2:nV
    archivo_j = fullfile(dataFolder, sprintf("demanda_vivienda%d.csv", j));
    if isfile(archivo_j)
        demanda_j = readtable(archivo_j, opts).Consumo(:);
        if numel(demanda_j) ~= 8760 || any(demanda_j < 0) || any(isnan(demanda_j))
            error("demanda_vivienda%d.csv debe tener 8760 valores horarios no negativos.", j);
        end
        % Reescalar el perfil real al pico objetivo, si se indica uno positivo
        if params.PdmaxObjetivo(j) > 0
            demanda_j = round(demanda_j * (params.PdmaxObjetivo(j) / max(demanda_j)));
        end
        dataConsumos(:,j) = demanda_j;
    else
        dataConsumos(:,j) = generarPerfilDemandaSintetico(demanda1, params.PdmaxObjetivo(j));
    end
end

% Resumen
fprintf("\nDemandas preparadas (%d viviendas):\n", nV);
for j = 1:nV
    archivo_j = fullfile(dataFolder, sprintf("demanda_vivienda%d.csv", j));
    origen = "sintetica"; if isfile(archivo_j); origen = "real"; end
    fprintf("Vivienda %d (%s): consumo anual = %7.2f kWh   Pdmax = %5.0f W\n", ...
            j, origen, sum(dataConsumos(:,j))/1000, max(dataConsumos(:,j)));
end

clear archivoV1 archivo_j opts demanda1 demanda_j j picoV1_real nV origen
