classdef Preprocessor < handle
    
    properties (SetAccess = immutable)
        PreprocessConfig
        Background
        DataHandle
    end
    
    methods
        function obj = Preprocessor(data_handle, config)
            arguments
                data_handle (1, 1) Dataset
                config (1, 1) PreprocessConfig = PreprocessConfig();
            end
            obj.DataHandle = data_handle;
            obj.PreprocessConfig = config;
            if config.BackgroundSubtraction
                obj.Background = load(config.BackgroundSubstractionParams.file);
            end
        end
        
        function proc_image = substractBackground(obj, images)
        end

    end
end