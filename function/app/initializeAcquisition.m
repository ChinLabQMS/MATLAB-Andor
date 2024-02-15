function initializeAcquisition(app)

    % Check if there is stored data
    if isfield(app.Data, 'Image')
        answer = questdlg('There is existing Data in storage. Would you like to save it?', ...
            'Image Aquisition App', ...
            'Yes', 'Yes', 'No');
        switch answer
            case 'Yes'
                saveData(app.Data, app.Live)
            case 'No'
        end
    end

    % Initialize camera and Data Config
    camera = app.SelectcameraButtonGroup.SelectedObject.Text;
    external_trigger = strcmp(app.TriggermodeDropDown.Value, 'External');
    switch camera
        case {'Andor 19330', 'Andor 19331'}
            serial = str2double(camera(7:end));
            initializeAndor()
            setCurrentAndor(serial)
            switch app.AcquisitionmodeDropDown.Value
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
                "exposure",app.ExposuresSpinner.Value, ...
                "external_trigger",external_trigger)
            app.Data.Config = getAcquisitionConfig("num_frames",num_frames);                
        case 'Zelux'
            app.Data.Config = struct(...
                'Exposure', app.ExposuresSpinner.Value, ...
                'XPixels', 1440, ...
                'YPixels', 1080);
            if ~isempty(app.Handle)
                closeZelux(app.Handle{:})
            end
            [tlCameraSDK, tlCamera] = initializeZelux('exposure',app.ExposuresSpinner.Value, ...
                'external_trigger',external_trigger);
            app.Handle = {tlCameraSDK, tlCamera};
    end
    app.Data.Config.MaxImage = app.DatasetsizeSpinner.Value;
    app.Data.Config.External = external_trigger;
    app.Data.Config.Serial = camera;
    app.Data.Config.Background = app.BackgroundshotCheckBox.Value;
    fprintf('Camera Config for acquisition:\n')
    disp(app.Data.Config)
    
    % Initialize Data
    app.Data.Image = zeros(app.Data.Config.XPixels, app.Data.Config.YPixels, app.Data.Config.MaxImage);
    if app.Data.Config.Background
        app.Data.Background = zeros(app.Data.Config.XPixels, app.Data.Config.YPixels, app.Data.Config.MaxImage);
    end
    
    % Initialize statistics for live updates
    app.Live.Current = 0;
    app.Live.MeanCount = nan(1, app.Data.Config.MaxImage);

    app.StatusLamp.Color = [1, 1, 0];

end