function Handle = initializeAndor(serial, Handle, options)
    arguments
        serial = [19330, 19331]
        Handle (1, 1) struct = struct()
        options.verbose = true
    end

    if options.verbose
        fprintf('\n******Start initialization******\n\n')
    end
    
    for serial_number = serial
        serial_str = ['Andor', num2str(serial_number)];
        Handle = getAndorHandle(serial_str, Handle, "verbose",options.verbose);

        [ret] = SetCurrentCamera(Handle.(serial_str));
        CheckWarning(ret)

        [ret] = AndorInitialize(pwd);                      
        CheckWarning(ret)
        if options.verbose
            fprintf('Camera (serial: %d, handle: %d) is set to current CCD\n',...
                    serial_number, Handle.(serial_str))
        end
        
        % Get status and abort acquisition if it is acquiring
        [ret, status] = GetStatus();
        CheckWarning(ret)
        if status == atmcd.DRV_ACQUIRING
            [ret] = AbortAcquisition();
            CheckWarning(ret)
            if options.verbose
                fprintf('Acquisition aborted\n')
            end
        end
    
        % Set temperature
        [ret] = SetTemperature(-70);
        CheckWarning(ret)
    
        % Turn on temperature cooler
        [ret] = CoolerON();
        CheckWarning(ret)
        
        % Free internal memory
        [ret] = FreeInternalMemory();
        CheckWarning(ret)
    
        % Configuring Acquisition
    
        % Set acquisition mode; 1 for Single Scan
        [ret] = SetAcquisitionMode(1);
        CheckWarning(ret)
        
        % Set read mode; 4 for Image
        [ret] = SetReadMode(4);
        CheckWarning(ret)
        
        % Set trigger mode; 0 for internal, 1 for external
        [ret] = SetTriggerMode(1);                      
        CheckWarning(ret)
        
        % Open Shutter
        [ret] = SetShutter(1, 1, 0, 0);
        CheckWarning(ret)
        
        % Get detector size
        [ret, XPixels, YPixels] = GetDetector();
        CheckWarning(ret)
        
        % Set the image size
        [ret] = SetImage(1, 1, 1, XPixels, 1, YPixels);
        CheckWarning(ret)
        
        % Set Baseline clamp. 1 enable, 0 disable.
        [ret] = SetBaselineClamp(0);                      
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
        
        % Set Keep Clean: 0 = disable, 1 = enable
        [ret] = EnableKeepCleans(1);
        CheckWarning(ret)

    end
end