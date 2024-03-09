function closeAndor(serial, Handle, options)
    arguments
        serial = [19330, 19331]
        Handle (1, 1) struct = struct()
        options.verbose (1, 1) logical = true
    end

    [ret, NumCameras] = GetAvailableCameras();
    CheckWarning(ret)
    
    if options.verbose
        fprintf('\n******Shutting down CCD******\n\n')
        fprintf('Number of Cameras found: %d\n\n',NumCameras)
    end

    for serial_number = serial
        serial_str = ['Andor', num2str(serial_number)];
        Handle = getAndorHandle(serial_str, Handle, "verbose",options.verbose);

        [ret] = SetCurrentCamera(Handle.(serial_str));
        CheckWarning(ret)
    
        [ret, Status] = GetStatus();
        if ret == atmcd.DRV_NOT_INITIALIZED
            if options.verbose
                fprintf('Camera (serial: %d, handle: %d) is NOT initialized. \n', ...
                        serial_number, Handle.(serial_str))
            end
            continue
        end

        % Abort data acquisition
        if Status == atmcd.DRV_ACQUIRING
            [ret] = AbortAcquisition;
            CheckWarning(ret)
        end

        % Close shutter
        [ret] = SetShutter(1, 2, 1, 1);
        CheckWarning(ret)

        % Temperature is maintained on shutting down.
        % 0 - Returns to ambient temperature on ShutDown
        % 1 - Temperature is maintained on ShutDown
        [ret] = SetCoolerMode(1);
        CheckWarning(ret)

        [ret] = AndorShutDown;
        CheckWarning(ret)

        if options.verbose
            fprintf('Camera (serial: %d, handle: %d) is closed.\n', ...
                    serial_number, Handle.(serial_str))
        end
    end    
end