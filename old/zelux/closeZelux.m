function closeZelux(tlCameraSDK, tlCamera)
    fprintf('\n******Close Zelux******\n\n')

    % Stop image acquisition
    disp('Stopping image acquisition.');
    tlCamera.Disarm;
    
    % Release the camera
    disp('Releasing the camera');
    tlCamera.Dispose;
    delete(tlCamera)
    
    % Release the TLCameraSDK.
    tlCameraSDK.Dispose;
    delete(tlCameraSDK)

end