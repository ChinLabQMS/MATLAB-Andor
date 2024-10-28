classdef (Abstract) BaseProcessor < BaseObject
    %BASEPROCESSOR Base class for all processors. 
    % The default behavior is to init the processor upon configuration.

    methods
        function obj = BaseProcessor()
            % Dummy initialization to make sure all the set methods are
            % invoked for configurable property upon initiating object
            for p = obj.ConfigurableProp
                obj.(p) = obj.(p);
            end
            obj.init()
        end

        function config(obj, varargin)
            obj.configProp(varargin{:})
            obj.init()
        end
    end

    methods (Access = protected, Abstract)
        % Initialize the processor after configuration
        init(obj)
    end

end
