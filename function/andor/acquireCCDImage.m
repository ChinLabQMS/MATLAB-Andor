function image = acquireCCDImage(options)
    arguments
        options.timeout (1, 1) double = 20; % seconds
    end
    
    [ret, XPixels, YPixels] = GetDetector();
    CheckWarning(ret)

    % Taking data from Andor camera
    [ret] = StartAcquisition();
    CheckWarning(ret)
    [ret] = WaitForAcquisitionTimeOut(1000*options.timeout);
    CheckWarning(ret)
    
    if ret == atmcd.DRV_SUCCESS
        [ret, first, last] = GetNumberAvailableImages();
        CheckWarning(ret)
        [ret, ImgData, ~, ~] = GetImages(first, last, YPixels*XPixels);
        CheckWarning(ret)

        if ret == atmcd.DRV_SUCCESS
            fprintf('Successfully acquired %d images\n', last - first + 1)
            image = flip(transpose(reshape(ImgData, YPixels, XPixels)), 1);
        end
                
    else
        fprintf('Acquisition time out after %d seconds, aborting acquisition.\n', ...
            options.timeout)

        ret = AbortAcquisition();
        CheckWarning(ret)
        image = [];
        if ret == atmcd.DRV_SUCCESS
            fprintf('Acquisition aborted.\n')
        end
    end

end