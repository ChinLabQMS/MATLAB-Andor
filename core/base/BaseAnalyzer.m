classdef BaseAnalyzer < BaseRunner
    
    methods
        function obj = BaseAnalyzer(config)
            arguments
                config (1, 1) BaseObject = BaseObject()
            end
            obj@BaseRunner(config)
            obj.init()  % Apply config (loading files, etc.)
        end

        function config(obj, varargin)
            config@BaseRunner(obj, varargin{:})
            obj.init()
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            obj.info("Analyzer initialized.")
        end
    end

end
