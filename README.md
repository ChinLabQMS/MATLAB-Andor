# Matlab-Andor
MATLAB image analysis code for site-resolved atom imaging and manipulation.

## Functions

### CCD control

**Configuration**

- The parameter `serial` is the current CCD serial number, `serial` = 19330 (Upper CCD) or 19331 (Lower CCD).
- The parameter `exposure` is the exposure time in seconds.
- The parameter `num_frames` is the number of sub-frames to split the full frame into for fast kinetics mode, could be set to 1, 2, 4, 8.

Functions:
- [initializeCCD(serial)](/function/config/initializeCCD.m) Initialize CCD
- [shutDownCCD(serial)](/function/config/shutDownCCD.m) Shut down CCD and release connection
- [setCurrentCCD(serial)](/function/config/setCurrentCCD.m) Set current CCD
- [setDataLive1(exposure=0.2, crop=false, crop_height=100, crop_width=100, external_trigger=true)](/function/config/setDataLive1.m) Full frame acquisition mode, with options to crop the detector and use external/internal trigger
- [setDataLiveFK(exposure=0.2, num_frames=2)](/function/config/setDataLiveFK.m) Fast kinetics mode

**Acquisition**
- [acquireCCDImage(num_images=1, timeout=30)](/function/config/acquireCCDImage.m) Acquire a full frame image (could contain many sub-frames), could be used for both full frame and fast kinetics mode.

**User Interface**
- [ImageAcquisition](ImageAcquisition.mlapp)

### Basic analysis functions

**Background subtraction**

**ROI selection**

**Lattice calibration**

**DMD pixel calibration**

### Data processing scripts

**CCD noise analysis**
