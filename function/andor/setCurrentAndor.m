function setCurrentAndor(serial)
    arguments
        serial = 19330
    end
    if isstring(serial) || ischar(serial)
        serial = str2double(serial(6:end));
    end

    [ret, NumCameras] = GetAvailableCameras();
    CheckWarning(ret)
    fprintf('Number of Cameras found: %d\n\n',NumCameras)

    for i = 1: NumCameras
        [ret,CameraHandle] = GetCameraHandle(i-1);
        CheckWarning(ret)
    
        [ret] = SetCurrentCamera(CameraHandle);
        CheckWarning(ret)

        [ret, Number] = GetCameraSerialNumber();
        CheckWarning(ret)
        
        if ret == atmcd.DRV_SUCCESS
            if Number == serial
                fprintf('Camera %d (serial: %d, handle: %d) is set to current CCD\n',...
                    i, Number, CameraHandle)
                return
            end
        else
            fprintf('Camera %d (Serial: %d, handle: %d) is NOT initialized, can not obtain serial number\n', i, Number, CameraHandle)
        end
    end

    error('Serial number %d is not found, please check CCD connections', serial)
    
end