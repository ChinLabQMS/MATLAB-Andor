classdef PointSource < BaseObject

    properties (Constant)
        FindPeaks_BinThresholdMin = 20
        FindPeaks_BinThresholdMax = 50
        FindPeaks_BinThresholdPerct = 0.15
        FindPeaks_BinConnectivity = 8
        FindPeaks_FilterAreaMin = 4
        FindPeaks_DbscanDist = 10
        FindPeaks_DbscanSingleOnly = false
        FindPeaks_FilterIntensityMin = 50
        FindPeaks_FilterBoxSizeMax = [12, 12]
        FindPeaks_GaussFitCropRadius = []
        FindPeaks_FilterGaussWidthMax = 3
        FindPeaks_PlotDiagnostic = false
        MergePeaks_Scale = 10
        MergePeaks_CropRadius = [10, 10]
        Fit_Verbose = false
        Fit_Reset = false
    end

    properties (SetAccess = immutable)
        ID
    end

    properties (SetAccess = protected)
        PSF
        GaussPSF
        GaussGOF  % Goodness of fit
        DataPSF
        DataXRange
        DataYRange
        DataSumCount
        DataPeakCount
        DataStats
    end

    properties (Dependent)
        DataNumPeaks
        DataXRangeStep
        DataYRangeStep
    end

    methods
        function obj = PointSource(id)
            arguments
                id = "Test"
            end
            obj@BaseObject()
            obj.ID = id;
        end

        function fit(obj, img_data, opt, opt1, opt2)
            arguments
                obj
                img_data
                opt.reset = obj.Fit_Reset
                opt1.bin_threshold_min = obj.FindPeaks_BinThresholdMin
                opt1.bin_threshold_max = obj.FindPeaks_BinThresholdMax
                opt1.bin_threshold_perct = obj.FindPeaks_BinThresholdPerct
                opt1.bin_connectivity = obj.FindPeaks_BinConnectivity
                opt1.filter_area_min = obj.FindPeaks_FilterAreaMin
                opt1.dbscan_distance = obj.FindPeaks_DbscanDist
                opt1.dbscan_single_only = obj.FindPeaks_DbscanSingleOnly
                opt1.filter_intensity_min = obj.FindPeaks_FilterIntensityMin
                opt1.filter_box_max = obj.FindPeaks_FilterBoxSizeMax
                opt1.gauss_crop_radius = obj.FindPeaks_GaussFitCropRadius
                opt1.filter_gausswid_max = obj.FindPeaks_FilterGaussWidthMax
                opt1.plot_diagnostic = obj.FindPeaks_PlotDiagnostic
                opt1.verbose = obj.Fit_Verbose
                opt2.scale = obj.MergePeaks_Scale
                opt2.crop_radius = obj.MergePeaks_CropRadius
            end
            timer = tic;
            args1 = namedargs2cell(opt1);
            args2 = namedargs2cell(opt2);
            stats = obj.findPeaks(img_data, args1{:});
            if height(stats) > 0
                if opt.reset
                    obj.reset()
                end
                [psf, x_range, y_range] = obj.mergePeaks(img_data, stats, args2{:});
                obj.update(stats, psf, x_range, y_range)
            else
                obj.warn('No peak found from data!')
            end
            if opt1.verbose
                obj.info('PSF fitted from data (NumPeaks: %d), peak_count = %5.1f, sum_count = %7.1f, elapsed time is %5.3f s.', ...
                    obj.DataNumPeaks, obj.DataPeakCount, obj.DataSumCount, toc(timer))
            end
        end
    
        function stats_all = findPeaks(obj, img_all, options)
            arguments
                obj
                img_all
                options.bin_threshold_min = obj.FindPeaks_BinThresholdMin
                options.bin_threshold_max = obj.FindPeaks_BinThresholdMax
                options.bin_threshold_perct = obj.FindPeaks_BinThresholdPerct
                options.bin_connectivity = obj.FindPeaks_BinConnectivity
                options.filter_area_min = obj.FindPeaks_FilterAreaMin
                options.dbscan_distance = obj.FindPeaks_DbscanDist
                options.dbscan_single_only = obj.FindPeaks_DbscanSingleOnly
                options.filter_intensity_min = obj.FindPeaks_FilterIntensityMin
                options.filter_box_max = obj.FindPeaks_FilterBoxSizeMax
                options.gauss_crop_radius = obj.FindPeaks_GaussFitCropRadius
                options.filter_gausswid_max = obj.FindPeaks_FilterGaussWidthMax
                options.plot_diagnostic = obj.FindPeaks_PlotDiagnostic
                options.verbose = obj.Fit_Verbose
            end
            total_timer = tic;
            props = ["WeightedCentroid", "Area", "BoundingBox", "MaxIntensity", "PixelIdxList"];
            if isempty(options.gauss_crop_radius)
                options.gauss_crop_radius = [1, 1] * options.dbscan_distance;
            end
            stats_all = table();
            for i = 1: size(img_all, 3)
                timer = tic;
                img_data = img_all(:, :, i);
                % Digitize image and find connected components
                threshold = min(options.bin_threshold_max, ...
                    max(options.bin_threshold_min, ...
                    options.bin_threshold_perct * max(img_data(:))));
                img_bin = img_data > threshold;
                img_cc = bwconncomp(img_bin, options.bin_connectivity);
                stats = regionprops("table", img_cc, img_data, props);
            
                % Filter the connected components by area to get rid of noise peaks
                stats0 = stats;
                stats = stats(stats.Area >= options.filter_area_min, :);
            
                % Use dbscan to find clusters of peaks
                stats1 = stats;
                labels = zeros(size(img_data));
                for j = 1: height(stats)
                    labels(stats.PixelIdxList{j}) = j;
                end
                [Y, X] = meshgrid(1:size(labels, 2), 1:size(labels, 1));
                pix_x = X(labels > 0);
                pix_y = Y(labels > 0);
                clusters = dbscan([pix_x, pix_y], options.dbscan_distance, 1);
                labels(sub2ind(size(labels), pix_x, pix_y)) = clusters;
                for j = 1:height(stats)
                    stats.Cluster(j) = mode(labels(stats.PixelIdxList{j}));
                end
                stats = convertvars(stats, 'Cluster', 'categorical');
                stats = join(stats, groupsummary(stats, "Cluster"));
                if options.dbscan_single_only
                    % Only look at singly isolated peaks
                    stats = stats(stats.GroupCount == 1, :);
                else
                    % Merge peaks by cluster assignment to get a shorter stats
                    stats = regionprops("table", labels, img_data, props);
                end
            
                % Filter again by intensity and bounding box size
                stats2 = stats;
                threshold = max(options.filter_intensity_min, ...
                    options.bin_threshold_perct * max(img_data(:)));
                stats = stats(stats.MaxIntensity >= threshold, :);
                stats3 = stats;
                stats = stats((stats.BoundingBox(:, 3) <= options.filter_box_max(2)) & ...
                              (stats.BoundingBox(:, 4) <= options.filter_box_max(1)), :);
            
                % Refine the centroids by fitting 2D Gaussian and filter by width
                stats4 = stats;
                if options.filter_gausswid_max < inf
                    for j = 1: height(stats)
                        center = round(stats.WeightedCentroid(j, :));
                        x_range = center(2) + (-options.gauss_crop_radius(1): options.gauss_crop_radius(1));
                        y_range = center(1) + (-options.gauss_crop_radius(end): options.gauss_crop_radius(end));
                        x_range = x_range((x_range > 0) & (x_range <= size(img_data, 1)));
                        y_range = y_range((y_range > 0) & (y_range <= size(img_data, 1)));
                        spot = img_data(x_range, y_range);
                        [f, gof] = fitGauss2D(spot, x_range, y_range, 'cross_term', true);
                        stats.RefinedCentroid(j, :) = [f.y0, f.x0];
                        stats.RefinedWidth(j, :) = gof.eigen_widths;
                        stats.RefinedAngle(j, :) = gof.eigen_angles;
                        stats.MaxRefinedWidth(j) = max(gof.eigen_widths);
                        stats.RefinedRSquare(j) = gof.rsquare;
                    end
                    stats = stats(stats.MaxRefinedWidth < options.filter_gausswid_max, :);
                end
                
                % Add result to table
                stats.ImageIndex = repmat(i, height(stats), 1);
                stats_all = [stats_all; stats];
                
                if options.plot_diagnostic
                    plotPeaks(img_data, img_bin, stats0, stats1, stats2, stats3, stats4, stats)
                end
                if options.verbose
                    obj.info('Found %d (%d/%d/%d/%d/%d) peaks, elapsed time is %g s.', ...
                        height(stats), height(stats0), height(stats1), height(stats2), ...
                        height(stats3), height(stats4), toc(timer))
                end
            end
            if options.verbose
                obj.info('Total elapsed time is %g s.', toc(total_timer))
            end
        end

        function [psf, x_range, y_range, peaks] = mergePeaks(obj, img_all, stats, options)
            arguments
                obj
                img_all
                stats
                options.scale = obj.MergePeaks_Scale
                options.crop_radius = obj.MergePeaks_CropRadius
            end
            peaks = repmat(zeros(options.scale * (2*options.crop_radius + 1)), ...
                           1, 1, height(stats));
            x_size = options.scale * (2*options.crop_radius(1) + 1);
            y_size = options.scale * (2*options.crop_radius(end) + 1);
            x_range = ((1: x_size) - (1 + x_size)/2)./options.scale;
            y_range = ((1: y_size) - (1 + y_size)/2)./options.scale;
            padded = zeros(size(img_all, 1) + 2*options.crop_radius(1)+2, ...
                           size(img_all, 2) + 2*options.crop_radius(end)+2);
            img_x = options.crop_radius(1)+1 + (1: size(img_all, 1));
            img_y = options.crop_radius(end)+1 + (1: size(img_all, 2));
            curr = 0;
            for i = 1: height(stats)
                img_data = padded;
                img_data(img_x, img_y) = img_all(:, :, stats.ImageIndex(i));
                center = stats.RefinedCentroid(i, :);
                sample_x = round(center(2)) + options.crop_radius(1)+1 + ...
                        (-options.crop_radius(1): options.crop_radius(1));
                sample_y = round(center(1)) + options.crop_radius(end)+1 + ...
                    (-options.crop_radius(end): options.crop_radius(end));
                sample = kron(img_data(sample_x, sample_y), ones(options.scale));
                x_shift = round(options.scale * (round(center(2)) - center(2)));
                y_shift = round(options.scale * (round(center(1)) - center(1)));
                % Shift the center with sub-pixel resolution
                sample = circshift(sample, x_shift, 1);
                sample = circshift(sample, y_shift, 2);
                curr = curr + 1;
                peaks(:, :, curr) = sample;
            end
            psf = mean(peaks, 3);
        end

        function reset(obj)
            obj.PSF = [];
            obj.GaussPSF = [];
            obj.GaussGOF = [];
            obj.DataPSF = [];
            obj.DataXRange = [];
            obj.DataYRange = [];
            obj.DataSumCount = [];
            obj.DataPeakCount = [];
            obj.DataStats = [];
        end

        function update(obj, stats, psf, x_range, y_range, reset)
            arguments
                obj
                stats
                psf
                x_range = 1: size(psf, 1)
                y_range = 1: size(psf, 2)
                reset = isempty(obj.PSF)
            end
            if ~reset && (~isequal(x_range, obj.DataXRange) || ~isequal(y_range, obj.DataYRange))
                obj.warn2('Unable to add fitted PSF to the existing result, range does not match. Reset result to new data.')
                reset = true;
            end
            obj.DataXRange = x_range;
            obj.DataYRange = y_range;
            peak_count = max(psf(:));
            sum_count = sum(psf, 'all') * obj.DataXRangeStep * obj.DataYRangeStep;
            if reset || isempty(obj.PSF)
                obj.DataStats = stats;
                obj.DataPeakCount = peak_count;
                obj.DataSumCount = sum_count;
                obj.DataPSF = psf / sum_count;
            else
                old_num = obj.DataNumPeaks;
                new_num = height(stats);
                obj.DataStats = [obj.DataStats; stats];
                old_weight = old_num / (old_num + new_num);
                new_weight = new_num / (old_num + new_num);
                obj.DataPeakCount = obj.DataPeakCount * old_weight + peak_count * new_weight;
                obj.DataSumCount = obj.DataSumCount * old_weight + sum_count * new_weight;
                obj.DataPSF = obj.DataPSF * old_weight + psf / sum_count * new_weight;
            end
            [Y, X] = meshgrid(y_range, x_range);
            obj.PSF = @(x, y) interp2(Y, X, obj.DataPSF, y, x);
            [gauss_fit, gof] = fitGauss2D(obj.DataPSF * obj.DataSumCount, ...
                x_range, y_range, "cross_term", true);
            obj.GaussPSF = gauss_fit;
            obj.GaussGOF = gof;
        end
        
        function disp(obj)
            fprintf('%s: \n', obj.getStatusLabel())
            for p = ["DataNumPeaks", "DataPeakCount", "DataSumCount"]
                fprintf('%15s: %g\n', p, obj.(p))
            end
            if ~isempty(obj.GaussPSF)
                fprintf('Gaussian PSF fit\n')
                disp(obj.GaussPSF)
                disp(obj.GaussGOF)
            end
        end

        function varargout = plot(obj)
            h = imagesc2(obj.DataYRange, obj.DataXRange, obj.DataPSF);
            title(obj.ID)
            if nargout == 1
                varargout{1} = h;
            end
        end

        function val = get.DataNumPeaks(obj)
            val = height(obj.DataStats);
        end

        function val = get.DataXRangeStep(obj)
            if isempty(obj.DataXRange)
                val = nan;
            else
                val = obj.DataXRange(2) - obj.DataXRange(1);
            end
        end

        function val = get.DataYRangeStep(obj)
            if isempty(obj.DataYRange)
                val = nan;
            else
                val = obj.DataYRange(2) - obj.DataYRange(1);
            end
        end
    end

    methods (Access = protected, Hidden)
        function label = getStatusLabel(obj)
            label = sprintf('%s (%s)', class(obj), obj.ID);
        end
    end
end

function plotPeaks(img_data, img_bin, stats0, stats1, stats2, stats3, stats4, stats5)
    figure
    subplot(2, 3, 1)
    imagesc2(img_bin.*img_data, 'title', sprintf('0.Discretized: %d', size(stats0, 1)))
    viscircles(stats0.WeightedCentroid, sqrt(stats0.Area)/2);
    subplot(2, 3, 2)
    imagesc2(img_data, 'title', sprintf('1.After filtering small area: %d', size(stats1, 1)))
    viscircles(stats0.WeightedCentroid, sqrt(stats0.Area)/2, 'Color', 'w', 'LineWidth', 0.5);
    viscircles(stats1.WeightedCentroid, sqrt(stats1.Area)/2);
    subplot(2, 3, 3)
    imagesc2(img_data, 'title', sprintf('2.After dbscan to find isolated: %d', size(stats2, 1)))
    viscircles(stats1.WeightedCentroid, sqrt(stats1.Area)/2, 'Color', 'w', 'LineWidth', 0.5);
    viscircles(stats2.WeightedCentroid, sqrt(stats2.Area)/2);
    subplot(2, 3, 4)
    imagesc2(img_data, 'title', sprintf('3.After filter low-intensity: %d', size(stats3, 1)))
    viscircles(stats2.WeightedCentroid, sqrt(stats2.Area)/2, 'Color', 'w', 'LineWidth', 0.5);
    viscircles(stats3.WeightedCentroid, sqrt(stats3.Area)/2);
    subplot(2, 3, 5)
    imagesc2(img_data, 'title', sprintf('4.After filter bounding box size: %d', size(stats4, 1)))
    viscircles(stats3.WeightedCentroid, sqrt(stats3.Area)/2, 'Color', 'w', 'LineWidth', 0.5);
    viscircles(stats4.WeightedCentroid, sqrt(stats4.Area)/2);
    subplot(2, 3, 6)
    imagesc2(img_data, 'title', sprintf('5.After filtering gaussian fit width: %d', size(stats5, 1)))
    viscircles(stats4.WeightedCentroid, sqrt(stats4.Area)/2, 'Color', 'w', 'LineWidth', 0.5);
    viscircles(stats5.RefinedCentroid, sqrt(stats5.Area)/2);
end
