classdef (Abstract) BaseRunner < BaseObject
    %BASERUNNER Base class for all runners in the framework.
    % Provides basic functionality of setting and displaying configuration.
    % The default behavior is to only configure the attached Config

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
            names = obj.Config.configProp(varargin{:});
            obj.info("Configured [%s]", names)
        end

        function disp(obj)
            disp@handle(obj)
            disp(obj.Config)
        end
    end
    
end
