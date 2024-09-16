classdef (Abstract) CameraConfig
    %CAMERACONFIG Base class for all camera configurations

    properties (Abstract, SetAccess = {?Camera})
        Exposure (1, 1) double
        ExternalTrigger (1, 1) logical
        XPixels (1, 1) double
        YPixels (1, 1) double
    end

    properties (Abstract, Constant)
        MaxPixelValue (1, 1) double
    end

    methods
        function s = struct(obj)
            fields = fieldnames(obj);
            s = struct();
            for i = 1:length(fields)
                s.(fields{i}) = obj.(fields{i});
            end
        end
    end

end
