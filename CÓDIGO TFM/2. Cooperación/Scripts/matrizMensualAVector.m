function vector = matrizMensualAVector(matrizMensual)
% Convierte una matriz 744 x 12 con meses en columnas a un vector anual 8760 x 1.

    diasmes = [31,28,31,30,31,30,31,31,30,31,30,31];
    vector = zeros(8760,1);
    ref = 0;

    for mes = 1:12
        for d = 1:diasmes(mes)
            for h = 1:24
                horadata = 24*(d-1)+h;
                horagen = ref*24 + 24*(d-1) + h;
                vector(horagen) = matrizMensual(horadata, mes);
            end
        end
        ref = ref + diasmes(mes);
    end
end
