# 29524233_TFM
# Dimensionado óptimo de sistemas híbridos aislados y cooperación entre viviendas

Herramientas desarrolladas en **MATLAB (R2024b)** como parte de un Trabajo de Fin de Máster. Permiten dimensionar de forma óptima un sistema híbrido aislado y estudiar el efecto de que varias viviendas cooperen compartiendo energía.

Cada herramienta se maneja desde una **interfaz gráfica**: no hace falta tocar el código para usarla.

---

## Lo primero que debe saber: el repositorio tiene DOS programas

El código está dividido en **dos programas independientes**, cada uno en su propia carpeta y con su **propia interfaz**. No se usan a la vez; abre el que te interese:

| Programa | Carpeta | Interfaz (archivo a abrir) | ¿Para qué sirve? |
|---|---|---|---|
| **1. Dimensionado óptimo (SAPV)** | `1. Dimensionamiento/` | `SAPV_App.m` | Calcula el tamaño óptimo (nº de paneles, baterías y aerogeneradores) de **una** instalación aislada, al menor coste posible cumpliendo una fiabilidad. |
| **2. Cooperación entre viviendas** | `2. Cooperacion/` | `Cooperacion_App.m` | Compara **varias** viviendas funcionando aisladas frente a compartiendo energía entre ellas, para ver cuánto mejora la fiabilidad. |

> Los dos programas tienen la **misma estructura interna**, así que una vez se entiende uno, el otro resultará familiar.

---

## Requisitos

- **MATLAB R2024b** (o versión compatible).
- **Programa 1 (Dimensionamiento óptimo):** necesita la *Statistics and Machine Learning Toolbox*.
- **Programa 2 (Cooperación):** funciona **solo con la instalación base** de MATLAB, sin toolboxes adicionales.

---

## Cómo empezar (vale para los dos programas)

1. Abre MATLAB.
2. En MATLAB, navega hasta la carpeta del programa que quieras usar (`1. Dimensionamiento/` o `2. Cooperacion/`).
3. Abre el archivo de la interfaz (`SAPV_App.m` o `Cooperacion_App.m`) y pulsa **Run** (▶), o escribe su nombre en la consola:
   ```matlab
   SAPV_App          % programa 1
   Cooperacion_App   % programa 2
   ```
4. Se abre la ventana de la aplicación. Configura las opciones y pulsa **Ejecutar**.

No tiene que ejecutar los scripts a mano: la interfaz se encarga de lanzar todo el cálculo y de mostrar los resultados.

---

## Programa 1 — Dimensionado óptimo

**Qué hace:** busca la combinación más barata de paneles, baterías y aerogenerador que abastece a una vivienda aislada cumpliendo un nivel de fiabilidad, evaluando cada configuración con simulación de **Monte Carlo**.

**En la interfaz eliges:**
- **Algoritmo de optimización:** AG (algoritmo genético), ACOR (colonia de hormigas) o CMA-ES.
- **Emplazamiento:** Islas Feroe, Cabo Verde o Asuán.
- **Aleatorizar:** activa el modo estocástico (más realista) frente al determinista.
- **Mostrar evolución:** muestra el avance de la optimización.

**Qué obtienes:**
- La solución óptima (potencia FV, capacidad de batería y potencia eólica), su versión con número entero de equipos, coste, LCOE y fiabilidad.
- La **curva de convergencia** del algoritmo y un resumen de métricas en pantalla.

---

## Programa 2 — Cooperación entre viviendas

**Qué hace:** simula una pequeña **microrred** de varias viviendas y compara dos escenarios:
- **S1** — cada vivienda aislada, sin compartir.
- **S2x** — las viviendas cooperan compartiendo excedentes de energía.

Así se ve cuánto mejora la fiabilidad global gracias a la cooperación.

**En la interfaz eliges:**
- **Número de viviendas.**
- **Modo de diseño:** `manual` (introduces tú los tamaños en la tabla), `escalado` (a partir de un diseño base) u `óptimo` (los dimensiona automáticamente).
- **LOLP objetivo**, número de iteraciones, aleatorización y pico de demanda objetivo.
- Un **barrido del umbral de cooperación (SOC_C)** para ver su influencia.

**Qué obtienes:**
- Tablas comparativas entre S1 y S2x.
- Gráficas del **LOLP global**, la **energía no suministrada**, la **fiabilidad global** y la **mejora por vivienda** frente al umbral de cooperación.

---

## Autor

Alejandro Sánchez Rico.


