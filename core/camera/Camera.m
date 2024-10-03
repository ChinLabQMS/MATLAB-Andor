classdef Camera < BaseRunner
    %CAMERA Base class for camera objects.
    
    properties (SetAccess = immutable, Hidden)
        ID
    end

    properties (SetAccess = protected, Hidden)
        Initialized (1, 1) logical = false
    end

    properties (Access = private)
        AcquisitionStartTime
        ExampleLocation = "data/2024/09 September/20240930 multilayer/FK2_focused_to_major_layer.mat"
        ExampleImage
        CurrentIndex = 0
    end

    methods
        function obj = Camera(id, config)
            arguments
                id = "Test"
                config = AndorCameraConfig()
            end
            obj@BaseRunner(config)
            obj.ID = id;
        end

        function init(obj)
            if obj.Initialized
                return
            end
            obj.initCamera()
            obj.applyConfig()
            obj.Initialized = true;
            fprintf("%s: %s initialized.\n", obj.CurrentLabel, class(obj))
        end

        function close(obj)
            if obj.Initialized
                obj.abortAcquisition()
                obj.closeCamera()
                obj.Initialized = false;
                fprintf('%s: %s closed.\n', obj.CurrentLabel, class(obj))
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
            obj.checkStatus()
            obj.AcquisitionStartTime = datetime("now");
            if options.verbose
                fprintf("%s: Acquisition started.\n", obj.CurrentLabel)
            end
        end
        
        function abortAcquisition(obj)
            obj.checkStatus()
        end

        function num_available = getNumberNewImages(obj)
            obj.checkStatus()
            if isempty(obj.AcquisitionStartTime)
                error("%s: Acquisition hasn't started.", obj.CurrentLabel)
            end
            if datetime("now") > obj.AcquisitionStartTime + seconds(obj.Config.Exposure)
                num_available = 1;
            else
                num_available = 0;
            end
        end
        
        function [image, num_frames, is_saturated] = acquireImage(obj, label)
            num_frames = obj.getNumberNewImages();
            if isfield(obj.ExampleImage, label)
                obj.CurrentIndex = mod(obj.CurrentIndex, size(obj.ExampleImage.(label), 3)) + 1;
                image = obj.ExampleImage.(label)(:, :, obj.CurrentIndex);
            else
                image = randi(obj.Config.MaxPixelValue, obj.Config.XPixels, obj.Config.YPixels, "uint16");
            end
            is_saturated = false;
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
                warning('%s: Acquisition timeout.', obj.CurrentLabel)
                obj.abortAcquisition()
                image = zeros(obj.Config.XPixels, obj.Config.YPixels, "uint16");
                num_frames = 0;
                is_saturated = false;
                return
            end
            [image, num_frames, is_saturated] = obj.acquireImage(options.label);
            if options.verbose
                fprintf("%s: [%s] Acquisition completed in %.3f s.\n", obj.CurrentLabel, options.label, toc(timer))
            end
            if is_saturated
                warning('backtrace', 'off')
                warning("%s: [%s] Image is saturated.", obj.CurrentLabel, options.label)
                warning('backtrace', 'on')
            end
        end

        function [exposure_time, readout_time] = getTimings(obj)
            exposure_time = obj.Config.Exposure;
            readout_time = 0;
        end

        function [is_stable, temp, status] = checkTemperature(obj)
            is_stable = false;
            temp = nan;
            status = sprintf("Not implemented for this class %s", class(obj));
        end

        function label = getStatusLabel(obj)
            label = sprintf("%s", string(obj.ID));
        end

        function delete(obj)
            obj.close()
        end
    end

    methods (Access = protected, Hidden)
        function initCamera(obj)
            % Implement for each subclass
            try
                obj.ExampleImage = load(obj.ExampleLocation, "Data").Data.(obj.ID);
            catch
                warning("%s: Unable to load example images from %s.", obj.CurrentLabel, obj.ExampleLocation)
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
                    disp(label)
                    disp(size(obj.ExampleImage.(label), [1, 2]))
                    disp([obj.Config.XPixels, obj.Config.YPixels])
                    obj.ExampleImage = struct.empty;
                    break
                end
            end
        end

        function checkStatus(obj)
            if ~obj.Initialized
                error('%s: %s not initialized.', obj.CurrentLabel, class(obj))
            end
        end
    end

end
