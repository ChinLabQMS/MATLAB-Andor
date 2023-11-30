function shutDownCCD(serial)
    arguments
        serial = [19330, 19331];
    end

    [ret, NumCameras] = GetAvailableCameras();
    CheckWarning(ret)

    fprintf('\n******Shutting down CCD******\n')
    fprintf('\n\tNumber of Cameras found: %d\n\n',NumCameras)

    num_shutdown = 0;
    for i = 1:NumCameras
    
        % Set current camera
        [ret,CameraHandle] = GetCameraHandle(i-1);
        CheckWarning(ret)
    
        [ret] = SetCurrentCamera(CameraHandle);
        CheckWarning(ret)
    
        % Abort data acquisition
        [ret,Status] = GetStatus();
        CheckWarning(ret)
        
        if Status == 20072
            [ret] = AbortAcquisition;
            CheckWarning(ret)
        end
    
        % Close shutter
        [ret] = SetShutter(1, 2, 1, 1);
        CheckWarning(ret);
    
        % Temperature is maintained on shutting down.
        % 0 - Returns to ambient temperature on ShutDown
        % 1 - Temperature is maintained on ShutDown
        [ret] = SetCoolerMode(1);
        CheckWarning(ret)
    
        [ret, Number] = GetCameraSerialNumber();
        CheckWarning(ret)
        fprintf('\nSerial Number: %d\n',Number)
        
        if ismember(Number, serial)
            num_shutdown = num_shutdown + 1;
            fprintf('\nShutting down camera %d\n',Number)
            
            % Shut down current camera
            [ret] = AndorShutDown;
            CheckWarning(ret);

            fprintf(['Camera %d is shut down\n' ...
                'Temperature is maintained on shutting down.\n'],i) 
        end
    end
end