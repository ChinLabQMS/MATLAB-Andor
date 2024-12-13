classdef AxesConfig < BaseObject



    methods
        function obj = AxesConfig(config)
            arguments
                config.camera (1, 1) string = "Andor19330"
                config.label (1, 1) string = "Image"
                config.content (1, 1) string = "Signal"
                config.func (1, 1) string = "Max"
            end
            obj.CameraName = config.camera;
            obj.ImageLabel = config.label;
            obj.Content = config.content;
            obj.FuncName = config.func;
        end
    end

end
