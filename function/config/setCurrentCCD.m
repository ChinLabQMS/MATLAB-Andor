function setCurrentCCD(CurrentCCD)
% CurrentCCD = 'Upper'
%            = 'Lower'

    [ret, NumCameras] = GetAvailableCameras();
    CheckWarning(ret)

    for i = 1: NumCameras
        [ret,CameraHandle] = GetCameraHandle(i-1);
        CheckWarning(ret)
    
        [ret] = SetCurrentCamera(CameraHandle);
        CheckWarning(ret)

        [ret, Number] = GetCameraSerialNumber();
        CheckWarning(ret)

        if strcmp(CurrentCCD,'Upper') && Number == 19330
            disp('Current CCD is set to Upper CCD: 19330')
            return
        elseif strcmp(CurrentCCD,'Lower') && Number == 19331
            disp('Current CCD is set to Lower CCD: 19331')
            return
        end
    end
    error('Current CCD is not found')
    
end