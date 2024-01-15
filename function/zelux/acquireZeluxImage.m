function imageData2D = acquireZeluxImage(tlCamera, options)
    arguments
        tlCamera
        options.refresh (1, 1) double = 0.1
    end

    % Check if image buffer has been filled, every options.refresh seconds.
    while (tlCamera.NumberOfQueuedFrames == 0)
        pause(options.refresh)
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
    if ~isempty(imageFrame)

        % For color images, the image data is in BGR format.
        imageData = imageFrame.ImageData.ImageData_monoOrBGR;
        disp(['Image frame number: ' num2str(imageFrame.FrameNumber)]);
    
        imageHeight = imageFrame.ImageData.Height_pixels;
        imageWidth = imageFrame.ImageData.Width_pixels;
        imageData2D = reshape(uint16(imageData), [imageWidth, imageHeight]);
    else
        error('Image frame is empty')
    end
end