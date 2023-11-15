# Matlab-Andor
MATLAB image analysis code for cold atoms research.

## Completed Functions

### CCD control

**Configuration**
- initializeCCD
- shutDownCCD
- setCurrentCCD(current), current = 'Upper': 19330 or 'Lower': 19331
- setDataLive1(exposure)
- setDataLive1Cropped(exposure)
- setDataLiveFK(exposure, num_frames)
- setDMDLive(exposure)

**Acquisition**
- acquireCCDImage(num_images=1, timeout=30)
- 