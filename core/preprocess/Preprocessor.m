classdef Preprocessor < BaseProcessor
    %PREPROCESSOR Preprocess raw images for further analysis

    properties (SetAccess = {?BaseObject})        
        BackgroundFilePath = 'calibration/BkgStat_20241025.mat'
    end

    properties (Constant)
        Process_Verbose = false
        Process_CameraList = ["Andor19330", "Andor19331"]
        BackgroundSubtraction_VarName = "SmoothMean"
        OutlierRemoval_NumMaxPixels = 50
        OutlierRemoval_NumMinPixels = 0
        OutlierRemoval_DiffThres = 40
        OutlierRemoval_Warning = true
        OffsetCorrection_RegionWidth = 100
        OffsetCorrection_Warning = true
        OffsetCorrection_WarnOffsetThres = 10
        OffsetCorrection_WarnVarThres = 40
    end

    properties (SetAccess = protected)
        Background
    end

    methods
        function obj = Preprocessor(varargin)
            obj@BaseProcessor(varargin{:})
        end

        function [signal, leakage] = process(obj, raw, info, options)
            arguments
                obj
                raw
                info.camera
                info.label
                info.config
                options.verbose = Preprocessor.Process_Verbose
                options.camera_list = Preprocessor.Process_CameraList
            end
            timer = tic;
            assert(all(isfield(info, ["camera", "label", "config"])))
            if ~ismember(info.camera, options.camera_list)
                signal = raw;
                leakage = zeros(size(signal));
                return
            end
            signal = subtractBackground(obj, raw, info);
            signal = removeOutlier(obj, signal, info);
            [signal, leakage] = correctOffset(obj, signal, info);
            if options.verbose
                obj.info("[%s %s] Preprocessing completed in %.3f s.", info.camera, info.label, toc(timer))
            end
        end

        function [Signal, Leakage] = processSingleData(obj, Data, varargin)
            Signal = Data;
            Leakage = Data;
            for label = string(fields(Data.Config.AcquisitionNote)')
                [Signal.(label), Leakage.(label)] = obj.process( ...
                    Data.(label), 'camera', Data.Config.CameraName, 'label', label, 'config', Data.Config, ...
                    varargin{:});
            end
            obj.info("Data taken by camera %s is processed.", Data.Config.CameraName)
        end

        function [Signal, Leakage] = processData(obj, Data, varargin)
            if isfield(Data, "Config")
                [Signal, Leakage] = processSingleData(obj, Data, varargin{:});
                return
            end
            Signal = Data;
            Leakage = Data;
            for camera = string(fields(Data))'
                if camera == "AcquisitionConfig"
                    continue
                end
                [Signal.(camera), Leakage.(camera)] = obj.processSingleData(Data.(camera), varargin{:});
            end
        end
    end

    methods (Access = protected, Hidden)
        % Override default init in BaseProcessor
        function init(obj)
            obj.Background = load(obj.BackgroundFilePath);
            obj.info("Background file loaded from '%s'.", obj.BackgroundFilePath)
        end

        function signal = subtractBackground(obj, raw, info)
            assert(all(isfield(info, "camera")))
            signal = double(raw);
            signal = signal - obj.Background.(parseConfig(info.config)).(info.camera).(Preprocessor.BackgroundSubtraction_VarName);
        end
        
        function signal = removeOutlier(obj, raw, info)
            assert(all(isfield(info, ["camera", "label"])))
            signal = raw;
            num_acq = size(signal, 3);
            [max_val, max_idx] = maxk(raw(:), (Preprocessor.OutlierRemoval_NumMaxPixels + 1) * num_acq);
            [min_val, min_idx] = mink(raw(:), (Preprocessor.OutlierRemoval_NumMinPixels + 1) * num_acq);
            diff1 = (-diff(max_val)) > Preprocessor.OutlierRemoval_DiffThres;
            diff2 = diff(min_val) > Preprocessor.OutlierRemoval_DiffThres;
            if any(diff1)
                index = find(diff1, 1, 'last');
                signal(max_idx(1:index)) = 0;
                obj.warn("[%s %s] [%d] outliers detected, max = %g, min = %g.", ...
                         info.camera, info.label, index, max_val(1), max_val(index))
            end
            if any(diff2)
                index = find(diff2, 1, 'last');
                signal(min_idx(1:index)) = 0;
                obj.warn("[%s %s] [%d] outliers detected, max = %g, min = %g.", ...
                         info.camera, info.label, index, min_val(index), min_val(1))
            end
        end
        
        function [signal, leakage, variance] = correctOffset(obj, raw, info)
            assert(all(isfield(info, ["camera", "label", "config"])))
            [leakage, variance] = cancelOffset(raw, ...
                getNumFrames(info.config),  Preprocessor.OffsetCorrection_RegionWidth); 
            signal = raw - leakage;
            if Preprocessor.OffsetCorrection_Warning
                if any(abs(leakage) > Preprocessor.OffsetCorrection_WarnOffsetThres)
                    obj.warn("[%s %s] Noticeable background offset, max = %4.2f, min = %4.2f.", ...
                             info.camera, info.label, max(leakage(:)),min(leakage(:)))
                end
                if variance > Preprocessor.OffsetCorrection_WarnVarThres
                    obj.warn("[%s %s] Noticeable background variance, max = %4.2f, min = %4.2f.", ...
                             info.camera, info.label, max(variance(:)), min(variance(:)))
                end
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

function [offset, variance, residuals] = cancelOffset(signal, num_frames, region_width)
    arguments
        signal
        num_frames (1,1) double = 1
        region_width (1,1) double = 100
    end
    signal = mean(signal, 3);
    [x_pixels, y_pixels] = size(signal);
    x_size = x_pixels / num_frames;
    if y_pixels < 2*region_width + 200
        error('Not enough edge space to calibrate background offset!')
    end
    offset = zeros(x_pixels, y_pixels);
    y_range1 = 1:region_width;
    y_range2 = y_pixels + (1-region_width:0);
    residuals = zeros(x_pixels, 2*region_width);
    for i = 1:num_frames
        x_range = (i-1)*x_size + (1:x_size);
        bg_box1 = signal(x_range, y_range1);
        bg_box2 = signal(x_range, y_range2);
        [XOut1, YOut1, ZOut1] = prepareSurfaceData(x_range, y_range1', bg_box1');
        [XOut2, YOut2, ZOut2] = prepareSurfaceData(x_range, y_range2', bg_box2');
        XYFit = fit([[XOut1; XOut2], [YOut1; YOut2]], [ZOut1; ZOut2], 'poly11');

        % Background offset canceling with fitted plane
        offset(x_range,:) = XYFit.p00 + XYFit.p10*x_range' + XYFit.p01*(1:y_pixels);

        res1 = bg_box1 - offset(x_range, y_range1);
        res2 = bg_box2 - offset(x_range, y_range2);
        res = [res1, res2];    
        residuals(x_range, :) = res;
    end
    variance = var(residuals(:));
end
