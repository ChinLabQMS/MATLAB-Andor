classdef Camera < BaseRunner
    %CAMERA Base class for camera objects. Also simulate a real camera.
    
    properties (SetAccess = immutable, Hidden)
        ID
    end

    properties (SetAccess = protected)
        Initialized (1, 1) logical = false
        NumExpectedFrames (1, 1) double = 0
    end

    properties (Access = private)
        AcquisitionStartTime
        ExampleLocation = "data/2024/10 October/20241004/anchor=64_array64_spacing=70_centered_r=20_r=10.mat"
        ExampleImage
        CurrentIndex = 0
    end
    
    % Override these methods to implement for each subclass
    methods
        function obj = Camera(id, config)
            arguments
                id = "Andor19330"
                config = AndorCameraConfig()
            end
            obj@BaseRunner(config)
            obj.ID = id;
        end

        function num_available = getNumberNewImages(obj)
            obj.checkInitialized()
            if isempty(obj.AcquisitionStartTime)
                obj.error("Acquisition not started.")
            end
            num_available = sum(datetime("now") > obj.AcquisitionStartTime + seconds(obj.Config.Exposure));
        end

        function [exposure_time, readout_time] = getTimings(obj)
            exposure_time = obj.Config.Exposure;
            readout_time = nan;
        end

        function [is_stable, temp, status] = checkTemperature(obj)
            is_stable = false;
            temp = nan;
            status = sprintf("Not implemented for this class %s", class(obj));
        end

        function delete(obj)
            obj.close()
        end
    end
    
    % Sealed methods for major camera functionalities
    methods (Sealed)
        function init(obj)
            if obj.Initialized
                obj.abortAcquisition()
                return
            end
            obj.initCamera()
            obj.applyConfig()
            obj.Initialized = true;
            obj.NumExpectedFrames = 0;
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

        function startAcquisition(obj, options)
            arguments
                obj
                options.verbose (1, 1) logical = false
            end
            obj.checkInitialized()
            if obj.NumExpectedFrames == 0
                obj.abortAcquisitionCamera()  % Clear the internal memory before first acquisition
            end
            if obj.NumExpectedFrames < obj.Config.MaxQueuedFrames
                obj.startAcquisitionCamera()  % Start acquisition
                obj.NumExpectedFrames = obj.NumExpectedFrames + 1;
            else
                obj.abortAcquisition()
                obj.error("Too many start commands before retriving data, MaxQueuedFrames = %d.", obj.Config.MaxQueuedFrames)
            end
            if options.verbose
                obj.info("Acquisition started for frame number = %d.", obj.NumExpectedFrames)
            end
        end
        
        function abortAcquisition(obj)
            obj.checkInitialized()
            obj.abortAcquisitionCamera()
            obj.NumExpectedFrames = 0;
        end

        function [image, status] = acquire(obj, options)
            arguments
                obj
                options.label (1, 1) string = "Image"
                options.refresh (1, 1) double {mustBePositive} = 0.01
                options.timeout (1, 1) double {mustBePositive} = 10
                options.flag_immediate (1, 1) logical = false
                options.min_wait (1, 1) double = 0
                options.verbose (1, 1) logical = false
            end
            timer = tic;
            obj.checkInitialized()
            if obj.NumExpectedFrames == 0
                obj.error("[%s] Expected number of frame is 0, please start acquisition before retriving data.", options.label)
            end
            num_available = obj.getNumberNewImages();
            status = "good";
            if num_available > obj.NumExpectedFrames
                status = "delayed"; %#ok<*NASGU>
                obj.warn2("[%s] More than expected images are available, check if analysis falls behind acquisition.", options.label)
            elseif num_available == obj.NumExpectedFrames && options.flag_immediate
                status = "immediate";
                obj.warn2("[%s] Image is immediately available upon acquire.", options.label)
            else
                while toc(timer) < options.timeout && (num_available < obj.NumExpectedFrames)
                    num_available = obj.getNumberNewImages();
                    pause(options.refresh)
                end
                elapsed = toc(timer);
                if elapsed >= options.timeout
                    image = zeros(obj.Config.XPixels, obj.Config.YPixels, "uint16");
                    status = "timeout";
                    obj.warn2("[%s] Acquisition timed out.", options.label)
                    obj.abortAcquisitionCamera()
                    return
                elseif elapsed < options.min_wait
                    status = "short";
                    obj.warn2("[%s] Elapsed time too short for this acquisition.", options.label)
                end
            end
            [image, new_status] = obj.acquireImage(options.label);
            if status == "good" && new_status ~= "good"
                status = new_status;
            end
            obj.NumExpectedFrames = obj.NumExpectedFrames - 1;
            if any(image(:) == obj.Config.MaxPixelValue)
                obj.warn("[%s] Image is saturated.", options.label)
            end
            if options.verbose
                obj.info("[%s] Acquisition completed in %4.2f s.", options.label, toc(timer))
            end
        end
    end
    
    % Hidden methods, implement for each subclass
    methods (Access = private, Hidden)
        function initCamera(obj)
            try
                obj.ExampleImage = load(obj.ExampleLocation, "Data").Data.(obj.ID);
            catch
                obj.warn("Example image not found at '%s'.", obj.ExampleLocation)
                obj.ExampleImage = struct.empty;
            end
        end

        function closeCamera(~)
        end

        function applyConfig(obj)
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

        function startAcquisitionCamera(obj)
            obj.AcquisitionStartTime = [obj.AcquisitionStartTime, datetime("now")];
        end

        function abortAcquisitionCamera(obj)
            obj.AcquisitionStartTime = [];
        end

        function [image, status] = acquireImage(obj, label)
            if isfield(obj.ExampleImage, label)
                obj.CurrentIndex = mod(obj.CurrentIndex, size(obj.ExampleImage.(label), 3)) + 1;
                image = obj.ExampleImage.(label)(:, :, obj.CurrentIndex);
            else
                image = randi(obj.Config.MaxPixelValue - 1, obj.Config.XPixels, obj.Config.YPixels, "uint16");
            end
            status = "good";
            obj.AcquisitionStartTime = obj.AcquisitionStartTime(2:end);
        end
    end
    
    % Generic methods shared by all subclasses, can be overridden
    methods (Access = protected, Hidden)
        function label = getStatusLabel(obj)
            label = string(class(obj)) + string(obj.ID);
        end
    end

    methods (Access = protected, Sealed, Hidden)
        function checkInitialized(obj)
            if ~obj.Initialized
                obj.error("Camera not initialized.")
            end
        end
    end

end
