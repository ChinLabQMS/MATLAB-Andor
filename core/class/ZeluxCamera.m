classdef ZeluxCamera < Camera
    %ANDORCAMERA AndorCamera class
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
        function obj = AndorCamera()
            %ANDORCAMERA Construct an instance of this class
            %   Detailed explanation goes here
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end