function mostrarResultadoFinal(BestSol, titulo)

disp(titulo);

disp(['PowerPV = ' num2str(BestSol.Position(1)) ' W']);
disp(['PowerEOL = ' num2str(BestSol.Position(3)) ' W']);
disp(['Battery = ' num2str(BestSol.Position(2)) ' Wh']);

if isfield(BestSol,'nPaneles')
    disp(['nPaneles = ' num2str(BestSol.nPaneles)]);
end
if isfield(BestSol,'nBaterias')
    disp(['nBaterias = ' num2str(BestSol.nBaterias)]);
end
if isfield(BestSol,'nMolinos')
    disp(['nMolinos = ' num2str(BestSol.nMolinos)]);
end

disp(['Coste = ' num2str(BestSol.Cost) ' €']);
disp(['LCOE = ' num2str(BestSol.LCOE) ' €/kWh']);
disp(['Fiabilidad = ' num2str(BestSol.Reliability) ' %']);

end