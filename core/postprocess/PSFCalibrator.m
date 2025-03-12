classdef PSFCalibrator < DataProcessor & CombinedProcessor
    %FRAMECALIBRATOR Calibrator for
    % 1. Getting PSF calibration
    % 2. Analyze calibration drifts over time

    properties (SetAccess = {?BaseObject})
        PSFCameraList = ["Andor19330", "Andor19331", "Zelux"]
        PSFImageLabel = ["Image", "Image", "Pattern_532"]
    end
    
    properties (Constant)
        PlotPSF_XLim = [-2.5, 2.5] % in um
        PlotPSF_YLim = [-2.5, 2.5] % in um
        PlotPSF_StepDensity = 50
        TrackPeaks_Camera = "Zelux"
    end

    properties (SetAccess = protected)
        LabeledSignal
    end

    methods
        function obj = PSFCalibrator(varargin, options)
            arguments (Repeating)
                varargin
            end
            arguments
                options.reset_fields = true
                options.init = true
            end
            obj@DataProcessor('reset_fields', false, 'init', false)
            obj@CombinedProcessor(varargin{:}, 'reset_fields', options.reset_fields, 'init', options.init)
        end

        function fit(obj, camera, idx_range, ratio, varargin)
            arguments
                obj
                camera
                idx_range = []
                ratio = []
            end
            arguments (Repeating)
                varargin
            end
            if isempty(idx_range)
                idx_range = 1:size(obj.LabeledSignal.(camera), 3);
            end
            if ~isempty(ratio)
                obj.PSFCalib.(camera).setRatio(ratio);
            end
            p = obj.PSFCalib.(camera);
            signal = obj.LabeledSignal.(camera)(:, :, idx_range);
            p.fit(signal, varargin{:})
        end

        function plotPSF(obj, options)
            arguments
                obj
                options.x_lim = obj.PlotPSF_XLim
                options.y_lim = obj.PlotPSF_YLim
                options.scale = obj.PlotPSF_StepDensity
            end
            num_cameras = length(obj.PSFCameraList);
            args = namedargs2cell(options);
            figure('Name', 'PSF of all cameras')
            for i = 1: num_cameras
                camera = obj.PSFCameraList(i);
                ps = obj.PSFCalib.(camera);
                lat = obj.LatCalib.(camera).copy('r', [0, 0]);
                subplot(2, num_cameras, i)
                [transformed, x_range, y_range] = lat.transformFunctionalStandard( ...
                    ps.IdealPSFAiry, args{:});
                imagesc2(y_range, x_range, transformed * ps.DataSumCount, ...
                    'title', sprintf('Ideal PSF, %s', camera))
                viscircles([0, 0], lat.RealSpacing / 2, ...
                    'LineStyle', '--', 'LineWidth', 0.5, 'EnhanceVisibility', 0);
                xlabel('X (\mum)')
                ylabel('Y (\mum)')
                subplot(2, num_cameras, num_cameras + i)
                if isempty(ps.PSF)
                    continue
                end
                [transformed, x_range, y_range] = lat.transformFunctionalStandard( ...
                    ps.PSF, args{:});
                imagesc2(y_range, x_range, transformed * ps.DataSumCount, ...
                    'title', sprintf('Actual PSF, %s', camera))
                viscircles([0, 0], lat.RealSpacing / 2, ...
                    'LineStyle', '--', 'LineWidth', 0.5, 'EnhanceVisibility', 0);
                xlabel('X (\mum)')
                ylabel('Y (\mum)')
            end
        end

        function plotSignal(obj, index)
            arguments
                obj
                index = 1
            end
            num_cameras = length(obj.PSFCameraList);
            figure
            sgtitle(sprintf('Image index: %d', index))
            for i = 1: num_cameras
                camera = obj.PSFCameraList(i);
                subplot(1, num_cameras, i)
                imagesc2(obj.LabeledSignal.(camera)(:, :, index), 'title', camera)
            end
        end

        function result = trackPeaks(obj, camera, centroids, varargin)
            arguments
                obj
                camera = obj.TrackPeaks_Camera
                centroids = []
            end
            arguments (Repeating)
                varargin
            end
            img_all = obj.LabeledSignal.(camera);
            ps = obj.PSFCalib.(camera);
            lat = obj.LatCalib.(camera);
            result = ps.trackPeaks(img_all, centroids, lat, varargin{:});
        end

        % Save the calibration result to file
        function save(obj, filename, most_recent_filename, options)
            arguments
                obj
                filename = sprintf("calibration/dated_PSFCalib/PSFCalib_%s", datetime("now", "Format","uuuuMMdd"))
                most_recent_filename = "calibration/PSFCalib.mat"
                options.clear_before_save = true
            end
            calib.Config = obj.struct();
            for camera = obj.PSFCameraList
                ps = obj.PSFCalib.(camera);
                if isempty(ps.PSF)
                    obj.warn2("Camera %s is not calibrated.", camera)
                end
                if options.clear_before_save
                    ps.clear()
                end
                calib.(camera) = ps;
            end
            if filename.endsWith('.mat')
                filename = filename.extractBefore('.mat');
            end
            if isfile(filename + ".mat")
                filename = filename + sprintf("_%s", datetime("now", "Format", "HHmmss"));
            end
            save(filename, "-struct", "calib")
            save(most_recent_filename, "-struct", "calib")
            obj.info("PSF calibration saved as '%s' and '%s'.", filename, most_recent_filename)
        end
    end

    methods (Access = protected, Hidden)
        function init(obj, skip_init_data)
            arguments
                obj 
                skip_init_data = false
            end
            if ~skip_init_data
                init@DataProcessor(obj)
            end
            for i = 1: length(obj.PSFCameraList)
                camera = obj.PSFCameraList(i);
                label = obj.PSFImageLabel(i);
                if label.contains("_")
                    wavelength = label.extractAfter("_");
                else
                    wavelength = "852";
                end
                obj.LabeledSignal.(camera) = obj.Signal.(camera).(label);
                if ~isfield(obj.PSFCalib, camera)
                    if isfield(obj.LatCalib, camera)
                        obj.PSFCalib.(camera) = PointSource( ...
                            camera, obj.Signal.(camera).Config.PixelSize, ...
                            double(wavelength) / 1000, ...
                            obj.LatCalib.(camera).Magnification, 'verbose', true);
                    else
                        obj.PSFCalib.(camera) = PointSource( ...
                            camera, obj.Signal.(camera).Config.PixelSize, ...
                            double(wavelength) / 1000, 'verbose', true);
                    end
                else
                    obj.info('Found PSF calibration for %s in loaded PSFCalib file.', camera)
                end
            end
        end
    end

end
