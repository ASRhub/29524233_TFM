function Sistema = resetearSistema(SistemaBase, params)
% Reinicia SOC e índices antes de cada iteración Monte Carlo.

    Sistema = SistemaBase;

    for j = 1:numel(Sistema)
        Sistema(j).SOC = params.SOCini;
        Sistema(j).ENS = 0;
        Sistema(j).ENA = 0;
        Sistema(j).LOLE = 0;
        Sistema(j).HNA = 0;
        Sistema(j).LOLP = 0;
        Sistema(j).fiabilidad = 0;
    end
end
