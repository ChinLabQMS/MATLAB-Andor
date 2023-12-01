function setCurrentCCD(current)
arguments
    current double = 19330
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
        
        if Number == current
            fprintf('\nCurrent CCD is set to serial number: %d\n', current)
            return
        end
    end
    error('Serial number is not found, check CCD connections')
    
end