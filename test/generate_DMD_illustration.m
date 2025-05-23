clear
clc

XRange = 1:20;
YRange = 1:40;

XStep = 10;
% YStep = repelem(20,24);
YStep = 9:32;
R1 = 5;
R2 = inf;

[YIndex,XIndex] = meshgrid(YRange,XRange);
dmd_image = ones(length(XRange),length(YRange),24);
rgb_image = ones(length(XRange),length(YRange),3);

i = 0;
for X = XStep
    for Y = YStep
        i = i+1;
        Mask = (XIndex-X).^2+(YIndex-Y).^2>R1^2 ...
            & (XIndex-X).^2+(YIndex-Y).^2<R2^2;
        sample_image = false(length(XRange),length(YRange));
        sample_image(Mask) = true;
        dmd_image(:,:,i) = sample_image;        
    end
end
for x = XRange
    for y = YRange
        rgb_image(x,y,1) = binaryVectorToDecimal(reshape(dmd_image(x,y,1:8),1,[]))/255;
        rgb_image(x,y,2) = binaryVectorToDecimal(reshape(dmd_image(x,y,9:16),1,[]))/255;
        rgb_image(x,y,3) = binaryVectorToDecimal(reshape(dmd_image(x,y,17:24),1,[]))/255;
    end
end

%%
close all
figure
imshow(rgb_image)
% imshow(dmd_image(:,:,17))
daspect([1 1 1])

% Get image size
[rows, cols] = size(rgb_image, [1, 2]);

% Draw vertical grid lines
for c = 0:cols
    x = [c + 0.5, c + 0.5];
    y = [0.5, rows + 0.5];
    line(x, y, 'Color', 'k', 'LineWidth', 0.5);
end

% Draw horizontal grid lines
for r = 0:rows
    x = [0.5, cols + 0.5];
    y = [r + 0.5, r + 0.5];
    line(x, y, 'Color', 'k', 'LineWidth', 0.5);
end

%%


%%
figure
p = imshow(dmd_image(:,:,1));
daspect([1 1 1])
for i = 2:24
      p.CData = dmd_image(:,:,i);
      exportgraphics(gcf,'tweezer_gif.gif','Append',true);
end

% [rows, columns, numberOfColorChannels] = size(test_dmd_image);
% lineSpacing = 1; % Whatever you want.
% for row = 1 : rows
%     yline(row, 'Color', 'k', 'LineWidth', 1);
% end
% for col = 1 : columns
%     xline(col, 'Color', 'k', 'LineWidth', 1);
% end
%% 
% Writing RBG image
% imwrite(rgb_image, './test/rgb_image.tif')

% Writing binary images
% for i=1:24
%     T = compose("./test/dmd_image%d.tif", i);
%     imwrite(dmd_im~age(:,:,i), T);
% end