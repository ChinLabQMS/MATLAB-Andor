classdef LiveData < BaseObject
    
    properties (SetAccess = {?BaseObject})
        RunNumber = 0
        Raw
        Signal
        Background
        Analysis
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
            obj.Raw = [];
            obj.Signal = [];
            obj.Background = [];
            obj.Analysis = [];
        end
    end

end
