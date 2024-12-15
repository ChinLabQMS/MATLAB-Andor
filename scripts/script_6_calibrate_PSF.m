% PSF calibrations are
% labeled as '<camera_name>_<imaging_wavelength>' which not only includes 
% the camera name but also the imaging wavelength, because at different 
% wavelengths the diffraction-limited resolution is different.to accurately compare the measured PSF to 
% diffraction limit, it has to include the imaging wavelength.
% The physical lattice spacing is assumed to be equal for all the
% calibrations, which is 2*0.935/(3*sin(45 deg)) = 0.8815 um. This value
% serves as a ruler to calibrate the size of PSF in this frame.

% - PSFCameraList: list of camera names for calibrating PSF
% - PSFImageLabel: corresponding list of image labels for PSF calibration
