function [Data, dsize] = initializeData(Setting, CameraHandle)
    arguments
        Setting (1, 1) struct
        CameraHandle (1, 1) struct = struct()
    end
    
    Data = struct();
    Data.SequenceTable = Setting.Acquisition.SequenceTable;
    
    % Initialize Config for each active camera
    cameras = unique(Setting.Acquisition.SequenceTable.Camera);
    for i = 1:length(cameras)
        camera = char(cameras(i));
        Data.(camera) = struct();
        Data.(camera).Config = Setting.(camera);
        Data.(camera).Config.Serial = camera;
        Data.(camera).Config.MaxImage = Setting.Acquisition.NumAcquisitions;
        Data.(camera).Config.Note = struct();
        switch camera
            case {'Andor19330', 'Andor19331'}
                setCurrentAndor(camera, CameraHandle)
                [ret, Data.(camera).Config.YPixels, Data.(camera).Config.XPixels] = GetDetector();
                CheckWarning(ret)
                if Data.(camera).Config.NumFrames == 1
                    [ret, Data.(camera).Config.Exposure, Data.(camera).Config.Accumulate] = GetAcquisitionTimings();
                    CheckWarning(ret)
                end
            case 'Zelux'
                Data.(camera).Config.XPixels = 1440;
                Data.(camera).Config.YPixels = 1080;
        end
    end
    
    % Initialize storage for each shot in sequence
    num_images = height(Setting.Acquisition.SequenceTable);
    for i = 1:num_images
        camera = char(Setting.Acquisition.SequenceTable.Camera(i));
        label = Setting.Acquisition.SequenceTable.Label{i};
        note = Setting.Acquisition.SequenceTable.Note{i};
        
        % Initialize Data storage
        Data.(camera).(label) = zeros(Data.(camera).Config.XPixels, ...
            Data.(camera).Config.YPixels, Data.(camera).Config.MaxImage, 'uint16');
        Data.(camera).Config.Note.(label) = note;
    end
    
    % Print out camera config and memory usage
    for i = 1:length(cameras)
        fprintf('Config for camera %d: \n', i)
        camera = char(cameras(i));
        disp(Data.(camera).Config) 
    end
   
    dsize = whos('Data').bytes*9.53674e-7;
    fprintf('Data storage initialized for %d cameras, total memory is %g MB\n\n', ...
        length(cameras), dsize)    
end