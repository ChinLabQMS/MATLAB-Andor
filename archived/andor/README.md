# Functions for Andor CCD control

## Important parameters
- The parameter `serial` is the current CCD serial number, `serial` = 19330 (Upper CCD) or 19331 (Lower CCD).
- The parameter `exposure` is the exposure time in seconds.
- The parameter `num_frames` is the number of sub-frames to split the full frame into for fast kinetics mode, could be set to 1, 2, 4, 8.
- The parameter `timeout` is the maximum time in seconds to wait for the image acquisition to complete.
- The structure `Handle` is used to store the camera handle for quickly looking up the camera.

## Functions
- [initializeAndor(serial=[19330,19331])](/function/andor/initializeAndor.m) Initialize Andor CCD with serial number and return the Camera handle as a struct. Optionally, the `Handle` struct could be passed to the function to update the handle.
- [closeAndor(serial=[19330,19331])](/function/andor/closeAndor.m) Shut down Andor CCD and release connection. Optionally, the `Handle` struct could be passed to the function to help looking up specific camera.
- [setCurrentAndor(serial)](/function/andor/setCurrentAndor.m) Set current CCD to the one with the given serial number. Optionally, the `Handle` struct could be passed to the function to help looking up specific camera.
- [setModeFull(exposure=0.2, crop=false, crop_height=100, crop_width=100, external_trigger=true, horizontal_speed=2, vertical_speed=1)](/function/andor/setModeFull.m) Set to Full frame acquisition mode, with options to crop the detector and use external/internal trigger and set readout speed.
- [setModeFK(exposure=0.2, num_frames=2)](/function/andor/setModeFK.m) Fast kinetics mode, with options to set the number of sub-frames.
- [acquireAndorImage(num_images=1, timeout=30, mode=0)](/function/andor/acquireAndorImage.m) Acquire a full frame image (could contain many sub-frames), could be used for both full frame and fast kinetics mode. The mode is set to 0 for both starting acquisition and waiting for the acquisition to complete, and set to 1 for starting acquisition only, and set to 2 for waiting for the acquisition to complete only.
- [readAscImage(path, file)](/function/andor/readAscImage.m) Read .asc image file and convert to 2D `uint16` array.
- [getAndorHandle(serial, Handle)](/function/andor/getAndorHandle.m) Helper function to scan all connected camera and update Handle struct which serves as a lookup table for future camera selection.