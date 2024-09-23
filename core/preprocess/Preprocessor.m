classdef Preprocessor < BaseAnalyzer

    properties (SetAccess = protected, Hidden)
        Background
    end

    methods
        function obj = Preprocessor(config)
            arguments
                config (1, 1) PreprocessConfig = PreprocessConfig();
            end
            obj@BaseAnalyzer(config);
        end

        function initLoadBackground(obj, params)
            arguments
                obj
                params.filename
            end
            obj.Background = load(params.filename);
        end

        function processed_image = runBackgroundSubtraction(obj, raw_image, camera_name, image_label, params)
            arguments
                obj
                raw_image
                camera_name
                image_label
                params.var_name
            end
            processed_image = raw_image - obj.Background.(camera_name).(params.var_name);
        end

        function processed_image = runOffsetCorrection(obj, raw_image, camera_name, image_label, params)
            arguments
                obj
                raw_image
                camera_name
                image_label
                params.method
                params.region_width
                params.warning
                params.warning_thres_offset
                params.warning_thres_var
            end
        end
    end
end
