classdef BaseAnalyzer < BaseRunner

    properties (SetAccess = protected)
        Initialized (1, 1) logical = false
    end
    
    methods
        function obj = BaseAnalyzer(config)
            arguments
                config (1, 1) BaseObject = BaseObject();
            end
            obj@BaseRunner(config)
        end

        function init(obj)
            for step = obj.Config.InitSequence
                args = namedargs2cell(obj.Config.(step + "Params"));
                obj.("init" + step)(args{:});
                fprintf("%s: Finished step [%s].\n", obj.CurrentLabel, step)
            end
            obj.Initialized = true;
            fprintf("%s: %s Initialized.\n", obj.CurrentLabel, class(obj))
        end

        function processed_image = process(obj, raw_image, camera_name, image_label)
            if ~obj.Initialized
                obj.init();
            end
            data = raw_image;
            for step = obj.Config.ProcessSequence
                args = namedargs2cell(obj.Config.(step + "Params"));
                data = obj.("run" + step)(data, camera_name, image_label, args{:});
            end
            processed_image = data;
        end
    end

end