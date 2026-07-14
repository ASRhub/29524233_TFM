% discretizarSol.m
% Convierte la solucion continua en un numero entero de paneles, baterias y
% aerogeneradores, y la reevalua. Si la solucion discretizada no alcanza la
% fiabilidad exigida, anade equipos hasta lograrlo (o hasta un maximo de
% iteraciones).

BestSolDisc = BestSol;

BestSolDisc.nPaneles  = max(1, round(BestSol.Position(1)/potenciaNominalFV));
BestSolDisc.nBaterias = max(1, ceil(BestSol.Position(2)/capacidadNominal));
BestSolDisc.nMolinos  = max(0, round(BestSol.Position(3)/potenciaNominalEol));

BestSolDisc.Position(1) = BestSolDisc.nPaneles  * potenciaNominalFV;
BestSolDisc.Position(2) = BestSolDisc.nBaterias * capacidadNominal;
BestSolDisc.Position(3) = BestSolDisc.nMolinos  * potenciaNominalEol;

PgBasemaxFV  = BestSolDisc.Position(1);
capacidadMax = BestSolDisc.Position(2);
PgBasemaxEol = BestSolDisc.Position(3);
simulacionMontecarlo;
BestSolDisc.Cost        = costeAnual;
BestSolDisc.LCOE        = LCOE;
BestSolDisc.Reliability = fiabilidad;

% Refuerzo por si la discretizacion baja de la fiabilidad exigida:
% se anade una bateria y, si sigue sin cumplir, un panel FV
maxIter = 15;
iter = 0;
while BestSolDisc.Reliability < fiabilidadExigible && iter < maxIter
    BestSolDisc.nBaterias   = BestSolDisc.nBaterias + 1;
    BestSolDisc.Position(2) = BestSolDisc.nBaterias * capacidadNominal;

    PgBasemaxFV  = BestSolDisc.Position(1);
    capacidadMax = BestSolDisc.Position(2);
    PgBasemaxEol = BestSolDisc.Position(3);
    simulacionMontecarlo;
    BestSolDisc.Cost        = costeAnual;
    BestSolDisc.LCOE        = LCOE;
    BestSolDisc.Reliability = fiabilidad;
    if BestSolDisc.Reliability >= fiabilidadExigible
        break;
    end

    BestSolDisc.nPaneles    = BestSolDisc.nPaneles + 1;
    BestSolDisc.Position(1) = BestSolDisc.nPaneles * potenciaNominalFV;

    PgBasemaxFV  = BestSolDisc.Position(1);
    capacidadMax = BestSolDisc.Position(2);
    PgBasemaxEol = BestSolDisc.Position(3);
    simulacionMontecarlo;
    BestSolDisc.Cost        = costeAnual;
    BestSolDisc.LCOE        = LCOE;
    BestSolDisc.Reliability = fiabilidad;

    iter = iter + 1;
end

if BestSolDisc.Reliability < fiabilidadExigible
    warning('La solucion discretizada no alcanza la fiabilidad exigida.');
end
