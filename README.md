# Matlab-Andor
MATLAB image analysis code for cold atoms research.

## Functions

### CCD control

**Configuration**

The parameter `serial` is the current CCD serial number, serial = 19330 (Upper CCD) or 19331 (Lower CCD).
The parameter `exposure` is the exposure time in seconds.
The parameter `num_frames` is the number of sub-frames to split the full frame into for fast kinetics mode.
- [initializeCCD(serial)](/function/config/initializeCCD.m)
- [shutDownCCD(serial)](/function/config/shutDownCCD.m)
- [setCurrentCCD(serial)](/function/config/setCurrentCCD.m)
- [setDataLive1(exposure)](/function/config/setDataLive1.m)
- [setDataLiveFK(exposure, num_frames)](/function/config/setDataLiveFK.m)
- [setDMDLive(exposure)](/function/config/setDMDLive.m)

**Acquisition**
- [acquireCCDImage(num_images=1, timeout=30)](/function/config/acquireCCDImage.m)
- 

**User Interface**
- [ImageAcquisition](ImageAcquisition.mlapp)
