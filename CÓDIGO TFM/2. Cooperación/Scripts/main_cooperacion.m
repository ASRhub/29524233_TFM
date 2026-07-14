% main_cooperacion.m
% Segunda parte del TFM: microrred cooperativa entre N viviendas aisladas.
% Compara el escenario sin cooperacion (S1) con escenarios cooperativos (S2x)
% para uno o varios umbrales de cooperacion SOC_C, mediante simulacion Monte
% Carlo secuencial. Basado en Roldan-Blay et al., Appl. Sci. 2021, 11, 11723.
%
% Puede ejecutarse directamente (usa los valores por defecto) o desde la
% interfaz, que fija previamente la configuracion en el workspace.

tic;

% Rutas del proyecto (se configuran solas al ejecutar en solitario)
if ~exist('projectFolder', 'var')
    scriptFolder  = fileparts(mfilename('fullpath'));
    projectFolder = fileparts(scriptFolder);
    dataFolder    = fullfile(projectFolder, 'Data');
    addpath(scriptFolder);
end

% Marca que indica si se ejecuta desde la interfaz (para no abrir figuras)
if ~exist('modoApp', 'var'); modoApp = false; end

%% Configuracion por defecto (solo lo que no venga fijado desde la interfaz)
if ~exist('params', 'var'); params = struct(); end
def = struct('nIter',100, 'SOCl',0.20, 'SOCmax',1.00, 'SOCini',0.80, ...
             'rendIn',0.90, 'rendOut',0.90, 'rendTrans',0.95, ...
             'aleatorizar',true, 'lambdaFallos',2, 'ttrMedio',24, ...
             'nViviendas',5, 'modoDiseno','optimo', 'LOLPobjetivo',10);
campos = fieldnames(def);
for c = 1:numel(campos)
    if ~isfield(params, campos{c}); params.(campos{c}) = def.(campos{c}); end
end
if ~isfield(params, 'PdmaxObjetivo') || isempty(params.PdmaxObjetivo)
    params.PdmaxObjetivo = [3000, 3300, 2800, 3500, 3100];
end
if ~exist('PgFV_base', 'var');   PgFV_base   = 9900;  end   % diseno base [W]
if ~exist('CapBat_base', 'var'); CapBat_base = 17760; end   % diseno base [Wh]
if ~exist('PgEOL_base', 'var');  PgEOL_base  = 0;     end   % diseno base [W]
if ~exist('SOCc_values', 'var'); SOCc_values = 0.20:0.05:0.40; end  % umbrales a barrer

%% Semilla global: fija toda la aleatoriedad (perfiles, dimensionado y Monte
%% Carlo) para que la ejecucion sea reproducible. Sin semilla, cada ejecucion
%% da resultados algo distintos (propio de una simulacion estocastica).
if isfield(params, 'semillaPerfiles') && ~isempty(params.semillaPerfiles)
    rng(params.semillaPerfiles, 'twister');
end

%% Demanda: perfil real por vivienda si existe, si no sintetico
importar_consumos_cooperacion;   % genera dataConsumos (8760 x nViviendas)

%% Perfiles de generacion normalizados (mismo recurso para todas las viviendas)
[perfilFV, perfilEOL] = cargarPerfilesGeneracionCooperacion(dataFolder);

%% Diseno individual de cada vivienda
optimos = zeros(params.nViviendas, 3);
switch lower(params.modoDiseno)

    case 'manual'
        % El diseno de cada vivienda lo aporta el usuario en optimosManual
        % (nViviendas x 3: [PgFV_W, CapBat_Wh, PgEOL_W]).
        if ~exist('optimosManual', 'var')
            error('modoDiseno "manual" requiere la matriz optimosManual.');
        end
        optimos = optimosManual(1:params.nViviendas, :);

    case 'escalado'
        % Se escala el diseno base con el consumo anual relativo de cada vivienda
        EyV1 = sum(dataConsumos(:,1));
        for j = 1:params.nViviendas
            factor = sum(dataConsumos(:,j)) / EyV1;
            optimos(j,:) = [PgFV_base*factor, CapBat_base*factor, PgEOL_base*factor];
        end

    case 'optimo'
        % Se dimensiona cada vivienda por biseccion hasta el LOLP objetivo
        fprintf('\nDimensionando cada vivienda para LOLP objetivo = %.2f %%\n', params.LOLPobjetivo);
        optsDim = struct('nIter',20, 'maxBis',12, 'tol',0.2, 'verbose',false);
        for j = 1:params.nViviendas
            [PgFV_j, CapBat_j, LOLP_j] = dimensionarVivienda( ...
                dataConsumos(:,j), perfilFV, perfilEOL, params, ...
                PgEOL_base, params.LOLPobjetivo, optsDim);
            optimos(j,:) = [PgFV_j, CapBat_j, PgEOL_base];
            fprintf('Vivienda %d: PgFV = %6.0f W   CapBat = %7.0f Wh   LOLP_est = %.2f %%\n', ...
                    j, PgFV_j, CapBat_j, LOLP_j);
        end

    otherwise
        error('params.modoDiseno = "%s" no reconocido (manual | escalado | optimo).', params.modoDiseno);
end

fprintf('\nDiseno individual (modo "%s"):\n', params.modoDiseno);
for j = 1:params.nViviendas
    fprintf('Vivienda %d: PgFV = %6.0f W   CapBat = %7.0f Wh   PgEOL = %4.0f W\n', ...
            j, optimos(j,1), optimos(j,2), optimos(j,3));
end

SistemaBase = crearSistemaDesdeOptimos(optimos, params);

%% Escenario S1: viviendas aisladas
fprintf('\nEjecutando S1 (%d iteraciones)...\n', params.nIter);
ResultadosS1 = ejecutarMontecarloCooperacion( ...
    SistemaBase, dataConsumos, perfilFV, perfilEOL, params, NaN, false);

%% Escenarios S2x: viviendas cooperativas (uno o varios SOC_C)
ResultadosS2x = repmat(ResultadosS1, numel(SOCc_values), 1);
for s = 1:numel(SOCc_values)
    fprintf('Ejecutando S2_%d ...\n', round(SOCc_values(s)*100));
    ResultadosS2x(s) = ejecutarMontecarloCooperacion( ...
        SistemaBase, dataConsumos, perfilFV, perfilEOL, params, SOCc_values(s), true);
end

%% Resultados
mostrarResultadosCooperacion(ResultadosS1, ResultadosS2x, SOCc_values, modoApp);

toc;
