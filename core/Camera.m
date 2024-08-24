classdef (Abstract) Camera
    %CAMERA Generic class for camera object
    % 

    properties (Abstract)
        SerialNumber
        ImageSize (1, 2) double
        ExternalTrigger (1, 1) logical
        Exposure (1, 1) double
    end

    methods (Abstract)
    end
end
