%% Import data from text file

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
irradiancia = zeros(744,12);
temperatura = zeros(744,12);
dataGeneracionFV = zeros(744,12);

% Extraer irradiancia y temperatura
for mes = 1:12
    for d = 1:diasmes(mes)
        for h = 1:24
            irradiancia((d-1)*24+h, mes) = PVGIS.Gi((ref*24)+(24*(d-1))+h);
            temperatura((d-1)*24+h, mes) = PVGIS.T2m((ref*24)+(24*(d-1))+h);
        end
    end
    ref = ref + diasmes(mes);
end

%% Calcular generación FV relativa
for mes = 1:12
    for d = 1:diasmes(mes)
        for h = 1:24
            G = irradiancia((d-1)*24+h, mes);
            Tamb = temperatura((d-1)*24+h, mes);

            % Temperatura de célula
            Tcel = Tamb + G * (NOCT - 20) / 800;

            % Potencia relativa del módulo
            dataGeneracionFV((d-1)*24+h, mes) = (G / GSTC) * (1 + ktempPotencia/100 * (Tcel - 25));
        end
    end
end

%% Limitar sobrepotencias, si las hubiera
dataGeneracionFV(dataGeneracionFV > 1.05) = 1.05;

%% Clear temporary variables
clear opts folder ref mes d h diasmes PVGIS G Tamb Tcel
clear irradiancia temperatura 