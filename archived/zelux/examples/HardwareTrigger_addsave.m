% Simple Matlab sample for using TSICamera DotNET interface with hardware
% trigger
%%
clear
close all

% Load TLCamera DotNet assembly. The assembly .dll is assumed to be in the 
% same folder as the scripts.
NET.addAssembly([pwd, '\Thorlabs.TSI.TLCamera.dll']);
disp('Dot NET assembly loaded.');

tlCameraSDK = Thorlabs.TSI.TLCamera.TLCameraSDK.OpenTLCameraSDK;

% Get serial numbers of connected TLCameras.
serialNumbers = tlCameraSDK.DiscoverAvailableCameras;
disp([num2str(serialNumbers.Count), ' camera was discovered.']);

if (serialNumbers.Count > 0)
    % Open the first camera using the serial number.
    disp('Opening the first camera')
    tlCamera = tlCameraSDK.OpenCamera(serialNumbers.Item(0), false);
    
    % Check if the camera is Color.
    isColorCamera = tlCamera.CameraSensorType == Thorlabs.TSI.TLCameraInterfaces.CameraSensorType.Bayer;
    if (isColorCamera)
        % Load color processing .NET assemblies
        NET.addAssembly([pwd, '\Thorlabs.TSI.Demosaicker.dll']);
        NET.addAssembly([pwd, '\Thorlabs.TSI.ColorProcessor.dll']);
        
        % Initialize the demosaicker
        demosaicker = Thorlabs.TSI.Demosaicker.Demosaicker;
        % Create color processor SDK.
        colorProcessorSDK = Thorlabs.TSI.ColorProcessor.ColorProcessorSDK;

        % Query the default white balance matrix from camera. Alternatively
        % can also use user defined white balance matrix.
        defaultWhiteBalanceMatrix = tlCamera.GetDefaultWhiteBalanceMatrix;
        
        % Query other relevant camera information
        cameraColorCorrectionMatrix = tlCamera.GetCameraColorCorrectionMatrix;
        bitDepth = int32(tlCamera.BitDepth);
        colorFilterArrayPhase = tlCamera.ColorFilterArrayPhase;
        
        % Create standard RGB color processing pipeline.
        standardRGBColorProcessor = colorProcessorSDK.CreateStandardRGBColorProcessor(defaultWhiteBalanceMatrix,...
            cameraColorCorrectionMatrix, bitDepth);
    end
    
    % Set exposure time and gain of the camera.
    tlCamera.ExposureTime_us = 200000;

    % Check if the camera supports setting "Gain"
    gainRange = tlCamera.GainRange;
    if (gainRange.Maximum > 0)
        tlCamera.Gain = 0;
    end

    % Set the FIFO frame buffer size. Default size is 1.
    tlCamera.MaximumNumberOfFramesToQueue = 5;
    
    figure(1)
    %%
    % Start hardware triggered image acquisition
    disp('Starting hardware triggered image acquisition.');
    
    % Set the number of frames per hardware trigger and start trigger
    % acquisition
    tlCamera.OperationMode = Thorlabs.TSI.TLCameraInterfaces.OperationMode.HardwareTriggered;
    tlCamera.FramesPerTrigger_zeroForUnlimited = 1;
    tlCamera.Arm;
    
    maxPixelValue = double(2^tlCamera.BitDepth - 1);

%%

    numberOfFramesToAcquire = 2;
    % adding a couple of lines to add a cell array that stores the images
    allFrames = cell(numberOfFramesToAcquire,1);
    allImages = cell(numberOfFramesToAcquire,1);

    frameCount = 0;
    while frameCount < numberOfFramesToAcquire
        % Wait for external trigger.
        
        % Check if image buffer has been filled
        if (tlCamera.NumberOfQueuedFrames > 0)
            
            
            % If data processing in Matlab falls behind camera image
            % acquisition, the FIFO image frame buffer could be filled up,
            % which would result in missed frames.
            if (tlCamera.NumberOfQueuedFrames > 1)
                disp(['Data processing falling behind acquisition. ' num2str(tlCamera.NumberOfQueuedFrames) ' remains']);
            end
            
            % Get the pending image frame.
            imageFrame = tlCamera.GetPendingFrameOrNull;
            if ~isempty(imageFrame)
                frameCount = frameCount + 1;
                % For color images, the image data is in BGR format.
                imageData = imageFrame.ImageData.ImageData_monoOrBGR;
                
                disp(['Image frame number: ' num2str(imageFrame.FrameNumber)]);
                
                % TODO: custom image processing code goes here
                imageHeight = imageFrame.ImageData.Height_pixels;
                imageWidth = imageFrame.ImageData.Width_pixels;
                if (isColorCamera)
                    % Allocate memory for demosaicking output.
                    demosaickedImageData = NET.createArray('System.UInt16',imageHeight * imageWidth * 3);
                    colorFormat = Thorlabs.TSI.ColorInterfaces.ColorFormat.BGRPixel;
                    % Demosaic the Bayer patterned image from the camera.
                    demosaicker.Demosaic(imageWidth, imageHeight, int32(0), int32(0), colorFilterArrayPhase,...
                        colorFormat, Thorlabs.TSI.ColorInterfaces.ColorSensorType.Bayer,...
                        bitDepth, imageData, demosaickedImageData);
                    
                    % Allocate memory for color processed image.
                    processedImageData = NET.createArray('System.UInt16',imageHeight * imageWidth * 3);
                    
                    % Use the color processor to perform color transform.
                    standardRGBColorProcessor.Transform48To48(demosaickedImageData, colorFormat,...
                        uint16(0), uint16(maxPixelValue), uint16(0), uint16(maxPixelValue),...
                        uint16(0), uint16(maxPixelValue), int32(0), int32(0), int32(0), processedImageData, colorFormat);
                    
                    % Display the color image
                    imageColor = reshape(uint16(processedImageData), [3, imageWidth, imageHeight]);
                    imageColor = double(permute(imageColor,[3 2 1]));
                    imageColor = flip(imageColor,3);    % Change from BGR to RGB
                    figure(1),image(imageColor/maxPixelValue), colorbar
                else
                    imageData2D = reshape(uint16(imageData), [imageWidth, imageHeight]);
                    figure(1),imagesc(imageData2D'), colormap(gray), colorbar
                end
            allFrames{frameCount}=imageFrame;
            allImages{frameCount}=imageData2D;
            end
            
            % Release the image frame
            
            delete(imageFrame);
        end
        drawnow;
    end
    
    % Stop hardware triggered image acquisition
    disp('Stopping hardware triggered image acquisition.');
    tlCamera.Disarm;
    
    % Release the camera
    disp('Releasing the camera');
    tlCamera.Dispose;
    delete(tlCamera);

    if (isColorCamera)
        standardRGBColorProcessor.Dispose;
        delete(standardRGBColorProcessor);
        colorProcessorSDK.Dispose;
        delete(colorProcessorSDK);
    end
end

% Release the serial numbers
delete(serialNumbers);

% Release the TLCameraSDK.
tlCameraSDK.Dispose;
delete(tlCameraSDK);
