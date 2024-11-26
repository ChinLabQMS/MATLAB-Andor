classdef PointFitter < BaseObject

    properties (Constant)
        FindPeak_ExpectedSigma = 1.5
        FindPeak_PlotDiagnostic = false
        FindPeak_Verbose = false
        FindPeak_PeakProperties = ["WeightedCentroid", "BoundingBox", "MaxIntensity", "Area"]
        FindPeak_BinThreshold = 30
        FindPeak_FilterAreaMin = 5
        FindPeak_FilterIntensityMin = 50
        FindPeak_DBScanDistSigma = 12
        FindPeak_DBScanSingleOnly = true
        FindPeak_FilterBoxXMaxSigma = 7
        FindPeak_FilterBoxYMaxSigma = 7
    end

    methods
        function centroids = findPeaks(obj, img_data, expected_sigma, options)
            arguments
                obj
                img_data
                expected_sigma = obj.FindPeak_ExpectedSigma
                options.plot_diagnostic = obj.FindPeak_PlotDiagnostic
                options.verbose = obj.FindPeak_Verbose
                options.peak_properties = obj.FindPeak_PeakProperties
                options.binarize_threshold = obj.FindPeak_BinThreshold
                options.filter_area_min = obj.FindPeak_FilterAreaMin
                options.filter_intensity_min = obj.FindPeak_FilterIntensityMin
                options.dbscan_distance = obj.FindPeak_DBScanDistSigma * expected_sigma
                options.dbscan_single_only = obj.FindPeak_DBScanSingleOnly
                options.filter_box_xmax = obj.FindPeak_FilterBoxXMaxSigma * expected_sigma
                options.filter_box_ymax = obj.FindPeak_FilterBoxYMaxSigma * expected_sigma
            end
            timer = tic;
            % Binarize image and find connected components
            img_bin = img_data > options.binarize_threshold;
            stats = regionprops("table", img_bin, img_data, options.peak_properties);
            % Filter the connected components by area and intensity
            stats = stats(stats.Area >= options.filter_area_min, :);
            stats = stats(stats.MaxIntensity >= options.filter_intensity_min, :);
            % Use dbscan to cluster nearby peaks
            stats.Cluster = dbscan(stats.WeightedCentroid, options.dbscan_distance, 1);
            stats = convertvars(stats, 'Cluster', 'categorical');
            stats = renamevars(groupsummary(stats, 'Cluster', 'mean', options.peak_properties), ...
                arrayfun(@(x) "mean_" + x, options.peak_properties), options.peak_properties);
            if options.dbscan_single_only
                stats = stats((stats.GroupCount == 1), :);
            end
            % Filter on bounding box size
            stats = stats(...
                (stats.BoundingBox(:, 4) <= options.filter_box_xmax) & ...
                (stats.BoundingBox(:, 3) <= options.filter_box_ymax), :);
            centroids = stats.WeightedCentroid;
            if options.plot_diagnostic
                figure
                imagesc2(img_data)
                viscircles(stats.WeightedCentroid, 3*expected_sigma);
            end
            if options.verbose
                obj.info('Find %d peaks in the image, elapsed time is %g s.', size(centroids, 1), toc(timer))
            end
        end
    end

end

function centroids = refineCentroid(centroids, img_data)
    
end
