%% Initialize Andor CCDs
initializeAndor()
setCurrentAndor(19330)

%% Acquire image from Andor
setModeFull(exposure=0.01)
num_image = 0;
max_image = 100;
count_data = zeros(max_image, 1);

fig = figure;
while num_image < max_image

    num_image = num_image + 1;
    image = acquireAndorImage(timeout=60000);
    background = acquireAndorImage();
    signal = double(image - background);

    count = mean(signal, 'all');
    count_data(num_image) = count;

    figure(fig)
    subplot(2,1,1)
    imagesc(signal)
    daspect([1 1 1])
    clim([0 10])
    colorbar
    title(sprintf('number: %d, count: %g', num_image, count))

    subplot(2,1,2)
    plot(count_data(1:num_image))
    drawnow
end

%% 

figure
plot(count_data)


%% Close Andor
closeAndor()