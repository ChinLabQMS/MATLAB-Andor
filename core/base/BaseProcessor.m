classdef BaseProcessor < BaseObject
    %BASEPROCESSOR: Base class for all processors. The default behavior is to
    % init the processor upon configuration.
    % Good to have main method packaged to static method if initiating an
    % object is not preferred.

    methods
        function obj = BaseProcessor(varargin)
            obj.configProp(varargin{:})
            obj.init()
        end

        function config(obj, varargin)
            obj.configProp(varargin{:})
            obj.init()
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            % Implement for each subclass
            obj.info("Processor initialized.")
        end
    end

end
