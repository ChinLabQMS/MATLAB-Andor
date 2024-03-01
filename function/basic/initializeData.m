function [AllData, dsize] = initializeData(Setting)
    arguments
        Setting (1, 1) struct
    end
    
    num_cameras = length(Setting.ActiveCameras);
    AllData = cell(1, num_cameras);
    
    for i = 1:num_cameras
        camera = Setting.ActiveCameras{i};        
        Data = struct();

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
            Data.(field) = zeros(Data.Config.XPixels, Data.Config.YPixels, Data.Config.MaxImage, 'uint16');
        end
        AllData{i} = Data;
    end
    
    dsize = whos('AllData').bytes*9.53674e-7;
    fprintf('Data storage initialized for %d cameras, total memory is %g MB\n', num_cameras, dsize)
    for i = 1:num_cameras
       disp(Data{i}.Config) 
    end
    
end