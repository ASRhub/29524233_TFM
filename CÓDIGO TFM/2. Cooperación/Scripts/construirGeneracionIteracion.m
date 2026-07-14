function [generacion, fallosFV, fallosEOL] = construirGeneracionIteracion(Sistema, perfilFV, perfilEOL, params)
% Construye la generacion horaria de cada vivienda para una iteracion.
% El recurso (perfil FV/eolico en p.u.) es comun a todas las viviendas por ser
% vecinas; los fallos de la rama renovable son independientes en cada una.
% Devuelve la generacion (8760 x nViviendas) y el numero de fallos por vivienda.

    nHoras = 8760;
    nViviendas = numel(Sistema);

    generacion = zeros(nHoras, nViviendas);
    fallosFV   = zeros(1, nViviendas);
    fallosEOL  = zeros(1, nViviendas);

    if params.aleatorizar
        % Mismo perfil aleatorizado para todas las viviendas (vecinas)
        perfilFV_it  = aleatorizarPerfilMensual(perfilFV);
        perfilEOL_it = aleatorizarPerfilMensual(perfilEOL);
    else
        perfilFV_it  = perfilFV;
        perfilEOL_it = perfilEOL;
    end

    for j = 1:nViviendas
        if params.aleatorizar
            % Fallos INDEPENDIENTES por vivienda
            [onFV,  fallosFV(j)]  = generarDisponibilidadSimple(nHoras, params.lambdaFallos, params.ttrMedio);
            [onEOL, fallosEOL(j)] = generarDisponibilidadSimple(nHoras, params.lambdaFallos, params.ttrMedio);
        else
            onFV  = ones(nHoras,1);
            onEOL = ones(nHoras,1);
        end

        generacion(:,j) = perfilFV_it  .* onFV  * Sistema(j).PgFV + ...
                          perfilEOL_it .* onEOL * Sistema(j).PgEOL;
    end
end
