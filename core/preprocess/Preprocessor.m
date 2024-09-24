classdef Preprocessor < BaseRunner

    properties (SetAccess = protected, Hidden)
        Background
    end

    properties (SetAccess = protected)
        Initialized (1, 1) logical = false
    end

    methods
        function obj = Preprocessor(config)
            arguments
                config (1, 1) PreprocessConfig = PreprocessConfig();
            end
            obj@BaseRunner(config);
        end

        function init(obj)
            obj.initLoadBackground()
            obj.Initialized = true;
            fprintf("%s: %s Initialized.\n", obj.CurrentLabel, class(obj))
        end

        function processed_image = process(obj, raw_image, label, config)
            arguments
                obj
                raw_image (:, :) uint16
                label (1, 1) string
                config (1, 1) struct
            end
            processed_image = obj.runBackgroundSubtraction(double(raw_image), label, config);
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

        function processed_image = runBackgroundSubtraction(obj, raw_image, ~, config)
            camera = config.CameraName;
            if isfield(obj.Background, camera)
                processed_image = raw_image - obj.Background.(camera).(obj.Config.BackgroundSubtractionParams.var_name);
            else
                processed_image = raw_image;
            end
        end

        function processed_image = runOffsetCorrection(obj, raw_image, label, config)
            if ~config.FastKinetic
                num_frames = 1;
            else
                num_frames = config.FastKineticSeriesLength;
            end
            processed_image = raw_image;
        end
    end
end
