classdef CombinedProcessor < LatProcessor & PSFProcessor
    
    methods
        function obj = CombinedProcessor(varargin, options)
            arguments (Repeating)
                varargin
            end
            arguments
                options.reset_fields = true
                options.init = true
            end
            obj@PSFProcessor('reset_fields', false, 'init', false)
            obj@LatProcessor(varargin{:}, 'reset_fields', options.reset_fields, 'init', options.init)
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            init@LatProcessor(obj)
            init@PSFProcessor(obj)
        end
    end

end
