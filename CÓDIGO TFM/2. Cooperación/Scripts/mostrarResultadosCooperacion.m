function mostrarResultadosCooperacion(ResultadosS1, ResultadosS2x, SOCc_values, modoApp)
% Imprime las tablas comparativas de S1 frente a los escenarios cooperativos
% S2x y, salvo que se ejecute desde la interfaz (modoApp = true), representa
% las graficas de efecto de la cooperacion.

    if nargin < 4; modoApp = false; end

    nEsc       = numel(SOCc_values);
    nViviendas = numel(ResultadosS1.ENS);

    fprintf('\n=========== RESULTADOS S1 (SIN COOPERACION) ===========\n');
    imprimirResultado(ResultadosS1);

    fprintf('\n=========== RESULTADOS S2x (CON COOPERACION) ===========\n');
    for s = 1:nEsc
        fprintf('\n--- S2_%d ---\n', round(SOCc_values(s)*100));
        imprimirResultado(ResultadosS2x(s));
    end

    % Mejora porcentual del LOLP de cada vivienda respecto a S1
    fprintf('\n=========== MEJORA DE LOLP RESPECTO A S1 (%%) ===========\n');
    fprintf('SOCc(%%)\t');
    for j = 1:nViviendas; fprintf('V%d\t', j); end
    fprintf('Media\n');

    mejoraLOLP = zeros(nEsc, nViviendas);
    for s = 1:nEsc
        for j = 1:nViviendas
            if ResultadosS1.LOLP(j) > 0
                mejoraLOLP(s,j) = 100 * (ResultadosS1.LOLP(j) - ResultadosS2x(s).LOLP(j)) / ResultadosS1.LOLP(j);
            end
        end
        fprintf('%2d\t', round(SOCc_values(s)*100));
        for j = 1:nViviendas; fprintf('%6.2f\t', mejoraLOLP(s,j)); end
        fprintf('%6.2f\n', mean(mejoraLOLP(s,:)));
    end

    if modoApp
        return;
    end

    % Series globales del barrido
    LOLP_global       = arrayfun(@(r) r.LOLP_global,       ResultadosS2x);
    ENS_global        = arrayfun(@(r) r.ENS_global,        ResultadosS2x);
    fiabilidad_global = arrayfun(@(r) r.fiabilidad_global, ResultadosS2x);

    figure;
    plot(SOCc_values*100, LOLP_global, '-o', 'LineWidth', 2); hold on;
    yline(ResultadosS1.LOLP_global, '--', 'S1 sin cooperacion');
    xlabel('SOC_C (%)'); ylabel('LOLP global (%)');
    title('Efecto de la cooperacion sobre el LOLP global'); grid on;

    figure;
    plot(SOCc_values*100, ENS_global/1000, '-o', 'LineWidth', 2); hold on;
    yline(ResultadosS1.ENS_global/1000, '--', 'S1 sin cooperacion');
    xlabel('SOC_C (%)'); ylabel('ENS global (kWh/anio)');
    title('Efecto de la cooperacion sobre el ENS global'); grid on;

    figure;
    plot(SOCc_values*100, fiabilidad_global, '-o', 'LineWidth', 2); hold on;
    yline(ResultadosS1.fiabilidad_global, '--', 'S1 sin cooperacion');
    xlabel('SOC_C (%)'); ylabel('Fiabilidad global (%)');
    title('Efecto de la cooperacion sobre la fiabilidad global'); grid on;

    figure;
    plot(SOCc_values*100, mejoraLOLP, '-o', 'LineWidth', 2); hold on;
    if nViviendas == 2
        plot(SOCc_values*100, abs(mejoraLOLP(:,1) - mejoraLOLP(:,2)), '--', 'LineWidth', 1.5);
        legend('Vivienda 1', 'Vivienda 2', '|Diferencia|', 'Location', 'best');
    else
        legend(arrayfun(@(j) sprintf('Vivienda %d', j), 1:nViviendas, 'UniformOutput', false), 'Location', 'best');
    end
    xlabel('SOC_C (%)'); ylabel('Mejora de LOLP respecto a S1 (%)');
    title('Mejora de fiabilidad por vivienda'); grid on;
end

function imprimirResultado(R)
    nV = numel(R.ENS);
    for j = 1:nV
        fprintf('Vivienda %d:  ENU = %9.2f kWh   HNU = %5.1f h   ENS = %7.2f kWh   LOLP = %5.3f %%\n', ...
                j, R.ENA(j)/1000, R.HNA(j), R.ENS(j)/1000, R.LOLP(j));
    end
    fprintf('GLOBAL    :  ENU = %9.2f kWh   HNU = %5.1f h   ENS = %7.2f kWh   LOLP = %5.3f %%\n', ...
            R.ENA_global/1000, R.HNA_global, R.ENS_global/1000, R.LOLP_global);
    fprintf('Fiabilidad global = %.3f %%\n', R.fiabilidad_global);
end
