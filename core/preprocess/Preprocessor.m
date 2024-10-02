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
            obj.Background = load(obj.Config.BackgroundFileLocation);
            fprintf("%s: Background loaded.\n", obj.CurrentLabel)
        end

        function [signal, leakage] = process(obj, raw, label, config, options)
            arguments
                obj
                raw (:, :, :) {mustBeNumeric}
                label (1, 1) string
                config (1, 1) struct
                options.verbose (1, 1) logical = false
            end
            timer = tic;
            signal = obj.runBackgroundSubtraction(double(raw), label, config);
            [signal, leakage] = obj.runOffsetCorrection(signal, label, config);
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
            fprintf("%s: Data from single camera is processed.\n", obj.CurrentLabel)
        end

        function [signal, leakage] = processData(obj, data, varargin)
            if isfield(data, "Config")
                [signal, leakage] = processSingleData(obj, data, varargin{:});
                return
            end
            signal = data;
            leakage = data;
            for field = string(fields(data)')
                if field.endsWith("Config")
                    continue
                end
                [signal.(field), leakage.(field)] = obj.processSingleData(data.(field), varargin{:});
            end
        end
    end

    methods (Access = protected)
        function signal = runBackgroundSubtraction(obj, raw, ~, config)
            if ~isfield(config, "Cropped")
                signal = raw;
                return
            end
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
            try
                signal = raw - obj.Background.(str1 + str2).(config.CameraName).(obj.Config.BackgroundSubtractionParams.var_name);
            catch
                signal = raw;
                warning("backtrace", "off")
                warning("%s: Unable to subtract background.", obj.CurrentLabel)
                warning("backtrace", "on")
            end
        end

        function signal = runOutlierRemoval(obj, raw, ~, config)            
        end

        function [signal, leakage] = runOffsetCorrection(obj, raw, ~, config)            
            switch obj.Config.OffsetCorrectionParams.method
                case "linear_plane"
                    if ~isfield(config, "FastKinetic") 
                        signal = raw;
                        leakage = zeros(size(raw, [1, 2]));
                        return
                    end
                    if config.FastKinetic
                        num_frames = config.FastKineticSeriesLength;
                    else
                        num_frames = 1;
                    end
                    leakage = cancelOffset(raw, num_frames, ...
                        "region_width", obj.Config.OffsetCorrectionParams.region_width, ...
                        "warning", obj.Config.OffsetCorrectionParams.warning, ...
                        "warning_thres_offset", obj.Config.OffsetCorrectionParams.warning_thres_offset, ...
                        "warning_thres_var", obj.Config.OffsetCorrectionParams.warning_thres_var, ...
                        "warning_note", sprintf("%s: [%s] ", obj.CurrentLabel, config.CameraName));
                    signal = raw - leakage;
                otherwise
                    error("%s: %s method not implemented", obj.CurrentLabel, obj.Config.method)
            end
        end
    end

end

function [offset, variance, residuals] = cancelOffset(signal, num_frames, options)
    arguments
        signal
        num_frames (1,1) double = 1
        options.region_width (1,1) double = 100
        options.warning (1,1) logical = true
        options.warning_thres_offset (1,1) double = 10
        options.warning_thres_var (1,1) double = 50
        options.warning_note (1, 1) string = ""
    end
    signal = mean(signal, 3);
    [x_pixels, y_pixels] = size(signal);
    x_size = x_pixels/num_frames;
    if y_pixels < 2*options.region_width + 200
        error('Not enough edge space to calibrate background offset!')
    end
    offset = zeros(x_pixels, y_pixels);
    variance = zeros(num_frames, 2);

    y_range1 = 1:options.region_width;
    y_range2 = y_pixels+(1-options.region_width:0);
    residuals = cell(num_frames,2);
    for i = 1:num_frames
        x_range = (i-1)*x_size+(1:x_size);
        bg_box1 = signal(x_range,y_range1);
        bg_box2 = signal(x_range,y_range2);
        [XOut1,YOut1,ZOut1] = prepareSurfaceData(x_range,y_range1',bg_box1');
        [XOut2,YOut2,ZOut2] = prepareSurfaceData(x_range,y_range2',bg_box2');
        XOut = [XOut1;XOut2];
        YOut = [YOut1;YOut2];
        ZOut = [ZOut1;ZOut2];
        XYFit = fit([XOut,YOut],ZOut,'poly11');

        % Background offset canceling with fitted plane
        offset(x_range,:) = XYFit.p00+XYFit.p10*x_range'+XYFit.p01*(1:y_pixels);

        res1 = bg_box1-offset(x_range,y_range1);
        res2 = bg_box2-offset(x_range,y_range2);
        variance(i,:) = [var(res1(:)),var(res2(:))];
        
        residuals{i,1} = res1;
        residuals{i,2} = res2;
    end
    
    if options.warning
        warning('off','backtrace')
        if any(variance>options.warning_thres_var)
            warning('%sNoticable background variance, max = %4.2f, min = %4.2f.', ...
                options.warning_note,max(variance(:)),min(variance(:)))
        end
        if any(abs(offset)>options.warning_thres_offset)
            warning('%sNoticable background offset, max = %4.2f, min = %4.2f.', ...
                options.warning_note,max(offset(:)),min(offset(:)))
        end
        warning('on','backtrace')
    end
end

