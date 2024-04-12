function vargout = setModeFK(options)
    arguments
        options.exposure (1,1) double {mustBePositive,mustBeFinite} = 0.2
        options.external_trigger (1,1) logical = true
        options.num_frames = 2        
        options.crop = false
        options.crop_height = 100
        options.crop_width = 100        
        options.horizontal_speed = 2
        options.vertical_speed = 1
    end
    if ischar(options.horizontal_speed)
        switch options.horizontal_speed
            case '1MHz'
                options.horizontal_speed = 2;
            case '3MHz'
                options.horizontal_speed = 1;
            case '5MHz'
                options.horizontal_speed = 0;
        end
    end
    if ischar(options.num_frames)
        options.num_frames = str2double(options.num_frames(end));
    end

    switch options.num_frames
        case 1
            vargout = setModeFull('exposure', options.exposure, ...
                        'external_trigger',options.external_trigger, ...
                        'crop',options.crop, ...
                        'crop_height',options.crop_height, ...
                        'crop_width',options.crop_width, ...
                        'horizontal_speed',options.horizontal_speed, ...
                        'vertical_speed',options.vertical_speed);
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
    if ret == atmcd.DRV_NOT_INITIALIZED
        error('Camera NOT initialized.')
    end

    % Set acquisition mode; 4 for fast kinetics
    [ret] = SetAcquisitionMode(4);
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

    % Configure fast kinetics mode acquisition
    % (exposed rows, series length, exposure, 4 for Image, horizontal binning, vertical binning, offset)
    [ret] = SetFastKineticsEx(settings.exposed_rows, options.num_frames, ...
                            options.exposure, 4, 1, 1, settings.offset);
    CheckWarning(ret)
    
    % Set Fast Kinetic vertical shift speed
    [ret] = SetFKVShiftSpeed(1);
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
    
    % Get the kinetic cycle time
    [ret, ~, ~, kinetic] = GetAcquisitionTimings();
    CheckWarning(ret)

    % Free internal memory
    [ret] = FreeInternalMemory();
    CheckWarning(ret)
    
    fprintf('\n******Fast Kinetic mode******\n\n')
    fprintf('Current camera serial number: %d\n', Number)
    fprintf('Number of frames: %d\n', options.num_frames)
    fprintf('Exposure time: %5.3fs\n', options.exposure)
    fprintf('Kinetic cycle time: %5.3fs\n', kinetic)    
    if options.external_trigger
        fprintf('Trigger: External\n\n')
    else
        fprintf('Trigger: Internal\n\n')
    end

    if nargout == 1
        vargout = kinetic;
    end

end