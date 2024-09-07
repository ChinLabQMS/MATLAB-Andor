classdef AndorCamera < Camera
    %ANDORCAMERA AndorCamera class

    properties (SetAccess = private)
        Initialized = false
        CameraLabel = 'Andor'
        CameraConfig = AndorCameraConfig()
        SerialNumber {mustBeMember(SerialNumber, [19330, 19331])}
        CameraIndex (1, 1) double = nan
        CameraHandle (1, 1) double = nan
    end

    properties (Dependent)
        CurrentLabel
    end

    methods
        function obj = AndorCamera(serial_number, options)
            arguments
                serial_number (1, 1) double
                options.verbose (1, 1) logical = true
            end
            obj.SerialNumber = serial_number;
            obj.CameraLabel = sprintf('Andor%d', obj.SerialNumber);
            obj = obj.init('verbose', options.verbose);
            obj = obj.config();
        end

        function obj = init(obj, options)
            arguments
                obj
                options.verbose (1, 1) logical = true
            end
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
                    initialized = true;
                end
                
                % If the connected initialized camera is the one to initialize
                if serial_number == obj.SerialNumber
                    obj.CameraIndex = i;
                    obj.CameraHandle = camera_handle;
                    obj.Initialized = true;
                    CheckWarning(ret)
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
            obj.abortAcquisition("verbose", options.verbose)
                        
            % Basic config
            [ret] = SetTemperature(-70);
            CheckWarning(ret)
            [ret] = CoolerON();
            CheckWarning(ret)
            [ret] = FreeInternalMemory();
            CheckWarning(ret)
            [ret] = SetAcquisitionMode(1);
            CheckWarning(ret)
            [ret] = SetReadMode(4);
            CheckWarning(ret)
            [ret] = SetTriggerMode(1);                      
            CheckWarning(ret)
            [ret] = SetShutter(1, 1, 0, 0);
            CheckWarning(ret)
            [ret, XPixels, YPixels] = GetDetector();
            CheckWarning(ret)            
            [ret] = SetImage(1, 1, 1, XPixels, 1, YPixels);
            CheckWarning(ret)
            [ret] = SetBaselineClamp(0);          
            CheckWarning(ret)
            % Set Pre-Amp Gain, 0 (1x), 1 (2x), 2 (4x).
            [ret] = SetPreAmpGain(2);
            CheckWarning(ret)
            % Set Horizontal speed. (0,0) = 5 MHz, (0,1) = 3 MHz, (0,2) = 1 MHz, (0,3) = 50 kHz
            [ret] = SetHSSpeed(0, 2);
            CheckWarning(ret)
            % Set Vertical Shift speed. 0 = 2.25 us, 1 = 4.25 us, 2 = 8.25 us, 3 = 16.25 us, 4 = 32.25 us, 5 = 64.25 us
            [ret] = SetVSSpeed(1);
            CheckWarning(ret)
            [ret] = EnableKeepCleans(1);
            CheckWarning(ret)

            obj.CameraConfig.XPixels = XPixels;
            obj.CameraConfig.YPixels = YPixels;

            if options.verbose
                if obj.Initialized
                    fprintf('%s: Camera initialized.\n', obj.CurrentLabel)
                else
                    warning('off', 'backtrace')
                    warning('%s initialization fails.', obj.CurrentLabel)
                    for i = 1:size(missing_camera, 1)
                        if missing_camera(i)
                            warning('AndorCamera (index: %d) is connected but failed to initialize, please check if there are connections in other applications.', i)
                        end
                    end
                    warning('on', 'backtrace')
                end
            end
        end

        function obj = close(obj, options)
            arguments
                obj
                options.verbose (1, 1) logical = true
            end
            if obj.Initialized
                % Select the current camera and abort acquisition
                obj.abortAcquisition("verbose", options.verbose);
                % Temperature is maintained on shutting down.
                % 0 - Returns to ambient temperature on ShutDown
                % 1 - Temperature is maintained on ShutDown
                [ret] = SetCoolerMode(1);
                CheckWarning(ret)
                [ret] = AndorShutDown;
                CheckWarning(ret)
                if ret == atmcd.DRV_SUCCESS
                    obj.Initialized = false;
                end
                if options.verbose && ~obj.Initialized
                    fprintf('%s: Camera closed\n', obj.CurrentLabel)
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
            % Configure camera settings
            arg_len = length(name);
            for i = 1:arg_len
                obj.CameraConfig.(name{i}) = value{i};
            end
            % Apply the settings, set current camera and abort acquisition
            obj.abortAcquisition()
            % Set Crop mode. 1 = ON/0 = OFF; Crop height; Crop width; Vbin; Hbin
            [ret] = SetIsolatedCropMode(double(obj.CameraConfig.Cropped), obj.CameraConfig.XPixels, obj.CameraConfig.YPixels, 1, 1);
            CheckWarning(ret)
            % Get detector size (with croped mode ON this may change)
            [ret, YPixels, XPixels] = GetDetector();
            CheckWarning(ret)
            % Set the image size
            [ret] = SetImage(1, 1, 1, YPixels, 1, XPixels);
            CheckWarning(ret)
            if obj.CameraConfig.FastKinetic
                % Set acquisition mode; 4 for fast kinetics
                [ret] = SetAcquisitionMode(4);
                CheckWarning(ret)
                % Configure fast kinetics mode acquisition
                % (exposed rows, series length, exposure, 4 for Image, horizontal binning, vertical binning, offset)
                [ret] = SetFastKineticsEx(obj.CameraConfig.FastKineticExposedRows, ...
                                          obj.CameraConfig.FastKineticSeriesLength, ...
                                          obj.CameraConfig.Exposure, ...
                                          4, 1, 1, ...
                                          obj.CameraConfig.FastKineticOffset);
                CheckWarning(ret)
                % Set Fast Kinetic vertical shift speed
                [ret] = SetFKVShiftSpeed(obj.CameraConfig.VSSpeed);
                CheckWarning(ret)
            else
                % Set acquisition mode; 1 for Image
                [ret] = SetAcquisitionMode(1);
                CheckWarning(ret)
                % Set exposure time
                [ret] = SetExposureTime(obj.CameraConfig.Exposure);
                CheckWarning(ret)
            end
            % Set trigger mode; 0 for internal, 1 for external
            [ret] = SetTriggerMode(double(obj.CameraConfig.ExternalTrigger));
            CheckWarning(ret)
            % Set horizontal speed
            [ret] = SetHSSpeed(0, obj.CameraConfig.HSSpeed);
            CheckWarning(ret)
            % Set vertical speed
            [ret] = SetVSSpeed(obj.CameraConfig.VSSpeed);
            CheckWarning(ret)
        end

        function startAcquisition(obj, options)
            arguments
                obj
                options.verbose (1, 1) logical = true
            end
            obj.abortAcquisition('verbose', options.verbose)
            [ret] = StartAcquisition();
            CheckWarning(ret)
            if options.verbose
                fprintf('%s: Acquisition started\n', obj.CurrentLabel)
            end
        end

        function abortAcquisition(obj, options)
            arguments
                obj
                options.verbose (1, 1) logical = true
            end
            obj.setToCurrent()
            % Get status and abort acquisition if it is acquiring
            [ret, status] = GetStatus();
            CheckWarning(ret)
            if status == atmcd.DRV_ACQUIRING
                [ret] = AbortAcquisition();
                CheckWarning(ret)
                if options.verbose
                    fprintf('%s: Acquisition aborted\n', obj.CurrentLabel)
                end
            end
            % Free internal memory
            [ret] = FreeInternalMemory();
            CheckWarning(ret)
        end

        function is_acquiring = isAcquiring(obj)
            obj.setToCurrent()
            [ret, status] = GetStatus();
            CheckWarning(ret)
            is_acquiring = status == atmcd.DRV_ACQUIRING;
        end
        
        function [image, num_frames, is_saturated] = getImage(obj, options)
            arguments
                obj
                options.verbose (1, 1) logical = false
            end
            if obj.isAcquiring()
                if options.verbose
                    warning('%s: Camera is acquiring, please wait for acquisition to finish.', obj.CurrentLabel)
                end
                num_frames = 0;
                image = [];
                is_saturated = false;
                return
            end
            [ret, first, last] = GetNumberAvailableImages();
            CheckWarning(ret)
            [ret, ImgData, ~, ~] = GetImages16(first, last, obj.CameraConfig.YPixels*obj.CameraConfig.XPixels);
            CheckWarning(ret)
            num_frames = last - first + 1;
            image = uint16(flip(transpose(reshape(ImgData, obj.CameraConfig.YPixels, obj.CameraConfig.XPixels)), 1));
            is_saturated = any(image(:) == obj.CameraConfig.MaxPixelValue);
        end

        function [exposure_time, readout_time, keep_clean_time] = getTimings(obj, options)
            arguments
                obj
                options.verbose (1, 1) logical = true
            end
            obj.abortAcquisition()
            if obj.CameraConfig.FastKinetic
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
            if options.verbose
                fprintf('%s: Readout time = %g s, Exposure time = %g s, Keep clean time = %g s\n', ...
                        obj.CurrentLabel, readout_time, exposure_time, keep_clean_time)
            end
        end

        function [is_stable, temperature, status] = checkTemperature(obj, options)
            arguments
                obj
                options.verbose (1, 1) logical = true
            end
            obj.setToCurrent()
            [ret, temperature] = GetTemperatureF();
            is_stable = ret == atmcd.DRV_TEMPERATURE_STABILIZED;
            switch ret
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
            if options.verbose
                fprintf('%s: Current temperature = %g C, Status = %s\n', ...
                        obj.CurrentLabel, temperature, status)
            end
        end

        function camera_name = get.CurrentLabel(obj)
            camera_name = string(sprintf('[%s] AndorCamera (index: %d, handle: %d, serial#: %d)', ...
                                 datetime("now", "Format", "uuuu-MMM-dd HH:mm:ss"), ...
                                 obj.CameraIndex, obj.CameraHandle, obj.SerialNumber));                
        end

    end

    methods (Access = private, Hidden)
        function setToCurrent(obj)
            if ~obj.Initialized
                if isnan(obj.CameraHandle)
                    error('%s: Camera is not initialized.', obj.CurrentLabel)
                else
                    obj = obj.init();
                end
            end
            [ret] = SetCurrentCamera(obj.CameraHandle);
            CheckWarning(ret)
        end
    end

end
