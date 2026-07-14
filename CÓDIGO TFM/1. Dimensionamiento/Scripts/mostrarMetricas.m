function mostrarMetricas(Metricas)
% Muestra por pantalla las metricas detalladas de fiabilidad y operacion
% del sistema, promediadas sobre las simulaciones Monte Carlo.

disp('--- METRICAS DEL SISTEMA ---');
disp(['LOLE (horas/anio de deficit) = ' num2str(Metricas.LOLE, '%.1f')]);
disp(['LOLP = ' num2str(Metricas.LOLP, '%.2f') ' %']);
disp(['ENS (energia no suministrada) = ' num2str(Metricas.ENS/1000, '%.1f') ' kWh/anio']);
disp(['ENA (energia no absorbida) = ' num2str(Metricas.ENA/1000, '%.1f') ' kWh/anio']);
disp(['Horas con deficit (HNS) = ' num2str(Metricas.HNS, '%.1f')]);
disp(['Horas con excedente (HNA) = ' num2str(Metricas.HNA, '%.1f')]);
disp(['Fallos FV = ' num2str(Metricas.nFallosFV, '%.1f')]);
disp(['Fallos eolicos = ' num2str(Metricas.nFallosEol, '%.1f')]);
disp(['Fallos renovables (ambas ramas) = ' num2str(Metricas.nFallosRenov, '%.1f')]);
disp(['Arranques del grupo auxiliar = ' num2str(Metricas.nIDG, '%.1f')]);
disp(['Estado de carga medio = ' num2str(Metricas.SOCmedio, '%.1f') ' %']);

end
