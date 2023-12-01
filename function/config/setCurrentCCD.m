function setCurrentCCD(serial)
    arguments
        serial (1,1) double = 19330
    end

    [ret, NumCameras] = GetAvailableCameras();
    CheckWarning(ret)

    for i = 1: NumCameras
        [ret,CameraHandle] = GetCameraHandle(i-1);
        CheckWarning(ret)
    
        [ret] = SetCurrentCamera(CameraHandle);
        CheckWarning(ret)

        [ret, Number] = GetCameraSerialNumber();
        CheckWarning(ret)
        
        if ret == 20002
            if Number == serial
                fprintf('\nCamera %d (Serial: %d) is set to current CCD\n',i, Number)
                return
            end
        else
            fprintf('\nCamera %d is NOT initialized: %d\n', i, Number)
        end
    end

    error('Serial number is not found, check CCD connections')
    
end