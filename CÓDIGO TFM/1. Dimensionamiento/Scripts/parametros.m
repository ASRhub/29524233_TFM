% parametros.m
% Parametros del sistema y opciones de ejecucion por defecto.
% Se cargan al ejecutar en solitario (sin la interfaz). La interfaz
% sobrescribe las opciones de ejecucion segun lo que elija el usuario.

%% Modulo FV: Jinko Tiger Neo JKM430N-54HL4R-B
potenciaNominalFV  = 430;      % potencia nominal del panel [W]
ktempPotencia      = -0.29;    % coef. temperatura potencia [%/C]
NOCT               = 45;       % temperatura nominal de operacion de la celula [C]
GSTC               = 1000;     % irradiancia STC [W/m2]
vidaFV             = 25;       % vida util [anios]
precioWFV          = 0.6;      % coste por Wp instalado [EUR/W]

%% Aerogenerador: Leading Edge LE-300 (48 V)
% La potencia nominal (300 W) y la curva de potencia se definen en importar_eolica.m
precioWeol         = 4.5;      % coste por W instalado, sin el controlador [EUR/W]
vidaEol            = 25;       % vida util [anios]
precioRegulador    = 250;      % controlador/regulador eolico 48 V [EUR]

%% Bateria: Dyness B3/B3A 48 V
capacidadNominal   = 3552;     % capacidad nominal del modulo [Wh]
precioWh           = 0.285;    % precio [EUR/Wh]
vidaBat            = 15;       % vida util [anios]
rendIn             = 0.95;     % rendimiento de carga [p.u.]
rendOut            = 0.95;     % rendimiento de descarga [p.u.]

%% Grupo auxiliar: Genergy Mulhacen SOL 7000 W
precioGenerador    = 1219;     % precio [EUR]
consumoGrupo       = 0.62;     % consumo al 75 % de carga [l/kWh]
precioCombustible  = 1.528;    % precio gasolina 95 [EUR/l]

%% Sistema y economia
fiabilidadExigible = 90;       % fiabilidad minima exigida [%]
Pdmax              = 4600;     % potencia maxima demandada [W]
precioInversor     = 1010;     % inversor Solis S5-EO1P5K-48-P [EUR]
costeMantenimiento = 10;       % coste O&M como % de la inversion [%/anio]
tasaInteres        = 0.05;     % tasa de interes anual [p.u.]

%% Opciones de ejecucion (valores por defecto)
% Solo se asignan si no vienen ya fijadas desde la interfaz, de modo que la
% seleccion del usuario tiene prioridad.
if ~exist('localizacion', 'var');     localizacion     = "Islas Feroe"; end  % emplazamiento
if ~exist('algoritmo', 'var');        algoritmo        = "ACOR";        end  % PSO | AG | ACOR | CMAES
if ~exist('aleatorizar', 'var');      aleatorizar      = true;          end  % true: Monte Carlo | false: determinista
if ~exist('mostrarEvolucion', 'var'); mostrarEvolucion = true;          end  % mostrar coste por iteracion
