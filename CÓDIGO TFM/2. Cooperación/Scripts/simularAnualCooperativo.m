function Sistema = simularAnualCooperativo(Sistema, demanda, generacion, params, SOCc)
% Simula un anio del escenario cooperativo S2x, generalizado a N viviendas.
% Cada hora se resuelve en cuatro pasos:
%   1. Balance local de cada vivienda (carga/descarga de su bateria).
%   2. Calculo del excedente cedible (por encima de SOC_C) y de la necesidad
%      de cada vivienda (deficit de demanda y recarga hasta SOC_C).
%   3. Reparto proporcional de la energia entre emisores y receptores, afectado
%      por el rendimiento de transmision; se prioriza ceder/cubrir la energia
%      directa antes que la almacenada.
%   4. Actualizacion del estado de bateria y de los indices ENS, ENU, LOLE, HNA.
% El reparto proporcional es independiente del orden de las viviendas y se
% reduce al caso de 2 viviendas de Roldan-Blay et al. (2021) cuando N = 2.

    nHoras     = size(demanda, 1);
    nViviendas = numel(Sistema);

    for h = 1:nHoras

        % --- Paso 1 y 2: balance local y cálculo de pools/necesidades -----
        U     = zeros(1, nViviendas);
        Bp    = zeros(1, nViviendas);
        E     = zeros(1, nViviendas);
        Bpp   = zeros(1, nViviendas);
        BC    = zeros(1, nViviendas);
        BL    = zeros(1, nViviendas);
        BM    = zeros(1, nViviendas);
        Pgen  = zeros(1, nViviendas);
        Pbat  = zeros(1, nViviendas);
        Ndem  = zeros(1, nViviendas);
        Ncar  = zeros(1, nViviendas);

        for j = 1:nViviendas
            BL(j) = params.SOCl   * Sistema(j).cap;
            BM(j) = params.SOCmax * Sistema(j).cap;
            BC(j) = SOCc          * Sistema(j).cap;
            B     = Sistema(j).SOC * Sistema(j).cap;
            U(j)  = generacion(h,j) - demanda(h,j);

            if U(j) >= 0
                Bp(j)  = B + U(j) * params.rendIn;
                E(j)   = max(0, Bp(j) - BM(j));
                Bpp(j) = min(Bp(j), BM(j));
            else
                Bp(j)  = B + U(j) / params.rendOut;
                E(j)   = min(0, Bp(j) - BL(j));
                Bpp(j) = max(Bp(j), BL(j));
            end

            Pgen(j) = max(0, E(j));
            Pbat(j) = max(0, Bpp(j) - BC(j)) * params.rendOut;
            Ndem(j) = max(0, -E(j)) * params.rendOut;
            Ncar(j) = max(0, BC(j) - Bpp(j)) / params.rendIn;
        end

        % --- Paso 3: reparto proporcional emisores <-> receptores ---------
        P_total = sum(Pgen + Pbat);
        N_total = sum(Ndem + Ncar);

        envGen_bus = zeros(1, nViviendas);   % enviado desde generación (bus)
        envBat_bus = zeros(1, nViviendas);   % enviado desde batería    (bus)
        recv_dem   = zeros(1, nViviendas);   % recibido para demanda    (bus)
        recv_bat   = zeros(1, nViviendas);   % recibido para batería    (bus)

        if P_total > 1e-9 && N_total > 1e-9
            alpha = min(1, N_total / (P_total * params.rendTrans));
            beta  = min(1, (P_total * params.rendTrans) / N_total);

            for j = 1:nViviendas
                envio_j = (Pgen(j) + Pbat(j)) * alpha;
                envGen_bus(j) = min(Pgen(j), envio_j);
                envBat_bus(j) = envio_j - envGen_bus(j);
                Pgen(j) = Pgen(j) - envGen_bus(j);
                Pbat(j) = Pbat(j) - envBat_bus(j);
            end

            for k = 1:nViviendas
                recibido_k = (Ndem(k) + Ncar(k)) * beta;
                recv_dem(k) = min(Ndem(k), recibido_k);
                recv_bat(k) = recibido_k - recv_dem(k);
                Ndem(k) = Ndem(k) - recv_dem(k);
                Ncar(k) = max(0, Ncar(k) - recv_bat(k));
            end
        end

        % --- Paso 4: actualizar batería e índices -------------------------
        for j = 1:nViviendas
            B_new = Bpp(j) - envBat_bus(j) / params.rendOut ...
                          + recv_bat(j)   * params.rendIn;
            B_new = min(BM(j), max(BL(j), B_new));
            Sistema(j).SOC = B_new / Sistema(j).cap;

            ENS_h = max(0, Ndem(j));     % déficit no cubierto tras ayuda
            ENU_h = Pgen(j);             % excedente sin aprovechar

            Sistema(j).ENS = Sistema(j).ENS + ENS_h;
            Sistema(j).ENA = Sistema(j).ENA + ENU_h;

            if ENS_h > 0.01
                Sistema(j).LOLE = Sistema(j).LOLE + 1;
            end
            if ENU_h > 0.01
                Sistema(j).HNA = Sistema(j).HNA + 1;
            end
        end
    end

    Sistema = calcularIndicesCooperacion(Sistema, nHoras);
end
