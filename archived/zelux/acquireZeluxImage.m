function imageData2D = acquireZeluxImage(tlCamera, options)
    arguments
        tlCamera
        options.refresh (1, 1) double = 0.01
        options.timeout (1, 1) double = 30
        options.verbose (1, 1) logical = true
    end
    
    % If the Camera is set to software triggered mode, issue a trigger
    if tlCamera.OperationMode == Thorlabs.TSI.TLCameraInterfaces.OperationMode.SoftwareTriggered
        tlCamera.IssueSoftwareTrigger;
    end

    % Check if image buffer has been filled, every options.refresh seconds.
    timer = tic;
    while (tlCamera.NumberOfQueuedFrames == 0)
        pause(options.refresh)
        t = toc(timer);
        if t > options.timeout
            error('Current time %g. Acquisition time out after %d seconds', t, options.timeout)
        end
    end
    
    % If data processing in Matlab falls behind camera image
    % acquisition, the FIFO image frame buffer could be filled up,
    % which would result in missed frames.
    if (tlCamera.NumberOfQueuedFrames > 1)
        warning(['Data processing falling behind acquisition. ', ...
               num2str(tlCamera.NumberOfQueuedFrames), ' remains']);
    end
    
    % Get the pending image frame.
    imageFrame = tlCamera.GetPendingFrameOrNull;
    imageData = imageFrame.ImageData.ImageData_monoOrBGR;
    
    if options.verbose
        disp(['Image frame number: ' num2str(imageFrame.FrameNumber)]);
    end

    imageHeight = imageFrame.ImageData.Height_pixels;
    imageWidth = imageFrame.ImageData.Width_pixels;
    imageData2D = reshape(uint16(imageData), [imageWidth, imageHeight]);
end