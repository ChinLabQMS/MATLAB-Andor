# Matlab-Andor
MATLAB image analysis code for site-resolved atom imaging and manipulation.

## Functions

### CCD control
We control Andor ([iKon-M 934 CCD](https://andor.oxinst.com/products/ikon-xl-and-ikon-large-ccd-series/ikon-m-934)) and Thorlabs ([Zelux CMOS](https://www.thorlabs.com/thorproduct.cfm?partnumber=CS165MU1)) cameras.

**Andor Configuration**

- The parameter `serial` is the current CCD serial number, `serial` = 19330 (Upper CCD) or 19331 (Lower CCD).
- The parameter `exposure` is the exposure time in seconds.
- The parameter `num_frames` is the number of sub-frames to split the full frame into for fast kinetics mode, could be set to 1, 2, 4, 8.

Functions:
- [initializeAndor(serial=[19330,19331])](/function/andor/initializeAndor.m) Initialize Andor CCD
- [closeAndor(serial=[19330,19331])](/function/andor/closeAndor.m) Shut down Andor CCD and release connection
- [setCurrentAndor(serial)](/function/andor/setCurrentAndor.m) Set current CCD
- [setModeFull(exposure=0.2, crop=false, crop_height=100, crop_width=100, external_trigger=true, horizontal_speed=2, vertical_speed=1)](/function/andor/setModeFull.m) Full frame acquisition mode, with options to crop the detector and use external/internal trigger and set readout speed
- [setModeFK(exposure=0.2, num_frames=2)](/function/andor/setModeFK.m) Fast kinetics mode, with options to set the number of sub-frames
- [acquireAndorImage(num_images=1, timeout=30)](/function/andor/acquireAndorImage.m) Acquire a full frame image (could contain many sub-frames), could be used for both full frame and fast kinetics mode.
- [getAcquisitionConfig(num_frames=1)](/function/andor/getAcquisitionConfig.m) Get current acquisition configuration

**User Interface**
- [ImageAcquisition](ImageAcquisition.mlapp)

### Basic analysis functions

**Background subtraction**

**ROI selection**

**Lattice calibration**

**DMD pixel calibration**

### Data processing scripts

**CCD noise analysis**
