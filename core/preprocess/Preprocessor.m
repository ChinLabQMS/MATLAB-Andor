classdef Preprocessor < BaseProcessor
    %PREPROCESSOR Preprocess raw images for further analysis

    properties (SetAccess = {?BaseObject})
        BackgroundFilePath = 'calibration/BkgStat_20241025.mat'
        BackgroundLeakageFilePath = 'calibration/BkgLeakage.mat'
    end

    properties (Constant)
        Process_Verbose = false
        Process_CameraList = ["Andor19330", "Andor19331"]
        Process_FastMode = false
        BackgroundSubtraction_VarName = "SmoothMean"
        OutlierRemoval_NumMaxPixels = 50
        OutlierRemoval_NumMinPixels = 0
        OutlierRemoval_DiffThres = 100
        OutlierRemoval_Warning = true
        OffsetCorrection_RegionWidth = 100
        OffsetCorrection_Warning = true
        OffsetCorrection_WarnOffsetThres = 10
        OffsetCorrection_WarnVarThres = 40
        OffsetCorrectionFast_OutputDiagnostic = false
    end

    properties (SetAccess = protected)
        Background
        Leakage
    end

    methods
        function set.BackgroundFilePath(obj, path)
            obj.loadBackgroundFile(path)
            obj.BackgroundFilePath = path;
        end

        function set.BackgroundLeakageFilePath(obj, path)
            obj.loadBackgroundLeakageFile(path)
            obj.BackgroundLeakageFilePath = path;
        end
        
        % Main entry in the app interface
        % Process with fast mode off to record an offset, which will be
        % used if fast mode is turned on
        function [signal, leakage, noise] = process(obj, raw, varargin)
            if isnumeric(raw)
                [signal, leakage, noise] = obj.processSingleLabel(raw, varargin{:});
            elseif isfield(raw, 'Config')
                [signal, leakage, noise] = obj.processSingleData(raw, varargin{:});
            elseif isfield(raw, 'AcquisitionConfig')
                [signal, leakage, noise] = obj.processData(raw, varargin{:});
            else
                obj.error("Unreconginized input format.")
            end
        end

        function updateLeakage(obj, Data, varargin)
            obj.process(Data, varargin{:}, 'fast_mode', 0)
        end

        function saveLeakage(obj, filename, most_recent_filename)
            arguments
                obj
                filename = sprintf("calibration/BkgLeakage_%s", datetime("now", "Format","uuuuMMdd"))
                most_recent_filename = "calibration/BkgLeakage.mat"
            end
            if filename.endsWith('.mat')
                filename = filename.extractBefore('.mat');
            end
            if isfile(filename + ".mat")
                filename = filename + sprintf("_%s", datetime("now", "Format", "HHmmss"));
            end
            leakage = obj.Leakage;
            save(filename, "-struct", "leakage")
            save(most_recent_filename, "-struct", "leakage")
            obj.info("Background leakage data saved as '%s' and '%s'.", filename, most_recent_filename)
        end
    end

    methods (Access = protected)
        % Process images with single label
        function [signal, leakage, noise] = processSingleLabel(obj, raw, info, opt, opt1, opt2, opt3, opt4)
            arguments
                obj
                raw
                info.camera = "Andor19330"
                info.label = "Image"
                info.config = AndorCameraConfig()
                opt.verbose = obj.Process_Verbose
                opt.camera_list = obj.Process_CameraList
                opt.fast_mode = obj.Process_FastMode
                opt1.var_name = obj.BackgroundSubtraction_VarName
                opt2.num_pixels_max = obj.OutlierRemoval_NumMaxPixels
                opt2.num_pixels_min = obj.OutlierRemoval_NumMinPixels
                opt2.diff_thres = obj.OutlierRemoval_DiffThres
                opt3.region_width = obj.OffsetCorrection_RegionWidth
                opt3.warning = obj.OffsetCorrection_Warning
                opt3.warn_offset_thres = obj.OffsetCorrection_WarnOffsetThres
                opt3.warn_var_thres = obj.OffsetCorrection_WarnVarThres
                opt4.output_diagnostic = obj.OffsetCorrectionFast_OutputDiagnostic
            end
            timer = tic;
            if ~ismember(info.camera, opt.camera_list)
                signal = double(raw);
                leakage = zeros(size(signal));
                noise = [];
                return
            end
            args1 = namedargs2cell(opt1);
            signal = subtractBackground(obj, raw, info, args1{:});
            if ~opt.fast_mode
                args2 = namedargs2cell(opt2);
                args3 = namedargs2cell(opt3);
                signal = removeOutlier(obj, signal, info, args2{:});
                [signal, leakage, ~, noise] = correctOffset(obj, signal, info, args3{:});
                obj.Leakage.(info.camera).(info.label) = leakage;
            else
                args4 = namedargs2cell(opt4);
                [signal, leakage, ~, noise] = correctOffsetFast(obj, signal, info, args4{:}, ...
                    'region_width', opt3.region_width);
            end
            if opt.verbose
                obj.info("[%s %s] Preprocessing completed in %.3f s.", info.camera, info.label, toc(timer))
            end
        end
        
        % Process images coming from a single camera but may be with
        % multiple labeled fields
        function [Signal, Leakage, Noise] = processSingleData(obj, Data, varargin)
            for label = string(fields(Data))'
                if label == "Config"
                    Signal.Config = Data.Config;
                    Leakage.Config = Data.Config;
                    Noise.Config = Data.Config;
                    continue
                end
                info = {'camera', Data.Config.CameraName, 'label', label, 'config', Data.Config};
                [Signal.(label), Leakage.(label), Noise.(label)] = obj.process(Data.(label), info{:}, varargin{:});
            end
        end
        
        % Process entire dataset than includes all cameras, record the
        % leakage into memory
        function [Signal, Leakage, Noise] = processData(obj, Data, varargin)
            Signal = Data;
            Leakage = Data;
            Noise = Data;
            active_cameras = SequenceRegistry.getActiveCameras(Data.AcquisitionConfig.SequenceTable);
            for camera = active_cameras
                [Signal.(camera), Leakage.(camera), Noise.(camera)] = obj.processSingleData(Data.(camera), varargin{:});
            end
            obj.info("Dataset is pre-processed.")
        end
    end

    methods (Access = protected, Sealed, Hidden)
        % Load background file
        function loadBackgroundFile(obj, path)
            obj.checkFilePath(path)
            obj.Background = load(path);
            obj.info("Background file loaded from '%s'.", path)
        end
        
        % Load background leakage file
        function loadBackgroundLeakageFile(obj, path)
            obj.checkFilePath(path)
            obj.Leakage = load(path);
            obj.info("Background leakage file loaded from '%s'.", path)
        end
        
        % Subtract loaded background from raw images, convert to double
        function signal = subtractBackground(obj, raw, info, opt1)
            arguments
                obj
                raw
                info
                opt1.var_name
            end
            assert(all(isfield(info, ["camera", "config"])))
            signal = double(raw);
            signal = signal - obj.Background.(parseConfig(info.config)).(info.camera).(opt1.var_name);
        end
        
        % Remove outliers in the signal
        function signal = removeOutlier(obj, raw, info, opt2)
            arguments
                obj
                raw
                info
                opt2.num_pixels_max
                opt2.num_pixels_min
                opt2.diff_thres
            end
            assert(all(isfield(info, ["camera", "label"])))
            signal = raw;
            num_acq = size(signal, 3);
            [max_val, max_idx] = maxk(raw(:), (opt2.num_pixels_max + 1) * num_acq);
            [min_val, min_idx] = mink(raw(:), (opt2.num_pixels_min + 1) * num_acq);
            diff1 = (-diff(max_val)) > opt2.diff_thres;
            diff2 = diff(min_val) > opt2.diff_thres;
            if any(diff1)
                index = find(diff1, 1, 'last');
                signal(max_idx(1:index)) = 0;
                obj.warn("[%s %s] [%d] outliers detected, max = %g, min = %g, next = %g.", ...
                         info.camera, info.label, index, max_val(1), max_val(index), max_val(index + 1))
            end
            if any(diff2)
                index = find(diff2, 1, 'last');
                signal(min_idx(1:index)) = 0;
                obj.warn("[%s %s] [%d] outliers detected, min = %g, max = %g, next = %g.", ...
                         info.camera, info.label, index, min_val(1), min_val(index), min_val(index + 1))
            end
        end
        
        % Fit a plane on the background pixels to remove the offsets
        function [signal, leakage, variance, noise] = correctOffset(obj, raw, info, opt3)
            arguments
                obj
                raw
                info
                opt3.region_width
                opt3.warning
                opt3.warn_offset_thres
                opt3.warn_var_thres
            end
            assert(all(isfield(info, ["camera", "label", "config"])))
            [leakage, variance, noise] = cancelOffset(raw, info.config.NumSubFrames, opt3.region_width, 0); 
            signal = raw - leakage;
            if opt3.warning
                if any(abs(leakage) > opt3.warn_offset_thres)
                    obj.warn("[%s %s] Noticeable background offset, max = %4.2f, min = %4.2f.", ...
                             info.camera, info.label, max(leakage(:)),min(leakage(:)))
                end
                if variance > opt3.warn_var_thres
                    obj.warn("[%s %s] Noticeable background variance, max = %4.2f, min = %4.2f.", ...
                             info.camera, info.label, max(variance(:)), min(variance(:)))
                end
            end
        end
        
        % Bypass the fitting plane to get an offset with a pre-loaded data
        function [signal, leakage, variance, noise] = correctOffsetFast(obj, raw, info, opt4)
            arguments
                obj
                raw
                info
                opt4.region_width
                opt4.output_diagnostic
            end
            try
                signal = raw - obj.Leakage.(info.camera).(info.label);
            catch
                signal = raw;
                obj.warn("Background offset (leakage) is not fully calibrated.")
            end
            if opt4.output_diagnostic
                [leakage, variance, noise] = cancelOffset(signal, info.Config.NumSubFrames, opt4.region_width, 1);
            else
                leakage = [];
                variance = [];
                noise = [];
            end
        end
    end

end

%% Utilities functions

function str = parseConfig(config)
    if config.Cropped
        str1 = "Cropped_";
    else
        str1 = "Full_";
    end
    switch config.HSSpeed
        case 0
            str2 = "5MHz";
        case 1
            str2 = "3MHz";
        case 2
            str2 = "1MHz";
    end
    str = str1 + str2;
end

function [offset, variance, residuals] = cancelOffset(signal, num_frames, region_width, bypass)
    [x_pixels, y_pixels, num_acq] = size(signal, [1, 2, 3]);
    signal_mean = mean(signal, 3);
    x_size = x_pixels / num_frames;
    if y_pixels < 2*region_width + 200
        error('Not enough edge space to calibrate background offset!')
    end
    offset = zeros(x_pixels, y_pixels);
    y_range1 = 1:region_width;
    y_range2 = y_pixels + (1-region_width:0);
    residuals = zeros(x_pixels, 2*region_width, num_acq);
    for i = 1:num_frames
        x_range = (i-1)*x_size + (1:x_size);
        bg_box1 = signal_mean(x_range, y_range1);
        bg_box2 = signal_mean(x_range, y_range2);
        % Whether to bypass the linear plane fit
        if ~bypass
            [XOut1, YOut1, ZOut1] = prepareSurfaceData(x_range, y_range1', bg_box1');
            [XOut2, YOut2, ZOut2] = prepareSurfaceData(x_range, y_range2', bg_box2');
            XYFit = fit([[XOut1; XOut2], [YOut1; YOut2]], [ZOut1; ZOut2], 'poly11');
            % Background offset canceling with fitted plane
            offset(x_range,:) = XYFit.p00 + XYFit.p10*x_range' + XYFit.p01*(1:y_pixels);
        else
            offset(x_range,:) = 0;
        end
        res1 = signal(x_range, y_range1, :) - offset(x_range, y_range1);
        res2 = signal(x_range, y_range2, :) - offset(x_range, y_range2);
        res = [res1, res2];
        residuals(x_range, :, :) = res;
    end
    variance = var(residuals(:));
end
