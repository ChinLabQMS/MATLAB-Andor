classdef SiteProcessor < LatProcessor & PSFProcessor

    properties (SetAccess = {?BaseObject})
        SiteCounterList = ["Andor19330", "Andor19331"]
    end

    properties (SetAccess = protected)
        SiteCounter
    end

    methods
        function obj = SiteProcessor(varargin)
            obj@PSFProcessor('reset_fields', false, 'init', false)
            obj@LatProcessor(varargin{:}, 'reset_fields', true, 'init', true)
        end
    end

    methods (Access = protected)
        function init(obj)
            init@PSFProcessor(obj)
            init@LatProcessor(obj)
        end
    end

end
