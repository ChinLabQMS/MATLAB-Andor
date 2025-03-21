%% Introduction
% Goal: Generate a file containing lattice calibration for different 
% cameras. Lattice calibrations are labeled as its corresponding camera
% name.
% The physical lattice spacing is assumed to be equal for all the
% frames, which is 2*0.935/(3*sin(45 deg)) = 0.8815 um. This value
% serves as a ruler to calibrate the imaging magnification.

% Note that this script is for **FIRST** calibration that starts from no
% prior knowledge of the lattice geometry. Script_3 is available for 
% re-calibration from an existing calibration file.

% The most important calibration results obtained are:
% 1. Lattice vectors (V) 
% 2. Lattice offset (R)
% Together they gives the affine transformation between the physical 
% lattice frame and the camera frame

% Both lattice calibration (V, R) and PSF calibration are necessary to
% reconstruct counts at a given lattice site. To calibrate PSF, run the
% script_5.

%% Create a LatCalibrator object
% Configurable settings:
% - LatCalibFilePath: path to pre-calibration file to use, leave empty for 
%                     the first calibration
% - DataPath: path to .mat data file for this calibration. Lattice
%             calibration should work in both sparse and dense settings
% - LatCameraList: list of camera names for calibrating lattice V and R
% - LatImageLabel: corresponding list of image labels for lattice
%                  calibration
% - TemplatePath: path to template (real-space) pattern for visual check

clear; clc; close all
p = LatCalibrator( ... 
    "LatCalibFilePath", [], ...
    "DataPath", "data/2025/03 March/20250319/dense_calibration.mat", ... % "DataPath", "data/2025/02 February/20250225 modulation frequency scan/gray_calibration_square_width=5_spacing=150.mat", ...
    "LatCameraList", ["Andor19330", "Andor19331", "Zelux"], ...
    "LatImageLabel", ["Image", "Image", "Lattice_935"], ...
    "ProjectorList", "DMD");

%% Plot a single shot image to check
p.plotSignal(1)

%% Andor19330: Plot FFT of a small box centered at atom cloud
close all
p.plotFFT("Andor19330")

%% Andor19330: Input center of lattice and initial peak positions as [x1, y1; x2, y2]
% Select the *first* and *second* peaks to the right, clockwise from 12 o'clock
% The consistent peak selection is important to align the lattice axis
% among different frames.
% The coordinate is Matlab Y then Matlab X

close all
p.calibrate("Andor19330", [130, 237; 195, 283], ...
            'plot_diagnosticR', 1, ...
            'plot_diagnosticV', 1)

%% Andor19331: Plot FFT of a small box centered at atom cloud
close all
p.plotFFT("Andor19331")

%% Andor19331: Input the peaks that corresponds to the Andor19330 peaks under its coordinates
% Select the *second* and *first* peaks to the right, clockwise
% This is to align the vectors with the vectors selected for Andor19330

close all
p.calibrate("Andor19331", [163, 270; 121, 206], ...
            'plot_diagnosticR', 1, ...
            'plot_diagnosticV', 1)

%% Zelux: Plot FFT of the entire image
% Note that Zelux image has larger magnification and more noisy.
% Discretization improves the signal strength for atom image, but might not 
% work for lattice images

close all
p.plotFFT("Zelux")

%% Zelux: Input the FFT peaks positions
% Input in the orientation similar to Andor19330 to align lattice vectors
% Set 'binarize' to 0 to disable binarization in the calibration

close all
p.calibrate("Zelux", [658, 565; 714, 595], ...
            'binarize', false, ...
            'plot_diagnosticR', 1, ...
            'plot_diagnosticV', 1)

%% Cross-calibrate Andor19331 to Andor19330
% Matching the origin of the lattice between the two Andors

close all
p.calibrateO(1, 'sites', SiteGrid.prepareSite('Hex', 'latr', 20), 'plot_diagnosticO', 1)

%% (optional) cross-calibrate to a different signal index by searching a smaller region
% Matching the origin of the lattice between the two Andors
p.calibrateO(20, 'sites', SiteGrid.prepareSite('Hex', 'latr', 2), 'plot_diagnosticO', 0)

%% Plot an example of transformed signal to look at the overall calibration
p.plotTransformed("x_lim", [-20, 20], "y_lim", [-20, 20], "index", 1)

%% Cross-calibrate camera and projector
% Projector needs to project a pattern of two vertical lines and two
% horizontal lines, matching the default template image
p.calibrateProjectorPattern(1)

%%
% Check the image of pattern on camera (Zelux) and the actual 
% pattern (real-space, "template") with atom density
p.plotProjection()

%% Save lattice calibration of all three cameras
% Default is "calibration/LatCalib_<today's date>.mat" for a record
% It will also update the default LatCalib file "calibration/LatCalib.mat"
p.save()
