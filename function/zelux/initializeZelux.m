function [tlCameraSDK, tlCamera] = initializeZelux(options)
    arguments
        options.exposure (1, 1) double = 0.2 % exposure time in seconds
        options.external_trigger (1, 1) logical = true
        options.verbose (1,1) logical = true
    end
        
    % Old initializeZelux
    oldPath = cd([pwd, '/function/zelux/dlls']);
    % disp(pwd)

    % Load TLCamera DotNet assembly. The assembly .dll is assumed to be in the 
    % same folder as the scripts.
    NET.addAssembly([pwd, '/Thorlabs.TSI.TLCamera.dll']);
    if options.verbose
        fprintf('\n******Zelux Initialization******\n\n')
        fprintf('Dot NET assembly loaded.')
    end
    try
        tlCameraSDK = Thorlabs.TSI.TLCamera.TLCameraSDK.OpenTLCameraSDK;
    catch
        cd(oldPath)
        error('Unable to load SDK, check if the camera is already initialized.')
    end
    cd(oldPath)

    % NET.addAssembly([pwd, '/function/zelux/dlls/Thorlabs.TSI.TLCamera.dll']);
    % disp('Dot NET assembly loaded.')
    % tlCameraSDK = Thorlabs.TSI.TLCamera.TLCameraSDK.OpenTLCameraSDK;

    % Get serial numbers of connected TLCameras.
    serialNumbers = tlCameraSDK.DiscoverAvailableCameras;
    if options.verbose
        fprintf('%d camera was discovered.\n', serialNumbers.Count)
    end

    if (serialNumbers.Count > 0)
        % Open the first camera using the serial number.
        tlCamera = tlCameraSDK.OpenCamera(serialNumbers.Item(0), false);
        
        % Set exposure time and gain of the camera.
        tlCamera.ExposureTime_us = options.exposure * 1000000;
    
        % Check if the camera supports setting "Gain"
        gainRange = tlCamera.GainRange;
        if (gainRange.Maximum > 0)
            tlCamera.Gain = 0;
        end
 
        % Set the number of frames per hardware trigger and start trigger
        % acquisition
        if options.external_trigger
            if options.verbose
                disp('Setting up hardware/external triggered image acquisition.');
            end
            tlCamera.OperationMode = Thorlabs.TSI.TLCameraInterfaces.OperationMode.HardwareTriggered;
        else
            if options.verbose
                disp('Setting up software/internal triggered image acquisition.')
            end
            tlCamera.OperationMode = Thorlabs.TSI.TLCameraInterfaces.OperationMode.SoftwareTriggered;
        end
       
        tlCamera.FramesPerTrigger_zeroForUnlimited = 1;
        tlCamera.Arm;
    else
        disp('Camera not detected!')
    end

end