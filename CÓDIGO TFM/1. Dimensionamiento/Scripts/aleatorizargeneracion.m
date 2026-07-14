function [genrand, OnOff] = aleatorizargeneracion(generacion, TTF, TTR, estocastico)
% Construye el perfil anual (8760 h) de generacion relativa y la secuencia
% de disponibilidad de un equipo.
%   estocastico = true  -> dias barajados por mes y fallos segun TTF/TTR
%   estocastico = false -> perfil directo y disponibilidad permanente

if nargin < 4
    estocastico = true;
end

diasmes = [31,28,31,30,31,30,31,31,30,31,30,31];
genrand = zeros(8760, 1);

% Perfil de generacion: se recorren los meses y, en el caso estocastico, se
% barajan los dias dentro de cada mes
ref = 0;
for mes = 1:12
    nd = diasmes(mes);
    if estocastico
        orden = randperm(nd);
    else
        orden = 1:nd;
    end
    srcRows = reshape((1:24)' + 24*(orden(:)-1)', nd*24, 1);
    genrand(ref*24+1 : ref*24+nd*24) = generacion(srcRows, mes);
    ref = ref + nd;
end

% Secuencia de disponibilidad
if ~estocastico
    OnOff = ones(8760, 1);
    return;
end

pos      = randi(length(TTF));
maxFails = min(8760, max(30, 2*ceil(8760 / mean(TTF))));

idxTTF   = mod((0:maxFails-1) + pos - 1, length(TTF)) + 1;
idxTTR   = mod((0:maxFails-1) + pos - 1, length(TTR)) + 1;
ttf_vals = max(1, round(TTF(idxTTF(:))));
ttr_vals = max(1, round(TTR(idxTTR(:))));

% Instante de inicio y fin de cada periodo de fallo
up_starts  = [1; 1 + cumsum(ttf_vals + ttr_vals)];
fail_start = up_starts(1:maxFails) + ttf_vals;
fail_end   = fail_start + ttr_vals - 1;

valid = fail_start <= 8760;
fs    = fail_start(valid);
fe    = min(fail_end(valid), 8760);

if isempty(fs)
    OnOff = ones(8760, 1);
else
    % +1 al iniciar cada fallo y -1 al terminar: el cumsum vale 0 cuando el equipo opera
    diff_vec = accumarray(fs,             ones(numel(fs), 1), [8761, 1]) ...
             - accumarray(min(fe+1, 8761), ones(numel(fe), 1), [8761, 1]);
    OnOff = double(cumsum(diff_vec(1:8760)) == 0);
end
OnOff = OnOff(:);
end
