classdef SiteProcessor < CombinedProcessor

    properties (SetAccess = {?BaseObject})
        SiteCounterList = ["Andor19330", "Andor19331"]
    end

    properties (SetAccess = protected)
        SiteCounter
    end

end
