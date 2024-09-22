classdef BaseAnalyzer < BaseObject

    properties (SetAccess = protected)
        Initialized (1, 1) logical = false
    end
    
    methods
        function obj = BaseAnalyzer(config)
            arguments
                config (1, 1) BaseConfig = BaseConfig();
            end
            obj@BaseObject(config);
        end

        function init(obj)
            for step = obj.Config.InitSequence
                obj.(['init' + step])();
            end
            obj.Initialized = true;
        end

        function data = process(obj, data)
            if ~obj.Initialized
                obj.init();
            end
            for step = obj.Config.ProcessSequence
                data = obj.(['run' + step])(data);
            end        
        end
    end

end