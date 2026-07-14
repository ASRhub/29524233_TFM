% acor.m
% Optimizacion por colonia de hormigas para dominio continuo (ACOR).
% Minimiza el coste anual del sistema penalizando las soluciones que no
% alcanzan la fiabilidad exigida.

if ~exist('ShowIterInfo', 'var'); ShowIterInfo = true; end

%% Definicion del problema
nVar    = 3;                              % variables: potencia FV, capacidad bateria, potencia eolica
VarSize = [1 nVar];
VarMin  = [potenciaNominalFV 500 0];      % limites inferiores
VarMax  = [20000 35000 20000];            % limites superiores

%% Parametros del algoritmo
MaxIt   = 20;      % numero de iteraciones
nPop    = 10;      % tamanio del archivo de soluciones
nSample = 40;      % numero de hormigas por iteracion
q       = 0.5;     % factor de intensificacion (presion de seleccion)
zeta    = 1;       % relacion desviacion-distancia

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

% Ordenar por coste
[~, SortOrder] = sort([pop.Cost]);
pop = pop(SortOrder);

% Mejor solucion inicial: la primera factible; si no hay, la de menor coste
BestSol = pop(1);
for k = 1:length(pop)
    if pop(k).Reliability > fiabilidadExigible
        BestSol = pop(k);
        break;
    end
end

BestCost = zeros(MaxIt, 1);

% Pesos y probabilidades de seleccion de cada solucion del archivo
w = 1/(sqrt(2*pi)*q*nPop)*exp(-0.5*(((1:nPop)-1)/(q*nPop)).^2);
p = w/sum(w);

%% Bucle principal
for it = 1:MaxIt

    % Medias (posiciones del archivo)
    s = zeros(nPop, nVar);
    for l = 1:nPop
        s(l, :) = pop(l).Position;
    end

    % Desviaciones tipicas
    sigma = zeros(nPop, nVar);
    for l = 1:nPop
        D = 0;
        for r = 1:nPop
            D = D + abs(s(l, :) - s(r, :));
        end
        sigma(l, :) = zeta*D/(nPop-1);
    end

    % Construccion de nuevas soluciones (hormigas)
    newpop = repmat(empty_individual, nSample, 1);
    for t = 1:nSample
        newpop(t).Position = zeros(VarSize);
        for j = 1:nVar
            l = RouletteWheelSelection(p);
            newpop(t).Position(j) = s(l, j) + sigma(l, j)*randn;
        end
        newpop(t).Position = max(newpop(t).Position, VarMin);
        newpop(t).Position = min(newpop(t).Position, VarMax);

        PgBasemaxFV  = newpop(t).Position(1);
        capacidadMax = newpop(t).Position(2);
        PgBasemaxEol = newpop(t).Position(3);
        simulacionMontecarlo;
        newpop(t).Cost        = costeAnual;
        newpop(t).LCOE        = LCOE;
        newpop(t).Reliability = fiabilidad;
        if newpop(t).Reliability < fiabilidadExigible
            newpop(t).Cost = newpop(t).Cost + 1e6*(fiabilidadExigible - newpop(t).Reliability);
        end
    end

    % Unir archivo y nuevas soluciones, ordenar y quedarse con las mejores
    pop = [pop; newpop]; %#ok<AGROW>
    [~, SortOrder] = sort([pop.Cost]);
    pop = pop(SortOrder);
    pop = pop(1:nPop);

    % Actualizar la mejor solucion factible encontrada
    for k = 1:length(pop)
        if pop(k).Reliability > fiabilidadExigible
            if ~(BestSol.Reliability > fiabilidadExigible) || pop(k).Cost < BestSol.Cost
                BestSol = pop(k);
            end
            break;
        end
    end

    BestCost(it) = BestSol.Cost;
    if ShowIterInfo
        disp(['Iteracion ' num2str(it) ': mejor coste = ' num2str(BestCost(it))]);
    end
end
