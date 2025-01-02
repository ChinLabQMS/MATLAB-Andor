classdef CombinedProcessor < LatProcessor & PSFProcessor
    
    methods
        function obj = CombinedProcessor(varargin)
            obj@PSFProcessor('reset_fields', false, 'init', false)
            obj@LatProcessor(varargin{:}, 'reset_fields', true, 'init', true)
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            init@LatProcessor(obj)
            init@PSFProcessor(obj)
        end
    end

end
