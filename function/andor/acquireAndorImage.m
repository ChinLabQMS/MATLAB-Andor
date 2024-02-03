function [image, num_frames] = acquireAndorImage(options)
% ACQUIREANDORIMAGE acquire one full-frame image from Andor CCD.
% 
% [image, num_frames] = acquireAndorImage()
% [image, num_frames] = acquireAndorImage(Name, Value)
% 
%Available name-value pairs:
% "timeout": double, time out limit for acquisition in seconds, default is
% 20. Acquisition will be aborted if timeout.

    arguments
        options.timeout (1, 1) double = 20 % seconds
    end
    
    [ret, XPixels, YPixels] = GetDetector();
    CheckWarning(ret)
    
    num_frames = 1;

    % Taking data from Andor camera
    [ret] = StartAcquisition();
    CheckWarning(ret)
    [ret] = WaitForAcquisitionTimeOut(1000*options.timeout);
    CheckWarning(ret)
    
    if ret == atmcd.DRV_NO_NEW_DATA
        warning('Acquisition time out after %d seconds, aborting acquisition...\n', ...
            options.timeout)
        
        ret = AbortAcquisition();
        CheckWarning(ret)

        error('Acquisition time out.')
        
    else
        [ret, first, last] = GetNumberAvailableImages();
        CheckWarning(ret)
        [ret, ImgData, ~, ~] = GetImages(first, last, YPixels*XPixels);
        CheckWarning(ret)

        if ret == atmcd.DRV_SUCCESS
            num_frames = last - first + 1;
            image = flip(transpose(reshape(ImgData, YPixels, XPixels)), 1);
        end
    end

end