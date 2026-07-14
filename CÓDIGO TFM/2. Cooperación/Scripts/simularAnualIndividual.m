function Sistema = simularAnualIndividual(Sistema, demanda, generacion, params)
% Simula S1: cada vivienda opera de forma aislada.

    nHoras = size(demanda,1);
    nViviendas = numel(Sistema);

    for h = 1:nHoras
        for j = 1:nViviendas
            [Sistema(j), ENS_h, ENA_h] = balanceViviendaAislada(Sistema(j), demanda(h,j), generacion(h,j), params);

            Sistema(j).ENS = Sistema(j).ENS + ENS_h;
            Sistema(j).ENA = Sistema(j).ENA + ENA_h;

            if ENS_h > 0.01
                Sistema(j).LOLE = Sistema(j).LOLE + 1;
            end

            if ENA_h > 0.01
                Sistema(j).HNA = Sistema(j).HNA + 1;
            end
        end
    end

    Sistema = calcularIndicesCooperacion(Sistema, nHoras);
end
