function perfil = generarPerfilDemandaSintetico(perfilBase, Pdmax_objetivo)
% Genera un perfil horario sintético de demanda residencial (8760 valores)
% a partir de un perfil base, manteniendo la estructura temporal pero
% introduciendo variabilidad diaria realista.
%
% Procedimiento:
%   1. Para cada día del año:
%        - se desplaza la curva horaria entre -3 y +3 h (circshift)
%        - se escala por un factor diario aleatorio entre 0.7 y 1.3
%   2. Se añade ruido gaussiano horario (sigma = 15% del valor).
%   3. Se trunca a valores no negativos.
%   4. Si se proporciona Pdmax_objetivo, el perfil se escala para que el
%      pico horario coincida con ese valor.
%
% Entradas:
%   perfilBase     : vector 8760x1 con demanda horaria base [Wh]
%   Pdmax_objetivo : (opcional) pico de demanda deseado [W]. Si se omite o
%                    es 0, el perfil mantiene su pico natural tras el ruido.
%
% Salida:
%   perfil : vector 8760x1 con la demanda horaria sintética [Wh]

    perfilBase = perfilBase(:);
    if numel(perfilBase) ~= 8760
        error('generarPerfilDemandaSintetico: el perfil base debe tener 8760 valores horarios.');
    end

    % Reorganizar como matriz 24 x 365 (cada columna = un día)
    perfilDias = reshape(perfilBase, 24, 365);
    perfilNuevoDias = zeros(size(perfilDias));

    for d = 1:365
        % Desplazamiento horario aleatorio (hábitos algo distintos cada día)
        desplazamiento = randi([-3, 3]);
        % Factor de escala diario (consumos algo distintos cada día)
        factorDia = 0.7 + 0.6 * rand;
        perfilNuevoDias(:,d) = circshift(perfilDias(:,d), desplazamiento) * factorDia;
    end

    perfil = perfilNuevoDias(:);

    % Ruido horario gaussiano (sigma = 15%)
    perfil = perfil .* (1 + 0.15 * randn(size(perfil)));
    perfil(perfil < 0) = 0;

    % Escalado al pico objetivo, si se ha indicado
    if nargin >= 2 && ~isempty(Pdmax_objetivo) && Pdmax_objetivo > 0
        picoActual = max(perfil);
        if picoActual > 0
            perfil = perfil * (Pdmax_objetivo / picoActual);
        end
    end

    perfil = round(perfil);
end
