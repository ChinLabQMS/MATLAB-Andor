function [AllData, AllLive] = initializeData(Setting)
    arguments
        Setting (1, 1) struct
    end

    num_cameras = length(Setting.ActiveCameras);

    AllData = cell(1, num_cameras);
    AllLive = cell(1, num_cameras);

    for i = 1:num_cameras
        camera = Setting.ActiveCameras{i};
        
        Data = struct();
        Live = struct();

        % Initialize Data Configuration
        Data.Config = Setting.(camera);
        Data.Config.Serial = camera;
        Data.Config.MaxImage = Setting.NumAcquisitions;

        switch camera
            case {'Andor19330', 'Andor19331'}
                setCurrentAndor(camera)    
                [ret, Data.Config.YPixels, Data.Config.XPixels] = GetDetector();
                CheckWarning(ret)
                if Data.Config.NumFrames == 1
                    [ret, Data.Config.Exposure, Data.Config.Accumulate] = GetAcquisitionTimings();
                    CheckWarning(ret)
                end
            case 'Zelux'
                Data.Config.XPixels = 1440;
                Data.Config.YPixels = 1080;            
        end
        
        % Initialize Data storage
        num_images = length(Data.Config.Acquisition);
        for j = 1:num_images
            field = Data.Config.Acquisition{j};
            Data.(field) = zeros(Data.Config.XPixels, Data.Config.YPixels, Data.Config.MaxImage);
        end

        AllData{i} = Data;
        AllLive{i} = Live;
    end
    
    fprintf('Acquisition initialized for %d cameras\n', num_cameras)
    for i = 1:num_cameras
        
    end

    % dt = whos('VARIABLE_YOU_CARE_ABOUT'); 
    % MB=dt.bytes*9.53674e-7; 
end