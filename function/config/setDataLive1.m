function setDataLive1(exposure, options)
    arguments
        exposure (1,1) double {mustBePositive,mustBeFinite} = 0.2
        options.crop (1,1) logical = false
        options.crop_height (1,1) double {mustBePositive,mustBeFinite} = 100
        options.crop_width (1,1) double {mustBePositive,mustBeFinite} = 100
        options.external_trigger (1,1) logical = true
    end

    % Get the current CCD serial number
    [ret, Number] = GetCameraSerialNumber();
    CheckWarning(ret)

    if ret ~= 20002
        error('Camera NOT initialized.\n')
    end

    % Set acquisition mode; 1 for Single Scan
    [ret] = SetAcquisitionMode(1);
    CheckWarning(ret)

    %   Set trigger mode; 0 for internal, 1 for external
    if options.external_trigger
        [ret] = SetTriggerMode(1);
    else
        [ret] = SetTriggerMode(0);
    end
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
    if options.crop
        [ret] = SetIsolatedCropMode(1, options.crop_height, options.crop_width, 1, 1);
        CheckWarning(ret)
    else
        [ret] = SetIsolatedCropMode(0, 1024, 1024, 1, 1);
        CheckWarning(ret)
    end
    
    % Get detector size (with croped mode ON this may change)
    [ret, YPixels, XPixels] = GetDetector();
    CheckWarning(ret)
    
    % Set the image size
    [ret] = SetImage(1, 1, 1, YPixels, 1, XPixels);
    CheckWarning(ret)
    
    % Set exposure time
    [ret] = SetExposureTime(exposure);
    CheckWarning(ret)
    
    % Get readout time
    [ret, ReadoutTime] = GetReadOutTime();
    CheckWarning(ret)

    fprintf('\n***Full frame mode***\n')
    fprintf('Current camera serial number: %d\n', Number)
    fprintf('Exposure time: %4.2fs\n', exposure)
    fprintf('Readout time for 1 image: %5.3fs\n\n', ReadoutTime)

end