function [Data, Live, dsize] = initializeData(Setting, CameraHandle)
    arguments
        Setting (1, 1) struct
        CameraHandle (1, 1) struct = struct()
    end
    
    tic
    
    Data = struct('SequenceTable',Setting.Acquisition.SequenceTable);
    Live = struct('Current',0, ...
                  'SequenceTable',Setting.Acquisition.SequenceTable);
    
    % Load saved calibration file
    StatBackground = load(fullfile("calibration/",Setting.Analysis.BackgroundFile));

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
                else
                    [ret, Data.(camera).Config.Exposure] = GetFKExposureTime();
                    CheckWarning(ret)
                end
            case 'Zelux'
                Data.(camera).Config.XPixels = 1440;
                Data.(camera).Config.YPixels = 1080;
                Live.ZeluxState = 'active';
        end
    end
    
    % Initialize storage for each shot in sequence
    num_images = height(Setting.Acquisition.SequenceTable);
    Live.Background = cell(1, num_images);
    for i = 1:num_images
        camera = char(Setting.Acquisition.SequenceTable.Camera(i));
        label = Setting.Acquisition.SequenceTable.Label{i};
        note = Setting.Acquisition.SequenceTable.Note{i};
        
        % Initialize Data storage
        Data.(camera).(label) = zeros(Data.(camera).Config.XPixels, ...
            Data.(camera).Config.YPixels, Data.(camera).Config.MaxImage, 'uint16');
        Data.(camera).Config.Note.(label) = note;
        
        % Initialize Background offset
        if isfield(StatBackground, camera)
            Live.Background{i} = StatBackground.(camera).SmoothMean;
        else
            Live.Background{i} = 0;
        end
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
    toc
end