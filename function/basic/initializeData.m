function [Data, dsize] = initializeData(Setting)
    arguments
        Setting (1, 1) struct
    end
    
    Data = struct();
    Data.SequenceTable = Setting.Acquisition.SequenceTable;

    cameras = unique(Setting.Acquisition.SequenceTable.Camera);
    for i = 1:length(cameras)
        camera = char(cameras(i));
        Data.(camera) = struct();
        Data.(camera).Config = Setting.(camera);
        Data.(camera).Config.Serial = camera;
        Data.(camera).Config.MaxImage = Setting.Acquisition.NumAcquisitions;
        Data.(camera).Config.Acquisition = struct();
        switch camera
            case {'Andor19330', 'Andor19331'}
                setCurrentAndor(camera)
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
    
    num_images = height(Setting.Acquisition.SequenceTable);
    for i = 1:num_images
        camera = char(Setting.Acquisition.SequenceTable.Camera(i));
        label = Setting.Acquisition.SequenceTable.Label{i};
        note = Setting.Acquisition.SequenceTable.Note{i};
        
        % Initialize Data storage
        Data.(camera).(label) = zeros(Data.(camera).Config.XPixels, ...
            Data.(camera).Config.YPixels, Data.(camera).Config.MaxImage, 'uint16');
        Data.(camera).Config.Acquisition.(label) = note;
    end
    
    for i = 1:length(cameras)
        fprintf('Config for camera %d: \n', i)
        camera = char(cameras(i));
        disp(Data.(camera).Config) 
    end

    dsize = whos('Data').bytes*9.53674e-7;
    fprintf('Data storage initialized for %d cameras, total memory is %g MB\n', ...
        length(cameras), dsize)
    
end