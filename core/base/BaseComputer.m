classdef (Abstract) BaseComputer < BaseObject

    properties (SetAccess = immutable)
        ID
    end
    
    methods
        function obj = BaseComputer(id)
            obj.ID = id;
        end
    end
    
    methods (Access = protected, Hidden)
        function label = getStatusLabel(obj)
            label = sprintf("%s (%s)", class(obj), obj.ID);
        end
    end

end
