clear
clc

%% Load dataset
images = load("calibration\Data_for_PSF_fitting_test.mat").Data.Andor19330.Image;

%% Background subtraction
background = load("calibration\StatBackground_20240311_HSSpeed=2_VSSpeed=1.mat").Andor19330.SmoothMean;
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
[offset, std, residuals] = cancelOffset(sample,2,"y_bg_size",100);

%%
surf(residuals{2,1},'EdgeColor','none')
daspect([1 1 1])

%%
surf(offset,'EdgeColor','none')

%%
signals_new = signals - offset;
sample_new = signals_new(:,:,index);

figure
subplot(1,2,1)
imagesc(sample)
daspect([1 1 1])
colorbar

subplot(1,2,2)
imagesc(sample_new)
daspect([1 1 1])
colorbar

%% Test peak finding algorithm
box_x = 1:400;
box_y = 301:700;
box = sample_new(box_x,box_y);

figure
imagesc(box)
daspect([1 1 1])
colorbar

%%
threshold = 10;
box1 = box.*(box>threshold);

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
box3 = box2.*(box2>threshold);

figure
imagesc(box3)
daspect([1 1 1])
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