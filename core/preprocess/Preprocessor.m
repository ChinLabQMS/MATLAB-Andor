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

        function [processed, background] = process(obj, raw, label, config)
            arguments
                obj
                raw (:, :) {mustBeNumeric}
                label (1, 1) string
                config (1, 1) struct
            end
            processed = obj.runBackgroundSubtraction(double(raw), label, config);
            [processed, background] = obj.runOffsetCorrection(processed, label, config);
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
            camera = config.CameraName;
            if isfield(obj.Background, camera)
                processed = raw - obj.Background.(camera).(obj.Config.BackgroundSubtractionParams.var_name);
            else
                processed = raw;
            end
        end

        function [processed, background] = runOffsetCorrection(obj, raw, label, config)
            processed = raw;
            background = zeros(size(raw));
            if ~isfield(config, "FastKinetic") || ~config.FastKinetic
                num_frames = 1;
            else
                num_frames = config.FastKineticSeriesLength;
            end
        end
    end
end
