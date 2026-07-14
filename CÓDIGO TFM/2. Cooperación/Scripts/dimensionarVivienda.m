function [PgFV, CapBat, LOLP_final, info] = dimensionarVivienda(demanda_j, perfilFV, perfilEOL, params, PgEOL_j, LOLPobjetivo, opts)
% Encuentra (PgFV, CapBat) que aproximan el LOLP objetivo de una vivienda
% aislada (escenario S1) mediante bisección en un factor de escala común.
%
% Se parte de un diseño inicial proporcional al consumo anual:
%   PgFV0   = 2 * Ey / horas_equivalentes_FV   (generación ~ 2x consumo)
%   CapBat0 = 1.5 * Ey / 365                   (~ 1.5 días de autonomía)
%
% Luego se busca k tal que el diseño (k*PgFV0, k*CapBat0) produce un LOLP
% individual cercano al objetivo. La búsqueda usa una SMC reducida (pocas
% iteraciones) para que sea rápida; el LOLP devuelto es estimado y la
% simulación final del estudio cooperativo recalculará los índices con la
% precisión completa (params.nIter iteraciones).
%
% Entradas:
%   demanda_j     : 8760 x 1, demanda horaria de la vivienda [Wh]
%   perfilFV      : 8760 x 1, perfil FV normalizado [p.u./W]
%   perfilEOL     : 8760 x 1, perfil eólico normalizado [p.u./W]
%   params        : struct con parámetros generales (SOCl, SOCmax, SOCini,
%                   rendIn, rendOut, lambdaFallos, ttrMedio, aleatorizar)
%   PgEOL_j       : potencia instalada de eólica en la vivienda [W] (fija)
%   LOLPobjetivo  : LOLP deseado en S1 [%], típicamente 2.5-2.7
%   opts          : struct opcional con campos:
%                       .nIter   nº de iteraciones SMC por evaluación (def. 20)
%                       .maxBis  nº máximo de iteraciones de bisección (def. 12)
%                       .tol     tolerancia absoluta en LOLP [%]   (def. 0.2)
%                       .kRange  [kmin kmax] rango inicial          (def. [0.3 5])
%                       .verbose true/false                          (def. false)
%
% Salidas:
%   PgFV, CapBat  : diseño dimensionado
%   LOLP_final    : LOLP estimado conseguido [%]
%   info          : struct con historial de la bisección y mensajes

    if nargin < 7 || isempty(opts), opts = struct(); end
    if ~isfield(opts, 'nIter'),   opts.nIter   = 20;       end
    if ~isfield(opts, 'maxBis'),  opts.maxBis  = 12;       end
    if ~isfield(opts, 'tol'),     opts.tol     = 0.2;      end
    if ~isfield(opts, 'kRange'),  opts.kRange  = [0.3 5];  end
    if ~isfield(opts, 'verbose'), opts.verbose = false;    end

    % --- Punto de partida basado en consumo anual ------------------------
    Ey      = sum(demanda_j);                  % Wh/año
    horasFV = max(1, sum(perfilFV));           % horas equivalentes FV/año
    PgFV0   = 2 * Ey / horasFV;                % generación ~ 2x consumo
    CapBat0 = 1.5 * Ey / 365;                  % ~1.5 días de autonomía

    % Parámetros reducidos para evaluaciones rápidas
    paramsRed = params;
    paramsRed.nIter = opts.nIter;

    % --- Bisección -------------------------------------------------------
    kLo = opts.kRange(1);
    kHi = opts.kRange(2);

    % Aseguramos que el rango "contiene" el objetivo (expansión adaptativa)
    LOLP_Lo = evaluarLOLP_S1(demanda_j, perfilFV, perfilEOL, paramsRed, ...
                             PgFV0 * kLo, CapBat0 * kLo, PgEOL_j);
    LOLP_Hi = evaluarLOLP_S1(demanda_j, perfilFV, perfilEOL, paramsRed, ...
                             PgFV0 * kHi, CapBat0 * kHi, PgEOL_j);

    expansiones = 0;
    while LOLP_Lo < LOLPobjetivo && expansiones < 3
        % El extremo inferior ya alcanza el objetivo -> reducir kLo
        kLo = kLo / 2;
        LOLP_Lo = evaluarLOLP_S1(demanda_j, perfilFV, perfilEOL, paramsRed, ...
                                 PgFV0 * kLo, CapBat0 * kLo, PgEOL_j);
        expansiones = expansiones + 1;
    end
    while LOLP_Hi > LOLPobjetivo && expansiones < 6
        % El extremo superior no alcanza el objetivo -> aumentar kHi
        kHi = kHi * 2;
        LOLP_Hi = evaluarLOLP_S1(demanda_j, perfilFV, perfilEOL, paramsRed, ...
                                 PgFV0 * kHi, CapBat0 * kHi, PgEOL_j);
        expansiones = expansiones + 1;
    end

    info.historial = zeros(opts.maxBis, 3);   % [k, LOLP, error]
    info.converged = false;
    info.mensaje   = '';

    for it = 1:opts.maxBis
        kMid   = 0.5 * (kLo + kHi);
        PgFV   = PgFV0  * kMid;
        CapBat = CapBat0 * kMid;

        LOLP = evaluarLOLP_S1(demanda_j, perfilFV, perfilEOL, paramsRed, ...
                              PgFV, CapBat, PgEOL_j);
        err  = LOLP - LOLPobjetivo;
        info.historial(it,:) = [kMid, LOLP, err];

        if opts.verbose
            fprintf('  Bis %2d: k=%.3f  PgFV=%6.0fW  CapBat=%6.0fWh  LOLP=%.3f%%  err=%+.3f\n', ...
                    it, kMid, PgFV, CapBat, LOLP, err);
        end

        if abs(err) <= opts.tol
            LOLP_final = LOLP;
            info.historial = info.historial(1:it,:);
            info.converged = true;
            return
        end

        if LOLP > LOLPobjetivo
            kLo = kMid;       % LOLP demasiado alto -> hace falta más capacidad
        else
            kHi = kMid;       % LOLP demasiado bajo -> sobra capacidad
        end
    end

    % Si llegamos aquí no se cumplió la tolerancia
    LOLP_final = LOLP;
    info.mensaje = sprintf('No se alcanzó la tolerancia tras %d bisecciones (LOLP=%.3f%%, objetivo=%.3f%%).', ...
                           opts.maxBis, LOLP, LOLPobjetivo);
    if opts.verbose
        warning(info.mensaje);
    end
end


% =========================================================================
function LOLP = evaluarLOLP_S1(demanda_j, perfilFV, perfilEOL, params, PgFV, CapBat, PgEOL)
% Ejecuta una SMC reducida del escenario S1 (vivienda aislada) y devuelve
% el LOLP medio en porcentaje.

    % Estructura mínima de la vivienda
    SistemaBase = struct( ...
        'PgFV',  PgFV, ...
        'cap',   CapBat, ...
        'PgEOL', PgEOL, ...
        'SOC',   params.SOCini, ...
        'ENS',   0, ...
        'ENA',   0, ...
        'LOLE',  0, ...
        'HNA',   0, ...
        'LOLP',  0, ...
        'fiabilidad', 0);

    nIter     = params.nIter;
    LOLP_iter = zeros(nIter, 1);

    for iter = 1:nIter
        Sistema = resetearSistema(SistemaBase, params);

        % Generación aleatorizada (mismo perfil y fallos por iter)
        if params.aleatorizar
            perfilFV_it  = aleatorizarPerfilMensual(perfilFV);
            perfilEOL_it = aleatorizarPerfilMensual(perfilEOL);
            [onFV,  ~] = generarDisponibilidadSimple(8760, params.lambdaFallos, params.ttrMedio);
            [onEOL, ~] = generarDisponibilidadSimple(8760, params.lambdaFallos, params.ttrMedio);
        else
            perfilFV_it  = perfilFV;
            perfilEOL_it = perfilEOL;
            onFV  = ones(8760,1);
            onEOL = ones(8760,1);
        end
        generacion = perfilFV_it  .* onFV  * Sistema(1).PgFV + ...
                     perfilEOL_it .* onEOL * Sistema(1).PgEOL;

        % Demanda aleatorizada
        if params.aleatorizar
            demandaIter = aleatorizarPerfilMensual(demanda_j);
        else
            demandaIter = demanda_j;
        end

        Sistema = simularAnualIndividual(Sistema, demandaIter, generacion, params);
        LOLP_iter(iter) = Sistema(1).LOLP;
    end

    LOLP = mean(LOLP_iter);
end
