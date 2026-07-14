function Resultados = ejecutarMontecarloCooperacion(SistemaBase, demanda, perfilFV, perfilEOL, params, SOCc, cooperacion)
% Ejecuta la simulacion Monte Carlo secuencial del escenario S1 (aislado) o
% S2x (cooperativo) y promedia los indices de fiabilidad sobre nIter anios.
% En cada iteracion se aleatorizan la demanda (por meses, independiente por
% vivienda), la generacion (recurso comun) y los fallos de la rama renovable
% (independientes por vivienda).

    nIter      = params.nIter;
    nViviendas = numel(SistemaBase);

    ENS   = zeros(nIter, nViviendas);
    ENA   = zeros(nIter, nViviendas);
    LOLE  = zeros(nIter, nViviendas);
    HNA   = zeros(nIter, nViviendas);
    LOLP  = zeros(nIter, nViviendas);
    fiabilidad = zeros(nIter, nViviendas);
    nF_FV  = zeros(nIter, nViviendas);
    nF_EOL = zeros(nIter, nViviendas);

    for iter = 1:nIter

        Sistema = resetearSistema(SistemaBase, params);

        % Generación aleatorizada (mismo recurso solar para todas las viviendas;
        % fallos independientes por vivienda)
        [generacion, fallosFV, fallosEOL] = construirGeneracionIteracion(Sistema, perfilFV, perfilEOL, params);

        % Demanda aleatorizada por meses (independiente por vivienda)
        if params.aleatorizar
            demandaIter = zeros(size(demanda));
            for j = 1:nViviendas
                demandaIter(:,j) = aleatorizarPerfilMensual(demanda(:,j));
            end
        else
            demandaIter = demanda;
        end

        if cooperacion
            Sistema = simularAnualCooperativo(Sistema, demandaIter, generacion, params, SOCc);
        else
            Sistema = simularAnualIndividual(Sistema, demandaIter, generacion, params);
        end

        for j = 1:nViviendas
            ENS(iter,j)        = Sistema(j).ENS;
            ENA(iter,j)        = Sistema(j).ENA;
            LOLE(iter,j)       = Sistema(j).LOLE;
            HNA(iter,j)        = Sistema(j).HNA;
            LOLP(iter,j)       = Sistema(j).LOLP;
            fiabilidad(iter,j) = Sistema(j).fiabilidad;
            nF_FV(iter,j)      = fallosFV(j);
            nF_EOL(iter,j)     = fallosEOL(j);
        end
    end

    Resultados.cooperacion = cooperacion;
    Resultados.SOCc        = SOCc;

    % Promedios por vivienda
    Resultados.ENS        = mean(ENS, 1);
    Resultados.ENA        = mean(ENA, 1);
    Resultados.LOLE       = mean(LOLE, 1);
    Resultados.HNA        = mean(HNA, 1);
    Resultados.LOLP       = mean(LOLP, 1);
    Resultados.fiabilidad = mean(fiabilidad, 1);
    Resultados.nF_FV      = mean(nF_FV, 1);
    Resultados.nF_EOL     = mean(nF_EOL, 1);

    % Globales: energías = suma, horas y probabilidades = media
    Resultados.ENS_global        = sum(Resultados.ENS);
    Resultados.ENA_global        = sum(Resultados.ENA);
    Resultados.LOLE_global       = mean(Resultados.LOLE);
    Resultados.HNA_global        = mean(Resultados.HNA);
    Resultados.LOLP_global       = mean(Resultados.LOLP);
    Resultados.fiabilidad_global = 100 - Resultados.LOLP_global;

    % Series iteración a iteración (para estudios de convergencia)
    Resultados.ENS_iter  = ENS;
    Resultados.ENA_iter  = ENA;
    Resultados.LOLE_iter = LOLE;
    Resultados.HNA_iter  = HNA;
    Resultados.LOLP_iter = LOLP;
end
