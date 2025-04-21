classdef SiteProcessor < CombinedProcessor

    properties (SetAccess = {?BaseObject})
        SiteCounterList = ["Andor19330", "Andor19331"]
    end

    properties (SetAccess = protected)
        SiteCounters
    end

    methods (Access = protected, Hidden)
        function init(obj)
            init@CombinedProcessor(obj)
            for i = 1: length(obj.SiteCounterList)
                camera = obj.SiteCounterList(i);
                obj.SiteCounters.(camera) = SiteCounter(camera, obj.LatCalib.(camera), obj.PSFCalib.(camera));
            end
            obj.info("SiteProcessor is initialized with loaded LatCalib and PSFCalib.")
        end
    end
end
