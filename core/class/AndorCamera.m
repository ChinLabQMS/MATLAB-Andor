classdef AndorCamera < Camera
    %ANDORCAMERA AndorCamera class

    properties (SetAccess=private)
        Initialized = false
        ExternalTrigger = true
        Exposure = nan
        ImageSizeX = 1024
        ImageSizeY = 1024
        SerialNumber {mustBeMember(SerialNumber, [19330, 19331])}
        CameraIndex (1, 1) double = nan
        CameraHandle (1, 1) double = nan
        Cropped (1, 1) logical = false
        FastKinetic (1, 1) logical = false
        FastKineticSeriesLength (1, 1) double {mustBePositive, mustBeInteger} = 2
        FastKineticExposedRows (1, 1) double {mustBePositive, mustBeInteger} = 512
        FastKineticOffset (1, 1) double {mustBePositive, mustBeInteger} = 512
        HSSpeed (1, 1) double = nan
        VSSpeed (1, 1) double = nan
    end
    properties (Dependent)
        HSSpeedStr (1, 1) string
        VSSpeedStr (1, 1) string
    end

    methods
        function obj = AndorCamera(serial_number, options)
            arguments
                serial_number (1, 1) double
                options.verbose (1, 1) logical = true
            end
            obj.SerialNumber = serial_number;
            obj = obj.init('verbose', options.verbose);
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
                
                % If the connected camera is the one to initialize
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
            
            obj = obj.abortAcquisition('verbose', options.verbose);
            
            % Basic config
            [ret, obj.ImageSizeX, obj.ImageSizeY] = GetDetector();
            CheckWarning(ret)
            [ret] = SetTemperature(-70);
            CheckWarning(ret)
            [ret] = CoolerON();
            CheckWarning(ret)
            [ret] = FreeInternalMemory();
            CheckWarning(ret)

            if options.verbose
                if obj.Initialized
                    fprintf('Camera (index: %d, handle: %d, serial#: %d) is initialized.\n', ...
                            obj.CameraIndex, obj.CameraHandle, obj.SerialNumber)
                else
                    warning('off', 'backtrace')
                    warning('Camera (serial#: %d) initialization fails.', obj.SerialNumber)
                    for i = 1:size(missing_camera, 1)
                        if missing_camera(i)
                            warning('Camera (index: %d) is connected but failed to initialize, please check if there are connections in other applications.', i)
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
                obj = obj.abortAcquisition("verbose", options.verbose);
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
                    fprintf('Camera (index: %d, handle: %d, serial#: %d) is closed\n', ...
                            obj.CameraIndex, obj.CameraHandle, obj.SerialNumber)
                end
            end
        end
        
        function obj = abortAcquisition(obj, options)
            arguments
                obj
                options.verbose (1, 1) logical = true
            end
            if ~obj.Initialized
                return
            end
            % Get status and abort acquisition if it is acquiring
            [ret] = SetCurrentCamera(obj.CameraHandle);
            CheckWarning(ret)
            [ret, status] = GetStatus();
            CheckWarning(ret)
            if status == atmcd.DRV_ACQUIRING
                [ret] = AbortAcquisition();
                CheckWarning(ret)
                if options.verbose
                    fprintf('Camera (index: %d, handle: %d, serial#: %d): Acquisition aborted\n', ...
                        obj.CameraIndex, obj.CameraHandle, obj.SerialNumber)
                end
            end
        end
    
        function [temperature, status] = checkTemperature(obj, options)
            arguments
                obj
                options.verbose (1, 1) logical = true
            end
            if ~obj.Initialized
                return
            end
            [ret] = SetCurrentCamera(obj.CameraHandle);
            CheckWarning(ret)
            [ret, temperature] = GetTemperatureF();    
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
                fprintf('Camera (index: %d, handle: %d, serial#: %d):\n\tCurrent temperature: %g C\n\tStatus: %s\n', ...
                        obj.CameraIndex, obj.CameraHandle, obj.SerialNumber, ...
                        temperature, status)
            end
        end

        function obj = config(obj, options)
        end

        function obj = configFK(obj, options)
            arguments
                obj (1, 1) AndorCamera
                options.verbose (1, 1) logical = true
            end
        end
        
        function image = acquireImage(obj)
        end

        function val = get.HSSpeedStr(obj)
            if ~obj.Initialized || isnan(obj.HSSpeed)
                val = 'NaN';
            else
                [ret, speed] = GetHSSpeed(0, 0, obj.HSSpeed);
                CheckWarning(ret)
                val = string(strcat(num2str(speed), ' MHz'));
            end
        end
        
        function val = get.VSSpeedStr(obj)
            if ~obj.Initialized || isnan(obj.VSSpeed)
                val = 'NaN';
            else
                [ret, speed] = GetVSSpeed(0, 0, obj.VSSpeed);
                CheckWarning(ret)
                val = string(strcat(num2str(speed), ' us'));
            end
        end
    end
end
