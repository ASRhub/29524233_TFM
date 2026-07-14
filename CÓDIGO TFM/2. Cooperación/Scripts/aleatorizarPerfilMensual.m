function perfilAleatorio = aleatorizarPerfilMensual(perfil)
% Aleatoriza días dentro de cada mes manteniendo estructura mensual.
% Entrada y salida: 8760 x 1.

    perfil = perfil(:);
    diasmes = [31,28,31,30,31,30,31,31,30,31,30,31];
    perfilAleatorio = zeros(8760,1);
    ref = 0;

    for mes = 1:12
        nd = diasmes(mes);
        bloque = perfil(ref*24 + (1:nd*24));
        bloqueDias = reshape(bloque, 24, nd);
        perm = randperm(nd);
        bloqueDias = bloqueDias(:, perm);
        perfilAleatorio(ref*24 + (1:nd*24)) = bloqueDias(:);
        ref = ref + nd;
    end
end
