classdef Camera < BaseRunner
    %CAMERA Base class for camera objects.
    
    properties (SetAccess = immutable, Hidden)
        ID
    end

    properties (SetAccess = protected)
        Initialized (1, 1) logical = false
    end

    properties (Access = private)
        AcquisitionStartTime
        ExampleLocation = "data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat"
        ExampleImage
        CurrentIndex = 0
    end

    methods
        function obj = Camera(id, config)
            arguments
                id = "Andor19330"
                config = AndorCameraConfig()
            end
            obj@BaseRunner(config)
            obj.ID = id;
        end

        function startAcquisition(obj, options)
            % Implement for each subclass
            arguments
                obj
                options.verbose (1, 1) logical = false
            end
            obj.checkStatus()
            obj.AcquisitionStartTime = datetime("now");
            if options.verbose
                obj.info("Acquisition started.")
            end
        end
        
        function abortAcquisition(obj)
            % Implement for each subclass
            obj.checkStatus()
        end

        function num_available = getNumberNewImages(obj)
            % Implement for each subclass
            obj.checkStatus()
            if isempty(obj.AcquisitionStartTime)
                obj.error("Acquisition not started.")
            end
            if datetime("now") > obj.AcquisitionStartTime + seconds(obj.Config.Exposure)
                num_available = 1;
            else
                num_available = 0;
            end
        end

        function [exposure_time, readout_time] = getTimings(obj)
            % Implement for each subclass
            exposure_time = obj.Config.Exposure;
            readout_time = 0;
        end

        function [is_stable, temp, status] = checkTemperature(obj)
            % Implement for each subclass
            is_stable = false;
            temp = nan;
            status = sprintf("Not implemented for this class %s", class(obj));
        end

        function delete(obj)
            obj.close()
        end
    end

    methods (Sealed)
        function init(obj)
            if obj.Initialized
                return
            end
            obj.initCamera()
            obj.applyConfig()
            obj.Initialized = true;
            obj.info("Camera initialized.")
        end

        function close(obj)
            if obj.Initialized
                obj.abortAcquisition()
                obj.closeCamera()
                obj.Initialized = false;
                obj.info("Camera closed.")
            end
        end

        function config(obj, varargin)
            config@BaseRunner(obj, varargin{:})
            obj.abortAcquisition()
            obj.applyConfig()
        end

        function [image, num_frames, is_saturated] = acquire(obj, options)
            arguments
                obj
                options.refresh (1, 1) double {mustBePositive} = 0.01
                options.timeout (1, 1) double {mustBePositive} = 1000
                options.verbose (1, 1) logical = false
                options.label (1, 1) string = "Image"
            end
            timer = tic;
            while toc(timer) < options.timeout && (obj.getNumberNewImages() == 0)
                pause(options.refresh)
            end
            if toc(timer) >= options.timeout
                obj.warn("Acquisition timed out.")
                obj.abortAcquisition()
                image = zeros(obj.Config.XPixels, obj.Config.YPixels, "uint16");
                num_frames = 0;
                is_saturated = false;
                return
            end
            [image, num_frames, is_saturated] = obj.acquireImage(options.label);
            if is_saturated
                obj.warn("[%s] Image is saturated.", options.label)
            end
            if options.verbose
                obj.info("[%s] Acquisition complete in %4.2f s.", options.label, toc(timer))
            end
        end
    end

    methods (Access = protected, Hidden)
        function initCamera(obj)
            % Implement for each subclass
            try
                obj.ExampleImage = load(obj.ExampleLocation, "Data").Data.(obj.ID);
            catch
                obj.warn("Example image not found at [%s].", obj.ExampleLocation)
                obj.ExampleImage = struct.empty;
            end
        end

        function closeCamera(obj)
            % Implement for each subclass
        end

        function applyConfig(obj)
            % Implement for each subclass
            for label = string(fields(obj.ExampleImage)')
                if label.endsWith("Config")
                    continue
                end
                if ~isequal(size(obj.ExampleImage.(label), [1, 2]), [obj.Config.XPixels, obj.Config.YPixels])
                    obj.warn("[%s] Example image size does not match current camera configuration.", label)
                    obj.ExampleImage = struct.empty;
                    break
                end
            end
        end

        function [image, num_frames, is_saturated] = acquireImage(obj, label)
            % Implement for each subclass
            num_frames = obj.getNumberNewImages();
            if isfield(obj.ExampleImage, label)
                obj.CurrentIndex = mod(obj.CurrentIndex, size(obj.ExampleImage.(label), 3)) + 1;
                image = obj.ExampleImage.(label)(:, :, obj.CurrentIndex);
            else
                image = randi(obj.Config.MaxPixelValue, obj.Config.XPixels, obj.Config.YPixels, "uint16");
            end
            is_saturated = false;
        end
    end

    methods (Access = protected, Sealed, Hidden)
        function checkStatus(obj)
            if ~obj.Initialized
                obj.error("Camera not initialized.")
            end
        end

        function label = getStatusLabel(obj)
            label = string(class(obj)) + string(obj.ID);
        end
    end

end
