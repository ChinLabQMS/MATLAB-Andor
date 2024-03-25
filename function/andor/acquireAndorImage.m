function [image, num_frames] = acquireAndorImage(options)
% ACQUIREANDORIMAGE acquire one full-frame image from Andor CCD.
% 
% [image, num_frames] = acquireAndorImage()
% [image, num_frames] = acquireAndorImage(Name, Value)
% 
%Available name-value pairs:
% "timeout": double, time out limit for acquisition in seconds, default is
% 20. Acquisition will be aborted if timeout.
% "mode": double, mode for acquisition.
% "refresh": pooling interval

    arguments
        options.mode (1, 1) double = 0 % 0: start + acquire; 1: only start; 2: only acquire
        options.timeout (1, 1) double = 20 % seconds
        options.refresh (1,1) double = 0.01 % seconds
    end
    
    [ret, XPixels, YPixels] = GetDetector();
    CheckWarning(ret)
    
    num_frames = 0;

    % Taking data from Andor camera
    switch options.mode
        case 0
            [ret] = StartAcquisition();
            CheckWarning(ret)            
        case 1
            [ret] = StartAcquisition();
            CheckWarning(ret)
            return
        case 2            
    end

    % [ret] = WaitForAcquisitionTimeOut(1000*options.timeout);
    % CheckWarning(ret)

    % Check if image buffer has been filled, every options.refresh seconds.
    timer = tic;
    [~, Status] = GetStatus();
    while (Status == atmcd.DRV_ACQUIRING)
        pause(options.refresh)
        
        [~, Status] = GetStatus();

        t = toc(timer);
        if t > options.timeout
            error('Current time %g. Acquisition time out after %d seconds', t, options.timeout)
        end
    end

    % if ret == atmcd.DRV_NO_NEW_DATA
    %     ret = AbortAcquisition();
    %     CheckWarning(ret)
    %     error('Acquisition time out after %d seconds, aborting acquisition...\n', ...
    %         options.timeout)    
    % else

    [ret, first, last] = GetNumberAvailableImages();
    CheckWarning(ret)
    [ret, ImgData, ~, ~] = GetImages16(first, last, YPixels*XPixels);
    CheckWarning(ret)

    if ret == atmcd.DRV_SUCCESS
        num_frames = last - first + 1;
        image = uint16(flip(transpose(reshape(ImgData, YPixels, XPixels)), 1));
    end
end