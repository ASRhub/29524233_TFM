% simulacionMontecarlo.m
% Evalua una configuracion del sistema (potencia FV, capacidad de bateria y
% potencia eolica) simulando el balance energetico horario de un anio,
% teniendo en cuenta la disponibilidad de los equipos (fallos TTF/TTR).
% Devuelve la fiabilidad, el coste anual y el LCOE.
%
% Con aleatorizar = true se promedian nMC simulaciones con perfiles y fallos
% aleatorios; con aleatorizar = false se hace una unica simulacion determinista.
%
% Si metricasCompletas = true, ademas se calcula el conjunto completo de
% metricas del sistema (estructura Metricas), promediadas sobre las nMC
% simulaciones. Solo se usa para la solucion final, por su mayor coste.

if ~exist('aleatorizar', 'var');      aleatorizar = true;       end
if ~exist('metricasCompletas', 'var'); metricasCompletas = false; end

if aleatorizar
    nMC = 30;
else
    nMC = 1;
end

capacidadMin = 0.2 * capacidadMax;
capInicial   = 0.8 * capacidadMax;

demanda = dataConsumos / max(dataConsumos) * Pdmax;   % perfil anual [W], 8760x1

% Generacion horaria de cada simulacion, con fallos aplicados
gen_mc = zeros(8760, nMC);
if metricasCompletas
    ONOFF_FV_mc  = zeros(8760, nMC);
    ONOFF_EOL_mc = zeros(8760, nMC);
end
for mc = 1:nMC
    [gFV,  oFV]  = aleatorizargeneracion(dataGeneracionFV,  TTF, TTR, aleatorizar);
    [gEOL, oEOL] = aleatorizargeneracion(dataGeneracionEOL, TTF, TTR, aleatorizar);
    gen_mc(:, mc) = (gFV .* oFV) * PgBasemaxFV + (gEOL .* oEOL) * PgBasemaxEol;
    if metricasCompletas
        ONOFF_FV_mc(:, mc)  = oFV;
        ONOFF_EOL_mc(:, mc) = oEOL;
    end
end
dem_mc = repmat(demanda, 1, nMC);

% Balance energetico horario (vectorizado sobre las nMC simulaciones)
almac  = zeros(8760, nMC);
ENS_mc = zeros(8760, nMC);   % energia no suministrada

% Hora 1: se parte del estado de carga inicial
d   = gen_mc(1,:) - dem_mc(1,:);
pos = d >= 0;
almac(1,  pos) = min(capacidadMax, capInicial + d(pos)  * rendIn);
almac(1, ~pos) = max(capacidadMin, capInicial + d(~pos) / rendOut);
da = almac(1,:) - capInicial;
ENS_mc(1, ~pos) = max(0, -d(~pos) + da(~pos) * rendOut);

% Resto de horas
for n = 2:8760
    d   = gen_mc(n,:) - dem_mc(n,:);
    pos = d >= 0;
    almac(n,  pos) = min(capacidadMax, almac(n-1, pos) + d(pos)  * rendIn);
    almac(n, ~pos) = max(capacidadMin, almac(n-1,~pos) + d(~pos) / rendOut);
    da = almac(n,:) - almac(n-1,:);
    ENS_mc(n, ~pos) = max(0, -d(~pos) + da(~pos) * rendOut);
end

% Indices de fiabilidad
LOLP_mc    = sum(ENS_mc > 0.01, 1) / 87.6;   % horas con deficit sobre 8760 (%)
fiabilidad = 100 - mean(LOLP_mc);
ENS_medio  = mean(sum(ENS_mc, 1));

% Costes
costePaneles = precioWFV  * PgBasemaxFV;
costeEolica  = precioWeol * PgBasemaxEol;
costeBateria = precioWh   * capacidadMax * vidaFV / vidaBat;

litrosCombustible = ENS_medio * consumoGrupo / 1000;
costeCombustible  = precioCombustible * litrosCombustible;

if PgBasemaxEol >= 0.5 * potenciaNominalEol
    costeRegulador = precioRegulador;
else
    costeRegulador = 0;
end

inversionInicial = precioGenerador + costePaneles + costeEolica + ...
                   costeBateria + precioInversor + costeRegulador;

ANF     = (tasaInteres * (1 + tasaInteres)^vidaFV) / ((1 + tasaInteres)^vidaFV - 1);
costeOM = costeMantenimiento / 100 * inversionInicial;

energiaAnualUtil = max(1, sum(demanda) - ENS_medio);
LCOE       = 1000 * (inversionInicial * ANF + costeOM + costeCombustible) / energiaAnualUtil;
costeAnual = costePaneles/vidaFV + costeEolica/vidaEol + ...
             costeBateria/vidaBat + costeRegulador/vidaEol + costeCombustible;

% Metricas detalladas de la solucion (solo si se solicitan)
if metricasCompletas
    % Energia no absorbida (excedente que la bateria no puede almacenar)
    dd   = gen_mc - dem_mc;
    posA = dd >= 0;
    da_mc = [almac(1,:) - capInicial; diff(almac, 1, 1)];
    ENA_mc = max(0, dd * rendIn - da_mc);
    ENA_mc(~posA) = 0;

    % Estado de carga
    SOC_mc = 100 * almac / capacidadMax;

    % Contadores de fallos (transiciones disponible -> no disponible)
    prevFV  = [ones(1, nMC); ONOFF_FV_mc(1:end-1, :)];
    prevEOL = [ones(1, nMC); ONOFF_EOL_mc(1:end-1, :)];
    nFallosFV_mc  = sum(ONOFF_FV_mc  == 0 & prevFV  == 1, 1);
    nFallosEOL_mc = sum(ONOFF_EOL_mc == 0 & prevEOL == 1, 1);

    % Fallo renovable global: solo cuando ambas ramas estan indisponibles
    glob     = (ONOFF_FV_mc + ONOFF_EOL_mc) > 0;
    prevGlob = [ones(1, nMC); glob(1:end-1, :)];
    nFallosRenov_mc = sum(glob == 0 & prevGlob == 1, 1);

    % Arranques del grupo auxiliar (la bateria alcanza su carga minima)
    enMin       = almac <= capacidadMin + 1e-6;
    prevPorEnc  = [true(1, nMC); ~enMin(1:end-1, :)];
    nIDG_mc     = sum(enMin & prevPorEnc, 1);

    Metricas = struct();
    Metricas.ENS          = ENS_medio;                    % energia no suministrada [Wh/anio]
    Metricas.ENA          = mean(sum(ENA_mc, 1));         % energia no absorbida [Wh/anio]
    Metricas.HNS          = mean(sum(ENS_mc > 0.01, 1));  % horas de deficit
    Metricas.HNA          = mean(sum(ENA_mc > 0.01, 1));  % horas de excedente no absorbido
    Metricas.LOLE         = Metricas.HNS;                 % loss of load expectation [h/anio]
    Metricas.LOLP         = mean(LOLP_mc);                % loss of load probability [%]
    Metricas.nFallosFV    = mean(nFallosFV_mc);
    Metricas.nFallosEol   = mean(nFallosEOL_mc);
    Metricas.nFallosRenov = mean(nFallosRenov_mc);
    Metricas.nIDG         = mean(nIDG_mc);                % arranques del grupo auxiliar
    Metricas.SOCmedio     = mean(SOC_mc(:));              % estado de carga medio [%]
end
