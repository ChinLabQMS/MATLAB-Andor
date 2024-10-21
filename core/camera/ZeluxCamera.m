classdef ZeluxCamera < Camera
    %ZELUXCAMERA Zelux camera class.
    
    properties (SetAccess = protected, Hidden)
        CameraSDK
        CameraHandle
        FrameIndex
    end
    
    methods
        function obj = ZeluxCamera(index, config)
            arguments
                index (1, 1) double = 0
                config (1, 1) ZeluxCameraConfig = ZeluxCameraConfig()
            end
            obj@Camera(index, config)
        end

        function num_frames = getNumberNewImages(obj)
            num_frames = double(obj.CameraHandle.NumberOfQueuedFrames);
        end

        function [exposure_time, readout_time] = getTimings(obj)
            obj.checkInitialized()
            exposure_time = double(obj.CameraHandle.ExposureTime_us) * 1e-6;
            readout_time = double(obj.CameraHandle.FrameTime_us) * 1e-6;
            obj.info('Readout time = %.3g s, Exposure time = %.2g s', readout_time, exposure_time)
        end
    end

    methods (Access = protected, Hidden)
        function initCamera(obj)
            % Load TLCamera DotNet assembly.
            % The assembly .dll is assumed to be in the same folder as the scripts.
            old_path = cd("dlls/");
            NET.addAssembly([pwd, '/Thorlabs.TSI.TLCamera.dll']);
            try
                obj.CameraSDK = Thorlabs.TSI.TLCamera.TLCameraSDK.OpenTLCameraSDK;
            catch
                cd(old_path)
                obj.error('Unable to load SDK, check if the camera is already initialized.')
            end
            cd(old_path)
            % Get serial numbers of connected TLCameras.
            serialNumbers = obj.CameraSDK.DiscoverAvailableCameras;
            if serialNumbers.Count - 1 < obj.ID
                obj.error('Camera index out of range. Number of cameras found: %d', serialNumbers.Count)
            end
            obj.CameraHandle = obj.CameraSDK.OpenCamera(serialNumbers.Item(obj.ID), false);
            obj.Config.XPixels = obj.CameraHandle.ImageWidth_pixels;
            obj.Config.YPixels = obj.CameraHandle.ImageHeight_pixels;
            obj.FrameIndex = 0;
        end

        function closeCamera(obj)
            obj.CameraHandle.Dispose;
            obj.CameraSDK.Dispose;
        end

        function applyConfig(obj)
            obj.CameraHandle.ExposureTime_us = obj.Config.Exposure * 1e6;
            if obj.Config.ExternalTrigger
                obj.CameraHandle.OperationMode = Thorlabs.TSI.TLCameraInterfaces.OperationMode.HardwareTriggered;
            else
                obj.CameraHandle.OperationMode = Thorlabs.TSI.TLCameraInterfaces.OperationMode.SoftwareTriggered;
            end
            obj.CameraHandle.MaximumNumberOfFramesToQueue = obj.Config.MaxQueuedFrames;
            obj.CameraHandle.FramesPerTrigger_zeroForUnlimited = 1;
        end

        function startAcquisitionCamera(obj)
            % Put the camera in armed state, ready to receive trigger.
            if ~obj.CameraHandle.IsArmed
                obj.CameraHandle.Arm;
                obj.info("Camera armed.")
            end
            % Issue a software trigger if triggered internally.
            if ~obj.Config.ExternalTrigger
                obj.CameraHandle.IssueSoftwareTrigger;
            end
        end

        function abortAcquisitionCamera(obj)
            if obj.CameraHandle.IsArmed
                obj.CameraHandle.Disarm;
                obj.FrameIndex = 0;
                obj.info("Camera disarmed.")
            end
        end

        function [image, status] = acquireImage(obj, label)
            image_frame = obj.CameraHandle.GetPendingFrameOrNull;
            image = reshape(uint16(image_frame.ImageData.ImageData_monoOrBGR), [obj.Config.XPixels, obj.Config.YPixels]);
            OldFrameIndex = obj.FrameIndex;
            obj.FrameIndex = image_frame.FrameNumber;
            if obj.FrameIndex > OldFrameIndex + 1
                obj.warn2('[%s] Dropped frame detected.', label)
                status = "dropped";
            end
        end

        % Override the default getStatusLabel method from Camera
        function label = getStatusLabel(obj)
            label = sprintf("%s%d(Index: %d)", class(obj), obj.ID, obj.FrameIndex);
        end
    end
    
end
