# Matlab-Andor
MATLAB image analysis code for cold atoms research.

## Completed Functions

### CCD control

**Configuration**
- initializeCCD
- shutDownCCD
- setCurrentCCD(current), current = 'Upper' or 'Lower'
- setDataLive1(exposure)
- setDataLive1Cropped(exposure)
- setDataLiveFK(exposure, num_frames)
- setDMDLive(exposure)

**Acquisition**
- acquireImage