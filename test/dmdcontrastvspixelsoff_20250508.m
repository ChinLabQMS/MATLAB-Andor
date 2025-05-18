%% import the data of a few pixels being off

%data = load("data/2025/04 April/20250430/r=10hole_v2.mat");
%data = load("data/2025/04 April/20250430/r=5hole_v2.mat");
%data = load("data/2025/04 April/20250430/r=3hole_v2.mat");
filename = ["r=5hole_v2.mat","r=10hole_v2.mat","r=3hole_v2.mat"];
    %for i = 1:length(filename)
    i=3
    shot=4;
data = load(strcat("data/2025/04 April/20250430/",filename(i)));
greendata = data.Data.Zelux.Pattern_532;
greendouble = double(greendata);

% %%
% shot = 4;
% figure;
% imagesc(greendata(:,:,shot));
% daspect([1 1 1]);
%
%% crop the image

bgval = double(min(greendata(:)));
imgs = greendouble(650:900,200:450,:);
figure;
imagesc(imgs(:,:,1));
daspect([1 1 1]);
img = imgs(:,:,shot)-bgval;
%% take some linecuts
% %find the location of the minimum
% [minVal,linearIdx]=min(img(:));
% [yc,xc]=ind2sub(size(img),linearIdx);
% % col_max = 117; % second coord in data tip these are for r = 10
% % row_max = 124; % first coord in data tip
% % xc = col_max;
% % yc = row_max;

%% rather than linecuts, can add up the entire rows in a small cropped region and plot. Can do the same with the columns.
cropped=greendouble(675:850,250:400,shot);
figure;
imagesc(cropped);
daspect([1 1 1]);
allrows = sum(cropped,1);
allcols = sum(cropped,2);
x_profile = allrows/size(cropped,1);
y_profile = allcols/size(cropped,2);
x = 1:length(x_profile);
y = 1:length(y_profile);

% figure;
% subplot(1,2,1);
% plot(x, x_profile, 'b');
% title('Horizontal Integrated Counts');
% legend('Data', 'Gaussian Fit');
% subplot(1,2,2);
% plot(y, y_profile, 'b');
% title('Vertical Integrated Counts');
% legend('Data', 'Gaussian Fit');

gauss1d = @(p,x) p(1)*exp(-((x-p(2)).^2)/(2*p(3)^2))+p(4);
% p = amplitude, center, sigma, offset
p0_x= [max(x_profile),75,20,min(x_profile)];
fit_x = lsqcurvefit(gauss1d,p0_x,x,x_profile);

% the fit gives me Gaussian sigma. I can then use 1/e^2 radius = 2* sigma
% to get width
p0_y = [max(y_profile), 75, 20, min(y_profile)];
fit_y = lsqcurvefit(gauss1d, p0_y, y, transpose(y_profile));

% figure;
% subplot(3,2,3*i-2);
% imagesc(cropped);
% title(filename);
% daspect([1 1 1]);
% subplot(3,2,3*i-1);
% plot(x, x_profile, 'b', x, gauss1d(fit_x, x), 'r--');
% title('Horizontal Integrated Profile');
% legend('Data', 'Gaussian Fit');
% subplot(3,2,3*i-2);
% plot(y, y_profile, 'b', y, gauss1d(fit_y, y), 'r--');
% title('Vertical Integrated Profile');
% legend('Data', 'Gaussian Fit');

% add fit eqs to plot
% Horizontal fit parameters
A_x = fit_x(1);
ai_x = A_x;
mu_x = fit_x(2);
sigma_x = fit_x(3);
offset_x = fit_x(4);
% Vertical fit parameters
A_y = fit_y(1);
ai_y = A_y;
mu_y = fit_y(2);
sigma_y = fit_y(3);
offset_y = fit_y(4);

%find the contrast from the Gaussian fit
horizcontrast = (ai_x/offset_x);
vertcontrast = (ai_y/offset_y);

eq_x = sprintf('y = %.2f·exp(-((x - %.1f)^2) / (2·%.1f^2)) + %.2f', ...
               A_x, mu_x, sigma_x, offset_x);
eq_y = sprintf('y = %.2f·exp(-((x - %.1f)^2) / (2·%.1f^2)) + %.2f', ...
               A_y, mu_y, sigma_y, offset_y);

figure;
subplot(1,3,1);
imagesc(cropped);
title(filename(i));
daspect([1 1 1]);
subplot(1,3,2);
plot(x, x_profile, 'b', x, gauss1d(fit_x, x), 'r--');
title('Horizontal Integrated Counts');
legend('Data', 'Gaussian Fit');
text(0.05, 0.9, eq_x, 'Units', 'normalized', 'FontSize', 8);
daspect([3 1 1]);
subplot(1,3,3);
plot(y, y_profile, 'b', y, gauss1d(fit_y, y), 'r--');
title('Vertical Integrated Counts');
legend('Data', 'Gaussian Fit');
text(0.05, 0.9, eq_y, 'Units', 'normalized', 'FontSize', 8);
daspect([3 1 1]);


%% this section is for cross sectional profiles
% col_max = xc; % this is horiz on the plot
% row_max = yc; % this is vert on the plot
col_max = 129; % first coord in data tip, along the bottom, for r = 5
row_max = 115; % second coord in data tip, along the side, for r = 5
col_max = 126; % first coord in data tip, along the bottom, for r = 5 after iterating
row_max = 113; % second coord in data tip, along the side, for r = 5 after iterating
col_max = 116; % first coord in data tip, along the bottom, for r = 10 after iterating
row_max = 117; % second coord in data tip, along the side, for r = 10 after iterating
col_max = 127; % first coord in data tip, along the bottom, for r = 3 after iterating
row_max = 118; % second coord in data tip, along the side, for r = 3 after iterating

x_profilec = double(img(row_max,:));
y_profilec = double(img(:,col_max));
x = 1:length(x_profilec);
y = 1:length(y_profilec);

gauss1d = @(p,x) -p(1)*exp(-((x-p(2)).^2)/(2*p(3)^2))+p(4);
% p = amplitude, center, sigma, offset
p0_x= [max(x_profilec),col_max,20,min(x_profilec)];
fit_x = lsqcurvefit(gauss1d,p0_x,x,x_profilec);

p0_y = [max(y_profilec), row_max, 20, min(y_profilec)];
fit_y = lsqcurvefit(gauss1d, p0_y, y, transpose(y_profilec));

% figure;
% subplot(1,2,1);
% plot(x, x_profilec, 'b', x, gauss1d(fit_x, x), 'r--');
% title('Horizontal Cross Section');
% legend('Data', 'Gaussian Fit');
% subplot(1,2,2);
% plot(y, y_profilec, 'b', y, gauss1d(fit_y, y), 'r--');
% title('Vertical Cross Section');
% legend('Data', 'Gaussian Fit');

% add fit eqs to plot
% Horizontal fit parameters
A_x = fit_x(1);
mu_x = fit_x(2);
sigma_x = fit_x(3);
offset_x = fit_x(4);
% Vertical fit parameters
A_y = fit_y(1);
mu_y = fit_y(2);
sigma_y = fit_y(3);
offset_y = fit_y(4);

eq_x = sprintf('y = %.2f·exp(-((x - %.1f)^2) / (2·%.1f^2)) + %.2f', ...
               A_x, mu_x, sigma_x, offset_x)
eq_y = sprintf('y = %.2f·exp(-((x - %.1f)^2) / (2·%.1f^2)) + %.2f', ...
               A_y, mu_y, sigma_y, offset_y)

figure;
subplot(1,3,1);
imagesc(img);
daspect([1 1 1]);
title(filename(i));
subplot(1,3,2);
plot(x, x_profilec, 'b', x, gauss1d(fit_x, x), 'r--');
title('Horizontal Cross Section');
legend('Data', 'Gaussian Fit');
text(0.05, 0.9, eq_x, 'Units', 'normalized', 'FontSize', 8);
subplot(1,3,3);
plot(y, y_profilec, 'b', y, gauss1d(fit_y, y), 'r--');
title('Vertical Cross Section');
legend('Data', 'Gaussian Fit');
text(0.05, 0.9, eq_y, 'Units', 'normalized', 'FontSize', 8);

%% find the contrast from the Gaussian fit
horizcontrast = (A_x/offset_x);
vertcontrast = (A_y/offset_y);


% %% adding section for radial profiles
% gray = img; % subtract the background value
% [rows, cols] = size(gray);
% [xGrid, yGrid] = meshgrid(1:cols, 1:rows);
% r = sqrt((xGrid - xc).^2 + (yGrid - yc).^2);
% r = round(r);  % Bin radii into integer pixels
% maxR = max(r(:));
% radialProfile = zeros(maxR+1, 1);
% counts = zeros(maxR+1, 1);
% for i = 0:maxR
%     mask = (r == i);
%     values = gray(mask);
%     radialProfile(i+1) = mean(values);
%     counts(i+1) = sum(mask(:));
% end
% radii = (0:maxR)';
% 
% % plotting
% figure;
% plot(radii,radialProfile);
% xlabel('radius (pixels)');
% ylabel('Mean intensity');
% title('radial intensity profile')