classdef BaseProcessor < BaseRunner
    % BaseProcessor: Base class for all processors. The default behavior is to
    % init the processor upon configuration.

    methods
        function obj = BaseProcessor(config)
            arguments
                config (1, 1) BaseObject = BaseObject()
            end
            obj@BaseRunner(config)
            obj.applyConfig()
        end

        function config(obj, varargin)
            config@BaseRunner(obj, varargin{:})
            obj.applyConfig()
        end
    end

    methods (Access = protected, Hidden)
        function applyConfig(obj)
            % Implement for each subclass
            obj.info("Configuration applied.")
        end
    end

end
