classdef LatAnalyzer < BaseAnalyzer
    %LATANALYZER Base class for analyzing lattice. Default behavior is to
    % load lattice calibration upon setting the path, and process the
    % images to get averaged upon initialization.

    properties (SetAccess = {?BaseObject})
        LatCalibFilePath = "calibration/LatCalib_20241028.mat"
        CameraList = ["Andor19330", "Andor19331", "Zelux"]
        ImageLabel = ["Image", "Image", "Lattice"]
    end

    properties (SetAccess = protected)
        Stat
        LatCalib
    end

    methods
        function set.LatCalibFilePath(obj, path)
            obj.LatCalibFilePath = path;
            obj.loadLatCalibFile()
        end
    end
    
    methods (Access = protected, Hidden)
        % Generate stats (cloud centers, widths, FFT pattern, ...) for lattice calibration
        function init(obj)
            for i = 1: length(obj.CameraList)
                camera = obj.CameraList(i);
                label = obj.ImageLabel(i);
                s.MeanImage = getSignalSum(obj.Signal.(camera).(label), getNumFrames(obj.Signal.(camera).Config));
                [xc, yc, xw, yw] = fitCenter2D(s.MeanImage);                
                [s.FFTImage, s.FFTX, s.FFTY] = prepareBox(s.MeanImage, [xc, yc], 2*[xw, yw]);
                s.FFTPattern = abs(fftshift(fft2(s.FFTImage)));
                s.Center = [xc, yc];
                s.Width = [xw, yw];
                obj.Stat.(camera) = s;
            end
            obj.info("Finish processing to get averaged images and basic statistics.")
        end

        function loadLatCalibFile(obj)
            if ~isempty(obj.LatCalibFilePath)
                obj.LatCalib = load(obj.LatCalibFilePath);
                obj.info("Pre-calibration loaded from: '%s'.", obj.LatCalibFilePath)
            else
                obj.LatCalib = [];
                for camera = obj.CameraList
                    obj.LatCalib.(camera) = Lattice(camera);
                    obj.info("Empty Lattice object created for camera %s.", camera)
                end
            end
        end
    end
end
