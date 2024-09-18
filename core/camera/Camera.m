classdef Camera < BaseObject
    %CAMERA Base class for camera objects.

    methods
        function obj = Camera(id, config)
            arguments
                id = "Test"
                config = AndorCameraConfig()
            end
            obj@BaseObject(id, config)
        end

        function config(obj, varargin)
            obj.abortAcquisition()
            config@BaseObject(obj, varargin{:})
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
            image = zeros(obj.Config.XPixels, obj.Config.YPixels, "uint16");
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

    end

end
