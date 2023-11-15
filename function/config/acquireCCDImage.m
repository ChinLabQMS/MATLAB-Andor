function image = acquireCCDImage(options)
    arguments
        options.num_images = 1;
        options.timeout = 30; % seconds
    end
    
    % Taking data from Andor camera
    [ret] = StartAcquisition();
    CheckWarning(ret);
    [ret] = WaitForAcquisitionTimeOut(1000*options.timeout);
    CheckWarning(ret);
    [ret, XPixels, YPixels] = GetDetector();
    CheckWarning(ret);
    
    %  SYNOPSIS : [ret, arr, validfirst, validlast] = GetImages(first, last, size)
    %     INPUT first: index of first image in buffer to retrieve.
    %     last: index of last image in buffer to retrieve.
    %     size: total number of pixels.
    % OUTPUT ret: Return Code: 
    %        DRV_SUCCESS - Images have been copied into array.
    %        DRV_NOT_INITIALIZED - System not initialized.
    %        DRV_ERROR_ACK - Unable to communicate with card.
    %        DRV_GENERAL_ERRORS - The series is out of range.
    %        DRV_P3INVALID - Invalid pointer (i.e. NULL).
    %        DRV_P4INVALID - Array size is incorrect.
    %        DRV_NO_NEW_DATA - There is no new data yet.
    %      arr: data storage allocated by the user.
    %      validfirst: index of the first valid image.
    %      validlast: index of the last valid image.
    [ret, ImgData, ~, ~] = GetImages(1, options.num_images, YPixels*XPixels);
    CheckWarning(ret);
    
    if ret == 20002
        image = flip(transpose(reshape(ImgData,YPixels,XPixels)),1);
    else
        error('Acquisition error!');
    end

end