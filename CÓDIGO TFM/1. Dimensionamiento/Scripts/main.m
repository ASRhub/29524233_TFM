% main.m
% Ejecuta una optimizacion completa del sistema SAPV: importa los datos del
% emplazamiento, lanza el algoritmo elegido, discretiza la solucion y muestra
% los resultados.
%
% Puede ejecutarse directamente (usa los valores por defecto de parametros.m)
% o desde la interfaz, que fija previamente las opciones en el workspace.

tic; clc;

% Rutas del proyecto (se configuran solas al ejecutar en solitario)
if ~exist('projectFolder', 'var')
    scriptFolder  = fileparts(mfilename('fullpath'));
    projectFolder = fileparts(scriptFolder);
    dataFolder    = fullfile(projectFolder, 'Data');
    cd(scriptFolder);
end

% Marca que indica si se ejecuta desde la interfaz (para no abrir figuras)
if ~exist('modoApp', 'var'); modoApp = false; end

% Cargar datos y parametros
inicializar;

% Verbosidad de los algoritmos
if ~exist('mostrarEvolucion', 'var'); mostrarEvolucion = true; end
ShowIterInfo = mostrarEvolucion;

% Ejecutar el algoritmo seleccionado
if ~exist('algoritmo', 'var'); algoritmo = "ACOR"; end
switch algoritmo
    case "PSO",   disp('Ejecutando PSO...');    pso;
    case "AG",    disp('Ejecutando AG...');     ga;
    case "ACOR",  disp('Ejecutando ACOR...');   acor;
    case "CMAES", disp('Ejecutando CMA-ES...'); cmaes;
    otherwise
        error('Algoritmo "%s" no reconocido. Opciones: PSO | AG | ACOR | CMAES', algoritmo);
end

% Resultados
mostrarResultadoFinal(BestSol, '--- SOLUCION CONTINUA ---');
discretizarSol;

% Evaluacion final de la solucion discretizada con metricas detalladas
metricasCompletas = true; %#ok<NASGU>  usado por simulacionMontecarlo
PgBasemaxFV  = BestSolDisc.Position(1);
capacidadMax = BestSolDisc.Position(2);
PgBasemaxEol = BestSolDisc.Position(3);
simulacionMontecarlo;
BestSolDisc.Cost        = costeAnual;
BestSolDisc.LCOE        = LCOE;
BestSolDisc.Reliability = fiabilidad;
BestSolDisc.Metricas    = Metricas;
clear metricasCompletas;

mostrarResultadoFinal(BestSolDisc, '--- SOLUCION DISCRETIZADA ---');
mostrarMetricas(Metricas);

if ~modoApp
    plotConvergencia(BestCost, algoritmo);
    cd(projectFolder);
end

toc;
