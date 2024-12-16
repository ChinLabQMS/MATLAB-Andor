classdef (Abstract) BaseProcessor < BaseObject
    %BASEPROCESSOR Base class for all processors. 
    % The default behavior is to init the processor upon configuration.

    methods
        function [obj, configured_props] = BaseProcessor(varargin, options)
            arguments (Repeating)
                varargin
            end
            arguments
                options.reset_fields = true
                options.init = true
            end
            % Dummy initialization to make sure all the set methods are
            % invoked for configurable property upon initiating object
            configured_props = obj.configProp(varargin{:}).split(" ");
            if options.reset_fields
                for p = obj.ConfigurableProp
                    if ~ismember(p, configured_props)
                        obj.(p) = obj.(p);
                    end
                end
            end
            if options.init
                obj.init()
            end
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
