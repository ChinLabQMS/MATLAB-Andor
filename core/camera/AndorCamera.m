classdef AndorCamera < Camera
    %ANDORCAMERA AndorCamera class for Andor cameras.

    properties (SetAccess = protected, Hidden)
        CameraIndex = nan
        CameraHandle = nan
    end

    methods
        function obj = AndorCamera(serial_number, config)
            arguments
                serial_number {mustBeMember(serial_number, [19330, 19331])} = 19330
                config (1, 1) AndorCameraConfig = AndorCameraConfig()
            end
            obj@Camera(serial_number, config)
        end

        function startAcquisition(obj, options)
            arguments
                obj
                options.verbose (1, 1) logical = false
            end
            obj.abortAcquisition()
            [ret] = StartAcquisition();
            CheckWarning(ret)
            if options.verbose
                obj.info("Acquisition started.")
            end
        end

        function abortAcquisition(obj)
            obj.checkStatus()
            obj.setToCurrent()
            % Get status and abort acquisition if it is acquiring
            [ret, status] = GetStatus();
            CheckWarning(ret)
            if status == atmcd.DRV_ACQUIRING
                [ret] = AbortAcquisition();
                CheckWarning(ret)
                obj.info("Acquisition aborted.")
            end
            % Free internal memory
            [ret] = FreeInternalMemory();
            CheckWarning(ret)
        end

        function [ret, status] = getStatus(obj)
            obj.checkStatus()
            obj.setToCurrent()
            [ret, status] = GetStatus();
            CheckWarning(ret)
            CheckWarning(status)
        end

        function [num_available, first, last] = getNumberNewImages(obj)
            obj.checkStatus()
            obj.setToCurrent()
            [ret, status] = GetStatus();
            CheckWarning(ret)
            if status == atmcd.DRV_ACQUIRING
                num_available = 0;
                first = 0;
                last = 0;
                return
            end
            [ret, first, last] = GetNumberAvailableImages();
            if ret == atmcd.DRV_SUCCESS
                num_available = last - first + 1;
            elseif ret == atmcd.DRV_NO_NEW_DATA
                num_available = 0;
            else
                CheckWarning(ret)
                obj.error("Unable to get number of available images.")
            end
        end

        function [exposure_time, readout_time, keep_clean_time] = getTimings(obj)
            obj.checkStatus()
            obj.setToCurrent()
            if obj.Config.FastKinetic
                [ret, exposure_time] = GetFKExposureTime();
                CheckWarning(ret)
            else
                [ret, exposure_time] = GetAcquisitionTimings();
                CheckWarning(ret)
            end
            [ret, readout_time] = GetReadOutTime();
            CheckWarning(ret)
            [ret, keep_clean_time] = GetKeepCleanTime();
            CheckWarning(ret)
            obj.info("Readout time = %g s, Exposure time = %g s, Keep clean time = %g s", readout_time, exposure_time, keep_clean_time)
        end

        function [is_stable, temperature, status] = checkTemperature(obj)
            obj.setToCurrent()
            [ret, temperature] = GetTemperatureF();
            is_stable = ret == atmcd.DRV_TEMPERATURE_STABILIZED;
            switch ret
                case atmcd.DRV_NOT_INITIALIZED
                    status = 'Camera is not initialized.';
                case atmcd.DRV_TEMPERATURE_STABILIZED
                    status = 'Temperature has stabilized at set point.';
                case atmcd.DRV_TEMP_NOT_REACHED
                    status = 'Temperature has not reached set point.';
                case atmcd.DRV_TEMP_DRIFT
                    status = 'Temperature had stabilised but has since drifted.';
                case atmcd.DRV_TEMP_NOT_STABILIZED
                    status = 'Temperature reached but not stabilized.';
                case atmcd.DRV_TEMPERATURE_OFF
                    status = 'Temperature control is turned off.';
                otherwise
                    status = sprintf('Unknown status (%d)', ret);
            end
            obj.info('Current temperature = %g C, Status = %s', temperature, status)
        end

        function checkTemperatureUntilStable(obj, options)
            arguments
                obj
                options.refresh (1, 1) double = 5
                options.timeout (1, 1) double = 300
            end
            timer = tic;
            while ~obj.checkTemperature() && toc(timer) < options.timeout
                pause(options.refresh)
            end
        end
    end

    methods (Access = protected, Hidden)
        function initCamera(obj)
            if isnan(obj.CameraIndex)
                % Find all connected cameras
                [ret, num_cameras] = GetAvailableCameras();
                CheckWarning(ret)
                i_range = 1:num_cameras;
            else
                i_range = obj.CameraIndex;
            end
            missing_camera = false(size(i_range));
            for i = i_range
                [ret, camera_handle] = GetCameraHandle(i-1);
                CheckWarning(ret)
                [ret] = SetCurrentCamera(camera_handle);
                CheckWarning(ret)                           
                % Try to get camera serial number
                % Record the initial state of the camera
                [ret, serial_number] = GetCameraSerialNumber();
                if ret == atmcd.DRV_NOT_INITIALIZED
                    % If camera is not initialized, initialize to get the serial number
                    initialized = false;
                    [ret] = AndorInitialize(pwd);
                    CheckWarning(ret)
                    if ret == atmcd.DRV_SUCCESS
                        [ret, serial_number] = GetCameraSerialNumber();
                        CheckWarning(ret)
                    else
                        % Unable to initialize a connected camera
                        missing_camera(i) = true;
                        continue
                    end
                else
                    % Camera is already initialized
                    initialized = true;
                end
                % If the connected initialized camera is the one to initialize
                if serial_number == obj.ID
                    obj.CameraIndex = i;
                    obj.CameraHandle = camera_handle;
                    obj.Initialized = true;
                    break
                end
                % If the camera is not the one, return to previous state
                if ~initialized
                    % Temperature is maintained on shutting down.
                    % 0 - Returns to ambient temperature on ShutDown
                    % 1 - Temperature is maintained on ShutDown
                    [ret] = SetCoolerMode(1);
                    CheckWarning(ret)
                    [ret] = AndorShutDown;
                    CheckWarning(ret)
                end
            end
            % If camera with specific identifier is not found, raise error
            if ~obj.Initialized
                warning('off', 'backtrace')
                for i = 1:length(missing_camera)
                    if missing_camera(i)
                        warning('AndorCamera (index: %d) is connected but failed to initialize, please check if remaining connection in other applications.', i)
                    end
                end
                warning('on', 'backtrace')
                obj.error('Camera with serial number %d initialization failed.', obj.ID)
            end             
            % Basic config
            [ret] = SetTemperature(-70);
            CheckWarning(ret)
            [ret] = CoolerON();
            CheckWarning(ret)
            [ret] = FreeInternalMemory();
            CheckWarning(ret)
            [ret] = SetShutter(1, 1, 0, 0);
            CheckWarning(ret)
            [ret] = SetBaselineClamp(0);          
            CheckWarning(ret)
            % Set Pre-Amp Gain, 0 (1x), 1 (2x), 2 (4x).
            [ret] = SetPreAmpGain(2);
            CheckWarning(ret)
        end

        function closeCamera(obj)
            % Temperature is maintained on shutting down.
            % 0 - Returns to ambient temperature on ShutDown
            % 1 - Temperature is maintained on ShutDown
            [ret] = SetCoolerMode(1);
            CheckWarning(ret)
            [ret] = AndorShutDown;
            CheckWarning(ret)
            if ret ~= atmcd.DRV_SUCCESS
                obj.error('Unable to close.')
            end
        end
        
        function applyConfig(obj, varargin)
            % Set Crop mode. 1 = ON/0 = OFF; Crop height; Crop width; Vbin; Hbin
            [ret] = SetIsolatedCropMode(double(obj.Config.Cropped), obj.Config.XPixels, obj.Config.YPixels, 1, 1);
            CheckWarning(ret)
            if obj.Config.FastKinetic
                % Set acquisition mode; 4 for fast kinetics
                [ret] = SetAcquisitionMode(4);
                CheckWarning(ret)
                % Configure fast kinetics mode acquisition
                % (exposed rows, series length, exposure, 4 for Image, horizontal binning, vertical binning, offset)
                [ret] = SetFastKineticsEx(obj.Config.FastKineticExposedRows, ...
                                          obj.Config.FastKineticSeriesLength, ...
                                          obj.Config.Exposure, ...
                                          4, 1, 1, ...
                                          obj.Config.FastKineticOffset);
                CheckWarning(ret)
                % Set Fast Kinetic vertical shift speed
                [ret] = SetFKVShiftSpeed(obj.Config.VSSpeed);
                CheckWarning(ret)
            else
                % Set acquisition mode; 1 for Image
                [ret] = SetAcquisitionMode(1);
                CheckWarning(ret)
                % Set exposure time
                [ret] = SetExposureTime(obj.Config.Exposure);
                CheckWarning(ret)
            end
            % Get detector size (with croped mode ON this may change)
            [ret, YPixels, XPixels] = GetDetector();
            CheckWarning(ret)
            % Set the image size
            [ret] = SetImage(1, 1, 1, YPixels, 1, XPixels);
            CheckWarning(ret)
            obj.Config.XPixels = XPixels;
            obj.Config.YPixels = YPixels;
            % Set read mode; 4 for Image
            [ret] = SetReadMode(4);
            CheckWarning(ret)
            % Set trigger mode; 0 for internal, 1 for external
            [ret] = SetTriggerMode(double(obj.Config.ExternalTrigger));
            CheckWarning(ret)
            % Set horizontal speed
            [ret] = SetHSSpeed(0, obj.Config.HSSpeed);
            CheckWarning(ret)
            % Set vertical speed
            [ret] = SetVSSpeed(obj.Config.VSSpeed);
            CheckWarning(ret)
        end

        function [image, num_available, is_saturated] = acquireImage(obj, label)
            [num_available, first, last] = obj.getNumberNewImages();
            if num_available == 0
                image = zeros(obj.Config.XPixels, obj.Config.YPixels, "uint16");
                is_saturated = false;
                return
            end
            [ret, ImgData, ~, ~] = GetImages16(first, last, obj.Config.YPixels*obj.Config.XPixels);
            CheckWarning(ret)
            if ret ~= atmcd.DRV_SUCCESS
                obj.error("[%s] Unable to acquire image.", label)
            end
            image = uint16(flip(transpose(reshape(ImgData, obj.Config.YPixels, obj.Config.XPixels)), 1));
            is_saturated = any(image(:) == obj.Config.MaxPixelValue);
        end

        function setToCurrent(obj)
            if ~isnan(obj.CameraHandle)
                [ret] = SetCurrentCamera(obj.CameraHandle);
                CheckWarning(ret)
            else
                obj.error('Camera handle is not set.')
            end
        end
    end

end
