function image = acquireCCDImage(options)
    arguments
        options.num_images = 1;
        options.timeout = 30; % seconds
    end
    
    % Taking data from Andor camera
    [ret] = StartAcquisition();
    CheckWarning(ret)
    [ret] = WaitForAcquisitionTimeOut(1000*options.timeout);
    CheckWarning(ret)
    [ret, XPixels, YPixels] = GetDetector();
    CheckWarning(ret)
    [ret, ImgData, ~, ~] = GetImages(1, options.num_images, YPixels*XPixels);
    CheckWarning(ret)
    
    if ret == atmcd.DRV_SUCCESS
        image = flip(transpose(reshape(ImgData,YPixels,XPixels)),1);

    elseif ret == atmcd.DRV_NO_NEW_DATA
        fprintf('No new data, aborting acquisition.\n')
        ret = AbortAcquisition();
        CheckWarning(ret)
        image = [];
            
    else
        error('Acquisition error!')
    end

end