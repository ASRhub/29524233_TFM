function Sistema = calcularIndicesCooperacion(Sistema, nHoras)
% Calcula LOLP y fiabilidad de cada vivienda.

    for j = 1:numel(Sistema)
        Sistema(j).LOLP = Sistema(j).LOLE / nHoras * 100;
        Sistema(j).fiabilidad = 100 - Sistema(j).LOLP;
    end
end
