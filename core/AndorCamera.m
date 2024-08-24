classdef AndorCamera < Camera
    %ANDORCAMERA AndorCamera class
    %   Detailed explanation goes here
    
    properties
        SerialNumber = 19330
        ImageSize = [1024, 1024]
        ExternalTrigger = true
        Exposure = 1
    end
    
    methods
        function obj = AndorCamera(serial_number)
            %ANDORCAMERA Construct an instance of this class
            
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

