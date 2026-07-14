% cmaes.m
% Estrategia evolutiva con adaptacion de la matriz de covarianza (CMA-ES).
% Minimiza el coste anual del sistema exigiendo la fiabilidad minima.

if ~exist('ShowIterInfo', 'var'); ShowIterInfo = true; end

%% Definicion del problema
nVar    = 3;
VarSize = [1 nVar];
VarMin  = [potenciaNominalFV 500 0];
VarMax  = [20000 35000 20000];

%% Parametros del algoritmo
MaxIt  = 20;                          % numero de iteraciones
lambda = (4+round(3*log(nVar)))*10;   % numero de muestras por generacion
mu     = round(lambda/2);             % numero de padres

% Pesos de los padres y numero efectivo de soluciones
w      = log(mu+0.5) - log(1:mu);
w      = w/sum(w);
mu_eff = 1/sum(w.^2);

% Parametros de control del tamanio de paso
sigma0 = 0.3*(VarMax-VarMin);
cs     = (mu_eff+2)/(nVar+mu_eff+5);
ds     = 1+cs+2*max(sqrt((mu_eff-1)/(nVar+1))-1, 0);
ENN    = sqrt(nVar)*(1-1/(4*nVar)+1/(21*nVar^2));

% Parametros de actualizacion de la covarianza
cc       = (4+mu_eff/nVar)/(4+nVar+2*mu_eff/nVar);
c1       = 2/((nVar+1.3)^2+mu_eff);
alpha_mu = 2;
cmu      = min(1-c1, alpha_mu*(mu_eff-2+1/mu_eff)/((nVar+2)^2+alpha_mu*mu_eff/2));
hth      = (1.4+2/(nVar+1))*ENN;

%% Inicializacion
ps    = cell(MaxIt, 1);
pc    = cell(MaxIt, 1);
C     = cell(MaxIt, 1);
sigma = cell(MaxIt, 1);
ps{1}    = zeros(VarSize);
pc{1}    = zeros(VarSize);
C{1}     = eye(nVar);
sigma{1} = sigma0;

empty_individual.Position    = [];
empty_individual.Step        = [];
empty_individual.Cost        = [];
empty_individual.LCOE        = [];
empty_individual.Reliability = [];

M = repmat(empty_individual, MaxIt, 1);
M(1).Position = unifrnd(VarMin, VarMax, VarSize);
M(1).Step     = zeros(VarSize);

PgBasemaxFV  = M(1).Position(1);
capacidadMax = M(1).Position(2);
PgBasemaxEol = M(1).Position(3);
simulacionMontecarlo;
M(1).Cost        = costeAnual;
M(1).LCOE        = LCOE;
M(1).Reliability = fiabilidad;

BestSol = M(1);
if M(1).Reliability <= fiabilidadExigible
    BestSol.Cost = Inf;   % obliga a que cualquier solucion factible la reemplace
end

BestCost = zeros(MaxIt, 1);

%% Bucle principal
for g = 1:MaxIt

    % Generar muestras alrededor de la media
    pop = repmat(empty_individual, lambda, 1);
    for j = 1:lambda
        pop(j).Step     = mvnrnd(zeros(VarSize), C{g});
        pop(j).Position = M(g).Position + sigma{g}.*pop(j).Step;
        pop(j).Position = max(pop(j).Position, VarMin);
        pop(j).Position = min(pop(j).Position, VarMax);

        PgBasemaxFV  = pop(j).Position(1);
        capacidadMax = pop(j).Position(2);
        PgBasemaxEol = pop(j).Position(3);
        simulacionMontecarlo;
        pop(j).Cost        = costeAnual;
        pop(j).LCOE        = LCOE;
        pop(j).Reliability = fiabilidad;

        if (pop(j).Cost < BestSol.Cost) && (pop(j).Reliability > fiabilidadExigible)
            BestSol = pop(j);
        end
    end

    % Ordenar penalizando las infactibles, para que los mu mejores lo sean
    Costs = [pop.Cost];
    Reliabilities = [pop.Reliability];
    infeasIdx = Reliabilities <= fiabilidadExigible;
    Costs(infeasIdx) = Costs(infeasIdx) + 1e6*(fiabilidadExigible - Reliabilities(infeasIdx));
    [~, SortOrder] = sort(Costs);
    pop = pop(SortOrder);

    BestCost(g) = BestSol.Cost;
    if ShowIterInfo
        disp(['Iteracion ' num2str(g) ': mejor coste = ' num2str(BestCost(g))]);
    end

    if g == MaxIt
        break;
    end

    % Actualizar la media
    M(g+1).Step = 0;
    for j = 1:mu
        M(g+1).Step = M(g+1).Step + w(j)*pop(j).Step;
    end
    M(g+1).Position = M(g).Position + sigma{g}.*M(g+1).Step;
    M(g+1).Position = max(M(g+1).Position, VarMin);
    M(g+1).Position = min(M(g+1).Position, VarMax);

    PgBasemaxFV  = M(g+1).Position(1);
    capacidadMax = M(g+1).Position(2);
    PgBasemaxEol = M(g+1).Position(3);
    simulacionMontecarlo;
    M(g+1).Cost        = costeAnual;
    M(g+1).LCOE        = LCOE;
    M(g+1).Reliability = fiabilidad;
    if (M(g+1).Cost < BestSol.Cost) && (M(g+1).Reliability > fiabilidadExigible)
        BestSol = M(g+1);
    end

    % Actualizar el tamanio de paso
    ps{g+1}    = (1-cs)*ps{g} + sqrt(cs*(2-cs)*mu_eff)*M(g+1).Step/chol(C{g})';
    sigma{g+1} = sigma{g}*exp(cs/ds*(norm(ps{g+1})/ENN-1))^0.3;

    % Actualizar la matriz de covarianza
    if norm(ps{g+1})/sqrt(1-(1-cs)^(2*(g+1))) < hth
        hs = 1;
    else
        hs = 0;
    end
    delta   = (1-hs)*cc*(2-cc);
    pc{g+1} = (1-cc)*pc{g} + hs*sqrt(cc*(2-cc)*mu_eff)*M(g+1).Step;
    C{g+1}  = (1-c1-cmu)*C{g} + c1*(pc{g+1}'*pc{g+1}+delta*C{g});
    for j = 1:mu
        C{g+1} = C{g+1} + cmu*w(j)*pop(j).Step'*pop(j).Step;
    end

    % Corregir la covarianza si deja de ser definida positiva
    [V, E] = eig(C{g+1});
    if any(diag(E) < 0)
        E = max(E, 0);
        C{g+1} = V*E/V;
    end
end
