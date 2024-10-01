% try looping through data set and compare centroid lists using fitPSF
% looking at DMD images on Zelux camera

load("data\2024\09 September\20240925 static patterns\gray_on_black_anchor=65_array64_spacing=70_r=10.mat")
shots = Data.Zelux.Lattice;
psf = cell(1,size(shots, 3));
centroids = cell(1,size(shots, 3));
for i  = 1:size(shots,3)
    data = shots(:,:,i);
    [psf{i},centroids{i}] = fitPSF(data);
end

% compare the centroids between the shots
% in this data, the exposure time is short so when there's a gray pattern
% sometimes we expose between shots- may need to increase the exposure
% time. try to find good settings for the DMD images on Zelux