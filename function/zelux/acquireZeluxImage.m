function imageData2D = acquireZeluxImage(tlCamera, options)
    arguments
        tlCamera
        options.refresh (1, 1) double = 0.1
        options.timeout (1, 1) double = 30
    end
    
    % If the Camera is set to software triggered mode, issue a trigger
    if tlCamera.OperationMode == Thorlabs.TSI.TLCameraInterfaces.OperationMode.SoftwareTriggered
        tlCamera.IssueSoftwareTrigger;
        disp('Software trigger issued.')
    end

    % Check if image buffer has been filled, every options.refresh seconds.
    tic
    while (tlCamera.NumberOfQueuedFrames == 0)
        pause(options.refresh)
        t = toc;
        if t > options.timeout
            warning('Current time %g. Acquisition time out after %d seconds', t, options.timeout)
        end
    end    
    
    % If data processing in Matlab falls behind camera image
    % acquisition, the FIFO image frame buffer could be filled up,
    % which would result in missed frames.
    if (tlCamera.NumberOfQueuedFrames > 1)
        disp(['Data processing falling behind acquisition. ', ...
               num2str(tlCamera.NumberOfQueuedFrames), ' remains']);
    end
    
    % Get the pending image frame.
    imageFrame = tlCamera.GetPendingFrameOrNull;
    imageData = imageFrame.ImageData.ImageData_monoOrBGR;
    disp(['Image frame number: ' num2str(imageFrame.FrameNumber)]);

    imageHeight = imageFrame.ImageData.Height_pixels;
    imageWidth = imageFrame.ImageData.Width_pixels;
    imageData2D = reshape(uint16(imageData), [imageWidth, imageHeight]);
end