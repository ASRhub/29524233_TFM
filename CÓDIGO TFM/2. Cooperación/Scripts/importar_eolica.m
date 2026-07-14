%% Import wind data from PVGIS.csv and compute estimated relative wind generation

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 6);

% Specify range and delimiter
opts.DataLines = [10, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["time", "Gi", "H_sun", "T2m", "WS10m", "Int"];
opts.VariableTypes = ["string", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, "time", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "time", "EmptyFieldRule", "auto");

% Import the data
folder = strcat(dataFolder, "\PVGIS.csv");
PVGIS = readtable(folder, opts);

diasmes = [31,28,31,30,31,30,31,31,30,31,30,31];
ref = 0;
velViento10m = zeros(744,12);
velVientoHub = zeros(744,12);
dataGeneracionEOL = zeros(744,12);

% Extraer velocidad del viento a 10 m
for mes = 1:12
    for d = 1:diasmes(mes)
        for h = 1:24
            velViento10m((d-1)*24+h, mes) = PVGIS.WS10m((ref*24)+(24*(d-1))+h);
        end
    end
    ref = ref + diasmes(mes);
end

%% Parámetros de instalación
z_ref = 10;      % altura de referencia de PVGIS [m]
z_buje = 12;      % altura de buje asumida [m]
alpha = 0.14;    % exponente de Hellmann (terreno abierto)

% Corrección de velocidad a altura de buje
for mes = 1:12
    for d = 1:diasmes(mes)
        for h = 1:24
            velVientoHub((d-1)*24+h, mes) = ...
                velViento10m((d-1)*24+h, mes) * (z_buje / z_ref)^alpha;
        end
    end
end

%% Curva de potencia aproximada del LE-300
% Potencia absoluta [W]
v_curve = [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18];
P_curve = [0 0 0 0 8 20 38 60 85 115 150 190 230 260 280 295 300 300 300];

% Curva relativa normalizada respecto a la potencia máxima del aerogenerador
potenciaNominalEol = 300;
P_curve_rel = P_curve / potenciaNominalEol;

%% Calcular generación eólica relativa
for mes = 1:12
    for d = 1:diasmes(mes)
        for h = 1:24
            v = velVientoHub((d-1)*24+h, mes);

            % Interpolación lineal de la curva relativa
            if v <= v_curve(1)
                dataGeneracionEOL((d-1)*24+h, mes) = P_curve_rel(1);
            elseif v >= v_curve(end)
                dataGeneracionEOL((d-1)*24+h, mes) = P_curve_rel(end);
            else
                dataGeneracionEOL((d-1)*24+h, mes) = interp1(v_curve, P_curve_rel, v, 'linear');
            end

        end
    end
end

%% Clear temporary variables
clear opts folder ref mes d h diasmes PVGIS v
clear z_ref z_buje alpha velViento10m velVientoHub
clear v_curve P_curve P_curve_rel Pmax_eolica