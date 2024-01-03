function initializeAndor(serial)
    arguments
        serial = [19330, 19331]
    end

    [ret, NumCameras] = GetAvailableCameras();
    CheckWarning(ret)
    fprintf('\n******Start initialization******\n\n')
    fprintf('Number of Cameras found: %d\n\n',NumCameras)

    for i = 1:NumCameras
        
        [ret, CameraHandle] = GetCameraHandle(i-1);
        CheckWarning(ret)
    
        [ret] = SetCurrentCamera(CameraHandle);
        CheckWarning(ret)

        % Initialize camera 
        fprintf('Initializing Camera %d...\n',i)
        [ret] = AndorInitialize(pwd);                      
        CheckWarning(ret)

        if ret == atmcd.DRV_SUCCESS
            
            % Get camera serial number (need initialize first)
            [ret, Number] = GetCameraSerialNumber();
            CheckWarning(ret)
            if ~ismember(Number, serial)
                % Shutdown unselected cameras
                [ret] = AndorShutDown();
                CheckWarning(ret)
                fprintf('Camera %d (Serial Number: %d) NOT initialized. \n', i, Number)
            else
                fprintf('Camera %d (Serial Number: %d) is initializing...', i, Number)
            end

            % Set temperature
            [ret] = SetTemperature(-70);
            CheckWarning(ret)
        
            % Turn on temperature cooler
            [ret] = CoolerON();
            CheckWarning(ret)
            
            % Free internal memory
            [ret] = FreeInternalMemory();
            if ret == atmcd.DRV_ACQUIRING
                fprintf('Acquisition in process, aborting...')
                ret = AbortAcquisition();
                CheckWarning(ret)
                fprintf('Acquisition aborted.\n')
            end
        
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
            
            fprintf('Initialization complete.\n')

        else
            fprintf('Camera %d not available, please check connections in other applications.\n',i)
        end

    end

end