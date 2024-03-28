clear
clc

%% Load dataset
images = load("calibration\Data_for_PSF_fitting_test.mat").Data.Andor19330.Image;

%% Background subtraction
background = load("calibration\StatBackground_20240311_HSSpeed=2_VSSpeed=1.mat").Andor19330.SmoothMean;
noise_var = load("calibration\StatBackground_20240311_HSSpeed=2_VSSpeed=1.mat").Andor19330.NoiseVar;

signals = double(images) - background;

%%
index = 1;
sample = signals(:,:,index);

figure
imagesc(sample)
daspect([1 1 1])
colorbar

%%
box_x = 1:1024;
box_y = 1:100;
bg_box = sample(box_x,box_y);

figure
% imagesc(bg_box)
surf(bg_box,'EdgeColor','none')
colorbar

%%
[offset, variance, residuals] = cancelOffset(sample,2,"y_bg_size",100);

%%
figure
subplot(1,2,1)
surf(residuals{2,1},'EdgeColor','none')
daspect([1 1 1])

subplot(1,2,2)
surf(offset,'EdgeColor','none')

%%
signals_new = signals - offset;
sample_new = signals_new(:,:,index);

figure
subplot(1,2,1)
imagesc(sample)
daspect([1 1 1])
title('Raw with background subtraction')
colorbar

subplot(1,2,2)
imagesc(sample_new)
daspect([1 1 1])
title('With linear offset subtraction')
colorbar

%% Test peak finding algorithm, first look at sparse peaks
box_x = 1:400;
box_y = 301:700;
box0 = sample_new(box_x,box_y);

figure
imagesc(box0)
daspect([1 1 1])
colorbar

%% Histogram of counts
[N, edges] = histcounts(box0(:),'Normalization','pdf');
centers = movmean(edges,2,'Endpoints','discard');

histogram('BinEdges',edges,'BinCounts',N,'EdgeColor','none')
hold on
y = normpdf(centers,0,sqrt(noise_var));
plot(centers,y)

%%
plot(centers,log(N./y))

%%
threshold = 15;
box1 = box0.*(box0>threshold);

figure
imagesc(box1)
daspect([1 1 1])
colorbar

%%
box2 = imgaussfilt(box1,2);

figure
imagesc(box2)
daspect([1 1 1])
colorbar

%%
mask = box2>0.9*threshold;
box3 = box2.*mask;

figure
imagesc(box3)
daspect([1 1 1])
colorbar

%%
p = regionprops("table",mask,"Area","Centroid","Eccentricity");

figure
histogram([p.Area],20)

%%
figure
imagesc(box0)
daspect([1 1 1])
viscircles(p.Centroid,5,'LineWidth',1)
text(p.Centroid(:,1),p.Centroid(:,2),arrayfun(@num2str, p.Area, 'UniformOutput', 0))
colorbar

%%
sd = size(box3);
[x, y] = find(box3);

% initialize outputs
cent=[];%
cent_map=zeros(sd);

x=x+edg-1;
y=y+edg-1;
for j=1:length(y)
    if (d(x(j),y(j))>d(x(j)-1,y(j)-1 )) &&...
            (d(x(j),y(j))>d(x(j)-1,y(j))) &&...
            (d(x(j),y(j))>d(x(j)-1,y(j)+1)) &&...
            (d(x(j),y(j))>d(x(j),y(j)-1)) && ...
            (d(x(j),y(j))>d(x(j),y(j)+1)) && ...
            (d(x(j),y(j))>d(x(j)+1,y(j)-1)) && ...
            (d(x(j),y(j))>d(x(j)+1,y(j))) && ...
            (d(x(j),y(j))>d(x(j)+1,y(j)+1))
        
        cent = [cent ;  y(j) ; x(j)];
        cent_map(x(j),y(j))=cent_map(x(j),y(j))+1; % if a binary matrix output is desired
        
    end
end