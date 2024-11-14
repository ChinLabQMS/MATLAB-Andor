classdef Camera < BaseRunner
    %CAMERA Base class for camera objects. Also simulate a real camera with
    % pre-loaded data.
    
    properties (SetAccess = immutable)
        ID
    end

    properties (SetAccess = protected)
        Initialized = false
        NumExpectedFrames = 0
    end

    properties (Access = private)
        AcquisitionStartTime
        ExampleLocation = "data/2024/11 November/20241113 sparse warmup/end_of_day.mat"
        ExampleImage
        CurrentIndex = 0
    end
    
    % Override these methods to implement for each subclass
    methods
        function obj = Camera(id, config)
            arguments
                id = "Test"
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
    
        % Close the connection upon delete
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
            if obj.Initialized
                obj.abortAcquisition()
                obj.applyConfig()
            end
        end

        function startAcquisition(obj, info, options)
            arguments
                obj
                info.label = "Test"
                options.verbose = false
            end
            obj.checkInitialized()
            if obj.NumExpectedFrames < obj.Config.MaxQueuedFrames
                obj.startAcquisitionCamera()  % Start acquisition
                obj.NumExpectedFrames = obj.NumExpectedFrames + 1;
            else
                obj.abortAcquisition()
                obj.warn("[%s] Too many start commands before retriving data, MaxQueuedFrames = %d.", ...
                    info.label, obj.Config.MaxQueuedFrames)
            end
            if options.verbose
                obj.info("[%s] Acquisition started for frame number = %d.", ...
                    info.label, obj.NumExpectedFrames)
            end
        end
        
        function abortAcquisition(obj)
            obj.checkInitialized()
            obj.abortAcquisitionCamera()
            obj.NumExpectedFrames = 0;
        end

        function [image, is_good] = acquire(obj, info, options)
            arguments
                obj
                info.label = "Test"
                options.refresh (1, 1) double {mustBePositive} = 0.01
                options.timeout (1, 1) double {mustBePositive} = 10
                options.flag_immediate (1, 1) logical = false
                options.min_wait (1, 1) double = 0
                options.verbose (1, 1) logical = true
            end
            timer = tic;
            obj.checkInitialized()
            if obj.NumExpectedFrames == 0
                obj.error("[%s] Expected number of frame is 0, please start acquisition before retriving data.", info.label)
            end
            is_good = true;
            num_available = obj.getNumberNewImages();
            if num_available > obj.NumExpectedFrames
                is_good = false;
                obj.warn2("[%s] More than expected images are available, check if analysis falls behind acquisition.", info.label)
            elseif num_available == obj.NumExpectedFrames && options.flag_immediate
                is_good = false;
                obj.warn2("[%s] Image is immediately available upon acquisition.", info.label)
            else
                while toc(timer) < options.timeout && (num_available < obj.NumExpectedFrames)
                    num_available = obj.getNumberNewImages();
                    pause(options.refresh)
                end
                elapsed = toc(timer);
                if elapsed >= options.timeout
                    image = zeros(obj.Config.XPixels, obj.Config.YPixels, "uint16");
                    is_good = false;
                    obj.warn2("[%s] Acquisition timed out.", info.label)
                    obj.abortAcquisition()
                    return
                elseif elapsed < options.min_wait
                    is_good = false;
                    obj.warn2("[%s] Elapsed time too short for this acquisition.", info.label)
                end
            end
            [image, new_status] = obj.acquireImage(info.label);
            is_good = is_good && new_status;
            obj.NumExpectedFrames = obj.NumExpectedFrames - 1;
            if any(image(:) == obj.Config.MaxPixelValue)
                obj.warn("[%s] Image is saturated, max pixel value = %d.", ...
                    info.label, obj.Config.MaxPixelValue)
            end
            if options.verbose
                obj.info("[%s] Acquisition completed in %4.2f s.", info.label, toc(timer))
            end
        end
    end
    
    % Hidden methods, implement for each subclass
    methods (Access = protected, Hidden)
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
                if label == "Config"
                    continue
                end
                if ~isequal(size(obj.ExampleImage.(label), [1, 2]), [obj.Config.XPixels, obj.Config.YPixels])
                    obj.warn("[%s] Example image size does not match current camera configuration.", label)
                    obj.ExampleImage = struct.empty;                 
                end
                break
            end
        end

        function startAcquisitionCamera(obj)
            obj.AcquisitionStartTime = [obj.AcquisitionStartTime, datetime("now")];
        end

        function abortAcquisitionCamera(obj)
            obj.AcquisitionStartTime = [];
        end

        function [image, is_good] = acquireImage(obj, label)
            if isfield(obj.ExampleImage, label)
                obj.CurrentIndex = mod(obj.CurrentIndex, size(obj.ExampleImage.(label), 3)) + 1;
                image = obj.ExampleImage.(label)(:, :, obj.CurrentIndex);
            else
                image = randi(obj.Config.MaxPixelValue - 1, obj.Config.XPixels, obj.Config.YPixels, "uint16");
            end
            is_good = true;
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
