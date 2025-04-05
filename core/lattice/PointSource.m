classdef PointSource < BaseComputer

    properties (Constant)
        Fit_Verbose = false
        Fit_Reset = true
        Fit_AutoResetWhenReachNumPeaks = 200
        Fit_AutoResetWhenReachRunNum = 5
        Fit_Timeoutms = 1000
        FindPeaks_BinThresholdMin = 20
        FindPeaks_BinThresholdMax = 50
        FindPeaks_BinThresholdPerct = 0.15
        FindPeaks_BinConnectivity = 8
        FindPeaks_FilterAreaMin = 4
        FindPeaks_DbscanDist = 2 % Multiply by RayleighResolution
        FindPeaks_DbscanSingleOnly = false
        FindPeaks_FilterIntensityMin = 50
        FindPeaks_FilterBoxSizeMin = 0.2 % Multiply by RayleighResolution
        FindPeaks_FilterBoxSizeMax = 2.5 % Multiply by RayleighResolution
        FindPeaks_RefineCropRadius = 2 % Multiply by RayleighResolution
        FindPeaks_GaussRefineSubSample = 0.3 % Multiply by RayleighResolution
        FindPeaks_FilterGaussWidthMax = 0.5 % Multiply by RayleighResolution
        FindPeaks_RefineMethod = "Gaussian"
        FindPeaks_PlotDiagnostic = false
        MergePeaks_SuperSample = 70 % Divided by RayleighResolution
        MergePeaks_CropRadius = 3 % Multiply by RayleighResolution 
        Update_WarnThreshold = 0.1
        Update_NormalizeMethod = "Gaussian" 
        Update_GaussFitCropRadius = 2 % Multiply by RayleighResolution
        Update_GaussFitSubSample = 70 % Divided by RayleighResolution
        Update_UpdateResolutionRatio = false
        Plot_ShowGaussSurface = true
        Plot_ShowIdealPSF = false
        Plot_LineCutRange = -10:0.01:10
    end

    properties (SetAccess = immutable)
        NA
        PixelSize
        ImagingWavelength
        Magnification
    end

    properties (SetAccess = protected)
        InitResolutionRatio = 1
        RunNumber
        RayleighResolution
        IdealPSFGauss
        IdealPSFAiry
        IdealPSFGaussPeakIntensity
        IdealPSFAiryPeakIntensity
        PSF
        GaussPSF
        GaussGOF  % Goodness of fit
        DataPSF
        DataXRange
        DataYRange
        DataSumCount = 0
        DataStats
        DataLastStats
        DataLastImages
        DataWidthMean
        DataWidthCov
    end

    properties (Dependent)
        RayleighResolutionGaussSigma
        GaussResolutionRatio
        DataPSFNormalized
        DataNumPeaks
        DataPeakCount
        DataXRangeStep
        DataYRangeStep
        StrehlRatioGauss
        StrehlRatioAiry
    end

    methods
        function obj = PointSource(id, pixel_size, wavelength, magnification, na, options)
            arguments
                id = "Test"
                pixel_size = 13
                wavelength = 0.852
                magnification = 89
                na = 0.8
                options.verbose = false
            end
            obj@BaseComputer(id)
            obj.NA = na;
            obj.PixelSize = pixel_size;
            obj.ImagingWavelength = wavelength;
            obj.Magnification = magnification;
            obj.init()
            if options.verbose
                obj.info(['Empty object created, pixel_size = %.3g um, ' ...
                    'imaging wavelength = %.3g um, magnification = %.3g, NA = %.2g.'], ...
                    pixel_size, wavelength, magnification, na)
            end
        end

        function result = trackPeaks(obj, img_all, centroids, Lat, opt1)
            arguments
                obj
                img_all 
                centroids = []
                Lat = []
                opt1.bin_threshold_min = obj.FindPeaks_BinThresholdMin
                opt1.bin_threshold_max = obj.FindPeaks_BinThresholdMax
                opt1.bin_threshold_perct = obj.FindPeaks_BinThresholdPerct
                opt1.bin_connectivity = obj.FindPeaks_BinConnectivity
                opt1.filter_area_min = obj.FindPeaks_FilterAreaMin
                opt1.dbscan_distance = (obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_DbscanDist
                opt1.dbscan_single_only = obj.FindPeaks_DbscanSingleOnly
                opt1.filter_intensity_min = obj.FindPeaks_FilterIntensityMin
                opt1.filter_box_min = (obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_FilterBoxSizeMin
                opt1.filter_box_max = (obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_FilterBoxSizeMax
                opt1.refine_method = obj.FindPeaks_RefineMethod
                opt1.refine_radius = round((obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_RefineCropRadius)
                opt1.gauss_refine_subsample = round((obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_GaussRefineSubSample)
                opt1.filter_gausswid_max = (obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_FilterGaussWidthMax
                opt1.plot_diagnostic = obj.FindPeaks_PlotDiagnostic
            end
            % If no initial peak position is provided, find all peaks in
            % the first image
            args1 = namedargs2cell(opt1);
            if isempty(centroids)
                first_img = img_all(:, :, 1);
                stats = obj.findPeaks(first_img, args1{:});
                centroids = stats.RefinedCentroid;
            end
            num_acq = size(img_all, 3);
            num_peaks = height(centroids);
            result = table('Size', [num_acq, 0], ...
                           'VariableTypes', []);
            result.R1 = nan(num_acq, 1);
            result.R2 = nan(num_acq, 1);
            result.R1_Std = nan(num_acq, 1);
            result.R2_Std = nan(num_acq, 1);
            result.R1_Peak = nan(num_acq, num_peaks);
            result.R2_Peak = nan(num_acq, num_peaks);
            result.R1_Drift = nan(num_acq, num_peaks);
            result.R2_Drift = nan(num_acq, num_peaks);
            result.LatR1 = nan(num_acq, 1);
            result.LatR2 = nan(num_acq, 1);
            result.LatR1_Drift = nan(num_acq, num_peaks);
            result.LatR2_Drift = nan(num_acq, num_peaks);
            result.LatR1_Std = nan(num_acq, 1);
            result.LatR2_Std = nan(num_acq, 1);
            obj.info('Start tracking peak centroids...')
            for i = 1: num_acq
                img_data = img_all(:, :, i);
                new_centroids = centroids;
                for j = 1: num_peaks
                    new_centroids(j, :) = refineCentroid( ...
                            img_data, centroids(j, :), opt1.refine_radius, opt1.refine_method, opt1.gauss_refine_subsample);
                end
                R = mean(new_centroids(:, 2:-1:1), 1);
                R_Drift = new_centroids(:, 2:-1:1) - centroids(:, 2:-1:1);
                if ~isempty(Lat) & ~isempty(Lat.V)
                    LatR = R / Lat.V;
                    LatR_Drift = R_Drift / Lat.V;
                else
                    LatR = nan(1, 2);
                    LatR_Drift = nan(num_peaks, 2);
                end
                result.R1(i) = R(1);
                result.R2(i) = R(2);
                result.R1_Std(i) = std(R_Drift(:, 1));
                result.R2_Std(i) = std(R_Drift(:, 2));
                result.R1_Peak(i, :) = centroids(:, 2)';
                result.R2_Peak(i, :) = centroids(:, 1)';
                result.R1_Drift(i, :) = R_Drift(:, 1)';
                result.R2_Drift(i, :) = R_Drift(:, 2)';
                result.LatR1(i) = LatR(1);
                result.LatR2(i) = LatR(2);
                result.LatR1_Drift(i, :) = LatR_Drift(:, 1)';
                result.LatR2_Drift(i, :) = LatR_Drift(:, 2)';
                result.LatR1_Std(i) = std(LatR_Drift(:, 1));
                result.LatR2_Std(i) = std(LatR_Drift(:, 2));
                centroids = new_centroids;
            end
            obj.info('Finish tracking peak centroids.')
        end

        function fit(obj, img_all, opt, opt1, opt2, opt3)
            arguments
                obj
                img_all
                opt.reset = obj.Fit_Reset
                opt.auto_reset_runnum = obj.Fit_AutoResetWhenReachRunNum
                opt.auto_reset_preaknum = obj.Fit_AutoResetWhenReachNumPeaks
                opt.timeout = obj.Fit_Timeoutms
                opt1.bin_threshold_min = obj.FindPeaks_BinThresholdMin
                opt1.bin_threshold_max = obj.FindPeaks_BinThresholdMax
                opt1.bin_threshold_perct = obj.FindPeaks_BinThresholdPerct
                opt1.bin_connectivity = obj.FindPeaks_BinConnectivity
                opt1.filter_area_min = obj.FindPeaks_FilterAreaMin
                opt1.dbscan_distance = (obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_DbscanDist
                opt1.dbscan_single_only = obj.FindPeaks_DbscanSingleOnly
                opt1.filter_intensity_min = obj.FindPeaks_FilterIntensityMin
                opt1.filter_box_min = (obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_FilterBoxSizeMin
                opt1.filter_box_max = (obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_FilterBoxSizeMax
                opt1.refine_method = obj.FindPeaks_RefineMethod
                opt1.refine_radius = round((obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_RefineCropRadius)
                opt1.gauss_refine_subsample = round((obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_GaussRefineSubSample)
                opt1.filter_gausswid_max = (obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_FilterGaussWidthMax
                opt1.plot_diagnostic = obj.FindPeaks_PlotDiagnostic
                opt1.verbose = obj.Fit_Verbose
                opt2.super_sample = round(obj.MergePeaks_SuperSample / (obj.InitResolutionRatio * obj.RayleighResolution))
                opt2.crop_radius = round(obj.MergePeaks_CropRadius * (obj.InitResolutionRatio * obj.RayleighResolution))
                opt3.warn_thres = obj.Update_WarnThreshold
                opt3.gauss_crop_radius = round((obj.InitResolutionRatio * obj.RayleighResolution) * obj.Update_GaussFitCropRadius)
                opt3.gauss_sub_sample = round(obj.Update_GaussFitSubSample / (obj.InitResolutionRatio * obj.RayleighResolution))
                opt3.normalize_method = obj.Update_NormalizeMethod
                opt3.update_ratio = obj.Update_UpdateResolutionRatio
            end
            start_time = tic;
            args1 = namedargs2cell(opt1);
            args2 = namedargs2cell(opt2);
            args3 = namedargs2cell(opt3);
            obj.RunNumber = obj.RunNumber + 1;
            obj.DataLastImages = img_all;            
            if opt.reset
                obj.reset()
                obj.info('PSF data is reset.')
            elseif (obj.DataNumPeaks >= opt.auto_reset_preaknum) || ...
                    (rem(obj.RunNumber, opt.auto_reset_runnum) == 0)
                obj.reset()
                obj.info('Reset frequency reached, PSF data is reset.')
            end
            stats = obj.findPeaks(img_all, args1{:});
            obj.DataLastStats = stats;
            if height(stats) > 0
                [psf, x_range, y_range] = obj.mergePeaks(img_all, stats, args2{:});
                obj.updatePSF(stats, psf, x_range, y_range, args3{:})
            else
                obj.warn('No peak found from data!')
            end
            if opt1.verbose
                obj.info('PSF fitted from data (NumPeaks: %d), peak_count = %5.1f, sum_count = %7.1f, elapsed time is %5.3f s.', ...
                    obj.DataNumPeaks, obj.DataPeakCount, obj.DataSumCount, toc(start_time))
            end
        end
        
        % Find all isolated peaks in the image data
        function stats_all = findPeaks(obj, img_all, opt1)
            arguments
                obj
                img_all
                opt1.bin_threshold_min = obj.FindPeaks_BinThresholdMin
                opt1.bin_threshold_max = obj.FindPeaks_BinThresholdMax
                opt1.bin_threshold_perct = obj.FindPeaks_BinThresholdPerct
                opt1.bin_connectivity = obj.FindPeaks_BinConnectivity
                opt1.filter_area_min = obj.FindPeaks_FilterAreaMin
                opt1.dbscan_distance = (obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_DbscanDist
                opt1.dbscan_single_only = obj.FindPeaks_DbscanSingleOnly
                opt1.filter_intensity_min = obj.FindPeaks_FilterIntensityMin
                opt1.filter_box_min = (obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_FilterBoxSizeMin
                opt1.filter_box_max = (obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_FilterBoxSizeMax
                opt1.refine_method = obj.FindPeaks_RefineMethod
                opt1.refine_radius = round((obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_RefineCropRadius)
                opt1.gauss_refine_subsample = round((obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_GaussRefineSubSample)
                opt1.filter_gausswid_max = (obj.InitResolutionRatio * obj.RayleighResolution) * obj.FindPeaks_FilterGaussWidthMax
                opt1.plot_diagnostic = obj.FindPeaks_PlotDiagnostic
                opt1.verbose = obj.Fit_Verbose
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
                threshold = min(opt1.bin_threshold_max, ...
                    max(opt1.bin_threshold_min, ...
                    opt1.bin_threshold_perct * max(img_data(:))));
                img_bin = img_data > threshold;
                img_cc = bwconncomp(img_bin, opt1.bin_connectivity);
                stats = regionprops("table", img_cc, img_data, props);
            
                % Filter the connected components by area to get rid of noise peaks
                stats0 = stats;
                stats = stats(stats.Area >= opt1.filter_area_min, :);
            
                % Use dbscan to find clusters of peaks
                stats1 = stats;
                if height(stats) ~= 0
                    labels = zeros(size(img_data));
                    for j = 1: height(stats)
                        labels(stats.PixelIdxList{j}) = j;
                    end
                    [Y, X] = meshgrid(1:size(labels, 2), 1:size(labels, 1));
                    pix_x = X(labels > 0);
                    pix_y = Y(labels > 0);
                    clusters = dbscan([pix_x, pix_y], opt1.dbscan_distance, 1);
                    labels(sub2ind(size(labels), pix_x, pix_y)) = clusters;
                    for j = 1:height(stats)
                        stats.Cluster(j) = mode(labels(stats.PixelIdxList{j}));
                    end
                    stats = convertvars(stats, 'Cluster', 'categorical');
                    stats = join(stats, groupsummary(stats, "Cluster"));
                    if opt1.dbscan_single_only
                        % Only look at singly isolated peaks
                        stats = stats(stats.GroupCount == 1, :);
                    else
                        % Merge peaks by cluster assignment to get a shorter stats
                        stats = regionprops("table", labels, img_data, props);
                    end
                end
            
                % Filter again by bounding box size and intensity
                stats2 = stats;
                stats = stats((stats.BoundingBox(:, 3) <= opt1.filter_box_max(end)) & ...
                              (stats.BoundingBox(:, 4) <= opt1.filter_box_max(1)), :);
                stats = stats((stats.BoundingBox(:, 3) >= opt1.filter_box_min(end)) & ...
                              (stats.BoundingBox(:, 4) >= opt1.filter_box_min(1)), :);
                stats3 = stats;
                threshold = max(opt1.filter_intensity_min, ...
                    opt1.bin_threshold_perct * max(img_data(:)));
                stats = stats(stats.MaxIntensity >= threshold, :);
            
                % Refine the centroid by fitting 2D Gaussian and filter by width
                stats4 = stats;
                stats.RefinedCentroid = nan(height(stats), 2);
                stats.RefinedWidth = nan(height(stats), 2);
                stats.MaxRefinedWidth = nan(height(stats), 1);
                stats.RefinedAngle = nan(height(stats), 2);
                stats.RefinedRSquare = nan(height(stats), 1);
                for j = 1: height(stats)
                    [refined_centroid, refined_width, refined_angle, rsquare] = refineCentroid( ...
                        img_data, ...
                        stats.WeightedCentroid(j, :), ...
                        opt1.refine_radius, ...
                        opt1.refine_method, ...
                        opt1.gauss_refine_subsample);
                    stats.RefinedCentroid(j, :) = refined_centroid;
                    stats.RefinedWidth(j, :) = refined_width;
                    stats.RefinedAngle(j, :) = refined_angle;
                    stats.RefinedRSquare(j, :) = rsquare;
                end
                stats.MaxRefinedWidth = stats.RefinedWidth(:, 2);
                stats = stats(stats.MaxRefinedWidth < opt1.filter_gausswid_max, :);       
                
                % Add result to table
                stats.ImageIndex = repmat(i, height(stats), 1);
                stats_all = [stats_all; stats]; %#ok<AGROW>
                
                if opt1.plot_diagnostic
                    plotPeaks(obj.ID, img_data, img_bin, stats0, stats1, stats2, stats3, stats4, stats)
                end
                if opt1.verbose
                    obj.info('Found %d (%d/%d/%d/%d/%d) peaks, elapsed time is %g s.', ...
                        height(stats), height(stats0), height(stats1), height(stats2), ...
                        height(stats3), height(stats4), toc(timer))
                end
            end
            if opt1.verbose
                obj.info('Total elapsed time for finding peaks is %g s.', toc(total_timer))
            end
        end
    
        % Merge all the isolated peaks to get PSF
        function [psf, x_range, y_range, peaks] = mergePeaks(obj, img_all, stats, opt2)
            arguments
                obj
                img_all
                stats
                opt2.super_sample = round(obj.MergePeaks_SuperSample / (obj.InitResolutionRatio * obj.RayleighResolution))
                opt2.crop_radius = round(obj.MergePeaks_CropRadius * (obj.InitResolutionRatio * obj.RayleighResolution))
            end
            peaks = repmat(zeros(opt2.super_sample * (2*opt2.crop_radius + 1)), ...
                           1, 1, height(stats));
            x_size = opt2.super_sample * (2*opt2.crop_radius(1) + 1);
            y_size = opt2.super_sample * (2*opt2.crop_radius(end) + 1);
            x_range = ((1: x_size) - (1 + x_size)/2)./opt2.super_sample;
            y_range = ((1: y_size) - (1 + y_size)/2)./opt2.super_sample;
            padded = zeros(size(img_all, 1) + 2*opt2.crop_radius(1)+2, ...
                           size(img_all, 2) + 2*opt2.crop_radius(end)+2);
            img_x = opt2.crop_radius(1)+1 + (1: size(img_all, 1));
            img_y = opt2.crop_radius(end)+1 + (1: size(img_all, 2));
            curr = 0;
            for i = 1: height(stats)
                img_data = padded;
                img_data(img_x, img_y) = img_all(:, :, stats.ImageIndex(i));
                center = stats.RefinedCentroid(i, :);
                sample_x = round(center(2)) + opt2.crop_radius(1)+1 + ...
                        (-opt2.crop_radius(1): opt2.crop_radius(1));
                sample_y = round(center(1)) + opt2.crop_radius(end)+1 + ...
                    (-opt2.crop_radius(end): opt2.crop_radius(end));
                sample = kron(img_data(sample_x, sample_y), ones(opt2.super_sample));
                x_shift = round(opt2.super_sample * (round(center(2)) - center(2)));
                y_shift = round(opt2.super_sample * (round(center(1)) - center(1)));
                % Shift the center with sub-pixel resolution
                sample = circshift(sample, x_shift, 1);
                sample = circshift(sample, y_shift, 2);
                curr = curr + 1;
                peaks(:, :, curr) = sample;
            end
            psf = mean(peaks, 3);
        end
    
        % Update the internally stored PSF data
        function updatePSF(obj, stats, psf, x_range, y_range, opt3)
            arguments
                obj
                stats
                psf
                x_range = 1: size(psf, 1)
                y_range = 1: size(psf, 2)
                opt3.warn_thres = obj.Update_WarnThreshold
                opt3.gauss_crop_radius = round((obj.InitResolutionRatio * obj.RayleighResolution) * obj.Update_GaussFitCropRadius)
                opt3.gauss_sub_sample = round(obj.Update_GaussFitSubSample / (obj.InitResolutionRatio * obj.RayleighResolution))
                opt3.normalize_method = obj.Update_NormalizeMethod
                opt3.update_ratio = obj.Update_UpdateResolutionRatio
            end
            if (~isempty(obj.DataXRange) && (~isequal(x_range, obj.DataXRange)) || ...
                    (~isempty(obj.DataYRange) && ~isequal(y_range, obj.DataYRange)))
                obj.warn2('Unable to add fitted PSF to the existing result, range does not match. Reset result to add new data.')
                obj.reset()
            end
            old_width = obj.DataWidthMean;
            new_width = mean(stats.RefinedWidth); 
            if ~isempty(old_width) && any(abs(new_width ./ old_width - 1) > opt3.warn_thres)
                obj.warn('PSF width changed significantly from (%.3g, %.3g) to (%.3g, %.3g), consider reset the fitting.', ...
                    old_width(1), old_width(2), new_width(1), new_width(2))
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
                obj.DataWidthMean = new_width;
                obj.DataWidthCov = cov(stats.RefinedWidth);
            else
                obj.DataPSF = obj.DataPSF*old_weight + psf*new_weight;
                obj.DataWidthMean = old_width*old_weight + new_width*new_weight;
                obj.DataWidthCov = (obj.DataWidthCov*(old_num - 1) + cov(stats.RefinedWidth)*(new_num - 1))/(old_num + new_num - 1);
            end
            fit_x = (x_range >= -opt3.gauss_crop_radius(1)) & (x_range <= opt3.gauss_crop_radius(1));
            fit_y = (y_range >= -opt3.gauss_crop_radius(end)) & (y_range <= opt3.gauss_crop_radius(end));
            fit_data = obj.DataPSF(fit_x, fit_y);
            fit_x_range = x_range(fit_x);
            fit_y_range = y_range(fit_y);
            [obj.GaussPSF, obj.GaussGOF] = fitGauss2D(fit_data, fit_x_range, fit_y_range, ...
                'cross_term', true, 'sub_sample', opt3.gauss_sub_sample, 'offset', 'linear');
            switch opt3.normalize_method
                case "Gaussian"
                    sum_count = 2*pi*obj.GaussPSF.a* ...
                        obj.GaussGOF.eigen_widths(1)*obj.GaussGOF.eigen_widths(2);
                case "Sum"
                    sum_count = sum(fit_data(:)) * obj.DataXRangeStep * obj.DataYRangeStep;
            end
            obj.DataSumCount = obj.DataSumCount*old_weight + sum_count*new_weight;
            [Y, X] = meshgrid(y_range, x_range);
            % obj.PSF = @(x, y) interp2(Y, X, obj.DataPSF / obj.DataSumCount, y, x);
            obj.PSF = @(x, y) funcPSF(obj.DataPSF / obj.DataSumCount, X, Y, x, y);
            if opt3.update_ratio
                obj.InitResolutionRatio = max(obj.GaussGOF.eigen_widths) / obj.RayleighResolutionGaussSigma;
            end
            function val = funcPSF(data, X, Y, x, y)
                val = interp2(Y, X, data, y, x);
                val(isnan(val) | val < 0) = 0;
            end
        end
        
        % Set the resolution ratio for peak filtering
        function setRatio(obj, ratio)
            obj.InitResolutionRatio = ratio;
        end
        
        function clear(obj)
            obj.DataLastImages = [];
            obj.DataLastStats = [];
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
            s = obj.struct(["DataNumPeaks", "DataPeakCount", "DataSumCount", "DataWidthMean", ...
                            "RayleighResolution", "RayleighResolutionGaussSigma", "GaussResolutionRatio", ...
                            "StrehlRatioGauss", "StrehlRatioAiry", "InitResolutionRatio"]);
            disp(s)
            if ~isempty(obj.GaussPSF)
                fprintf('%s, Goodness of Gaussian fit:\n', obj.getStatusLabel())
                disp(obj.GaussGOF)
                fprintf('%s, Gaussian PSF fit results:\n', obj.getStatusLabel())
                disp(obj.GaussPSF)
            end
        end

        function varargout = plot(obj, ax)
            arguments
                obj
                ax = gca()
            end
            h = imagesc(ax, obj.DataYRange, obj.DataXRange, obj.DataPSF);
            if nargout == 1
                varargout{1} = h;
            end
        end

        function varargout = plotV(obj, ax, options)
            arguments
                obj
                ax = gca()
                options.scale = 1
                options.add_legend = true
            end
            c_obj = onCleanup(@()preserveHold(ishold(ax), ax)); % Preserve original hold state
            v1 = options.scale * obj.GaussGOF.eigen_widths(1) * obj.GaussGOF.eigen_vectors(:, 1);
            v2 = options.scale * obj.GaussGOF.eigen_widths(2) * obj.GaussGOF.eigen_vectors(:, 2);
            hold(ax, "on")
            h(1) = quiver(ax, 0, 0, v1(2), v1(1), ...
                'LineWidth', 2, 'Color', 'r', 'MaxHeadSize', 10, ...
                'DisplayName', sprintf("major width: %.3g", obj.GaussGOF.eigen_widths(1)));
            h(2) = quiver(ax, 0, 0, v2(2), v2(1), ...
                'LineWidth', 2, 'Color', 'm', 'MaxHeadSize', 10, ...
                'DisplayName', sprintf("minor width: %.3g", obj.GaussGOF.eigen_widths(2)));
            if options.add_legend
                h(3) = legend(ax, 'Interpreter', 'none');
            end
            if nargout == 1
                varargout{1} = h;
            end
        end

        function plotPSF(obj, opt)
            arguments
                obj
                opt.show_ideal_psf = obj.Plot_ShowIdealPSF
                opt.surface_sub_sample = round(obj.Update_GaussFitSubSample / (obj.InitResolutionRatio * obj.RayleighResolution))
                opt.show_gauss_surface = obj.Plot_ShowGaussSurface
                opt.linecut_range = obj.Plot_LineCutRange
            end
            if opt.show_ideal_psf
                obj.plotIdealPSF()
            end
            if obj.DataSumCount == 0
                obj.warn('No peak data stored.')
                return
            end
            figure
            sgtitle(sprintf('%s, Number of peaks: %d', obj.ID, obj.DataNumPeaks))
            x_idx = 1:opt.surface_sub_sample:length(obj.DataXRange);
            y_idx = 1:opt.surface_sub_sample:length(obj.DataYRange);
            xsub_range = obj.DataXRange(x_idx);
            ysub_range = obj.DataYRange(y_idx);
            psf_sub = reshape(obj.DataPSF(x_idx, y_idx), length(x_idx), length(y_idx));
            [y, x, z] = prepareSurfaceData(ysub_range, xsub_range, psf_sub);
            [Y, X] = meshgrid(obj.DataYRange, obj.DataXRange);
            psf_airy = obj.DataSumCount*reshape(obj.IdealPSFAiry(X(:), Y(:)), length(obj.DataXRange), length(obj.DataYRange));
            [val1, range1] = findPSFLineCut(obj.PSF, obj.DataSumCount, obj.GaussGOF.eigen_vectors(:, 1), obj.GaussGOF.eigen_widths(1)*opt.linecut_range);
            [val10, range10] = findPSFLineCut(obj.IdealPSFAiry, obj.DataSumCount, obj.GaussGOF.eigen_vectors(:, 1), obj.GaussGOF.eigen_widths(1)*opt.linecut_range);
            [val2, range2] = findPSFLineCut(obj.PSF, obj.DataSumCount, obj.GaussGOF.eigen_vectors(:, 2), obj.GaussGOF.eigen_widths(2)*opt.linecut_range);
            [val20, range20] = findPSFLineCut(obj.IdealPSFAiry, obj.DataSumCount, obj.GaussGOF.eigen_vectors(:, 2), obj.GaussGOF.eigen_widths(2)*opt.linecut_range);
            ax1 = subplot(2, 3, 6);
            subplot(2, 3, 1)
            imagesc2(obj.DataYRange, obj.DataXRange, psf_airy)
            title(sprintf('Ideal Airy PSF, sigma: %.3g, max: %.5g', ...
                obj.RayleighResolutionGaussSigma, max(psf_airy(:))))
            ax2 = subplot(2, 3, 2);
            imagesc2(obj.DataYRange, obj.DataXRange, obj.DataPSF)
            xlabel('Y')
            ylabel('X')
            title(sprintf('Real PSF, max: %.5g', max(obj.DataPSF(:))))
            ax3 = subplot(2, 3, 3);
            imagesc2(obj.DataYRange, obj.DataXRange, log(obj.DataPSF - min(obj.DataPSF(:)) + 1))
            xlabel('Y')
            ylabel('X')
            title('Real PSF (log)')
            subplot(2, 3, 4)
            plot(range1, val1, 'LineWidth', 2, 'DisplayName', 'Actual PSF')
            hold on
            plot(range10, val10, 'LineStyle', '--', 'LineWidth', 2, 'DisplayName', 'Airy disk')
            title('Major axis cut')
            legend()
            subplot(2, 3, 5)
            plot(range2, val2, 'LineWidth', 2, 'DisplayName', 'Actual PSF')
            hold on
            plot(range20, val20, 'LineStyle', '--', 'LineWidth', 2, 'DisplayName', 'Airy disk')
            title('Minor axis cut')
            legend()
            if opt.show_gauss_surface
                axes(ax1)
                h = plot(obj.GaussPSF, [x, y], z);
                h(2).MarkerSize = 2;
                axis square
                ylabel('Y')
                xlabel('X')
                title('Real PSF with Gaussian fit')
                for ax = [ax2, ax3]
                    obj.plotV(ax)
                end
            else
                axes(ax1)
                scatter3(x, y, z, 10, z, 'filled')
                axis square
            end
        end

        function plotIdealPSF(obj)
            x_range = obj.RayleighResolution*(-3:0.01:3);
            y_range = obj.RayleighResolution*(-3:0.01:3);
            [Y, X] = meshgrid(y_range, x_range);
            psf_gauss = reshape(obj.IdealPSFGauss(X(:), Y(:)), length(x_range), length(y_range)) / obj.IdealPSFGaussPeakIntensity;
            psf_airy = reshape(obj.IdealPSFAiry(X(:), Y(:)), length(x_range), length(y_range)) / obj.IdealPSFAiryPeakIntensity;
            figure
            sgtitle(sprintf('%s, Ideal PSF', obj.ID))
            subplot(2, 3, 1)
            imagesc2(y_range, x_range, psf_gauss)
            xlabel('Y')
            ylabel('X')
            title(sprintf('Ideal Gaussian PSF, sigma = %.3g', obj.RayleighResolution/2.9))
            subplot(2, 3, 2)
            imagesc2(y_range, x_range, psf_airy)
            xlabel('Y')
            ylabel('X')
            title('Ideal Airy PSF')
            subplot(2, 3, 4)
            imagesc2(y_range, x_range, log(psf_gauss))
            xlabel('Y')
            ylabel('X')
            title(sprintf('Ideal Gaussian PSF (log), sigma = %.3g', obj.RayleighResolution/2.9))
            subplot(2, 3, 5)
            imagesc2(y_range, x_range, log(psf_airy))
            xlabel('Y')
            ylabel('X')
            title('Ideal Airy PSF (log)')
            subplot(2, 3, [3, 6])
            hold on
            plot(x_range, log(obj.IdealPSFGauss(x_range, 0) / obj.IdealPSFGaussPeakIntensity), ...
                'LineWidth', 2, 'DisplayName', 'Gaussian PSF')
            plot(x_range, log(obj.IdealPSFAiry(x_range, 0) / obj.IdealPSFAiryPeakIntensity), ...
                'LineWidth', 2, 'DisplayName', 'Airy PSF')
            ylim([-10, inf])
            hold off
            legend()
            title('Ideal PSF cross section (log)')
        end

        function plotWidthDist(obj)
            if obj.DataNumPeaks == 0
                obj.warn('No peak data stored.')
                return
            end
            prob = mvnpdf(obj.DataStats.RefinedWidth, obj.DataWidthMean, obj.DataWidthCov) * (0.1*obj.RayleighResolution)^2;
            figure
            scatter3(obj.DataStats.RefinedWidth(:, 1), obj.DataStats.RefinedWidth(:, 2), prob, 20, ...
                obj.DataStats.MaxIntensity)
            xlabel('Major width')
            ylabel('Minor width')
            zlabel('Normalized probability density')
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

        function val = get.RayleighResolutionGaussSigma(obj)
            val = obj.RayleighResolution / 2.9;
        end

        function val = get.StrehlRatioGauss(obj)
            if isempty(obj.GaussPSF)
                val = nan;
                return
            end
            val = obj.GaussPSF.a / (obj.DataSumCount * obj.IdealPSFGaussPeakIntensity);
        end

        function val = get.StrehlRatioAiry(obj)
            if isempty(obj.GaussPSF)
                val = nan;
                return
            end
            val = obj.GaussPSF.a / (obj.DataSumCount * obj.IdealPSFAiryPeakIntensity);
        end

        function val = get.GaussResolutionRatio(obj)
            if isempty(obj.GaussPSF)
                val = nan;
                return
            end
            val = obj.GaussGOF.eigen_widths / obj.RayleighResolutionGaussSigma;
        end
    end

    methods (Access = protected)
        function init(obj)
            obj.RayleighResolution =  0.61 * obj.ImagingWavelength / obj.NA * obj.Magnification / obj.PixelSize;
            [obj.IdealPSFGauss, obj.IdealPSFGaussPeakIntensity] = getIdealPSFGauss(obj.RayleighResolution);
            [obj.IdealPSFAiry, obj.IdealPSFAiryPeakIntensity] = getIdealPSFAiry(obj.RayleighResolution);
        end
    end
end

function [refined_centroid, refined_width, refined_angle, rsquare] = refineCentroid( ...
             img_data, centroid, refine_radius, refine_method, gauss_subsample)
    x_range = round(centroid(2)) + (-refine_radius(1): refine_radius(1));
    y_range = round(centroid(1)) + (-refine_radius(end): refine_radius(end));
    x_range = x_range((x_range > 0) & (x_range <= size(img_data, 1)));
    y_range = y_range((y_range > 0) & (y_range <= size(img_data, 2)));
    spot = img_data(x_range, y_range);
    switch refine_method
        case "Gaussian"
            [f, gof] = fitGauss2D(spot, x_range, y_range, 'cross_term', true, 'sub_sample', gauss_subsample);
            refined_centroid = [f.y0, f.x0];
            refined_width = gof.eigen_widths;
            refined_angle = gof.eigen_angles;
            rsquare = gof.rsquare;
        case "GaussXY"
            [xc, yc, xw, yw] = fitGaussXY(spot, x_range, y_range, 'sub_sample', gauss_subsample);
            refined_centroid = [yc, xc];
            refined_width = sort([yw, xw]);
            refined_angle = nan;
            rsquare = nan;
        case "COM"
            [xc, yc, xw, yw] = fitCenter2D(spot, x_range, y_range);
            refined_centroid = [yc, xc];
            refined_width = sort([yw, xw]);
            refined_angle = nan;
            rsquare = nan;
    end
end

function [val, s_range] = findPSFLineCut(psf, amp, v, step_range)
    v_range = v .* step_range;
    s_range = norm(v) * step_range';
    val = amp*psf(v_range(1, :)', v_range(2, :)');
end

function [func, peak_val] = getIdealPSFGauss(resolution)
    sigma = resolution / 2.9;
    func = @(x, y) 1/(2*pi*sigma^2)*exp(-1/2*(x.^2 + y.^2)./sigma^2);
    peak_val = 1/(2*pi*sigma^2);
end

function [func, peak_val] = getIdealPSFAiry(resolution)
    r0 = 3.8317;
    func1 = @(x, y) (2*besselj(1, r0*sqrt(x.^2 + y.^2)/resolution)./(r0*sqrt(x.^2 + y.^2)/resolution)).^2;
    total = integral2(func1, -20*resolution, 20*resolution, -20*resolution, 20*resolution);
    func = @idealAiry;
    peak_val = 1/total;
    function z = idealAiry(x, y)
        z = func1(x, y) / total;
        z(isnan(z)) = 1 / total;
    end
end

function plotPeaks(id, img_data, img_bin, stats0, stats1, stats2, stats3, stats4, stats5)
    figure
    sgtitle(id)
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
    imagesc2(img_data, 'title', sprintf('4.After filter bounding box size: %d', size(stats3, 1)))
    viscircles(stats2.WeightedCentroid, sqrt(stats2.Area)/2, 'Color', 'w', 'LineWidth', 0.5);
    viscircles(stats3.WeightedCentroid, sqrt(stats3.Area)/2);
    subplot(2, 3, 5)
    imagesc2(img_data, 'title', sprintf('4.After filter low-intensity: %d', size(stats4, 1)))
    viscircles(stats3.WeightedCentroid, sqrt(stats3.Area)/2, 'Color', 'w', 'LineWidth', 0.5);
    viscircles(stats4.WeightedCentroid, sqrt(stats4.Area)/2);
    subplot(2, 3, 6)
    imagesc2(img_data, 'title', sprintf('5.After filtering gaussian fit width: %d', size(stats5, 1)))
    viscircles(stats4.WeightedCentroid, sqrt(stats4.Area)/2, 'Color', 'w', 'LineWidth', 0.5);
    viscircles(stats5.RefinedCentroid, sqrt(stats5.Area)/2);
end
