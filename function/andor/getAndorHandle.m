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
    end

    if ~isfield(Handle, serial_str)
        Handle = getCameraHandle(Handle, 'verbose',options.verbose);
        if ~isfield(Handle, serial_str)
            error('Could not find camera with serial number %d', serial_number)
        end
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

        % Record the initial state of the camera
        initialized = true;

        % Try to get camera serial number
        [ret, Number] = GetCameraSerialNumber();
        if ret == atmcd.DRV_NOT_INITIALIZED
            initialized = false;
    
            [ret] = AndorInitialize(pwd);                      
            CheckWarning(ret)
            if ret == atmcd.DRV_SUCCESS
                [ret, Number] = GetCameraSerialNumber();
                CheckWarning(ret)
            else
                if options.verbose
                    fprintf('Camera %d is not available, please check connections in other applications.\n',i)
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
        Handle.(['Andor', char(Number)]) = CameraHandle;
    end
end