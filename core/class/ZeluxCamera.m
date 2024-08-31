classdef ZeluxCamera < Camera
    %ZELUXCAMERA Zelux camera class
    
    properties (SetAccess = private)
        Initialized = false;
        CameraConfig = ZeluxCameraConfig()
        CameraIndex (1, 1) double = 0
        CameraSDK = nan
        CameraHandle = nan
    end

    properties (Dependent)
        CameraLabel
    end
    
    methods
        function obj = ZeluxCamera(index, options)
            arguments
                index (1, 1) double = 0
                options.verbose (1, 1) logical = true
            end
            % Load TLCamera DotNet assembly.
            % The assembly .dll is assumed to be in the same folder as the scripts.
            old_path = cd("dlls/");
            NET.addAssembly([pwd, '/Thorlabs.TSI.TLCamera.dll']);
            try
                obj.CameraSDK = Thorlabs.TSI.TLCamera.TLCameraSDK.OpenTLCameraSDK;
            catch
                cd(old_path)
                error('Unable to load SDK, check if the camera is already initialized.')
            end
            cd(old_path)

            obj.CameraIndex = index;
            obj = obj.init('verbose', options.verbose);
            obj = obj.config();
        end
        
        function obj = init(obj, options)
            arguments
                obj
                options.verbose (1, 1) logical = true
            end
            % Get serial numbers of connected TLCameras.
            if ~obj.Initialized
                serialNumbers = obj.CameraSDK.DiscoverAvailableCameras;
                if serialNumbers.Count - 1 < obj.CameraIndex
                    error('%s: Camera index out of range. Number of cameras found: %d', obj.CameraLabel, serialNumbers.Count)
                end
                obj.CameraHandle = obj.CameraSDK.OpenCamera(serialNumbers.Item(obj.CameraIndex), false);
                obj.CameraConfig.XPixels = obj.CameraHandle.ImageHeight_pixels;
                obj.CameraConfig.YPixels = obj.CameraHandle.ImageWidth_pixels;
                obj.Initialized = true;
                if options.verbose
                    fprintf('%s: Camera initialized.\n', obj.CameraLabel)
                end
            end
        end

        function close(obj, options)
            arguments
                obj
                options.verbose (1, 1) logical = true
            end
            if obj.Initialized
                obj.abortAcquisition();
                obj.CameraHandle.Dispose;
                obj.CameraSDK.Dispose;
                obj.Initialized = false;
                obj.CameraHandle = nan;
                obj.CameraSDK = nan;
                if options.verbose
                    fprintf('%s: Camera closed.\n', obj.CameraLabel)
                end
            end
        end

        function obj = config(obj, name, value)
            arguments
                obj
            end
            arguments (Repeating)
                name
                value
            end
            if ~obj.Initialized
                error('%s: Camera not initialized.', obj.CameraLabel)
            end
            for i = 1:length(name)
                obj.CameraConfig.(name{i}) = value{i};
            end
            obj.CameraHandle.ExposureTime_us = obj.CameraConfig.Exposure * 1e6;
            if obj.CameraConfig.ExternalTrigger
                obj.CameraHandle.OperationMode = Thorlabs.TSI.TLCameraInterfaces.OperationMode.HardwareTriggered;
            else
                obj.CameraHandle.OperationMode = Thorlabs.TSI.TLCameraInterfaces.OperationMode.SoftwareTriggered;
            end
            obj.CameraHandle.FramesPerTrigger_zeroForUnlimited = 1;
        end

        function startAcquisition(obj)
            % Put the camera in armed state, ready to receive trigger.
            if ~obj.CameraHandle.IsArmed
                obj.CameraHandle.Arm;
            end
            % Issue a software trigger if triggered internally.
            if ~obj.CameraConfig.ExternalTrigger
                obj.CameraHandle.IssueSoftwareTrigger;
            end
        end

        function abortAcquisition(obj)
            if obj.CameraHandle.IsArmed
                obj.CameraHandle.Disarm;
            end
        end

        function [image, num_frames] = getImage(obj, options)
            arguments
                obj
                options.verbose (1, 1) logical = false
            end
            if ~obj.Initialized
                error('%s: Camera not initialized.', obj.CameraLabel)
            end
            num_frames = obj.CameraHandle.NumberOfQueuedFrames;
            if num_frames == 0
                if options.verbose
                    warning('%s: No image frame available.', obj.CameraLabel)
                end
                image = [];
                return
            end
            if num_frames > 1
                warning('%s: Data processing falling behind acquisition. %d remains.', obj.CameraLabel, obj.CameraHandle.NumberOfQueuedFrames)
            end
            imageFrame = obj.CameraHandle.GetPendingFrameOrNull;
            image = reshape(uint16(imageFrame.ImageData.ImageData_monoOrBGR), [obj.CameraConfig.XPixels, obj.CameraConfig.YPixels]);
            if options.verbose
                fprintf('%s: Image acquired, frame number: %d\n', obj.CameraLabel, imageFrame.FrameNumber)
            end
        end

        function camera_label = get.CameraLabel(obj)
            camera_label = string(sprintf('[%s] ZeluxCamera (index: %d)', ...
                datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss"), obj.CameraIndex));
        end

    end
end