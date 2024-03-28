%% Parameters
clear
clc

file = 'CleanBackground_20240327-4_HSSpeed=2_VSSpeed=1';
output = 'StatBackground_20240327-4_HSSpeed=2_VSSpeed=1';

%% Calibrate background

CleanBackground = load(fullfile('calibration',file)).Data;
StatBackground = struct('Config',CleanBackground.Andor19330.Config);

cameras = {'Andor19330','Andor19331'};
for i = 1:length(cameras)
    camera = cameras{i};
    StatBackground.(camera) = struct();
    images = removeOutliers(CleanBackground.(camera).Image);
    StatBackground.(camera) = struct( ...
        'Mean', mean(images, 3, 'omitmissing'), ...
        'Var', var(images, 0, 3, 'omitmissing'));

    mean_image = StatBackground.(camera).Mean;
    var_image = StatBackground.(camera).Var;
    mean_fft = abs(fftshift(fft2(mean_image)));
    mask = log(mean_fft) > 7.7;
    mean_new = abs(ifft2(ifftshift( fftshift(fft2(mean_image)).* mask )));

    StatBackground.(camera).SmoothMean = mean_new;
    StatBackground.(camera).NoiseVar = mean(var_image,'all');

    v = var(StatBackground.(camera).Var, 0, 'all');
    v_predicted = 2*mean(StatBackground.(camera).Var, 'all')^2/(StatBackground.Config.MaxImage-1);
    
    % Some diagonostic figures
    figure
    sgtitle(camera)

    subplot(3,3,1)
    imagesc(StatBackground.(camera).Mean)
    daspect([1 1 1])
    colorbar
    title('Mean')
    
    subplot(3,3,2)
    imagesc(StatBackground.(camera).Var)
    daspect([1 1 1])
    colorbar
    title('Var')
    
    subplot(3,3,3)
    surf(StatBackground.(camera).Mean, 'EdgeColor','none')
    title('Mean')

    subplot(3,3,4)
    imagesc(mean_new)
    daspect([1 1 1])
    colorbar
    title('SmoothMean')

    subplot(3,3,5)
    imagesc(mean_new-mean_image)
    daspect([1 1 1])
    colorbar
    title('Diff: SmoothMean-Mean')

    subplot(3,3,6)
    histogram(mean_new-mean_image,'EdgeColor','none')
    legend('diff')
    title(sprintf('Mean: %g', mean(mean_new - mean_image,'all')))

    subplot(3,3,7)
    histogram(StatBackground.(camera).Var(:), 100)
    title(sprintf('Var dist\nv = %.3f, v_{pred} = %.3f', v, v_predicted)) 
    
    subplot(3,3,8)
    histogram(mean_image,'EdgeColor','none')
    hold on
    histogram(mean_new,'EdgeColor','none')
    legend({'Mean','SmoothMean'})
    title('Histogram of Mean/SmoothMean')

    subplot(3,3,9)
    surf(mean_new - mean_image,'EdgeColor','none')
    title('Diff')
    
end

save(fullfile('calibration',output), '-struct', 'StatBackground')
fprintf('Background noise statistics saved as:\n %s\n',output)