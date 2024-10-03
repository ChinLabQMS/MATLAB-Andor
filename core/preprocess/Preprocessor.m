classdef Preprocessor < BaseRunner

    properties (SetAccess = protected)
        Background
    end

    methods
        function obj = Preprocessor(config)
            arguments
                config (1, 1) PreprocessConfig = PreprocessConfig();
            end
            obj@BaseRunner(config);
        end

        function init(obj)
            obj.Background = load(obj.Config.BackgroundDataPath);
            fprintf("%s: Background loaded.\n", obj.CurrentLabel)
        end

        function [signal, leakage] = process(obj, raw, label, config, options)
            arguments
                obj
                raw (:, :, :) double
                label (1, 1) string
                config (1, 1) struct
                options.verbose (1, 1) logical = false
                options.cam_name (1, :) string = obj.Config.ProcessCamName
            end
            if ~ismember(config.CameraName, options.cam_name)
                signal = raw;
                leakage = zeros(size(signal));
                return
            end
            timer = tic;
            signal = obj.subtractBackground(raw, label, config);
            signal = obj.removeOutlier(signal, label, config);
            [signal, leakage] = obj.correctOffset(signal, label, config);
            if options.verbose
                fprintf("%s: [%s %s] Preprocessing completed in %.3f s.\n", obj.CurrentLabel, config.CameraName, label, toc(timer))
            end
        end

        function [signal, leakage] = processSingleData(obj, data, varargin)
            signal = data;
            leakage = data;
            for label = string(fields(data.Config.AcquisitionNote)')
                [signal.(label), leakage.(label)] = obj.process( ...
                    data.(label), label, data.Config, varargin{:});
            end
            fprintf("%s: Data from camera %s is processed.\n", obj.CurrentLabel, data.Config.CameraName)
        end

        function [signal, leakage] = processData(obj, data, varargin)
            if isfield(data, "Config")
                [signal, leakage] = processSingleData(obj, data, varargin{:});
                return
            end
            signal = data;
            leakage = data;
            for camera = string(fields(data)')
                if camera == "AcquisitionConfig"
                    continue
                end
                [signal.(camera), leakage.(camera)] = obj.processSingleData(data.(camera), varargin{:});
            end
        end
    end

    methods (Access = protected)
        function signal = subtractBackground(obj, raw, ~, config)
            signal = raw - obj.Background.(parseConfig(config)).(config.CameraName).(obj.Config.BackgroundSubtraction_VarName);
        end

        function signal = removeOutlier(obj, raw, label, config)
            signal = raw;
            [max_val, max_idx] = maxk(raw(:), obj.Config.OutlierRemoval_NumMaxPixels + 1);
            [min_val, min_idx] = mink(raw(:), obj.Config.OutlierRemoval_NumMinPixels + 1);
            diff1 = (-diff(max_val)) > obj.Config.OutlierRemoval_DiffThres;
            diff2 = diff(min_val) > obj.Config.OutlierRemoval_DiffThres;
            num_detected = 0;
            if any(diff1)
                index = find(diff1, 1, 'last');
                num_detected = num_detected + index;
                signal(max_idx(1:index)) = max_val(index + 1);
            end
            if any(diff2)
                index = find(diff2, 1, 'last');
                num_detected = num_detected + index;
                signal(min_idx(1:index)) = min_val(index + 1);
            end
            if num_detected > 0
                warning('backtrace', 'off')
                warning("%s: [%s %s] [%d] outliers detected, max = %g, min = %g.", ...
                    obj.CurrentLabel, config.CameraName, label, num_detected, max_val(1), min_val(1))
                warning('backtrace', 'on')
            end
        end

        function [signal, leakage, variance] = correctOffset(obj, raw, label, config)
            [leakage, variance] = cancelOffset(raw, ...
                getNumFrames(config),  obj.Config.OffsetCorrection_RegionWidth); 
            signal = raw - leakage;
            if obj.Config.OffsetCorrection_Warning
                warning('off','backtrace')
                if any(abs(leakage) > obj.Config.OffsetCorrection_WarnOffsetThres)
                    warning('%s: [%s %s] Noticeable background offset, max = %4.2f, min = %4.2f.', ...
                            obj.CurrentLabel, config.CameraName, label, max(leakage(:)),min(leakage(:)))
                end
                if any(variance > obj.Config.OffsetCorrection_WarnVarThres)
                    warning('%s: [%s %s] Noticeable background variance, max = %4.2f, min = %4.2f.', ...
                            obj.CurrentLabel, config.CameraName, label, max(variance(:)), min(variance(:)))
                end
                warning('on','backtrace')
            end
        end
    end

end

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
