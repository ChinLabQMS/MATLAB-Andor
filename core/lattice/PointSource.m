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
        FindPeaks_GaussFitCropRadius = [10, 10]
        FindPeaks_FilterGaussWidthMax = 3
        FindPeaks_PlotDiagnostic = false
        MergePeaks_SuperSample = 10
        MergePeaks_CropRadius = [20, 20]
        Update_NormalizeMethod = "Gaussian"
        Update_GaussFitCropRadius = [10, 10]
        Update_GaussFitSubSample = 10
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
        DataSumCount = 0
        DataStats
    end

    properties (Dependent)
        DataPSFNormalized
        DataNumPeaks
        DataPeakCount
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
                opt2.super_sample = obj.MergePeaks_SuperSample
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
            add_props = ["RefinedCentroid", "RefinedWidth", "RefinedAngle", "MaxRefinedWidth", "RefinedRSquare", "ImageIndex"];
            stats_all = table('Size', [0, length(props) + length(add_props)], ...
                'VariableTypes', repmat("doublenan", 1, length(props) + length(add_props)), ...
                'VariableNames', [props, add_props]);
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
                stats.RefinedCentroid = nan(height(stats), 2);
                stats.RefinedWidth = nan(height(stats), 2);
                stats.RefinedAngle = nan(height(stats), 2);
                stats.MaxRefinedWidth = nan(height(stats), 1);
                stats.RefinedRSquare = nan(height(stats), 1);
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
                
                % Add result to table
                stats.ImageIndex = repmat(i, height(stats), 1);
                stats_all = [stats_all; stats]; %#ok<AGROW>
                
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
                obj.info('Total elapsed time for finding peaks is %g s.', toc(total_timer))
            end
        end

        function [psf, x_range, y_range, peaks] = mergePeaks(~, img_all, stats, options)
            arguments
                ~
                img_all
                stats
                options.super_sample = obj.MergePeaks_Scale
                options.crop_radius = obj.MergePeaks_CropRadius
            end
            peaks = repmat(zeros(options.super_sample * (2*options.crop_radius + 1)), ...
                           1, 1, height(stats));
            x_size = options.super_sample * (2*options.crop_radius(1) + 1);
            y_size = options.super_sample * (2*options.crop_radius(end) + 1);
            x_range = ((1: x_size) - (1 + x_size)/2)./options.super_sample;
            y_range = ((1: y_size) - (1 + y_size)/2)./options.super_sample;
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
                sample = kron(img_data(sample_x, sample_y), ones(options.super_sample));
                x_shift = round(options.super_sample * (round(center(2)) - center(2)));
                y_shift = round(options.super_sample * (round(center(1)) - center(1)));
                % Shift the center with sub-pixel resolution
                sample = circshift(sample, x_shift, 1);
                sample = circshift(sample, y_shift, 2);
                curr = curr + 1;
                peaks(:, :, curr) = sample;
            end
            psf = mean(peaks, 3);
        end

        function update(obj, stats, psf, x_range, y_range, options)
            arguments
                obj
                stats
                psf
                x_range = 1: size(psf, 1)
                y_range = 1: size(psf, 2)
                options.gauss_crop_radius = obj.Update_GaussFitCropRadius
                options.gauss_sub_sample = obj.Update_GaussFitSubSample
                options.normalize_method = obj.Update_NormalizeMethod
            end
            if (~isempty(obj.DataXRange) && (~isequal(x_range, obj.DataXRange)) || ...
                    (~isempty(obj.DataYRange) && ~isequal(y_range, obj.DataYRange)))
                obj.warn2('Unable to add fitted PSF to the existing result, range does not match. Reset result to add new data.')
                obj.reset()
            end
            obj.DataXRange = x_range;
            obj.DataYRange = y_range;
            old_num = obj.DataNumPeaks;
            new_num = height(stats);
            old_weight = old_num / (old_num + new_num);
            new_weight = new_num / (old_num + new_num);
            obj.DataStats = [obj.DataStats; stats];
            if isempty(obj.DataPSF)
                obj.DataPSF = psf;
            else
                obj.DataPSF = obj.DataPSF * old_weight + psf * new_weight;
            end
            fit_x = (x_range >= -options.gauss_crop_radius(1)) & (x_range <= options.gauss_crop_radius(1));
            fit_y = (y_range >= -options.gauss_crop_radius(end)) & (y_range <= options.gauss_crop_radius(end));
            fit_data = obj.DataPSF(fit_x, fit_y);
            fit_x_range = x_range(fit_x);
            fit_y_range = y_range(fit_y);
            [obj.GaussPSF, obj.GaussGOF] = fitGauss2D(fit_data, fit_x_range, fit_y_range, ...
                'cross_term', true, 'sub_sample', options.gauss_sub_sample, 'offset', 'linear');
            switch options.normalize_method
                case "Gaussian"
                    sum_count = 2*pi*obj.GaussPSF.a* ...
                        obj.GaussGOF.eigen_widths(1)*obj.GaussGOF.eigen_widths(2);
                case "Sum"
                    sum_count = sum(fit_data(:)) * obj.DataXRangeStep * obj.DataYRangeStep;
            end
            obj.DataSumCount = obj.DataSumCount*old_weight + sum_count*new_weight;
            [Y, X] = meshgrid(y_range, x_range);
            obj.PSF = @(x, y) interp2(Y, X, obj.DataPSF / obj.DataSumCount, y, x);
        end

        function reset(obj)
            obj.PSF = [];
            obj.GaussPSF = [];
            obj.GaussGOF = [];
            obj.DataPSF = [];
            obj.DataXRange = [];
            obj.DataYRange = [];
            obj.DataSumCount = 0;
            obj.DataStats = [];
        end
        
        function disp(obj)
            fprintf('%s: \n', obj.getStatusLabel())
            for p = ["DataNumPeaks", "DataPeakCount", "DataSumCount"]
                fprintf('%15s: %g\n', p, obj.(p))
            end
            if ~isempty(obj.GaussPSF)
                fprintf('\nGaussian PSF fit:\n')
                disp(obj.GaussPSF)
                fprintf('\nGoodness of fit:\n')
                disp(obj.GaussGOF)
            end
        end

        function plot(obj, options)
            arguments
                obj
                options.show_gauss = true
            end
            [y, x, z] = prepareSurfaceData(obj.DataYRange, obj.DataXRange, obj.DataPSF);
            figure
            sgtitle(sprintf('%s, NumPeaks: %d', obj.ID, obj.DataNumPeaks))
            ax1 = subplot(1, 3, 1);
            ax2 = subplot(1, 3, 2);
            imagesc2(ax2, obj.DataYRange, obj.DataXRange, obj.DataPSF)
            xlabel('Y')
            ylabel('X')
            subplot(1, 3, 3)
            imagesc2(obj.DataYRange, obj.DataXRange, log(obj.DataPSF))
            xlabel('Y')
            ylabel('X')
            if options.show_gauss
                v1 = obj.GaussGOF.eigen_widths(1) * obj.GaussGOF.eigen_vectors(:, 1);
                v2 = obj.GaussGOF.eigen_widths(2) * obj.GaussGOF.eigen_vectors(:, 2);
                h = plot(ax1, obj.GaussPSF, [x, y], z);
                h(2).MarkerSize = 3;
                xlabel(ax1, 'X')
                ylabel(ax1, 'Y')

                hold(ax2, "on")
                quiver(ax2, 0, 0, v1(2), v1(1), ...
                    'LineWidth', 2, 'Color', 'r', 'MaxHeadSize', 10, ...
                    'DisplayName', sprintf("major width: %.3g", obj.GaussGOF.eigen_widths(1)))
                quiver(ax2, 0, 0, v2(2), v2(1), ...
                    'LineWidth', 2, 'Color', 'm', 'MaxHeadSize', 10, ...
                    'DisplayName', sprintf("minor width: %.3g", obj.GaussGOF.eigen_widths(2)))
                hold(ax2, "off")
                legend(ax2)
            else
                [y, x] = meshgrid(obj.DataYRange, obj.DataXRange);
                surf(ax1, y, x, obj.DataPSF, 'EdgeColor', 'none')
            end
        end

        function [peak_data, x_range, y_range] = extractPeak(obj, img_all, i, options)
            arguments
                obj
                img_all
                i = 1
                options.crop_radius = obj.MergePeaks_CropRadius
                options.plot = false
            end
            if i > height(obj.DataStats)
                obj.warn('Specified index is larger than number of stored peaks!')
                return
            end
            img_data = img_all(:, :, obj.DataStats.ImageIndex(i));
            center = round(obj.DataStats.RefinedCentroid(i, :));
            x_range = center(2) + (-options.crop_radius(1): options.crop_radius(1));
            y_range = center(1) + (-options.crop_radius(end): options.crop_radius(end));
            x_range = x_range((x_range > 0) & (x_range <= size(img_all, 1)));
            y_range = y_range((y_range > 0) & (y_range <= size(img_all, 2)));
            peak_data = img_data(x_range, y_range);
            if options.plot
                figure
                imagesc2(y_range, x_range, peak_data)
            end
        end

        function val = get.DataNumPeaks(obj)
            val = height(obj.DataStats);
        end

        function val = get.DataPeakCount(obj)
            if isempty(obj.DataStats)
                val = nan;
                return
            end
            val = mean(obj.DataStats.MaxIntensity);
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

        function psf = get.DataPSFNormalized(obj)
            psf = obj.DataPSF / obj.DataSumCount;
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
