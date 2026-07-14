function plotConvergencia(BestCost, nombreAlgoritmo)

figure;
semilogy(BestCost, 'LineWidth', 2);
xlabel('Iteracion');
ylabel('Coste');
title(['Convergencia - ' nombreAlgoritmo]);
grid on;

end