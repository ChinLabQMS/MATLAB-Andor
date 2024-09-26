classdef AxesConfig < BaseObject
    properties (SetAccess = {?BaseObject})
        CameraName
        ImageLabel
        Style
        Content
        FuncName
    end

    methods
        function obj = AxesConfig(style, camera, label, content, func)
            arguments
                style (1, 1) string = "Image"
                camera (1, 1) string = "Andor19330"
                label (1, 1) string = "Image"
                content (1, 1) string = "Processed"
                func (1, 1) string = "Max"
            end
            obj.Style = style;
            obj.CameraName = camera;
            obj.ImageLabel = label;
            obj.Content = content;
            obj.FuncName = func;
        end
    end

end
