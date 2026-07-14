% ga.m
% Algoritmo genetico de codificacion real (AG).
% Minimiza el coste anual del sistema penalizando las soluciones que no
% alcanzan la fiabilidad exigida.

if ~exist('ShowIterInfo', 'var'); ShowIterInfo = true; end

%% Definicion del problema
nVar    = 3;
VarSize = [1 nVar];
VarMin  = [potenciaNominalFV 500 0];
VarMax  = [20000 35000 20000];

%% Parametros del algoritmo
MaxIt = 20;                    % numero de iteraciones
nPop  = 100;                   % tamanio de la poblacion
pc    = 0.7;                   % proporcion de cruce
nc    = 2*round(pc*nPop/2);    % numero de descendientes
gamma = 0.4;                   % factor de rango del cruce
pm    = 0.3;                   % proporcion de mutacion
nm    = round(pm*nPop);        % numero de mutantes
mu    = 0.1;                   % tasa de mutacion
beta  = 8;                     % presion de seleccion (ruleta)

%% Inicializacion
empty_individual.Position    = [];
empty_individual.Cost        = [];
empty_individual.LCOE        = [];
empty_individual.Reliability = [];

pop = repmat(empty_individual, nPop, 1);
for j = 1:nPop
    pop(j).Position = unifrnd(VarMin, VarMax, VarSize);

    PgBasemaxFV  = pop(j).Position(1);
    capacidadMax = pop(j).Position(2);
    PgBasemaxEol = pop(j).Position(3);
    simulacionMontecarlo;
    pop(j).Cost        = costeAnual;
    pop(j).LCOE        = LCOE;
    pop(j).Reliability = fiabilidad;
    if pop(j).Reliability < fiabilidadExigible
        pop(j).Cost = pop(j).Cost + 1e6*(fiabilidadExigible - pop(j).Reliability);
    end
end

[Costs, SortOrder] = sort([pop.Cost]);
pop = pop(SortOrder);
BestSol   = pop(1);
BestCost  = zeros(MaxIt, 1);
WorstCost = pop(end).Cost;

%% Bucle principal
for it = 1:MaxIt

    % Probabilidades de seleccion
    P = exp(-beta*Costs/WorstCost);
    P = P/sum(P);

    % Cruce
    popc = repmat(empty_individual, nc/2, 2);
    for k = 1:nc/2
        p1 = pop(RouletteWheelSelection(P));
        p2 = pop(RouletteWheelSelection(P));
        [popc(k, 1).Position, popc(k, 2).Position] = Crossover(p1.Position, p2.Position, gamma, VarMin, VarMax);

        for h = 1:2
            PgBasemaxFV  = popc(k, h).Position(1);
            capacidadMax = popc(k, h).Position(2);
            PgBasemaxEol = popc(k, h).Position(3);
            simulacionMontecarlo;
            popc(k, h).Cost        = costeAnual;
            popc(k, h).LCOE        = LCOE;
            popc(k, h).Reliability = fiabilidad;
            if popc(k, h).Reliability < fiabilidadExigible
                popc(k, h).Cost = popc(k, h).Cost + 1e6*(fiabilidadExigible - popc(k, h).Reliability);
            end
        end
    end
    popc = popc(:);

    % Mutacion
    popm = repmat(empty_individual, nm, 1);
    for k = 1:nm
        p = pop(randi([1 nPop]));
        popm(k).Position = Mutate(p.Position, mu, VarMin, VarMax);

        PgBasemaxFV  = popm(k).Position(1);
        capacidadMax = popm(k).Position(2);
        PgBasemaxEol = popm(k).Position(3);
        simulacionMontecarlo;
        popm(k).Cost        = costeAnual;
        popm(k).LCOE        = LCOE;
        popm(k).Reliability = fiabilidad;
        if popm(k).Reliability < fiabilidadExigible
            popm(k).Cost = popm(k).Cost + 1e6*(fiabilidadExigible - popm(k).Reliability);
        end
    end

    % Unir poblacion y descendientes, ordenar y truncar
    pop = [pop; popc; popm]; %#ok<AGROW>
    [Costs, SortOrder] = sort([pop.Cost]);
    pop = pop(SortOrder);
    WorstCost = max(WorstCost, pop(end).Cost);
    pop   = pop(1:nPop);
    Costs = Costs(1:nPop);

    BestSol      = pop(1);
    BestCost(it) = BestSol.Cost;
    if ShowIterInfo
        disp(['Iteracion ' num2str(it) ': mejor coste = ' num2str(BestCost(it))]);
    end
end
