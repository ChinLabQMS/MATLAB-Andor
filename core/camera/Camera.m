classdef Camera < handle
    %CAMERA Base class for camera objects.

    properties (SetAccess = protected)
        CameraConfig (1, 1)
        Initialized (1, 1) logical = false
    end

    properties (SetAccess = immutable)
        CameraIdentifier
    end

    properties (Dependent, Hidden)
        CurrentLabel (1, 1) string
    end

    methods
        function obj = Camera(identifier, config)
            arguments
                identifier = "Test"
                config = AndorCameraConfig()
            end
            obj.CameraIdentifier = identifier;
            obj.CameraConfig = config;
        end
    
        function init(obj)
            if obj.Initialized
                return
            end
            obj.Initialized = true;
            obj.config()
            fprintf('%s: Camera initialized.\n', obj.CurrentLabel)
        end

        function close(obj)
            if obj.Initialized
                obj.Initialized = false;
                fprintf('%s: Camera closed.\n', obj.CurrentLabel)
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
                obj.CameraConfig.(name{i}) = value{i};
            end
        end

        function startAcquisition(obj)
        end
        
        function abortAcquisition(obj)
        end

        function num_available = getNumberNewImages(obj)
            num_available = 1;
        end
        
        function [image, num_frames, is_saturated] = acquireImage(obj)
            obj.checkStatus()
            num_frames = obj.getNumberNewImages();
            image = zeros(obj.CameraConfig.MaxPixelValue, obj.CameraConfig.XPixels, obj.CameraConfig.YPixels, "uint16");
            is_saturated = false;
        end

        function [image, num_frames, is_saturated] = acquire(obj, options)
            arguments
                obj
                options.refresh (1, 1) double {mustBePositive} = 0.01
                options.timeout (1, 1) double {mustBePositive} = 1000
            end
            timer = tic;
            while toc(timer) < options.timeout && (obj.getNumberNewImages() == 0)
                pause(options.refresh)
            end
            if toc(timer) >= options.timeout
                warning('%s: Acquisition timeout.', obj.CurrentLabel)
                obj.abortAcquisition()
            end
            [image, num_frames, is_saturated] = obj.acquireImage();
        end

        function label = get.CurrentLabel(obj)
            label = string(sprintf('[%s] %s%s', ...
                           datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss"), ...
                           class(obj), string(obj.CameraIdentifier)));
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

    methods (Access = protected, Hidden)
        function checkStatus(obj)
            if ~obj.Initialized
                error('%s: Camera not initialized.', obj.CurrentLabel)
            end
        end
    end

end
