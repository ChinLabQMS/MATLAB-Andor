# Matlab-Andor

## Introduction
Image acquisition and analysis tools for site-resolved atom imaging and manipulation in MATLAB with Object-Oriented design.

## Dependencies
- External libraries
    - Andor MATLAB SDK3 (C++ mex function)
    - Thorlabs Camera SDK
    - [DMD-SDL](https://github.com/ChinLabQMS/DMD-SDL) (C++ mex function) for real-time DMD pattern control
- MATLAB toolboxes
    - Curve Fitting Toolbox
    - Image Processing Toolbox
    - Statistics and Machine Learning Toolbox

## Main modules

### Device control and image acquisition
The code includes classes for controlling the following devices:
- Andor iKon-M 934 low noise CCD
- Thorlabs Zelux CMOS camera
- Texas Instruments DLP LightCrafter 4500 Evaluation Module (DMD) as projector of optical patterns

The class definitions are under [camera](camera/) folder.

### Image processing and analysis

### Image visualization

## How to use

### MATLAB App interface
[AcquisitorApp.mlapp](AcquisitorApp.mlapp) provides an interface to control instruments and collect images.

### Example scripts
The [scripts](scripts/) folder provides a collection of example scripts for generating calibration files for the camera and DMD, and for performing image acquisition and analysis.
