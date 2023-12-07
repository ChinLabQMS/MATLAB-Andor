function setDataLiveFK(exposure, num_frames)
    arguments
        exposure (1,1) double {mustBePositive,mustBeFinite} = 0.2
        num_frames (1, 1) int = 2
    end
    
    % Format: [exposed rows, offset]
    switch num_frames
        case 2
            settings = [512, 512];
        case 4
            settings = [256, 768];
        case 8
            settings = [128, 896];
    end

    % Get the current CCD serial number
    [ret, Number] = GetCameraSerialNumber();
    CheckWarning(ret)

    if ret ~= 20002
        error('Camera NOT initialized.\n')
    end

    % Set acquisition mode; 4 for fast kinetics
    [ret] = SetAcquisitionMode(4);
    CheckWarning(ret)

    % Configure fast kinetics mode acquisition
    % 512 for exposed rows; 2 for series length; 4 for Image;
    % 1 for horizontal binning; 1 for vertical binning; 512 for offset
    [ret] = SetFastKineticsEx(settings(1), num_frames, exposure, 4, 1, 1, settings(2));
    CheckWarning(ret)
    
    % Set trigger mode; 0 for internal, 1 for external
    [ret] = SetTriggerMode(1);
    CheckWarning(ret)
    
    % Set Pre-Amp Gain, 0 (1x), 1 (2x), 2 (4x).
    [ret] = SetPreAmpGain(2);
    CheckWarning(ret)
    
    % Set Horizontal speed. (0,0) = 5 MHz, (0,1) = 3 MHz, (0,2) = 1 MHz, (0,3) = 50 kHz
    [ret] = SetHSSpeed(0, 2);
    CheckWarning(ret)
    
    % Set Vertical Shift speed. 0 = 2.25 us, 1 = 4.25 us, 2 = 8.25 us, 3 = 16.25 us, 4 = 32.25 us, 5 = 64.25 us
    [ret] = SetVSSpeed(1);
    CheckWarning(ret)
    
    % Set Crop mode. 1 = ON/0 = OFF; Crop height; Crop width; Vbin; Hbin
    [ret] = SetIsolatedCropMode(0, 1024, 1024, 1, 1);
    CheckWarning(ret)
    
    % Get detector size (with croped mode ON this may change)
    [ret, YPixels, XPixels] = GetDetector();
    CheckWarning(ret)
    
    % Set the image size
    [ret] = SetImage(1, 1, 1, YPixels, 1, XPixels);
    CheckWarning(ret)
    
    fprintf('\n***Fast Kinetic mode***\n')
    fprintf('Current camera serial number: %d\n', Number)
    fprintf('Number of frames: %d\n', num_frames)
    fprintf('Exposure time: %4.2fs\n', exposure)

end