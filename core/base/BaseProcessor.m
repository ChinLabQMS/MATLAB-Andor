classdef (Abstract) BaseProcessor < BaseObject
    %BASEPROCESSOR Base class for all processors. 
    % The default behavior is to init the processor upon configuration.

    methods
        function obj = BaseProcessor(varargin)
            % Dummy initialization to make sure all the set methods are
            % invoked for configurable property upon initiating object
            for p = obj.ConfigurableProp
                if ~isempty(obj.(p))
                    obj.(p) = obj.(p);
                end
            end
            obj.config(varargin{:})
        end

        function config(obj, varargin)
            obj.configProp(varargin{:})
            obj.init()
        end
    end

    methods (Access = protected)
        % Initialize the processor after configuration
        function init(~)
        end
    end

end
