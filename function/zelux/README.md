# Zelux CMOS Camera Configuration

## Important parameters
- The parameter `exposure` is the exposure time in seconds.

## Functions
- [initializeZelux(exposure=0.2, external_trigger=true)](/function/zelux/initializeZelux.m) Initialize Thorlabs Zelux CMOS camera and return the handle to `tlCameraSDK` and `tlCamera`
- [closeZelux(tlCameraSDK, tlCamera)](/function/zelux/closeZelux.m) Shut down Thorlabs Zelux CMOS camera and release connection
- [acquireZeluxImage(tlCamera, refresh=0.1, timeout=20)](/function/zelux/acquireZeluxImage.m) Acquire a full frame image

## Note
The camera will be locked by the previous MATLAB session if it is not closed properly. Camera handles will be returned by the `initializeZelux` function, and they should be passed to the `closeZelux` function to release the camera connection.