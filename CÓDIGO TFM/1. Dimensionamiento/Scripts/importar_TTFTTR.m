% importar_TTFTTR.m
% Lee las series de tiempos hasta fallo (TTF) y de reparacion (TTR) usadas
% para modelar la disponibilidad de los equipos en la simulacion estocastica.

opts = delimitedTextImportOptions("NumVariables", 2, "Encoding", "UTF-8");
opts.DataLines = [2, Inf];
opts.Delimiter = ";";
opts.VariableNames = ["TTF", "TTR"];
opts.VariableTypes = ["double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

TTF_TTR = readtable(fullfile(dataFolder, "TTF_TTR.csv"), opts);
TTF = table2array(TTF_TTR(:,1));
TTR = table2array(TTF_TTR(:,2));

clear opts TTF_TTR
