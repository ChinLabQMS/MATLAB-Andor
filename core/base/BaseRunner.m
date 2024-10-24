classdef BaseRunner < BaseObject
    %BASERUNNER Base class for all runners in the framework.
    % Provides basic functionality of setting and displaying configuration.

    properties (SetAccess = immutable)
        Config
    end
    
    methods
        function obj = BaseRunner(config)
            arguments
                config = BaseObject()
            end
            obj.Config = config;
        end
        
        % Change the configuration in obj.Config
        function config(obj, varargin)
            obj.Config.configProp(varargin{:})
        end

        function disp(obj)
            disp@handle(obj)
            disp(obj.Config)
        end
    end
    
end
