classdef Preprocessor < BaseRunner

    properties (SetAccess = protected, Hidden)
        Background
    end

    methods
        function obj = Preprocessor(config)
            arguments
                config (1, 1) PreprocessConfig = PreprocessConfig();
            end
            obj@BaseRunner(config);
            obj.initLoadBackground()
        end

        function [signal, background] = process(obj, raw, label, config)
            signal = obj.runBackgroundSubtraction(double(raw), label, config);
            [signal, background] = obj.runOffsetCorrection(signal, label, config);
        end

        function processed_data = processData(obj, raw_data)
            arguments
                obj
                raw_data (1, 1) struct
            end
        end
    end

    methods (Access = protected)
        function initLoadBackground(obj)
            obj.Background = load(obj.Config.LoadBackgroundParams.filename);
        end

        function processed = runBackgroundSubtraction(obj, raw, ~, config)
            try
                processed = raw - obj.Background.(config.CameraName).(obj.Config.BackgroundSubtractionParams.var_name);
            catch
                processed = raw;
            end
        end

        function [signal, background] = runOffsetCorrection(obj, raw, label, config)            
            switch obj.Config.OffsetCorrectionParams.method
                case "linear_plane"
                    if ~isfield(config, "FastKinetic") 
                        signal = raw;
                        background = zeros(size(raw));
                        return
                    end
                    if config.FastKinetic
                        num_frames = config.FastKineticSeriesLength;
                    else
                        num_frames = 1;
                    end
                    background = cancelOffsetLinearPlane(raw, num_frames, ...
                        "region_width", obj.Config.OffsetCorrectionParams.region_width, ...
                        "warning", obj.Config.OffsetCorrectionParams.warning, ...
                        "warning_thres_offset", obj.Config.OffsetCorrectionParams.warning_thres_offset, ...
                        "warning_thres_var", obj.Config.OffsetCorrectionParams.warning_thres_var, ...
                        "note", obj.CurrentLabel + sprintf("[%s %s]", config.CameraName, label));
                    signal = raw - background;
                otherwise
                    error("%s: %s method not implemented", obj.CurrentLabel, obj.Config.method)
            end
        end
    end
end
