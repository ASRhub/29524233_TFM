function [perfilFV, perfilEOL] = cargarPerfilesGeneracionCooperacion(dataFolder)
% Carga o calcula perfiles normalizados FV y eólico.
% Opción A: si existen perfilFV.csv y perfilEOL.csv en Data, los lee directamente.
% Opción B: si no existen, intenta ejecutar importar_PVGIS.m e importar_eolica.m.
%
% Salida:
%   perfilFV  = 8760 x 1, p.u. de generación FV por W instalado
%   perfilEOL = 8760 x 1, p.u. de generación eólica por W instalado

    fFV  = fullfile(dataFolder, "perfilFV.csv");
    fEOL = fullfile(dataFolder, "perfilEOL.csv");

    if isfile(fFV)
        perfilFV = readmatrix(fFV);
        perfilFV = perfilFV(:);
    else
        % Variables que necesita el script importar_PVGIS
        NOCT = 45;             %#ok<NASGU>
        GSTC = 1000;           %#ok<NASGU>
        ktempPotencia = -0.35; %#ok<NASGU>

        if ~isfile(fullfile(dataFolder, "PVGIS.csv"))
            error('No existe perfilFV.csv ni PVGIS.csv en Data. No puedo construir la generación FV.');
        end

        % El script importar_PVGIS usa dataFolder y crea dataGeneracionFV.
        importar_PVGIS;
        perfilFV = matrizMensualAVector(dataGeneracionFV);
    end

    if isfile(fEOL)
        perfilEOL = readmatrix(fEOL);
        perfilEOL = perfilEOL(:);
    else
        if ~isfile(fullfile(dataFolder, "PVGIS.csv"))
            warning('No existe perfilEOL.csv ni PVGIS.csv. Se toma perfil eólico nulo.');
            perfilEOL = zeros(8760,1);
        else
            % El script importar_eolica usa dataFolder y crea dataGeneracionEOL.
            importar_eolica;
            perfilEOL = matrizMensualAVector(dataGeneracionEOL);
        end
    end

    if numel(perfilFV) ~= 8760 || numel(perfilEOL) ~= 8760
        error('Los perfiles de generación deben tener 8760 valores.');
    end

    perfilFV(isnan(perfilFV)) = 0;
    perfilEOL(isnan(perfilEOL)) = 0;
    perfilFV(perfilFV < 0) = 0;
    perfilEOL(perfilEOL < 0) = 0;

end
