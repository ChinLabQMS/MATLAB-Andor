% try looping through data set and compare centroid lists using fitPSF
% looking at DMD images on Zelux camera

% load("data\2024\09 September\20240925 static
% patterns\gray_on_black_anchor=65_array64_spacing=70_r=10.mat") % too many
% dropped shots
load("data/2024/10 October/20241001/longer_exposure_zelux_ls_on_calib_anchorgray_on_blackanchor=65_array64_spacing=70_centeredr=10.mat")
shots = Data.Zelux.DMD;
psf = cell(1,size(shots, 3));
centroids = cell(1,size(shots, 3));
figure;
for i  = 1:size(shots,3)
    subplot(4,5,i);
    imagesc(shots(:,:,i));
    data = shots(:,:,i);
    [psf{i},centroids{i}] = fitPSF(data,0.6);
end

% can treat first image differently to get initial list of centroids. then
% in later shots, find centroids close to the initial list of coordinates.
% can create box then fit Gaussian to find intensity max

% compare the centroids between the shots
% in this data, the exposure time is short so when there's a gray pattern
% sometimes we expose between shots- may need to increase the exposure
% time. try to find good settings for the DMD images on Zelux
%%
 final_centroid_intensity = zeros(size(final_centroids,1),1);
    for i = 1:size(final_centroids,1)
           final_centroid_intensity(i) = data(round(final_centroids(i,2)),round(final_centroids(i,1)));
    end
    [sorted,sortindex]=sort(final_centroid_intensity,'descend');
    final_centroids_1 = final_centroids(sortindex, :);