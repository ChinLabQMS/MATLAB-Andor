classdef PSFCalibrator < LatProcessor & DataProcessor
    %PSFCALIBRATOR Calibrator for
    % 1. Getting PSF calibration
    % 2. Analyze calibration drifts over time

    properties (SetAccess = {?BaseObject})
        PSFCameraList = ["Andor19330", "Andor19331", "Zelux"]
        PSFImageLabel = ["Image", "Image", "Pattern_532"]
    end

    properties (Constant)
        Process_FilterGaussWidthMax = 3.5
        Process_RefineMethod = "Gaussian"
        Process_FilterBoxSizeMax = 15
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

        function process(obj, camera, options)
            arguments
                obj
                camera
                options.filter_box_max = obj.Process_FilterBoxSizeMax
                options.filter_gausswid_max = obj.Process_FilterGaussWidthMax
                options.refine_method = obj.Process_RefineMethod
            end
            p = obj.PSFCalib.(camera);
            signal = obj.Stat.(camera);
            args = namedargs2cell(options);
            p.fit(signal, args{:}, 'reset', true) 
        end

        function plotSignal(obj, camera, index)
            arguments
                obj
                camera
                index = 1
            end
            figure
            imagesc2(obj.Stat.(camera)(:, :, index))
        end

        function plotPSF(obj, camera)
            obj.PSFCalib.(camera).plot()
        end

         % Save the calibration result to file
        function save(obj, filename)
            arguments
                obj
                filename = sprintf("calibration/PSFCalib_%s", datetime("now", "Format","uuuuMMdd"))
            end
            for camera = obj.PSFCameraList
                if isempty(obj.PSFCalib.(camera).PSF)
                    obj.warn2("Camera %s is not calibrated.", camera)
                end
            end
            PSFAll = obj.PSFCalib;
            PSFAll.Config = obj.struct();
            if filename.endsWith('.mat')
                filename = filename.extractBefore('.mat');
            end
            if isfile(filename + ".mat")
                filename = filename + sprintf("_%s", datetime("now", "Format", "HHmmss"));
            end
            save(filename, "-struct", "PSFAll")
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
                    obj.LatCalib.(camera).Magnification);
                obj.info('Empty PointSource object created for camera %s.', camera)
            end
        end
    end

end
