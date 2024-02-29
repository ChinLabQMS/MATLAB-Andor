function closeAndor(serial)
    arguments
        serial = [19330, 19331]
    end

    [ret, NumCameras] = GetAvailableCameras();
    CheckWarning(ret)

    fprintf('\n******Shutting down CCD******\n\n')
    fprintf('Number of Cameras found: %d\n\n',NumCameras)

    for i = 1:NumCameras

        [ret,CameraHandle] = GetCameraHandle(i-1);
        CheckWarning(ret)
    
        [ret] = SetCurrentCamera(CameraHandle);
        CheckWarning(ret)
    
        [ret, Status] = GetStatus();
        CheckWarning(ret)
        
        if ret == atmcd.DRV_NOT_INITIALIZED
            fprintf('Camera %d (handle: %d) is NOT initialized. \n', ...
                    i, CameraHandle)
            continue
        end
    
        [ret, Number] = GetCameraSerialNumber();
        CheckWarning(ret)
        
        if ismember(Number, serial)
            fprintf('Closing Camera %d...\n',i)

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
            fprintf('Camera %d (serial: %d, handle: %d) is closed.\n', ...
                    i, Number, CameraHandle)
        else
            fprintf('Camera %d (serial: %d, handle: %d) is kept initialized. \n', ...
                    i, Number, CameraHandle)
        end
    end
    
end