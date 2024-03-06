classdef ImageAcquisition_exported < matlab.apps.AppBase
    %IMAGEACQUISITION_EXPORTED Camera Control software developed in MATLAB for
    %acquiring images.
    %   This app provides functionalities for:
    %   - Configure Andor and Zelux cameras
    %   - Acquire images with a programmable sequence
    %   - Display real-time analysis

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        RunNumLabel                     matlab.ui.control.Label
        StatusLamp                      matlab.ui.control.Lamp
        StatusLabel                     matlab.ui.control.Label
        TabGroup                        matlab.ui.container.TabGroup
        ImageTab                        matlab.ui.container.Tab
        GridLayout                      matlab.ui.container.GridLayout
        ElapsedTimeLabel                matlab.ui.control.Label
        Plot3DropDownLabel              matlab.ui.control.Label
        RunButton                       matlab.ui.control.Button
        PauseContinueButton             matlab.ui.control.StateButton
        Plot2DropDownLabel              matlab.ui.control.Label
        SaveButton                      matlab.ui.control.Button
        StopButton                      matlab.ui.control.StateButton
        Axes1DropDown                   matlab.ui.control.DropDown
        Axes2DropDown                   matlab.ui.control.DropDown
        Axes2DropDownLabel              matlab.ui.control.Label
        Plot1DropDownLabel              matlab.ui.control.Label
        Plot1DropDown                   matlab.ui.control.DropDown
        Plot2DropDown                   matlab.ui.control.DropDown
        Plot3DropDown                   matlab.ui.control.DropDown
        Axes1DropDownLabel              matlab.ui.control.Label
        SmallAxes3                      matlab.ui.control.UIAxes
        SmallAxes2                      matlab.ui.control.UIAxes
        SmallAxes1                      matlab.ui.control.UIAxes
        BigAxes2                        matlab.ui.control.UIAxes
        BigAxes1                        matlab.ui.control.UIAxes
        SettingsTab                     matlab.ui.container.Tab
        AcquisitionSettingsPanel        matlab.ui.container.Panel
        UITable                         matlab.ui.control.Table
        AcquisitionStatusLamp           matlab.ui.control.Lamp
        InitializeAcquisitionButton     matlab.ui.control.Button
        AcquisitiontimeoutsSpinner      matlab.ui.control.Spinner
        AcquisitiontimeoutsSpinnerLabel  matlab.ui.control.Label
        NumberofacquisitionsSpinner     matlab.ui.control.Spinner
        NumberofacquisitionsSpinnerLabel  matlab.ui.control.Label
        EstimatedDatasetsizeLabel       matlab.ui.control.Label
        ZeluxSettingsPanel              matlab.ui.container.Panel
        ZeluxStatusLamp                 matlab.ui.control.Lamp
        CloseZeluxButton                matlab.ui.control.Button
        ConfigureZeluxButton            matlab.ui.control.Button
        ZeluxTriggermodeDropDown        matlab.ui.control.DropDown
        TriggermodeDropDown_3Label      matlab.ui.control.Label
        ZeluxExposuresSpinner           matlab.ui.control.Spinner
        ExposuresSpinner_3Label         matlab.ui.control.Label
        Andor19331SettingsPanel         matlab.ui.container.Panel
        Andor19331StatusLamp            matlab.ui.control.Lamp
        CloseAndor19331Button           matlab.ui.control.Button
        ConfigureAndor19331Button       matlab.ui.control.Button
        Andor19331TriggermodeDropDown   matlab.ui.control.DropDown
        TriggermodeDropDown_2Label      matlab.ui.control.Label
        Andor19331AcquisitionmodeDropDown  matlab.ui.control.DropDown
        AcquisitionmodeDropDown_2Label  matlab.ui.control.Label
        Andor19331ExposuresSpinner      matlab.ui.control.Spinner
        ExposuresSpinner_2Label         matlab.ui.control.Label
        Andor19330SettingsPanel         matlab.ui.container.Panel
        Andor19330StatusLamp            matlab.ui.control.Lamp
        CloseAndor19330Button           matlab.ui.control.Button
        ConfigureAndor19330Button       matlab.ui.control.Button
        Andor19330TriggermodeDropDown   matlab.ui.control.DropDown
        TriggermodeDropDownLabel        matlab.ui.control.Label
        Andor19330AcquisitionmodeDropDown  matlab.ui.control.DropDown
        AcquisitionmodeDropDownLabel    matlab.ui.control.Label
        Andor19330ExposuresSpinner      matlab.ui.control.Spinner
        ExposuresSpinnerLabel           matlab.ui.control.Label
    end

    
    properties (Access = private)
        Setting = struct('Andor19330', struct(), ...
                         'Andor19331', struct(), ...
                         'Zelux', struct(), ...
                         'Acquisition', struct())
        Layout = struct('BigAxes1', struct('Content', 'Image_1'), ...
                        'BigAxes2', struct('Content', 'Image_2'), ...
                        'SmallAxes1', struct(), ...
                        'SmallAxes2', struct(), ...
                        'SmallAxes3', struct())
        CameraHandle = struct()
        Live = struct()
        Data = struct()
    end

    
    methods (Access = private)        
        function updateLayout(app)
            image1 = strsplit(app.Layout.BigAxes1.Content, '_');
            image1_num = str2double(image1{end});
            imagesc(app.BigAxes1, app.Live.Image{image1_num})
            colorbar(app.BigAxes1)

            image2 = strsplit(app.Layout.BigAxes2.Content, '_');
            image2_num = str2double(image2{end});
            imagesc(app.BigAxes2, app.Live.Image{image2_num})
            colorbar(app.BigAxes2)

            drawnow
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startApp(app)
            % Get screen size to set the APP dimension
            s = get(0, 'ScreenSize');
            app.UIFigure.Position = [s(1)+50, s(2)+50, s(3)-100, s(4)-100];

            % Pre-populate the acquisition table
            app.UITable.Data = table((1:8)', ...
                categorical( ...
                {'Zelux', 'Zelux', 'Andor19330', 'Andor19330', '--inactive--', '--inactive--', '--inactive--', '--inactive--'}, ...
                {'Andor19330','Andor19331','Zelux','--inactive--'},'Ordinal',true)', ...
                {'Lattice', 'DMD', 'Image', 'Background', '', '', '', ''}', ...
                {'', '', '', '', '', '', '', ''}', ...
                'VariableNames',{'Order', 'Camera', 'Label', 'Note'});

        end

        % Close request function: UIFigure
        function closeUI(app, event)
            closeZeluxCallback(app, event)           
            delete(app)
        end

        % Button pushed function: RunButton
        function run(app, event)
            if ~isequal(app.AcquisitionStatusLamp.Color, [0, 1, 0])
                initializeAcquisition(app, event)                
                if ~isequal(app.AcquisitionStatusLamp.Color, [0, 1, 0])
                    return
                end
            end

            % Run continuously until aborted
            while ~app.StopButton.Value
                while ~app.PauseContinueButton.Value && ~app.StopButton.Value
                    tic

                    app.StatusLamp.Color = [1, 1, 0];
                    app.StatusLabel.Text = 'Acquiring...';

                    % Acquire data
                    app.Live.Image = acquireImage(app.Setting.Acquisition, app.CameraHandle);
  
                    elapsed_time1 = toc;
                    fprintf('Images acquired. Elapsed time is %g seconds.\n', elapsed_time1)

                    app.StatusLamp.Color = [0, 1, 0];
                    app.StatusLabel.Text = 'Acquired';

                    % Update data storage
                    app.Live.Current = app.Live.Current + 1;
                    app.Data = updateData(app.Data, app.Live.Image, app.Live.Current);
                    app.RunNumLabel.Text = sprintf('Run Num: %d/%d', app.Live.Current, app.Setting.Acquisition.NumAcquisitions);

                    % Update layout
                    updateLayout(app)

                    elapsed_time2 = toc;
                    app.ElapsedTimeLabel.Text = sprintf('Elapsed time: %.2f s', elapsed_time2);

                    pause(0.1)               
                end
                
                app.StatusLamp.Color = [1, 1, 0];
                app.StatusLabel.Text = 'Paused';
                pause(0.1)
            end

            fprintf('Acquisition stopped\n')
            app.StatusLamp.Color = [1, 0, 0];
            app.StatusLabel.Text = 'Stopped';
            app.StopButton.Value = false;
            
        end

        % Button pushed function: SaveButton
        function save(app, event)
            Data = app.Data;
            uisave('Data', fullfile(pwd, 'Data'))

        end

        % Button pushed function: ConfigureAndor19330Button
        function configure19330(app, event)
            app.CameraHandle = initializeAndor(19330, app.CameraHandle, "verbose",false);
            setCurrentAndor(19330, app.CameraHandle)

            exposure = app.Andor19330ExposuresSpinner.Value;
            external_trigger = strcmp(app.Andor19330TriggermodeDropDown.Value, 'External');
            switch app.Andor19330AcquisitionmodeDropDown.Value
                case 'Full frame'
                    num_frames = 1;
                case 'FK 2'
                    num_frames = 2;
                case 'FK 4'
                    num_frames = 4;
                case 'FK 8'
                    num_frames = 8;
            end
            setModeFK("num_frames",num_frames, ...
                "exposure",exposure, ...
                "external_trigger",external_trigger)

            % After configuration, set the indicator to Green (RGB)
            app.Andor19330StatusLamp.Color = [0, 1, 0];

            % Store the settings to app.Setting
            app.Setting.Andor19330 = struct('Exposure', exposure, ...
                'External', external_trigger, ...
                'NumFrames', num_frames);

        end

        % Button pushed function: ConfigureAndor19331Button
        function configure19331(app, event)
            app.CameraHandle = initializeAndor(19331, app.CameraHandle, "verbose",false);
            setCurrentAndor(19331, app.CameraHandle)
            
            exposure = app.Andor19331ExposuresSpinner.Value;
            external_trigger = strcmp(app.Andor19331TriggermodeDropDown.Value, 'External');
            switch app.Andor19331AcquisitionmodeDropDown.Value
                case 'Full frame'
                    num_frames = 1;
                case 'FK 2'
                    num_frames = 2;
                case 'FK 4'
                    num_frames = 4;
                case 'FK 8'
                    num_frames = 8;
            end
            setModeFK("num_frames",num_frames, ...
            "exposure",exposure, ...
            "external_trigger",external_trigger)

            % After configuration, set the indicator to Green (RGB)
            app.Andor19331StatusLamp.Color = [0, 1, 0];

            % Store the settings to app.Setting
            app.Setting.Andor19331 = struct('Exposure', exposure, ...
                'External', external_trigger, ...
                'NumFrames', num_frames);

        end

        % Button pushed function: ConfigureZeluxButton
        function configureZelux(app, event)
            exposure = app.ZeluxExposuresSpinner.Value;
            external_trigger = strcmp(app.ZeluxTriggermodeDropDown.Value, 'External');
            
            if isfield(app.CameraHandle, 'Zelux') && ~isempty(app.CameraHandle.Zelux)
                closeZelux(app.CameraHandle.Zelux{:})
            end
            [tlCameraSDK, tlCamera] = initializeZelux("exposure",exposure, "external_trigger",external_trigger);
            app.CameraHandle.Zelux = {tlCameraSDK, tlCamera};

            % After configuration, set the indicator to Green (RGB)
            app.ZeluxStatusLamp.Color = [0, 1, 0];

            % Store the settings to app.Setting
            app.Setting.Zelux = struct('Exposure', exposure, ...
                'External', external_trigger, ...
                'XPixels', 1440, ...
                'YPixels', 1080);

        end

        % Button pushed function: CloseAndor19330Button
        function close19330(app, event)
            closeAndor(19330, app.CameraHandle, "verbose",false)

            % After closing, set the indicator to Red (RGB)
            app.Andor19330StatusLamp.Color = [1, 0, 0];

        end

        % Button pushed function: CloseAndor19331Button
        function close19331(app, event)
            closeAndor(19331, app.CameraHandle, "verbose",false)

            % After closing, set the indicator to Red (RGB)
            app.Andor19331StatusLamp.Color = [1, 0, 0];

        end

        % Button pushed function: CloseZeluxButton
        function closeZeluxCallback(app, event)
            if isfield(app.CameraHandle, 'Zelux') & ~isempty(app.CameraHandle.Zelux)
                closeZelux(app.CameraHandle.Zelux{:})
                app.CameraHandle.Zelux = {};
            end

            % After closing, set the indicator to Red (RGB)
            app.ZeluxStatusLamp.Color = [1, 0, 0];

        end

        % Value changed function: Andor19330AcquisitionmodeDropDown, 
        % ...and 2 other components
        function updateAndor19330Status(app, event)
            % Setting the status to "Yellow" to indicate the settings are
            % not active
            if isequal(app.Andor19330StatusLamp.Color, [0, 1, 0])
                app.Andor19330StatusLamp.Color = [1, 1, 0];
            end
            if isequal(app.AcquisitionStatusLamp.Color, [0, 1, 0])
                app.AcquisitionStatusLamp.Color = [1, 1, 0];
            end
        end

        % Value changed function: Andor19331AcquisitionmodeDropDown, 
        % ...and 2 other components
        function updateAndor19331Status(app, event)
            % Setting the status to "Yellow" to indicate the settings are
            % not active
            if isequal(app.Andor19331StatusLamp.Color, [0, 1, 0])
                app.Andor19331StatusLamp.Color = [1, 1, 0];
            end
            if isequal(app.AcquisitionStatusLamp.Color, [0, 1, 0])
                app.AcquisitionStatusLamp.Color = [1, 1, 0];
            end
        end

        % Value changed function: ZeluxExposuresSpinner, 
        % ...and 1 other component
        function updateZeluxStatus(app, event)
            % Setting the status to "Yellow" to indicate the settings are
            % not active
            if isequal(app.ZeluxStatusLamp.Color, [0, 1, 0])
                app.ZeluxStatusLamp.Color = [1, 1, 0];
            end
            if isequal(app.AcquisitionStatusLamp.Color, [0, 1, 0])
                app.AcquisitionStatusLamp.Color = [1, 1, 0];
            end
        end

        % Callback function: AcquisitiontimeoutsSpinner, 
        % ...and 2 other components
        function updateAcquisitionStatus(app, event)
            % Setting the status to "Yellow" to indicate the settings are
            % not active
            if isequal(app.AcquisitionStatusLamp.Color, [0, 1, 0])
                app.AcquisitionStatusLamp.Color = [1, 1, 0];
            end
        end

        % Button pushed function: InitializeAcquisitionButton
        function initializeAcquisition(app, event)
            % Record the acquisition settings and get a list of active
            % cameras
            rows = ~(app.UITable.Data.Camera == '--inactive--');
            app.Setting.Acquisition.SequenceTable = sortrows(app.UITable.Data(rows, :), 'Order');
            app.Setting.Acquisition.NumAcquisitions = app.NumberofacquisitionsSpinner.Value;
            app.Setting.Acquisition.Timeout = app.AcquisitiontimeoutsSpinner.Value;

            if isempty(app.Setting.Acquisition.SequenceTable)
                uialert(app.UIFigure, 'No active camera selected!', 'Error')
                return
            end
            
            % Configure all active cameras
            cameras = unique(app.Setting.Acquisition.SequenceTable.Camera);
            for i = 1:length(cameras)
                camera = char(cameras(i));
                switch camera
                    case 'Andor19330'
                        if ~isequal(app.Andor19330StatusLamp.Color, [0, 1, 0])
                            configure19330(app,event)
                        end
                    case 'Andor19331'
                        if ~isequal(app.Andor19331StatusLamp.Color, [0, 1, 0])
                            configure19331(app,event)
                        end
                    case 'Zelux'
                        if ~isequal(app.ZeluxStatusLamp.Color, [0, 1, 0])
                            configureZelux(app,event)
                        end
                end
            end

            % Pre-allocate storage for image acquisition
            [app.Data, data_size] = initializeData(app.Setting);
            app.EstimatedDatasetsizeLabel.Text = sprintf('Estimated Dataset size: %g MB', data_size);
            
            % Update Live statistics
            app.Live.Current = 0;

            % Update layout content selection
            num_images = height(app.Setting.Acquisition.SequenceTable);
            app.Axes1DropDown.Items = {};
            app.Axes2DropDown.Items = {};
            for i = 1:num_images
                app.Axes1DropDown.Items{i} = ['Image_', num2str(i)];
                app.Axes2DropDown.Items{i} = ['Image_', num2str(i)];
            end
            app.Axes1DropDown.Value = app.Axes1DropDown.Items{1};
            app.Axes2DropDown.Value = app.Axes2DropDown.Items{end};
            updateAxes1Content(app,event)
            updateAxes2Content(app,event)

            % Update the acquisition status
            app.AcquisitionStatusLamp.Color = [0, 1, 0];

        end

        % Value changed function: Axes1DropDown
        function updateAxes1Content(app, event)
            app.Layout.BigAxes1.Content = app.Axes1DropDown.Value;
            
        end

        % Value changed function: Axes2DropDown
        function updateAxes2Content(app, event)
            app.Layout.BigAxes2.Content = app.Axes2DropDown.Value;
            
        end

        % Value changed function: Plot1DropDown
        function updatePlot1Content(app, event)
            value = app.Plot1DropDown.Value;
            
        end

        % Value changed function: Plot2DropDown
        function updatePlot2Content(app, event)
            value = app.Plot2DropDown.Value;
            
        end

        % Value changed function: Plot3DropDown
        function updatePlot3Content(app, event)
            value = app.Plot3DropDown.Value;
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [50 50 1800 1000];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @closeUI, true);
            app.UIFigure.Scrollable = 'on';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 1800 1000];

            % Create ImageTab
            app.ImageTab = uitab(app.TabGroup);
            app.ImageTab.Title = 'Image';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.ImageTab);
            app.GridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.GridLayout.RowHeight = {22, '3x', '1x', '1x', '1x', '1x', '3x', '1x', 22, '4x'};

            % Create BigAxes1
            app.BigAxes1 = uiaxes(app.GridLayout);
            app.BigAxes1.DataAspectRatio = [1 1 1];
            app.BigAxes1.PlotBoxAspectRatio = [1 1 1];
            app.BigAxes1.FontSize = 18;
            app.BigAxes1.Layout.Row = [2 8];
            app.BigAxes1.Layout.Column = [1 11];
            app.BigAxes1.BusyAction = 'cancel';

            % Create BigAxes2
            app.BigAxes2 = uiaxes(app.GridLayout);
            title(app.BigAxes2, ' ')
            app.BigAxes2.DataAspectRatio = [1 1 1];
            app.BigAxes2.PlotBoxAspectRatio = [1 1 1];
            app.BigAxes2.FontSize = 18;
            app.BigAxes2.Layout.Row = [2 8];
            app.BigAxes2.Layout.Column = [12 22];
            app.BigAxes2.BusyAction = 'cancel';

            % Create SmallAxes1
            app.SmallAxes1 = uiaxes(app.GridLayout);
            xlabel(app.SmallAxes1, 'X')
            ylabel(app.SmallAxes1, 'Y')
            zlabel(app.SmallAxes1, 'Z')
            app.SmallAxes1.Toolbar.Visible = 'off';
            app.SmallAxes1.Layout.Row = 10;
            app.SmallAxes1.Layout.Column = [1 8];

            % Create SmallAxes2
            app.SmallAxes2 = uiaxes(app.GridLayout);
            xlabel(app.SmallAxes2, 'X')
            ylabel(app.SmallAxes2, 'Y')
            zlabel(app.SmallAxes2, 'Z')
            app.SmallAxes2.Toolbar.Visible = 'off';
            app.SmallAxes2.Layout.Row = 10;
            app.SmallAxes2.Layout.Column = [9 16];

            % Create SmallAxes3
            app.SmallAxes3 = uiaxes(app.GridLayout);
            xlabel(app.SmallAxes3, 'X')
            ylabel(app.SmallAxes3, 'Y')
            zlabel(app.SmallAxes3, 'Z')
            app.SmallAxes3.Toolbar.Visible = 'off';
            app.SmallAxes3.Layout.Row = 10;
            app.SmallAxes3.Layout.Column = [17 24];

            % Create Axes1DropDownLabel
            app.Axes1DropDownLabel = uilabel(app.GridLayout);
            app.Axes1DropDownLabel.HorizontalAlignment = 'right';
            app.Axes1DropDownLabel.FontSize = 16;
            app.Axes1DropDownLabel.Layout.Row = 1;
            app.Axes1DropDownLabel.Layout.Column = 1;
            app.Axes1DropDownLabel.Text = 'Axes 1';

            % Create Plot3DropDown
            app.Plot3DropDown = uidropdown(app.GridLayout);
            app.Plot3DropDown.Items = {'MeanCount', 'MaxCount'};
            app.Plot3DropDown.ValueChangedFcn = createCallbackFcn(app, @updatePlot3Content, true);
            app.Plot3DropDown.FontSize = 16;
            app.Plot3DropDown.Layout.Row = 9;
            app.Plot3DropDown.Layout.Column = [18 20];
            app.Plot3DropDown.Value = 'MeanCount';

            % Create Plot2DropDown
            app.Plot2DropDown = uidropdown(app.GridLayout);
            app.Plot2DropDown.Items = {'MeanCount', 'MaxCount'};
            app.Plot2DropDown.ValueChangedFcn = createCallbackFcn(app, @updatePlot2Content, true);
            app.Plot2DropDown.FontSize = 16;
            app.Plot2DropDown.Layout.Row = 9;
            app.Plot2DropDown.Layout.Column = [10 12];
            app.Plot2DropDown.Value = 'MeanCount';

            % Create Plot1DropDown
            app.Plot1DropDown = uidropdown(app.GridLayout);
            app.Plot1DropDown.Items = {'MeanCount', 'MaxCount'};
            app.Plot1DropDown.ValueChangedFcn = createCallbackFcn(app, @updatePlot1Content, true);
            app.Plot1DropDown.FontSize = 16;
            app.Plot1DropDown.Layout.Row = 9;
            app.Plot1DropDown.Layout.Column = [2 4];
            app.Plot1DropDown.Value = 'MeanCount';

            % Create Plot1DropDownLabel
            app.Plot1DropDownLabel = uilabel(app.GridLayout);
            app.Plot1DropDownLabel.HorizontalAlignment = 'right';
            app.Plot1DropDownLabel.FontSize = 16;
            app.Plot1DropDownLabel.Layout.Row = 9;
            app.Plot1DropDownLabel.Layout.Column = 1;
            app.Plot1DropDownLabel.Text = 'Plot 1';

            % Create Axes2DropDownLabel
            app.Axes2DropDownLabel = uilabel(app.GridLayout);
            app.Axes2DropDownLabel.HorizontalAlignment = 'right';
            app.Axes2DropDownLabel.FontSize = 16;
            app.Axes2DropDownLabel.Layout.Row = 1;
            app.Axes2DropDownLabel.Layout.Column = 12;
            app.Axes2DropDownLabel.Text = 'Axes 2';

            % Create Axes2DropDown
            app.Axes2DropDown = uidropdown(app.GridLayout);
            app.Axes2DropDown.Items = {'Image_1', 'Image_2'};
            app.Axes2DropDown.ValueChangedFcn = createCallbackFcn(app, @updateAxes2Content, true);
            app.Axes2DropDown.FontSize = 16;
            app.Axes2DropDown.Layout.Row = 1;
            app.Axes2DropDown.Layout.Column = [13 15];
            app.Axes2DropDown.Value = 'Image_1';

            % Create Axes1DropDown
            app.Axes1DropDown = uidropdown(app.GridLayout);
            app.Axes1DropDown.Items = {'Image_1', 'Image_2'};
            app.Axes1DropDown.ValueChangedFcn = createCallbackFcn(app, @updateAxes1Content, true);
            app.Axes1DropDown.FontSize = 16;
            app.Axes1DropDown.Layout.Row = 1;
            app.Axes1DropDown.Layout.Column = [2 4];
            app.Axes1DropDown.Value = 'Image_1';

            % Create StopButton
            app.StopButton = uibutton(app.GridLayout, 'state');
            app.StopButton.Text = 'Stop';
            app.StopButton.BackgroundColor = [1 0.302 0.302];
            app.StopButton.FontSize = 18;
            app.StopButton.Layout.Row = 5;
            app.StopButton.Layout.Column = [23 24];

            % Create SaveButton
            app.SaveButton = uibutton(app.GridLayout, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @save, true);
            app.SaveButton.BusyAction = 'cancel';
            app.SaveButton.BackgroundColor = [0 1 1];
            app.SaveButton.FontSize = 18;
            app.SaveButton.Layout.Row = 6;
            app.SaveButton.Layout.Column = [23 24];
            app.SaveButton.Text = 'Save';

            % Create Plot2DropDownLabel
            app.Plot2DropDownLabel = uilabel(app.GridLayout);
            app.Plot2DropDownLabel.HorizontalAlignment = 'right';
            app.Plot2DropDownLabel.FontSize = 16;
            app.Plot2DropDownLabel.Layout.Row = 9;
            app.Plot2DropDownLabel.Layout.Column = 9;
            app.Plot2DropDownLabel.Text = 'Plot 2';

            % Create PauseContinueButton
            app.PauseContinueButton = uibutton(app.GridLayout, 'state');
            app.PauseContinueButton.BusyAction = 'cancel';
            app.PauseContinueButton.Text = 'Pause/Continue';
            app.PauseContinueButton.BackgroundColor = [1 1 0];
            app.PauseContinueButton.FontSize = 18;
            app.PauseContinueButton.Layout.Row = 4;
            app.PauseContinueButton.Layout.Column = [23 24];

            % Create RunButton
            app.RunButton = uibutton(app.GridLayout, 'push');
            app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @run, true);
            app.RunButton.BusyAction = 'cancel';
            app.RunButton.BackgroundColor = [0 1 0];
            app.RunButton.FontSize = 18;
            app.RunButton.Layout.Row = 3;
            app.RunButton.Layout.Column = [23 24];
            app.RunButton.Text = 'Run';

            % Create Plot3DropDownLabel
            app.Plot3DropDownLabel = uilabel(app.GridLayout);
            app.Plot3DropDownLabel.HorizontalAlignment = 'right';
            app.Plot3DropDownLabel.FontSize = 16;
            app.Plot3DropDownLabel.Layout.Row = 9;
            app.Plot3DropDownLabel.Layout.Column = 17;
            app.Plot3DropDownLabel.Text = 'Plot 3';

            % Create ElapsedTimeLabel
            app.ElapsedTimeLabel = uilabel(app.GridLayout);
            app.ElapsedTimeLabel.FontSize = 18;
            app.ElapsedTimeLabel.Layout.Row = 1;
            app.ElapsedTimeLabel.Layout.Column = [22 24];
            app.ElapsedTimeLabel.Text = 'Elapsed Time:';

            % Create SettingsTab
            app.SettingsTab = uitab(app.TabGroup);
            app.SettingsTab.Title = 'Settings';

            % Create Andor19330SettingsPanel
            app.Andor19330SettingsPanel = uipanel(app.SettingsTab);
            app.Andor19330SettingsPanel.Title = 'Andor 19330 Settings';
            app.Andor19330SettingsPanel.FontSize = 18;
            app.Andor19330SettingsPanel.Position = [34 659 373 290];

            % Create ExposuresSpinnerLabel
            app.ExposuresSpinnerLabel = uilabel(app.Andor19330SettingsPanel);
            app.ExposuresSpinnerLabel.HorizontalAlignment = 'right';
            app.ExposuresSpinnerLabel.FontSize = 18;
            app.ExposuresSpinnerLabel.Position = [64 215 107 23];
            app.ExposuresSpinnerLabel.Text = 'Exposure (s)';

            % Create Andor19330ExposuresSpinner
            app.Andor19330ExposuresSpinner = uispinner(app.Andor19330SettingsPanel);
            app.Andor19330ExposuresSpinner.Step = 0.1;
            app.Andor19330ExposuresSpinner.ValueChangedFcn = createCallbackFcn(app, @updateAndor19330Status, true);
            app.Andor19330ExposuresSpinner.FontSize = 18;
            app.Andor19330ExposuresSpinner.Position = [185 214 155 24];
            app.Andor19330ExposuresSpinner.Value = 0.2;

            % Create AcquisitionmodeDropDownLabel
            app.AcquisitionmodeDropDownLabel = uilabel(app.Andor19330SettingsPanel);
            app.AcquisitionmodeDropDownLabel.HorizontalAlignment = 'right';
            app.AcquisitionmodeDropDownLabel.FontSize = 18;
            app.AcquisitionmodeDropDownLabel.Position = [30 167 142 23];
            app.AcquisitionmodeDropDownLabel.Text = 'Acquisition mode';

            % Create Andor19330AcquisitionmodeDropDown
            app.Andor19330AcquisitionmodeDropDown = uidropdown(app.Andor19330SettingsPanel);
            app.Andor19330AcquisitionmodeDropDown.Items = {'Full frame', 'FK 2', 'FK 4', 'FK 8'};
            app.Andor19330AcquisitionmodeDropDown.ValueChangedFcn = createCallbackFcn(app, @updateAndor19330Status, true);
            app.Andor19330AcquisitionmodeDropDown.FontSize = 18;
            app.Andor19330AcquisitionmodeDropDown.Position = [185 166 155 24];
            app.Andor19330AcquisitionmodeDropDown.Value = 'Full frame';

            % Create TriggermodeDropDownLabel
            app.TriggermodeDropDownLabel = uilabel(app.Andor19330SettingsPanel);
            app.TriggermodeDropDownLabel.HorizontalAlignment = 'right';
            app.TriggermodeDropDownLabel.FontSize = 18;
            app.TriggermodeDropDownLabel.Position = [57 120 111 23];
            app.TriggermodeDropDownLabel.Text = 'Trigger mode';

            % Create Andor19330TriggermodeDropDown
            app.Andor19330TriggermodeDropDown = uidropdown(app.Andor19330SettingsPanel);
            app.Andor19330TriggermodeDropDown.Items = {'External', 'Internal'};
            app.Andor19330TriggermodeDropDown.ValueChangedFcn = createCallbackFcn(app, @updateAndor19330Status, true);
            app.Andor19330TriggermodeDropDown.FontSize = 18;
            app.Andor19330TriggermodeDropDown.Position = [185 119 155 24];
            app.Andor19330TriggermodeDropDown.Value = 'External';

            % Create ConfigureAndor19330Button
            app.ConfigureAndor19330Button = uibutton(app.Andor19330SettingsPanel, 'push');
            app.ConfigureAndor19330Button.ButtonPushedFcn = createCallbackFcn(app, @configure19330, true);
            app.ConfigureAndor19330Button.FontSize = 18;
            app.ConfigureAndor19330Button.Position = [85 63 201 30];
            app.ConfigureAndor19330Button.Text = 'Configure Andor 19330';

            % Create CloseAndor19330Button
            app.CloseAndor19330Button = uibutton(app.Andor19330SettingsPanel, 'push');
            app.CloseAndor19330Button.ButtonPushedFcn = createCallbackFcn(app, @close19330, true);
            app.CloseAndor19330Button.FontSize = 18;
            app.CloseAndor19330Button.Position = [85 17 201 30];
            app.CloseAndor19330Button.Text = 'Close Andor 19330';

            % Create Andor19330StatusLamp
            app.Andor19330StatusLamp = uilamp(app.Andor19330SettingsPanel);
            app.Andor19330StatusLamp.Position = [351 266 20 20];
            app.Andor19330StatusLamp.Color = [1 0 0];

            % Create Andor19331SettingsPanel
            app.Andor19331SettingsPanel = uipanel(app.SettingsTab);
            app.Andor19331SettingsPanel.Title = 'Andor 19331 Settings';
            app.Andor19331SettingsPanel.FontSize = 18;
            app.Andor19331SettingsPanel.Position = [34 339 373 290];

            % Create ExposuresSpinner_2Label
            app.ExposuresSpinner_2Label = uilabel(app.Andor19331SettingsPanel);
            app.ExposuresSpinner_2Label.HorizontalAlignment = 'right';
            app.ExposuresSpinner_2Label.FontSize = 18;
            app.ExposuresSpinner_2Label.Position = [64 215 107 23];
            app.ExposuresSpinner_2Label.Text = 'Exposure (s)';

            % Create Andor19331ExposuresSpinner
            app.Andor19331ExposuresSpinner = uispinner(app.Andor19331SettingsPanel);
            app.Andor19331ExposuresSpinner.Step = 0.1;
            app.Andor19331ExposuresSpinner.ValueChangedFcn = createCallbackFcn(app, @updateAndor19331Status, true);
            app.Andor19331ExposuresSpinner.FontSize = 18;
            app.Andor19331ExposuresSpinner.Position = [185 214 155 24];
            app.Andor19331ExposuresSpinner.Value = 0.2;

            % Create AcquisitionmodeDropDown_2Label
            app.AcquisitionmodeDropDown_2Label = uilabel(app.Andor19331SettingsPanel);
            app.AcquisitionmodeDropDown_2Label.HorizontalAlignment = 'right';
            app.AcquisitionmodeDropDown_2Label.FontSize = 18;
            app.AcquisitionmodeDropDown_2Label.Position = [30 167 142 23];
            app.AcquisitionmodeDropDown_2Label.Text = 'Acquisition mode';

            % Create Andor19331AcquisitionmodeDropDown
            app.Andor19331AcquisitionmodeDropDown = uidropdown(app.Andor19331SettingsPanel);
            app.Andor19331AcquisitionmodeDropDown.Items = {'Full frame', 'FK 2', 'FK 4', 'FK 8'};
            app.Andor19331AcquisitionmodeDropDown.ValueChangedFcn = createCallbackFcn(app, @updateAndor19331Status, true);
            app.Andor19331AcquisitionmodeDropDown.FontSize = 18;
            app.Andor19331AcquisitionmodeDropDown.Position = [185 166 155 24];
            app.Andor19331AcquisitionmodeDropDown.Value = 'Full frame';

            % Create TriggermodeDropDown_2Label
            app.TriggermodeDropDown_2Label = uilabel(app.Andor19331SettingsPanel);
            app.TriggermodeDropDown_2Label.HorizontalAlignment = 'right';
            app.TriggermodeDropDown_2Label.FontSize = 18;
            app.TriggermodeDropDown_2Label.Position = [57 120 111 23];
            app.TriggermodeDropDown_2Label.Text = 'Trigger mode';

            % Create Andor19331TriggermodeDropDown
            app.Andor19331TriggermodeDropDown = uidropdown(app.Andor19331SettingsPanel);
            app.Andor19331TriggermodeDropDown.Items = {'External', 'Internal'};
            app.Andor19331TriggermodeDropDown.ValueChangedFcn = createCallbackFcn(app, @updateAndor19331Status, true);
            app.Andor19331TriggermodeDropDown.FontSize = 18;
            app.Andor19331TriggermodeDropDown.Position = [185 119 155 24];
            app.Andor19331TriggermodeDropDown.Value = 'External';

            % Create ConfigureAndor19331Button
            app.ConfigureAndor19331Button = uibutton(app.Andor19331SettingsPanel, 'push');
            app.ConfigureAndor19331Button.ButtonPushedFcn = createCallbackFcn(app, @configure19331, true);
            app.ConfigureAndor19331Button.FontSize = 18;
            app.ConfigureAndor19331Button.Position = [85 62 201 30];
            app.ConfigureAndor19331Button.Text = 'Configure Andor 19331';

            % Create CloseAndor19331Button
            app.CloseAndor19331Button = uibutton(app.Andor19331SettingsPanel, 'push');
            app.CloseAndor19331Button.ButtonPushedFcn = createCallbackFcn(app, @close19331, true);
            app.CloseAndor19331Button.FontSize = 18;
            app.CloseAndor19331Button.Position = [84 17 201 30];
            app.CloseAndor19331Button.Text = 'Close Andor 19331';

            % Create Andor19331StatusLamp
            app.Andor19331StatusLamp = uilamp(app.Andor19331SettingsPanel);
            app.Andor19331StatusLamp.Position = [351 266 20 20];
            app.Andor19331StatusLamp.Color = [1 0 0];

            % Create ZeluxSettingsPanel
            app.ZeluxSettingsPanel = uipanel(app.SettingsTab);
            app.ZeluxSettingsPanel.Title = 'Zelux Settings';
            app.ZeluxSettingsPanel.FontSize = 18;
            app.ZeluxSettingsPanel.Position = [34 64 373 243];

            % Create ExposuresSpinner_3Label
            app.ExposuresSpinner_3Label = uilabel(app.ZeluxSettingsPanel);
            app.ExposuresSpinner_3Label.HorizontalAlignment = 'right';
            app.ExposuresSpinner_3Label.FontSize = 18;
            app.ExposuresSpinner_3Label.Position = [64 168 107 23];
            app.ExposuresSpinner_3Label.Text = 'Exposure (s)';

            % Create ZeluxExposuresSpinner
            app.ZeluxExposuresSpinner = uispinner(app.ZeluxSettingsPanel);
            app.ZeluxExposuresSpinner.Step = 0.1;
            app.ZeluxExposuresSpinner.ValueChangedFcn = createCallbackFcn(app, @updateZeluxStatus, true);
            app.ZeluxExposuresSpinner.FontSize = 18;
            app.ZeluxExposuresSpinner.Position = [185 167 155 24];
            app.ZeluxExposuresSpinner.Value = 1e-06;

            % Create TriggermodeDropDown_3Label
            app.TriggermodeDropDown_3Label = uilabel(app.ZeluxSettingsPanel);
            app.TriggermodeDropDown_3Label.HorizontalAlignment = 'right';
            app.TriggermodeDropDown_3Label.FontSize = 18;
            app.TriggermodeDropDown_3Label.Position = [55 122 111 23];
            app.TriggermodeDropDown_3Label.Text = 'Trigger mode';

            % Create ZeluxTriggermodeDropDown
            app.ZeluxTriggermodeDropDown = uidropdown(app.ZeluxSettingsPanel);
            app.ZeluxTriggermodeDropDown.Items = {'External', 'Internal'};
            app.ZeluxTriggermodeDropDown.ValueChangedFcn = createCallbackFcn(app, @updateZeluxStatus, true);
            app.ZeluxTriggermodeDropDown.FontSize = 18;
            app.ZeluxTriggermodeDropDown.Position = [183 121 155 24];
            app.ZeluxTriggermodeDropDown.Value = 'External';

            % Create ConfigureZeluxButton
            app.ConfigureZeluxButton = uibutton(app.ZeluxSettingsPanel, 'push');
            app.ConfigureZeluxButton.ButtonPushedFcn = createCallbackFcn(app, @configureZelux, true);
            app.ConfigureZeluxButton.FontSize = 18;
            app.ConfigureZeluxButton.Position = [84 68 201 30];
            app.ConfigureZeluxButton.Text = 'Configure Zelux';

            % Create CloseZeluxButton
            app.CloseZeluxButton = uibutton(app.ZeluxSettingsPanel, 'push');
            app.CloseZeluxButton.ButtonPushedFcn = createCallbackFcn(app, @closeZeluxCallback, true);
            app.CloseZeluxButton.FontSize = 18;
            app.CloseZeluxButton.Position = [84 23 201 30];
            app.CloseZeluxButton.Text = 'Close Zelux';

            % Create ZeluxStatusLamp
            app.ZeluxStatusLamp = uilamp(app.ZeluxSettingsPanel);
            app.ZeluxStatusLamp.Position = [351 219 20 20];
            app.ZeluxStatusLamp.Color = [1 0 0];

            % Create AcquisitionSettingsPanel
            app.AcquisitionSettingsPanel = uipanel(app.SettingsTab);
            app.AcquisitionSettingsPanel.Title = 'Acquisition Settings';
            app.AcquisitionSettingsPanel.FontSize = 18;
            app.AcquisitionSettingsPanel.Position = [435 384 798 565];

            % Create EstimatedDatasetsizeLabel
            app.EstimatedDatasetsizeLabel = uilabel(app.AcquisitionSettingsPanel);
            app.EstimatedDatasetsizeLabel.FontSize = 22;
            app.EstimatedDatasetsizeLabel.FontColor = [0 0 1];
            app.EstimatedDatasetsizeLabel.Position = [404 118 365 29];
            app.EstimatedDatasetsizeLabel.Text = 'Estimated Dataset size: ';

            % Create NumberofacquisitionsSpinnerLabel
            app.NumberofacquisitionsSpinnerLabel = uilabel(app.AcquisitionSettingsPanel);
            app.NumberofacquisitionsSpinnerLabel.HorizontalAlignment = 'right';
            app.NumberofacquisitionsSpinnerLabel.FontSize = 18;
            app.NumberofacquisitionsSpinnerLabel.Position = [17 142 188 23];
            app.NumberofacquisitionsSpinnerLabel.Text = 'Number of acquisitions';

            % Create NumberofacquisitionsSpinner
            app.NumberofacquisitionsSpinner = uispinner(app.AcquisitionSettingsPanel);
            app.NumberofacquisitionsSpinner.ValueDisplayFormat = '%d';
            app.NumberofacquisitionsSpinner.ValueChangedFcn = createCallbackFcn(app, @updateAcquisitionStatus, true);
            app.NumberofacquisitionsSpinner.FontSize = 18;
            app.NumberofacquisitionsSpinner.Position = [219 141 155 24];
            app.NumberofacquisitionsSpinner.Value = 20;

            % Create AcquisitiontimeoutsSpinnerLabel
            app.AcquisitiontimeoutsSpinnerLabel = uilabel(app.AcquisitionSettingsPanel);
            app.AcquisitiontimeoutsSpinnerLabel.HorizontalAlignment = 'right';
            app.AcquisitiontimeoutsSpinnerLabel.FontSize = 18;
            app.AcquisitiontimeoutsSpinnerLabel.Position = [17 93 187 23];
            app.AcquisitiontimeoutsSpinnerLabel.Text = 'Acquisition time out (s)';

            % Create AcquisitiontimeoutsSpinner
            app.AcquisitiontimeoutsSpinner = uispinner(app.AcquisitionSettingsPanel);
            app.AcquisitiontimeoutsSpinner.ValueChangedFcn = createCallbackFcn(app, @updateAcquisitionStatus, true);
            app.AcquisitiontimeoutsSpinner.FontSize = 18;
            app.AcquisitiontimeoutsSpinner.Position = [219 92 155 24];
            app.AcquisitiontimeoutsSpinner.Value = 1000;

            % Create InitializeAcquisitionButton
            app.InitializeAcquisitionButton = uibutton(app.AcquisitionSettingsPanel, 'push');
            app.InitializeAcquisitionButton.ButtonPushedFcn = createCallbackFcn(app, @initializeAcquisition, true);
            app.InitializeAcquisitionButton.FontSize = 18;
            app.InitializeAcquisitionButton.Position = [314 33 171 30];
            app.InitializeAcquisitionButton.Text = 'Initialize Acquisition';

            % Create AcquisitionStatusLamp
            app.AcquisitionStatusLamp = uilamp(app.AcquisitionSettingsPanel);
            app.AcquisitionStatusLamp.Position = [776 542 20 20];
            app.AcquisitionStatusLamp.Color = [1 0 0];

            % Create UITable
            app.UITable = uitable(app.AcquisitionSettingsPanel);
            app.UITable.ColumnName = {'Order'; 'Camera'; 'Label'; 'Note'};
            app.UITable.ColumnWidth = {80, 150, 150, 'auto'};
            app.UITable.RowName = {};
            app.UITable.ColumnSortable = [true true false false];
            app.UITable.ColumnEditable = true;
            app.UITable.DisplayDataChangedFcn = createCallbackFcn(app, @updateAcquisitionStatus, true);
            app.UITable.FontSize = 18;
            app.UITable.Position = [17 192 765 332];

            % Create StatusLabel
            app.StatusLabel = uilabel(app.UIFigure);
            app.StatusLabel.HorizontalAlignment = 'right';
            app.StatusLabel.FontSize = 18;
            app.StatusLabel.Position = [1597 977 139 24];
            app.StatusLabel.Text = 'Status';

            % Create StatusLamp
            app.StatusLamp = uilamp(app.UIFigure);
            app.StatusLamp.Position = [1766 977 24 24];
            app.StatusLamp.Color = [1 0 0];

            % Create RunNumLabel
            app.RunNumLabel = uilabel(app.UIFigure);
            app.RunNumLabel.FontSize = 18;
            app.RunNumLabel.Position = [1363 977 214 24];
            app.RunNumLabel.Text = 'Run Num: ';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ImageAcquisition_exported

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.UIFigure)

                % Execute the startup function
                runStartupFcn(app, @startApp)
            else

                % Focus the running singleton app
                figure(runningApp.UIFigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end