function [onoff, nFallos] = generarDisponibilidadSimple(nHoras, lambdaFallos, ttrMedio)
% Genera una disponibilidad ON/OFF para una rama renovable según el modelo
% usado en el artículo (Roldán-Blay et al., 2021), apartado 2:
%
%   - Tiempos entre fallos: exponencial con tasa lambdaFallos (fallos/año).
%     Equivalentemente, nº de fallos en un año ~ Poisson(lambdaFallos).
%   - Tiempo de reparación (TTR): distribución de Rayleigh con media ttrMedio.
%
% Para Rayleigh con parámetro de escala sigma:
%     media = sigma * sqrt(pi/2)  =>  sigma = ttrMedio / sqrt(pi/2)
%     muestra: x = sigma * sqrt(-2 * ln(U)),  con U ~ U(0,1)

    onoff = ones(nHoras,1);
    nFallos = poissonSimple(lambdaFallos);

    sigma = ttrMedio / sqrt(pi/2);

    for f = 1:nFallos
        inicio   = randi(nHoras);
        u        = max(rand, eps);
        duracion = max(1, round(sigma * sqrt(-2 * log(u))));
        fin      = min(nHoras, inicio + duracion - 1);
        onoff(inicio:fin) = 0;
    end
end


function k = poissonSimple(lambda)
% Generador Poisson sencillo (algoritmo de Knuth) sin Statistics Toolbox.
% Adecuado para valores pequeños de lambda.
    L = exp(-lambda);
    k = 0;
    p = 1;
    while p > L
        k = k + 1;
        p = p * rand;
    end
    k = k - 1;
end
