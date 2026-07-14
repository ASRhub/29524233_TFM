function Sistema = crearSistemaDesdeOptimos(optimos, params)
% Crea el array Sistema a partir de una matriz de óptimos.
% optimos(j,:) = [PgFV, CapacidadBateria, PgEOL]

    nViviendas = size(optimos,1);

    for j = 1:nViviendas
        Sistema(j).PgFV = optimos(j,1); %#ok<AGROW>
        Sistema(j).cap = optimos(j,2); %#ok<AGROW>
        Sistema(j).PgEOL = optimos(j,3); %#ok<AGROW>
        Sistema(j).SOC = params.SOCini; %#ok<AGROW>

        Sistema(j).ENS = 0; %#ok<AGROW>
        Sistema(j).ENA = 0; %#ok<AGROW>
        Sistema(j).LOLE = 0; %#ok<AGROW>
        Sistema(j).HNA = 0; %#ok<AGROW>
        Sistema(j).nF_FV = 0; %#ok<AGROW>
        Sistema(j).nF_EOL = 0; %#ok<AGROW>
        Sistema(j).LOLP = 0; %#ok<AGROW>
        Sistema(j).fiabilidad = 0; %#ok<AGROW>
    end
end
