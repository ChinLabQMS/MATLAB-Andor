classdef BkgStatGenerator < BaseAnalyzer
    %BKGSTATGENERATOR Generate background statistics for image preprocessing

    properties (SetAccess = protected)
        BkgData
        BkgStat
    end
    
    methods
        function obj = BkgStatGenerator(config)
            arguments
                config (1, 1) BkgStatGeneratorConfig = BkgStatGeneratorConfig()
            end
            obj@BaseAnalyzer(config)
        end

        function process(obj)
            for field = obj.Config.SettingList
                obj.BkgStat.(field) = obj.getBkgStat(obj.BkgData.(field));               
            end
            obj.info("BkgStat generated.")
        end

        function save(obj, filename)
            arguments
                obj
                filename (1, 1) string = sprintf("calibration/BkgStat_%s.mat", datetime("now", "Format","uuuuMMdd"))
            end
            if isempty(obj.BkgStat)
                obj.error("No BkgStat available, please init first.")
            end
            data = obj.BkgStat;
            data.Config = obj.Config.struct();
            save(filename, "-struct", "data")
            obj.info("BkgStat saved as [%s].", filename)
        end

        function plot(obj, setting_str, camera)
            if isempty(obj.BkgStat)
                obj.error("No BkgStat available, please init first")
            end
            stat = obj.BkgStat.(setting_str).(camera);
            plotStat(stat, obj.BkgData.(setting_str).AcquisitionConfig.NumAcquisitions)
        end
    end

    methods (Access = protected, Hidden)
        function init(obj)
            for field = obj.Config.SettingList
                obj.BkgData.(field) = load(fullfile(obj.Config.DataPath, obj.Config.(field))).Data;
            end
            obj.info("All data loaded.")
        end
    end

    methods (Access = protected)
        function stat = getBkgStat(obj, data)
            label = obj.Config.ImageLabel;
            for camera = obj.Config.CameraList
                images = obj.removeOutliers(data.(camera).(label));
                mean_image = mean(images, 3, 'omitmissing');
                var_image = var(images, 0, 3, 'omitmissing');
                mean_fft = abs(fftshift(fft2(mean_image)));
                mask = log(mean_fft) > 7.7;
                mean_new = abs(ifft2(ifftshift( fftshift(fft2(mean_image)).* mask )));
                
                stat.(camera).Mean = mean_image;
                stat.(camera).Var = var_image;
                stat.(camera).SmoothMean = mean_new;
                stat.(camera).NoiseVar = mean(var_image,'all');
            end
        end

        function new_images = removeOutliers(obj, images, threshold)
            arguments
                obj
                images (:, :, :) double
                threshold (1, 1) double = obj.Config.RemoveOutlierThres
            end        
            median_image = median(images, 3);
            median_dev = median(abs(images-median_image), 'all');
            norm_median_dev = abs(images-median_image)/median_dev;
        
            new_images = images;
            outliers = norm_median_dev > threshold;
            new_images(outliers) = nan;
        
            num_outliers = sum(outliers, 'all');
            num_elements = numel(new_images);
            obj.info("Number of pixels disposed: %d, percentage in data: %.6f%%", num_outliers, num_outliers/num_elements*100)
        end
    end

end

function plotStat(stat, num_images)
    diff = stat.SmoothMean-stat.Mean;
    v = var(stat.Var, 0, 'all');
    v_predicted = 2*mean(stat.Var, 'all')^2/(num_images-1);

    figure
    subplot(3,3,1)
    imagesc(stat.Mean)
    daspect([1 1 1])
    colorbar
    title('Mean')
    
    subplot(3,3,2)
    imagesc(stat.Var)
    daspect([1 1 1])
    colorbar
    title('Var')
    
    subplot(3,3,3)
    surf(stat.Mean, 'EdgeColor','none')
    title('Mean')

    subplot(3,3,4)
    imagesc(stat.SmoothMean)
    daspect([1 1 1])
    colorbar
    title('SmoothMean')

    subplot(3,3,5)
    imagesc(diff)
    daspect([1 1 1])
    colorbar
    title('Diff: SmoothMean-Mean')

    subplot(3,3,6)
    histogram(diff,'EdgeColor','none')
    legend('diff')
    title(sprintf('Diff: Mean = %g', mean(diff, 'all')))

    subplot(3,3,7)
    histogram(stat.Var(:), 100)
    title(sprintf('Var histogram\nv = %.3f, v_{pred} = %.3f', v, v_predicted)) 
    
    subplot(3,3,8)
    histogram(stat.Mean,'EdgeColor','none')
    hold on
    histogram(stat.SmoothMean,'EdgeColor','none')
    legend({'Mean','SmoothMean'})
    title('Histogram of Mean/SmoothMean')

    subplot(3,3,9)
    surf(diff,'EdgeColor','none')
    title('Diff')
end
