classdef SAPV_App < matlab.apps.AppBase
    % Interfaz de usuario del optimizador SAPV.
    % Permite elegir el algoritmo, el emplazamiento y el modo de simulacion,
    % lanzar la optimizacion y ver los resultados y la curva de convergencia.
    % Ejecutar con:  SAPV_App

    properties (Access = public)
        UIFigure            matlab.ui.Figure
        MainGrid            matlab.ui.container.GridLayout
        ControlPanel        matlab.ui.container.Panel
        ControlGrid         matlab.ui.container.GridLayout
        TituloLabel         matlab.ui.control.Label
        AlgoritmoLabel      matlab.ui.control.Label
        AlgoritmoDropDown   matlab.ui.control.DropDown
        LocalizacionLabel   matlab.ui.control.Label
        LocalizacionDropDown matlab.ui.control.DropDown
        EstocasticoCheckBox matlab.ui.control.CheckBox
        EvolucionCheckBox   matlab.ui.control.CheckBox
        EjecutarButton      matlab.ui.control.Button
        EstadoLamp          matlab.ui.control.Lamp
        EstadoLabel         matlab.ui.control.Label
        ResultPanel         matlab.ui.container.Panel
        ResultGrid          matlab.ui.container.GridLayout
        UIAxes              matlab.ui.control.UIAxes
        ResumenTextArea     matlab.ui.control.TextArea
        SalidaTextArea      matlab.ui.control.TextArea
    end

    properties (Access = private)
        ProjectFolder   % carpeta raiz del proyecto
        DataFolder      % carpeta de datos
    end

    methods (Access = private)

        function EjecutarButtonPushed(app, ~)
            % Configurar el workspace base con las opciones elegidas y lanzar main.m

            app.EstadoLamp.Color  = [0.93 0.69 0.13];   % naranja: ejecutando
            app.EstadoLabel.Text  = 'Ejecutando...';
            app.EjecutarButton.Enable = 'off';
            drawnow;

            dlg = uiprogressdlg(app.UIFigure, 'Title', 'Optimizando', ...
                'Message', 'Ejecutando la simulacion, por favor espere...', ...
                'Indeterminate', 'on');

            try
                assignin('base', 'projectFolder',    app.ProjectFolder);
                assignin('base', 'dataFolder',       app.DataFolder);
                assignin('base', 'algoritmo',        string(app.AlgoritmoDropDown.Value));
                assignin('base', 'localizacion',     string(app.LocalizacionDropDown.Value));
                assignin('base', 'aleatorizar',      app.EstocasticoCheckBox.Value);
                assignin('base', 'mostrarEvolucion', app.EvolucionCheckBox.Value);

                % Ejecutar main.m capturando la salida de texto
                salida = evalin('base', 'evalc(''modoApp = true; main;'')');

                BestSol     = evalin('base', 'BestSol');
                BestSolDisc = evalin('base', 'BestSolDisc');
                BestCost    = evalin('base', 'BestCost');

                app.SalidaTextArea.Value  = strsplit(salida, newline);
                app.ResumenTextArea.Value = app.formatearResumen(BestSol, BestSolDisc);
                app.dibujarConvergencia(BestCost, string(app.AlgoritmoDropDown.Value));

                app.EstadoLamp.Color = [0.47 0.67 0.19];   % verde: terminado
                app.EstadoLabel.Text = 'Ejecucion completada';
            catch err
                app.EstadoLamp.Color = [0.85 0.33 0.10];   % rojo: error
                app.EstadoLabel.Text = 'Error en la ejecucion';
                uialert(app.UIFigure, err.message, 'Error');
            end

            close(dlg);
            app.EjecutarButton.Enable = 'on';
        end

        function dibujarConvergencia(app, BestCost, nombreAlgoritmo)
            % Representar la evolucion del mejor coste por iteracion
            semilogy(app.UIAxes, BestCost, 'LineWidth', 1.5);
            title(app.UIAxes, ['Convergencia - ' char(nombreAlgoritmo)]);
            xlabel(app.UIAxes, 'Iteracion');
            ylabel(app.UIAxes, 'Coste');
            grid(app.UIAxes, 'on');
        end

        function texto = formatearResumen(~, BestSol, BestSolDisc)
            % Construir el resumen de resultados que se muestra en el panel
            texto = {
                '--- SOLUCION DISCRETIZADA ---'
                sprintf('Paneles FV:     %d', BestSolDisc.nPaneles)
                sprintf('Baterias:       %d', BestSolDisc.nBaterias)
                sprintf('Aerogeneradores:%d', BestSolDisc.nMolinos)
                sprintf('Coste anual:    %.0f EUR', BestSolDisc.Cost)
                sprintf('LCOE:           %.4f EUR/kWh', BestSolDisc.LCOE)
                sprintf('Fiabilidad:     %.2f %%', BestSolDisc.Reliability)
                ''
                '--- SOLUCION CONTINUA ---'
                sprintf('Potencia FV:    %.0f W', BestSol.Position(1))
                sprintf('Capacidad bat.: %.0f Wh', BestSol.Position(2))
                sprintf('Potencia eol.:  %.0f W', BestSol.Position(3))
                sprintf('Coste anual:    %.0f EUR', BestSol.Cost)
                };
            if isfield(BestSolDisc, 'Metricas')
                m = BestSolDisc.Metricas;
                texto = [texto; {
                    ''
                    '--- METRICAS DEL SISTEMA ---'
                    sprintf('LOLE:           %.1f h/anio', m.LOLE)
                    sprintf('LOLP:           %.2f %%', m.LOLP)
                    sprintf('ENS:            %.1f kWh/anio', m.ENS/1000)
                    sprintf('ENA:            %.1f kWh/anio', m.ENA/1000)
                    sprintf('Fallos FV:      %.1f', m.nFallosFV)
                    sprintf('Fallos eol.:    %.1f', m.nFallosEol)
                    sprintf('Arranques grupo:%.1f', m.nIDG)
                    sprintf('SOC medio:      %.1f %%', m.SOCmedio)
                    }];
            end
        end
    end

    methods (Access = private)

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 920 560];
            app.UIFigure.Name = 'Optimizador SAPV';

            app.MainGrid = uigridlayout(app.UIFigure, [1 2]);
            app.MainGrid.ColumnWidth = {320, '1x'};
            app.MainGrid.RowHeight   = {'1x'};

            % ---- Panel de controles (izquierda) ----
            app.ControlPanel = uipanel(app.MainGrid);
            app.ControlPanel.Title = 'Configuracion';
            app.ControlPanel.Layout.Column = 1;

            app.ControlGrid = uigridlayout(app.ControlPanel, [9 1]);
            app.ControlGrid.RowHeight = {30, 22, 30, 22, 30, 30, 30, 40, '1x'};
            app.ControlGrid.RowSpacing = 8;

            app.TituloLabel = uilabel(app.ControlGrid);
            app.TituloLabel.Text = 'Optimizador de sistemas SAPV';
            app.TituloLabel.FontWeight = 'bold';
            app.TituloLabel.FontSize = 14;

            app.AlgoritmoLabel = uilabel(app.ControlGrid);
            app.AlgoritmoLabel.Text = 'Algoritmo de optimizacion';

            app.AlgoritmoDropDown = uidropdown(app.ControlGrid);
            app.AlgoritmoDropDown.Items     = {'PSO', 'Algoritmo genetico', 'ACOR', 'CMA-ES'};
            app.AlgoritmoDropDown.ItemsData = {'PSO', 'AG', 'ACOR', 'CMAES'};
            app.AlgoritmoDropDown.Value     = 'ACOR';

            app.LocalizacionLabel = uilabel(app.ControlGrid);
            app.LocalizacionLabel.Text = 'Localizacion';

            app.LocalizacionDropDown = uidropdown(app.ControlGrid);
            app.LocalizacionDropDown.Items     = {'Islas Feroe', 'Cabo Verde', 'Asuan (Egipto)'};
            app.LocalizacionDropDown.ItemsData = {'Islas Feroe', 'Cabo Verde', 'Asuan'};
            app.LocalizacionDropDown.Value     = 'Islas Feroe';

            app.EstocasticoCheckBox = uicheckbox(app.ControlGrid);
            app.EstocasticoCheckBox.Text = 'Simulacion estocastica (Monte Carlo)';
            app.EstocasticoCheckBox.Value = true;

            app.EvolucionCheckBox = uicheckbox(app.ControlGrid);
            app.EvolucionCheckBox.Text = 'Mostrar evolucion por iteracion';
            app.EvolucionCheckBox.Value = true;

            app.EjecutarButton = uibutton(app.ControlGrid, 'push');
            app.EjecutarButton.Text = 'Ejecutar';
            app.EjecutarButton.FontWeight = 'bold';
            app.EjecutarButton.ButtonPushedFcn = createCallbackFcn(app, @EjecutarButtonPushed, true);

            % Estado (lampara + texto) en la ultima fila
            estadoGrid = uigridlayout(app.ControlGrid, [1 2]);
            estadoGrid.ColumnWidth = {20, '1x'};
            estadoGrid.Layout.Row = 9;
            estadoGrid.Padding = [0 0 0 0];
            app.EstadoLamp = uilamp(estadoGrid);
            app.EstadoLamp.Color = [0.8 0.8 0.8];
            app.EstadoLabel = uilabel(estadoGrid);
            app.EstadoLabel.Text = 'Listo';

            % ---- Panel de resultados (derecha) ----
            app.ResultPanel = uipanel(app.MainGrid);
            app.ResultPanel.Title = 'Resultados';
            app.ResultPanel.Layout.Column = 2;

            app.ResultGrid = uigridlayout(app.ResultPanel, [2 2]);
            app.ResultGrid.ColumnWidth = {'1.4x', '1x'};
            app.ResultGrid.RowHeight   = {'1x', 150};

            app.UIAxes = uiaxes(app.ResultGrid);
            app.UIAxes.Layout.Row = 1;
            app.UIAxes.Layout.Column = [1 2];
            title(app.UIAxes, 'Convergencia');
            xlabel(app.UIAxes, 'Iteracion');
            ylabel(app.UIAxes, 'Coste');

            app.ResumenTextArea = uitextarea(app.ResultGrid);
            app.ResumenTextArea.Layout.Row = 2;
            app.ResumenTextArea.Layout.Column = 1;
            app.ResumenTextArea.Editable = 'off';
            app.ResumenTextArea.FontName = 'Consolas';

            app.SalidaTextArea = uitextarea(app.ResultGrid);
            app.SalidaTextArea.Layout.Row = 2;
            app.SalidaTextArea.Layout.Column = 2;
            app.SalidaTextArea.Editable = 'off';
            app.SalidaTextArea.FontName = 'Consolas';

            app.UIFigure.Visible = 'on';
        end
    end

    methods (Access = public)

        function app = SAPV_App
            % Localizar la raiz del proyecto y anadir la carpeta Scripts al path
            app.ProjectFolder = fileparts(mfilename('fullpath'));
            app.DataFolder    = fullfile(app.ProjectFolder, 'Data');
            addpath(fullfile(app.ProjectFolder, 'Scripts'));

            createComponents(app);
            registerApp(app, app.UIFigure);

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure);
        end
    end
end
