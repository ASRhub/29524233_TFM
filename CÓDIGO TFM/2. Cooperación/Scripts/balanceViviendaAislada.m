function [S, ENS_h, ENA_h] = balanceViviendaAislada(S, demanda_h, generacion_h, params)
% Balance horario de una vivienda aislada.

    cap = S.cap;
    eBat = S.SOC * cap;
    eMin = params.SOCl * cap;
    eMax = params.SOCmax * cap;

    ENS_h = 0;
    ENA_h = 0;

    balance = generacion_h - demanda_h;

    if balance >= 0
        eBatNueva = eBat + balance * params.rendIn;

        if eBatNueva > eMax
            ENA_h = (eBatNueva - eMax) / params.rendIn;
            eBatNueva = eMax;
        end
    else
        deficitEnBat = abs(balance) / params.rendOut;
        disponible = eBat - eMin;

        if disponible >= deficitEnBat
            eBatNueva = eBat - deficitEnBat;
        else
            eBatNueva = eMin;
            ENS_h = (deficitEnBat - disponible) * params.rendOut;
        end
    end

    S.SOC = eBatNueva / cap;
end
