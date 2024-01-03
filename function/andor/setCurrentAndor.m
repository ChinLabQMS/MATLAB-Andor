function setCurrentAndor(serial)
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
        
        if ret == atmcd.DRV_SUCCESS
            if Number == serial
                fprintf('Camera %d (Serial: %d, handle: %d) is set to current CCD\n',...
                    i, Number, CameraHandle)
                return
            end
        else
            warning('Camera %d (Serial: %d, handle: %d) is NOT initialized, can not obtain serial number\n', i, Number, CameraHandle)
        end
    end

    error('Serial number is not found, check CCD connections')
    
end