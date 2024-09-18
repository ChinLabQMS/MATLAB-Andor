classdef BaseObject < handle

    properties (SetAccess = protected)
        ID
        Config (1, 1) BaseConfig
        Initialized (1, 1) logical = false
    end

    properties (Dependent, Hidden)
        CurrentLabel
    end
    
    methods

        function obj = BaseObject(id, config)
            arguments
                id = ""
                config (1, 1) BaseConfig = BaseConfig()
            end
            obj.ID = id;
            obj.Config = config;
        end

        function init(obj)
            if obj.Initialized
                return
            end
            obj.Initialized = true;
            fprintf("%s: %s initialized.\n", obj.CurrentLabel, class(obj))
        end

        function close(obj)
            if obj.Initialized
                obj.Initialized = false;
                fprintf('%s: %s closed.\n', obj.CurrentLabel, class(obj))
            end
        end

        function config(obj, name, value)
            arguments
                obj
            end
            arguments (Repeating)
                name
                value
            end
            obj.checkStatus()
            for i = 1:length(name)
                obj.Config.(name{i}) = value{i};
            end
        end

        function label = getCurrentLabel(obj)
            label = sprintf("[%s] %s", ...
                            datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss.SSS"), ...
                            class(obj)) + string(obj.ID);
        end
        
        function label = get.CurrentLabel(obj)
            label = obj.getCurrentLabel();
        end

        function disp(obj)
            disp@handle(obj)
            disp(obj.Config)
        end

        function delete(obj)
            obj.close()
            delete@handle(obj)
        end

    end

    methods (Access = protected, Hidden)

        function checkStatus(obj)
            if ~obj.Initialized
                error('%s: %s not initialized.', obj.CurrentLabel, class(obj))
            end
        end

    end
end
