function Handle = getAndorHandle(serial, Handle, options)
    arguments
        serial
        Handle (1, 1) struct = struct()
        options.verbose = true
    end

    if isnumeric(serial)
        serial_str = ['Andor', char(serial)];
    else
        serial_str = serial;
        serial = str2double(serial(6:end));
    end

    if ~isfield(Handle, serial_str)
        Handle = getCameraHandle(Handle, 'verbose', options.verbose);
    end
    if ~isfield(Handle, serial_str)
        error('Could not find camera with serial number %d', serial)
    end
end

function Handle = getCameraHandle(Handle, options)
    arguments
        Handle
        options.verbose = true
    end
    [ret, NumCameras] = GetAvailableCameras();
    CheckWarning(ret)
    for i = 1:NumCameras    
        [ret, CameraHandle] = GetCameraHandle(i-1);
        CheckWarning(ret)    
        [ret] = SetCurrentCamera(CameraHandle);
        CheckWarning(ret)

        % Try to get camera serial number
        % Record the initial state of the camera
        initialized = true;        
        [ret, number] = GetCameraSerialNumber();
        if ret == atmcd.DRV_NOT_INITIALIZED
            % If camera is not initialized, initialize to get the serial number
            initialized = false;    
            [ret] = AndorInitialize(pwd);                      
            CheckWarning(ret)
            if ret == atmcd.DRV_SUCCESS
                [ret, number] = GetCameraSerialNumber();
                CheckWarning(ret)
            else
                % Unable to initialize a connected camera
                if options.verbose
                    warning('Camera %d is connected but can not be initialized, please check connections in other applications.\n',i)
                end
                continue
            end
        end
    
        % Return the initialized camera to its initial state
        if ~initialized
            % Temperature is maintained on shutting down.
            % 0 - Returns to ambient temperature on ShutDown
            % 1 - Temperature is maintained on ShutDown
            [ret] = SetCoolerMode(1);
            CheckWarning(ret)
            [ret] = AndorShutDown;
            CheckWarning(ret)
        end
        
        % Update stored Handle
        Handle.(['Andor', num2str(number)]) = CameraHandle;
    end
end