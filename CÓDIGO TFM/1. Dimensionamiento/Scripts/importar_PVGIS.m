% importar_PVGIS.m
% Lee irradiancia y temperatura horarias de PVGIS y calcula la generacion
% FV relativa (por unidad de potencia instalada) para un anio tipo.

opts = delimitedTextImportOptions("NumVariables", 6);
opts.DataLines = [10, Inf];
opts.Delimiter = ",";
opts.VariableNames = ["time", "Gi", "H_sun", "T2m", "WS10m", "Int"];
opts.VariableTypes = ["string", "double", "double", "double", "double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts = setvaropts(opts, "time", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "time", "EmptyFieldRule", "auto");

PVGIS = readtable(fullfile(dataFolder, ficheroPVGIS), opts);

diasmes = [31,28,31,30,31,30,31,31,30,31,30,31];
irradiancia   = zeros(744,12);
temperatura   = zeros(744,12);
dataGeneracionFV = zeros(744,12);

% Reorganizar las series horarias en columnas por mes
ref = 0;
for mes = 1:12
    for d = 1:diasmes(mes)
        for h = 1:24
            irradiancia((d-1)*24+h, mes) = PVGIS.Gi((ref*24)+(24*(d-1))+h);
            temperatura((d-1)*24+h, mes) = PVGIS.T2m((ref*24)+(24*(d-1))+h);
        end
    end
    ref = ref + diasmes(mes);
end

% Generacion FV relativa, con correccion por temperatura de celula
for mes = 1:12
    for d = 1:diasmes(mes)
        for h = 1:24
            G    = irradiancia((d-1)*24+h, mes);
            Tamb = temperatura((d-1)*24+h, mes);
            Tcel = Tamb + G * (NOCT - 20) / 800;
            dataGeneracionFV((d-1)*24+h, mes) = (G / GSTC) * (1 + ktempPotencia/100 * (Tcel - 25));
        end
    end
end

% Limitar sobrepotencias puntuales
dataGeneracionFV(dataGeneracionFV > 1.05) = 1.05;

clear opts ref mes d h diasmes PVGIS G Tamb Tcel irradiancia temperatura
