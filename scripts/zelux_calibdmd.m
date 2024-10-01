% DMD PSF on Zelux script- CalibDMD
% first, script to load in an image of the DMD pattern imaged on the Zelux
% camera.
% figure;
% imagesc(Data.Zelux.Lattice(:,:,2)); % this is an image of the DMD pattern
% %imagesc(Data.Zelux.DMD(:,:,2)); % this is an image of the lattice. Good!!
% daspect([1 1 1]);
% %% save new workspace including this image.
% data = Data.Zelux.Lattice(:,:,2);

% package as a function
%[PSF,centroids] = calibPSF(data,threshpercent)

%% load in the workspace- want to end up with 1140x1080 uint16 file (single image)330
load("zeluxdmddata.mat"); % it is a variable named data.

figure;
imagesc(data);
daspect([1 1 1]);
colorbar;
%%
image = data;
threshpercent = 0.5;
% set a threshold
% threshold_value = 50; %try to implement automatic threshold based on % of the max pixel value
threshold_value = threshpercent*max(data, [], "all");
binary_image = image > threshold_value;

figure;
imagesc(binary_image);
daspect([1 1 1]);
colorbar;
%label connected components
labeled_image = bwlabel(binary_image);
% find centroids
stats = regionprops(labeled_image, 'Centroid');
centroids = cat(1,stats.Centroid);

% Display original image overlaid with the centroids
figure;
imshow(image,[],'InitialMagnification','fit')
title('Detected Bright Spots- centroids')
hold on
plot(centroids(:,1),centroids(:,2),'r+','MarkerSize',10','LineWidth',2);
hold off

% for some points, more than one centroid was fit. Cluster them using
% dbscan.
distance_threshold = 70;
epsilon = distance_threshold;
minPts = 1;
clusters = dbscan(centroids, epsilon, minPts);
final_centroids = [];
for i = 1:max(clusters)
    cluster_points = centroids(clusters ==i,:);
    final_centroids = [final_centroids;mean(cluster_points,1)];
end

% Display original image overlaid with the centroids after clustering
figure;
imshow(image,[],'InitialMagnification','fit')
title('Detected Bright Spots- clustered centroids')
hold on
plot(final_centroids(:,1),final_centroids(:,2),'r+','MarkerSize',10','LineWidth',2);
hold off

%% around each centroid, crop the image centered on the spot. then overlay them for PSF monitoring.
crop_size = 50;

% create 3D array to store cropped regions
num_spots = size(final_centroids,1);
cropped_spots = zeros(2*crop_size+1,2*crop_size+1,num_spots);

% crop around each centroid and store in 3D array
for i = 1:num_spots
    x=round(final_centroids(i,1)); % x coord of centroid
    y=round(final_centroids(i,2)); % x coord of centroid
    % define cropping window
    x_start = max(x-crop_size,1);
    x_end = min(x+crop_size,size(image,2));
    y_start = max(y-crop_size,1);
    y_end = min(y+crop_size,size(image,1));
    % crop image and store in array
    cropped_spot = image(y_start:y_end,x_start:x_end);
    cropped_spots(:,:,i)=cropped_spot;
end

%% Display average psf
average_psf = mean(cropped_spots,3);

figure;
imshow(average_psf,[],'InitialMagnification','fit');
title('Average PSF')

