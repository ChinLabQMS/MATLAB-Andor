classdef PSFCalibrator < LatProcessor & DataProcessor
    %PSFCALIBRATOR Calibrator for
    % 1. Getting PSF calibration
    % 2. Analyze calibration drifts over time

    properties (SetAccess = {?BaseObject})
        PSFCameraList = ["Andor19330", "Andor19331", "Zelux"]
        PSFImageLabel = ["Image", "Image", "Pattern_532"]
        PSFInitRatio = [1.3, 1.5, 4]
    end

    properties (SetAccess = protected)
        PSFCalib
        Stat
    end

    methods
        function obj = PSFCalibrator(varargin)
            obj@DataProcessor('reset_fields', false, 'init', false)
            obj@LatProcessor(varargin{:}, 'reset_fields', true, 'init', true)
        end

        function fit(obj, camera, idx_range, varargin)
            arguments
                obj
                camera
                idx_range = []
            end
            arguments (Repeating)
                varargin
            end
            if isempty(idx_range)
                idx_range = 1:size(obj.Stat.(camera), 3);
            end
            p = obj.PSFCalib.(camera);
            signal = obj.Stat.(camera)(:, :, idx_range);
            p.fit(signal, varargin{:})
        end

        function plotSignal(obj, index)
            if nargin == 1
                index = 1;
            end
            num_cameras = length(obj.PSFCameraList);
            figure
            sgtitle(sprintf('Image index: %d', index))
            for i = 1: num_cameras
                camera = obj.PSFCameraList(i);
                subplot(1, num_cameras, i)
                imagesc2(obj.Stat.(camera)(:, :, index), 'title', camera)
            end
        end

        % Save the calibration result to file
        function save(obj, filename, options)
            arguments
                obj
                filename = sprintf("calibration/PSFCalib_%s", datetime("now", "Format","uuuuMMdd"))
                options.clear_before_save = true
            end
            calib = obj.PSFCalib;
            calib.Config = obj.struct();
            for camera = obj.PSFCameraList
                if isempty(calib.(camera).PSF)
                    obj.warn2("Camera %s is not calibrated.", camera)
                end
                if options.clear_before_save
                    calib.(camera).clear()
                end
            end
            if filename.endsWith('.mat')
                filename = filename.extractBefore('.mat');
            end
            if isfile(filename + ".mat")
                filename = filename + sprintf("_%s", datetime("now", "Format", "HHmmss"));
            end
            save(filename, "-struct", "calib")
            obj.info("PSF calibration saved as '%s'.", filename)
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            init@DataProcessor(obj)
            for i = 1: length(obj.PSFCameraList)
                camera = obj.PSFCameraList(i);
                label = obj.PSFImageLabel(i);
                if label.contains("_")
                    wavelength = label.extractAfter("_");
                else
                    wavelength = "852";
                end
                obj.Stat.(camera) = obj.Signal.(camera).(label);
                obj.PSFCalib.(camera) = PointSource(camera, ...
                    obj.Signal.(camera).Config.PixelSize, ...
                    double(wavelength) / 1000, ...
                    obj.LatCalib.(camera).Magnification, ...
                    obj.PSFInitRatio(i));
                obj.info('Empty PointSource object created for camera %s.', camera)
            end
        end
    end

end
