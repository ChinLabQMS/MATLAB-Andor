classdef (Abstract) Camera < handle
    %CAMERA

    properties (Abstract, SetAccess = private)
        Initialized (1, 1) logical
        CameraConfig (1, 1) CameraConfig
    end

    properties (Abstract, Dependent)
        CurrentLabel (1, 1) string
    end

    methods
        function init(obj)
            fprintf('%s: Camera initialized.\n', obj.CurrentLabel)
        end

        function close(obj)
            fprintf('%s: Camera closed.\n', obj.CurrentLabel)
        end

        function config(obj, name, value)
            arguments
                obj
            end
            arguments (Repeating)
                name
                value
            end
            if ~obj.Initialized
                error('%s: Camera not initialized.', obj.CurrentLabel)
            end
            for i = 1:length(name)
                obj.CameraConfig.(name{i}) = value{i};
            end
        end

        function disp(obj)
            disp@handle(obj)
            disp(obj.CameraConfig)
        end

        function delete(obj)
            obj.close();
            delete@handle(obj)
        end

    end

    methods (Abstract)
        startAcquisition(obj)
        abortAcquisition(obj)
        image = getImage(obj)
    end

end
