% importar_consumos.m
% Lee el perfil horario de consumo (8760 valores) desde Consumos.csv.

opts = delimitedTextImportOptions("NumVariables", 4, "Encoding", "UTF-8");
opts.DataLines = [1, Inf];
opts.Delimiter = ";";
opts.VariableNames = ["Fecha", "Dia", "Var3", "MiConsumo"];
opts.SelectedVariableNames = ["Fecha", "Dia", "MiConsumo"];
opts.VariableTypes = ["datetime", "double", "string", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts = setvaropts(opts, "Var3", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "Var3", "EmptyFieldRule", "auto");
opts = setvaropts(opts, "Fecha", "InputFormat", "dd/MM/yyyy HH:mm");

Consumos = readtable(fullfile(dataFolder, "Consumos.csv"), opts);
dataConsumos = table2array(Consumos(:,3));

clear opts Consumos
