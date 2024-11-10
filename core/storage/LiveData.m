classdef LiveData < BaseObject
    
    properties (SetAccess = {?BaseObject})
        RunNumber = 0
        Raw
        Signal
        Background
        Analysis
        Temporary
        BadFrameDetected
    end

    properties (SetAccess = protected)
        LastData
    end

    properties (SetAccess = immutable)
        LatCalib
    end

    methods
        function init(obj)
            obj.LastData = obj.struct();
            obj.RunNumber = obj.RunNumber + 1;
            obj.BadFrameDetected = false;
            obj.Raw = [];
            obj.Signal = [];
            obj.Background = [];
            obj.Analysis = [];
            obj.Temporary = [];
        end
    end

end
