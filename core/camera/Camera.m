classdef Camera < BaseObject
    %CAMERA Base class for camera objects.
    
    properties (SetAccess = immutable)
        ID
    end

    properties (SetAccess = protected, Transient)
        Initialized (1, 1) logical = false
    end

    methods
        function obj = Camera(id, config)
            arguments
                id = "Test"
                config = AndorCameraConfig()
            end
            obj@BaseObject(config)
            obj.ID = id;
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

        function config(obj, varargin)
            obj.abortAcquisition()
            config@BaseObject(obj, varargin{:})
        end

        function startAcquisition(obj)
            obj.checkStatus()
        end
        
        function abortAcquisition(obj)
        end

        function num_available = getNumberNewImages(obj)
            obj.checkStatus()
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

        function label = getStatusLabel(obj)
            label = sprintf("%s (Initialized: %d)", string(obj.ID), obj.Initialized);
        end

        function delete(obj)
            obj.close()
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
