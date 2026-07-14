classdef Cooperacion_App < matlab.apps.AppBase
    % Interfaz de usuario del estudio de cooperacion entre viviendas.
    % Permite configurar el numero de viviendas, su diseno y el umbral de
    % cooperacion, ejecutar la simulacion y ver los resultados y las graficas.
    % Ejecutar con:  Cooperacion_App

    properties (Access = public)
        UIFigure             matlab.ui.Figure
        MainGrid             matlab.ui.container.GridLayout
        ControlPanel         matlab.ui.container.Panel
        ControlGrid          matlab.ui.container.GridLayout
        TituloLabel          matlab.ui.control.Label
        NViviendasLabel      matlab.ui.control.Label
        NViviendasDropDown   matlab.ui.control.DropDown
        ModoLabel            matlab.ui.control.Label
        ModoDropDown         matlab.ui.control.DropDown
        LOLPLabel            matlab.ui.control.Label
        LOLPField            matlab.ui.control.NumericEditField
        ViviendasTable       matlab.ui.control.Table
        SOCcLabel            matlab.ui.control.Label
        SOCcModoDropDown     matlab.ui.control.DropDown
        SOCcGrid             matlab.ui.container.GridLayout
        SOCcMinField         matlab.ui.control.NumericEditField
        SOCcMaxField         matlab.ui.control.NumericEditField
        SOCcPasoField        matlab.ui.control.NumericEditField
        NIterLabel           matlab.ui.control.Label
        NIterField           matlab.ui.control.NumericEditField
        SemillaCheckBox      matlab.ui.control.CheckBox
        SemillaField         matlab.ui.control.NumericEditField
        AleatorizarCheckBox  matlab.ui.control.CheckBox
        EjecutarButton       matlab.ui.control.Button
        EstadoLamp           matlab.ui.control.Lamp
        EstadoLabel          matlab.ui.control.Label
        ResultPanel          matlab.ui.container.Panel
        ResultGrid           matlab.ui.container.GridLayout
        AxesGrid             matlab.ui.container.GridLayout
        AxLOLP               matlab.ui.control.UIAxes
        AxENS                matlab.ui.control.UIAxes
        AxFiab               matlab.ui.control.UIAxes
        AxMejora             matlab.ui.control.UIAxes
        SalidaTextArea       matlab.ui.control.TextArea
    end

    properties (Access = private)
        ProjectFolder
        DataFolder
        PdmaxDefault = [3000 3300 2800 3500 3100];
    end

    methods (Access = private)

        function actualizarTabla(app)
            % Ajusta las filas de la tabla al numero de viviendas elegido
            n = str2double(app.NViviendasDropDown.Value);
            datos = zeros(n, 3);
            for j = 1:n
                datos(j,1) = app.PdmaxDefault(min(j, numel(app.PdmaxDefault)));
                datos(j,2) = 9900;      % PgFV base por defecto
                datos(j,3) = 17760;     % CapBat base por defecto
            end
            app.ViviendasTable.Data = datos;
            app.ViviendasTable.RowName = arrayfun(@(j) sprintf('V%d',j), 1:n, 'UniformOutput', false);
        end

        function actualizarEstado(app)
            % Habilita/inhabilita campos segun el modo elegido
            esOptimo = strcmp(app.ModoDropDown.Value, 'optimo');
            esManual = strcmp(app.ModoDropDown.Value, 'manual');
            app.LOLPField.Enable = matlab.lang.OnOffSwitchState(esOptimo);
            app.ViviendasTable.ColumnEditable = [true esManual esManual];

            esBarrido = strcmp(app.SOCcModoDropDown.Value, 'barrido');
            app.SOCcMaxField.Enable  = matlab.lang.OnOffSwitchState(esBarrido);
            app.SOCcPasoField.Enable = matlab.lang.OnOffSwitchState(esBarrido);
            if esBarrido
                app.SOCcMinField.Tooltip = 'SOC_C minimo (%)';
            else
                app.SOCcMinField.Tooltip = 'Valor unico de SOC_C (%)';
            end
            app.SemillaField.Enable = app.SemillaCheckBox.Value;
        end

        function EjecutarButtonPushed(app, ~)
            app.EstadoLamp.Color = [0.93 0.69 0.13];
            app.EstadoLabel.Text = 'Ejecutando...';
            app.EjecutarButton.Enable = 'off';
            drawnow;

            dlg = uiprogressdlg(app.UIFigure, 'Title', 'Simulando', ...
                'Message', 'Ejecutando la simulacion Monte Carlo, por favor espere...', ...
                'Indeterminate', 'on');

            try
                n     = str2double(app.NViviendasDropDown.Value);
                datos = app.ViviendasTable.Data;

                params = struct();
                params.nViviendas    = n;
                params.modoDiseno    = app.ModoDropDown.Value;
                params.LOLPobjetivo  = app.LOLPField.Value;
                params.nIter         = app.NIterField.Value;
                params.aleatorizar   = app.AleatorizarCheckBox.Value;
                params.PdmaxObjetivo = datos(:,1)';
                if app.SemillaCheckBox.Value
                    params.semillaPerfiles = app.SemillaField.Value;
                end

                % Umbrales de cooperacion segun el selector
                if strcmp(app.SOCcModoDropDown.Value, 'barrido')
                    SOCc_values = (app.SOCcMinField.Value : app.SOCcPasoField.Value : app.SOCcMaxField.Value) / 100;
                else
                    SOCc_values = app.SOCcMinField.Value / 100;
                end

                assignin('base', 'projectFolder', app.ProjectFolder);
                assignin('base', 'dataFolder',    app.DataFolder);
                assignin('base', 'params',        params);
                assignin('base', 'SOCc_values',   SOCc_values);
                assignin('base', 'PgFV_base',     9900);
                assignin('base', 'CapBat_base',   17760);
                assignin('base', 'PgEOL_base',    0);
                if strcmp(params.modoDiseno, 'manual')
                    optimosManual = [datos(:,2), datos(:,3), zeros(n,1)];
                    assignin('base', 'optimosManual', optimosManual);
                end

                salida = evalin('base', 'evalc(''modoApp = true; main_cooperacion;'')');

                ResultadosS1  = evalin('base', 'ResultadosS1');
                ResultadosS2x = evalin('base', 'ResultadosS2x');
                SOCc_values   = evalin('base', 'SOCc_values');
                optimos       = evalin('base', 'optimos');

                % Reflejar el diseno usado (util en modos automaticos)
                datos(:,2) = optimos(:,1);
                datos(:,3) = optimos(:,2);
                app.ViviendasTable.Data = datos;

                app.SalidaTextArea.Value = strsplit(salida, newline);
                app.dibujarGraficas(ResultadosS1, ResultadosS2x, SOCc_values);

                app.EstadoLamp.Color = [0.47 0.67 0.19];
                app.EstadoLabel.Text = 'Ejecucion completada';
            catch err
                app.EstadoLamp.Color = [0.85 0.33 0.10];
                app.EstadoLabel.Text = 'Error en la ejecucion';
                uialert(app.UIFigure, err.message, 'Error');
            end

            close(dlg);
            app.EjecutarButton.Enable = 'on';
        end

        function dibujarGraficas(app, R1, R2x, SOCc)
            x = SOCc * 100;
            nV = numel(R1.ENS);

            LOLPg = arrayfun(@(r) r.LOLP_global, R2x);
            ENSg  = arrayfun(@(r) r.ENS_global, R2x);
            Fiabg = arrayfun(@(r) r.fiabilidad_global, R2x);
            mejora = zeros(numel(SOCc), nV);
            for s = 1:numel(SOCc)
                for j = 1:nV
                    if R1.LOLP(j) > 0
                        mejora(s,j) = 100 * (R1.LOLP(j) - R2x(s).LOLP(j)) / R1.LOLP(j);
                    end
                end
            end

            plot(app.AxLOLP, x, LOLPg, '-o', 'LineWidth', 1.5);
            yline(app.AxLOLP, R1.LOLP_global, '--', 'S1');
            title(app.AxLOLP, 'LOLP global'); xlabel(app.AxLOLP, 'SOC_C (%)');
            ylabel(app.AxLOLP, 'LOLP (%)'); grid(app.AxLOLP, 'on');

            plot(app.AxENS, x, ENSg/1000, '-o', 'LineWidth', 1.5);
            yline(app.AxENS, R1.ENS_global/1000, '--', 'S1');
            title(app.AxENS, 'ENS global'); xlabel(app.AxENS, 'SOC_C (%)');
            ylabel(app.AxENS, 'ENS (kWh/anio)'); grid(app.AxENS, 'on');

            plot(app.AxFiab, x, Fiabg, '-o', 'LineWidth', 1.5);
            yline(app.AxFiab, R1.fiabilidad_global, '--', 'S1');
            title(app.AxFiab, 'Fiabilidad global'); xlabel(app.AxFiab, 'SOC_C (%)');
            ylabel(app.AxFiab, 'Fiabilidad (%)'); grid(app.AxFiab, 'on');

            plot(app.AxMejora, x, mejora, '-o', 'LineWidth', 1.5);
            title(app.AxMejora, 'Mejora de LOLP por vivienda');
            xlabel(app.AxMejora, 'SOC_C (%)'); ylabel(app.AxMejora, 'Mejora (%)');
            grid(app.AxMejora, 'on');
            legend(app.AxMejora, arrayfun(@(j) sprintf('V%d',j), 1:nV, 'UniformOutput', false), ...
                   'Location', 'best', 'FontSize', 7);
        end
    end

    methods (Access = private)

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [80 80 1080 620];
            app.UIFigure.Name = 'Microrred cooperativa entre viviendas';

            app.MainGrid = uigridlayout(app.UIFigure, [1 2]);
            app.MainGrid.ColumnWidth = {360, '1x'};
            app.MainGrid.RowHeight = {'1x'};

            % ----- Controles -----
            app.ControlPanel = uipanel(app.MainGrid);
            app.ControlPanel.Title = 'Configuracion';
            app.ControlPanel.Layout.Column = 1;

            app.ControlGrid = uigridlayout(app.ControlPanel, [15 2]);
            app.ControlGrid.ColumnWidth = {'1x', '1x'};
            app.ControlGrid.RowHeight = {26, 26, 26, 26, 120, 24, 26, 26, 26, 26, 26, 34, 20, '1x'};
            app.ControlGrid.RowSpacing = 6;

            app.TituloLabel = uilabel(app.ControlGrid);
            app.TituloLabel.Text = 'Microrred cooperativa SAPV';
            app.TituloLabel.FontWeight = 'bold';
            app.TituloLabel.FontSize = 14;
            app.TituloLabel.Layout.Row = 1; app.TituloLabel.Layout.Column = [1 2];

            app.NViviendasLabel = uilabel(app.ControlGrid);
            app.NViviendasLabel.Text = 'Numero de viviendas';
            app.NViviendasLabel.Layout.Row = 2; app.NViviendasLabel.Layout.Column = 1;
            app.NViviendasDropDown = uidropdown(app.ControlGrid);
            app.NViviendasDropDown.Items = {'2','3','4','5'};
            app.NViviendasDropDown.Value = '5';
            app.NViviendasDropDown.Layout.Row = 2; app.NViviendasDropDown.Layout.Column = 2;
            app.NViviendasDropDown.ValueChangedFcn = createCallbackFcn(app, @(a,e) app.actualizarTabla(), true);

            app.ModoLabel = uilabel(app.ControlGrid);
            app.ModoLabel.Text = 'Modo de diseno';
            app.ModoLabel.Layout.Row = 3; app.ModoLabel.Layout.Column = 1;
            app.ModoDropDown = uidropdown(app.ControlGrid);
            app.ModoDropDown.Items = {'Manual','Escalado','Optimo'};
            app.ModoDropDown.ItemsData = {'manual','escalado','optimo'};
            app.ModoDropDown.Value = 'optimo';
            app.ModoDropDown.Layout.Row = 3; app.ModoDropDown.Layout.Column = 2;
            app.ModoDropDown.ValueChangedFcn = createCallbackFcn(app, @(a,e) app.actualizarEstado(), true);

            app.LOLPLabel = uilabel(app.ControlGrid);
            app.LOLPLabel.Text = 'LOLP objetivo [%] (modo optimo)';
            app.LOLPLabel.Layout.Row = 4; app.LOLPLabel.Layout.Column = 1;
            app.LOLPField = uieditfield(app.ControlGrid, 'numeric');
            app.LOLPField.Value = 10;
            app.LOLPField.Limits = [0.1 50];
            app.LOLPField.Layout.Row = 4; app.LOLPField.Layout.Column = 2;

            app.ViviendasTable = uitable(app.ControlGrid);
            app.ViviendasTable.ColumnName = {'Pdmax (W)','PgFV (W)','CapBat (Wh)'};
            app.ViviendasTable.ColumnEditable = [true false false];
            app.ViviendasTable.Layout.Row = 5; app.ViviendasTable.Layout.Column = [1 2];

            app.SOCcLabel = uilabel(app.ControlGrid);
            app.SOCcLabel.Text = 'Umbral de cooperacion SOC_C';
            app.SOCcLabel.FontWeight = 'bold';
            app.SOCcLabel.Layout.Row = 6; app.SOCcLabel.Layout.Column = [1 2];

            app.SOCcModoDropDown = uidropdown(app.ControlGrid);
            app.SOCcModoDropDown.Items = {'Barrido','Unico'};
            app.SOCcModoDropDown.ItemsData = {'barrido','unico'};
            app.SOCcModoDropDown.Value = 'barrido';
            app.SOCcModoDropDown.Layout.Row = 7; app.SOCcModoDropDown.Layout.Column = [1 2];
            app.SOCcModoDropDown.ValueChangedFcn = createCallbackFcn(app, @(a,e) app.actualizarEstado(), true);

            % Min / Max / Paso de SOC_C
            app.SOCcGrid = uigridlayout(app.ControlGrid, [1 3]);
            app.SOCcGrid.Layout.Row = 8; app.SOCcGrid.Layout.Column = [1 2];
            app.SOCcGrid.Padding = [0 0 0 0]; app.SOCcGrid.ColumnSpacing = 4;
            app.SOCcMinField = uieditfield(app.SOCcGrid, 'numeric');
            app.SOCcMinField.Value = 20; app.SOCcMinField.Limits = [20 100];
            app.SOCcMinField.Tooltip = 'SOC_C minimo (%)';
            app.SOCcMaxField = uieditfield(app.SOCcGrid, 'numeric');
            app.SOCcMaxField.Value = 40; app.SOCcMaxField.Limits = [20 100];
            app.SOCcMaxField.Tooltip = 'SOC_C maximo (%)';
            app.SOCcPasoField = uieditfield(app.SOCcGrid, 'numeric');
            app.SOCcPasoField.Value = 5; app.SOCcPasoField.Limits = [1 50];
            app.SOCcPasoField.Tooltip = 'Paso (%)';

            app.NIterLabel = uilabel(app.ControlGrid);
            app.NIterLabel.Text = 'Iteraciones Monte Carlo';
            app.NIterLabel.Layout.Row = 9; app.NIterLabel.Layout.Column = 1;
            app.NIterField = uieditfield(app.ControlGrid, 'numeric');
            app.NIterField.Value = 50; app.NIterField.Limits = [1 1000];
            app.NIterField.RoundFractionalValues = 'on';
            app.NIterField.Layout.Row = 9; app.NIterField.Layout.Column = 2;

            app.SemillaCheckBox = uicheckbox(app.ControlGrid);
            app.SemillaCheckBox.Text = 'Usar semilla';
            app.SemillaCheckBox.Value = true;
            app.SemillaCheckBox.Layout.Row = 10; app.SemillaCheckBox.Layout.Column = 1;
            app.SemillaCheckBox.ValueChangedFcn = createCallbackFcn(app, @(a,e) app.actualizarEstado(), true);
            app.SemillaField = uieditfield(app.ControlGrid, 'numeric');
            app.SemillaField.Value = 42;
            app.SemillaField.Layout.Row = 10; app.SemillaField.Layout.Column = 2;

            app.AleatorizarCheckBox = uicheckbox(app.ControlGrid);
            app.AleatorizarCheckBox.Text = 'Aleatorizar (Monte Carlo estocastico)';
            app.AleatorizarCheckBox.Value = true;
            app.AleatorizarCheckBox.Layout.Row = 11; app.AleatorizarCheckBox.Layout.Column = [1 2];

            app.EjecutarButton = uibutton(app.ControlGrid, 'push');
            app.EjecutarButton.Text = 'Ejecutar';
            app.EjecutarButton.FontWeight = 'bold';
            app.EjecutarButton.Layout.Row = 12; app.EjecutarButton.Layout.Column = [1 2];
            app.EjecutarButton.ButtonPushedFcn = createCallbackFcn(app, @EjecutarButtonPushed, true);

            estadoGrid = uigridlayout(app.ControlGrid, [1 2]);
            estadoGrid.Layout.Row = 13; estadoGrid.Layout.Column = [1 2];
            estadoGrid.ColumnWidth = {20, '1x'}; estadoGrid.Padding = [0 0 0 0];
            app.EstadoLamp = uilamp(estadoGrid);
            app.EstadoLamp.Color = [0.8 0.8 0.8];
            app.EstadoLabel = uilabel(estadoGrid);
            app.EstadoLabel.Text = 'Listo';

            % ----- Resultados -----
            app.ResultPanel = uipanel(app.MainGrid);
            app.ResultPanel.Title = 'Resultados';
            app.ResultPanel.Layout.Column = 2;

            app.ResultGrid = uigridlayout(app.ResultPanel, [2 1]);
            app.ResultGrid.RowHeight = {'1x', 150};

            app.AxesGrid = uigridlayout(app.ResultGrid, [2 2]);
            app.AxesGrid.Layout.Row = 1;
            app.AxLOLP   = uiaxes(app.AxesGrid);
            app.AxENS    = uiaxes(app.AxesGrid);
            app.AxFiab   = uiaxes(app.AxesGrid);
            app.AxMejora = uiaxes(app.AxesGrid);
            title(app.AxLOLP, 'LOLP global'); title(app.AxENS, 'ENS global');
            title(app.AxFiab, 'Fiabilidad global'); title(app.AxMejora, 'Mejora por vivienda');

            app.SalidaTextArea = uitextarea(app.ResultGrid);
            app.SalidaTextArea.Layout.Row = 2;
            app.SalidaTextArea.Editable = 'off';
            app.SalidaTextArea.FontName = 'Consolas';

            actualizarTabla(app);
            actualizarEstado(app);
            app.UIFigure.Visible = 'on';
        end
    end

    methods (Access = public)

        function app = Cooperacion_App
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
