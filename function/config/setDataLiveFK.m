function setDataLiveFK(options)
    arguments
        options.exposure (1,1) double {mustBePositive,mustBeFinite} = 0.2
        options.num_frames (1, 1) int = 2
    end
    
    switch options.num_frames
        case 1
            setDataLive1('exposure', options.exposure)
            return
        case 2
            settings.exposed_rows = 512;
            settings.offset = 512;
        case 4
            settings.exposed_rows = 256;
            settings.offset = 768;
        case 8
            settings.exposed_rows = 128;
            settings.offset = 896;
    end

    % Get the current CCD serial number
    [ret, Number] = GetCameraSerialNumber();
    CheckWarning(ret)

    if ret == atmcd.DRV_NOT_INITIALIZED
        error('Camera NOT initialized.\n')
    end

    % Set acquisition mode; 4 for fast kinetics
    [ret] = SetAcquisitionMode(4);
    CheckWarning(ret)

    % Configure fast kinetics mode acquisition
    % (exposed rows, series length, exposure, 4 for Image, horizontal binning, vertical binning, offset)
    [ret] = SetFastKineticsEx(settings.exposed_rows, options.num_frames, options.exposure, 4, 1, 1, settings.offset);
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
    fprintf('Number of frames: %d\n', options.num_frames)
    fprintf('Exposure time: %4.2fs\n', options.exposure)

end