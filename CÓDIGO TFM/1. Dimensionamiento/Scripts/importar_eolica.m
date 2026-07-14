% importar_eolica.m
% Lee la velocidad del viento de PVGIS, la corrige a la altura de buje y
% calcula la generacion eolica relativa segun la curva de potencia del LE-300.

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
velViento10m = zeros(744,12);
dataGeneracionEOL = zeros(744,12);

% Velocidad del viento a 10 m, reorganizada en columnas por mes
ref = 0;
for mes = 1:12
    for d = 1:diasmes(mes)
        for h = 1:24
            velViento10m((d-1)*24+h, mes) = PVGIS.WS10m((ref*24)+(24*(d-1))+h);
        end
    end
    ref = ref + diasmes(mes);
end

% Correccion a la altura de buje con la ley de Hellmann
z_ref  = 10;     % altura de referencia de PVGIS [m]
z_buje = 12;     % altura de buje [m]
alpha  = 0.14;   % exponente de Hellmann (terreno abierto)
velVientoHub = velViento10m * (z_buje / z_ref)^alpha;

% Curva de potencia del LE-300 [W] y su version relativa
v_curve = 0:18;
P_curve = [0 0 0 0 8 20 38 60 85 115 150 190 230 260 280 295 300 300 300];
potenciaNominalEol = 300;
P_curve_rel = P_curve / potenciaNominalEol;

% Generacion eolica relativa por interpolacion de la curva
for mes = 1:12
    for d = 1:diasmes(mes)
        for h = 1:24
            v = velVientoHub((d-1)*24+h, mes);
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

clear opts ref mes d h diasmes PVGIS v
clear z_ref z_buje alpha velViento10m velVientoHub v_curve P_curve P_curve_rel
