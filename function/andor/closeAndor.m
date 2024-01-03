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
        
        if ret == 20075
            fprintf('Camera %d is NOT initialized. \n', i)
            continue
        end

        % Abort data acquisition
        if Status == 20072
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
    
        [ret, Number] = GetCameraSerialNumber();
        CheckWarning(ret)
        
        if ismember(Number, serial)
            fprintf('Shutting down camera %d. Serial number: %d\nTemperature is maintained on shutting down\n', ...
                    i, Number)
            [ret] = AndorShutDown;
            CheckWarning(ret)
        else
            fprintf('Camera %d is initialized but NOT shutting down. Serial number: %d\n',i, Number)
        end
    end

end