% fit Gaussian to the intensity profile on the Zelux camera
% put the intensity profile into units of lattice sites after fitting it
alldata = load('C:\Users\qmspc\Documents\MATLAB\MATLAB-Andor\data\2025\04 April\20250424 ls characterization\white_pattern.mat');
greendata = alldata.Data.Zelux.Pattern_532;
greendouble = double(greendata);

%%
shot = 4;
figure;
imagesc(greendata(:,:,shot));
daspect([1 1 1]);

%% crop the image
img = greendouble(201:1200,1:700,1);
figure;
imagesc(img);
daspect([1 1 1]);

%% try taking cross sections around brightest point
[max_val,max_idx]=max(img(:));
[row_max,col_max]=ind2sub(size(img),max_idx);
col_max = 264;
x_profile = double(img(row_max,:));
y_profile = double(img(:,col_max));
x = 1:length(x_profile);
y = 1:length(y_profile);

gauss1d = @(p,x) p(1)*exp(-((x-p(2)).^2)/(2*p(3)^2))+p(4);
% p = amplitude, center, sigma, offset
p0_x= [max(x_profile),col_max,20,min(x_profile)];
fit_x = lsqcurvefit(gauss1d,p0_x,x,x_profile);

p0_y = [max(y_profile), row_max, 20, min(y_profile)];
fit_y = lsqcurvefit(gauss1d, p0_y, y, transpose(y_profile));

figure;
subplot(1,2,1);
plot(x, x_profile, 'b', x, gauss1d(fit_x, x), 'r--');
title('Horizontal Cross Section');
legend('Data', 'Gaussian Fit');
subplot(1,2,2);
plot(y, y_profile, 'b', y, gauss1d(fit_y, y), 'r--');
title('Vertical Cross Section');
legend('Data', 'Gaussian Fit');

%% add fit eqs to plot
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
               A_x, mu_x, sigma_x, offset_x);
eq_y = sprintf('y = %.2f·exp(-((x - %.1f)^2) / (2·%.1f^2)) + %.2f', ...
               A_y, mu_y, sigma_y, offset_y);

figure;
subplot(1,2,1);
plot(x, x_profile, 'b', x, gauss1d(fit_x, x), 'r--');
title('Horizontal Cross Section');
legend('Data', 'Gaussian Fit');
text(0.05, 0.9, eq_x, 'Units', 'normalized', 'FontSize', 8);
subplot(1,2,2);
plot(y, y_profile, 'b', y, gauss1d(fit_y, y), 'r--');
title('Vertical Cross Section');
legend('Data', 'Gaussian Fit');
text(0.05, 0.9, eq_y, 'Units', 'normalized', 'FontSize', 8);

%%
% Generate coordinate grids
[x, y] = meshgrid(1:size(img,2), 1:size(img,1));
% Flatten data
xdata = [x(:), y(:)];
zdata = img(:);
% Initial parameter guess
A0 = max(zdata);
% x0 = size(img,2)/2;
% y0 = size(img,1)/2;
x0 = 501;
y0 = 297;
sigma_x = 200;
sigma_y = 200;
theta = 0;
offset = min(zdata);

gauss2d = @(params, coords) ...
    params(1) * exp( (-((coords(:,1)-params(2)) * cos(params(6)) + (coords(:,2)-params(3)) * sin(params(6))).^2 ) / (2 * params(4)^2)) + ...
            ( ((-(coords(:,1)-params(2)) * sin(params(6)) + (coords(:,2)-params(3)) * cos(params(6))).^2 ) / (2 * params(5)^2)) + params(7);

params0 = [A0, x0, y0, sigma_x, sigma_y, theta, offset];
% Fit using lsqcurvefit (Optimization Toolbox)
%opts = optimset('Display','off');
opts = optimset('Display', 'iter', 'MaxIter', 500);
[params_fit, ~] = lsqcurvefit(gauss2d, params0, xdata, zdata, [0,0,0,0,0,-100,0],[5000,800,800,500,500,360,5000], opts);
% Extract fitted parameters
A = params_fit(1);
x0 = params_fit(2);
y0 = params_fit(3);
sigma_x = params_fit(4);
sigma_y = params_fit(5);
theta = params_fit(6);
offset = params_fit(7);
% Convert sigmas to FWHM (optional)
fwhm_x = 2*sqrt(2*log(2)) * sigma_x;
fwhm_y = 2*sqrt(2*log(2)) * sigma_y;
fprintf('Center: (%.2f, %.2f)\n', x0, y0);
fprintf('Major width (FWHM): %.2f pixels\n', max(fwhm_x, fwhm_y));
fprintf('Minor width (FWHM): %.2f pixels\n', min(fwhm_x, fwhm_y));
fprintf('Orientation (theta): %.2f radians\n', theta);
%%
% Create figure with tiled layout
figure;
tiledlayout(1, 2);
% --- Original cropped image
nexttile;
imagesc(img);
title('Original Cropped Image');
axis image;
colorbar;
% --- Fitted Gaussian reconstruction
nexttile;
% Reconstruct fitted 2D Gaussian
[x, y] = meshgrid(1:size(img,2), 1:size(img,1));
x_flat = x(:);
y_flat = y(:);
coords = [x_flat, y_flat];
% Evaluate fitted Gaussian at each pixel
z_fit = gauss2d(params_fit, coords);
img_fit = reshape(z_fit, size(img));
imagesc(img_fit);
title('Fitted 2D Gaussian');
axis image;
colorbar;

%% and plot ellipse on top
% Show the image
figure; imagesc(img); colormap hot; axis image;
hold on;
% Parameters from fit
nPoints = 100;
t = linspace(0, 2*pi, nPoints);
ellipse_x = sigma_x * cos(t);
ellipse_y = sigma_y * sin(t);
% Rotation matrix
R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
% Apply rotation
ellipse_coords = R * [ellipse_x; ellipse_y];
% Translate to center
ellipse_coords(1,:) = ellipse_coords(1,:) + x0;
ellipse_coords(2,:) = ellipse_coords(2,:) + y0;
% Plot the ellipse
plot(ellipse_coords(1,:), ellipse_coords(2,:), 'b-', 'LineWidth', 2);
title('Laser Beam Profile with 1-\sigma Ellipse');


%%
function F = D2GaussFunction(x,xdata)
 F = x(1)*exp(   -((xdata(:,:,1)-x(2)).^2/(2*x(3)^2) + (xdata(:,:,2)-x(4)).^2/(2*x(5)^2) )    );
end

%%
function F = D2GaussFunctionRot(x,xdata)
%% x = [Amp, x0, wx, y0, wy, fi]
%[X,Y] = meshgrid(x,y) 
%  xdata(:,:,1) = X
%  xdata(:,:,2) = Y           
% Mrot = [cos(fi) -sin(fi); sin(fi) cos(fi)]
%%
xdatarot(:,:,1)= xdata(:,:,1)*cos(x(6)) - xdata(:,:,2)*sin(x(6));
xdatarot(:,:,2)= xdata(:,:,1)*sin(x(6)) + xdata(:,:,2)*cos(x(6));
x0rot = x(2)*cos(x(6)) - x(4)*sin(x(6));
y0rot = x(2)*sin(x(6)) + x(4)*cos(x(6));

F = x(1)*exp(   -((xdatarot(:,:,1)-x0rot).^2/(2*x(3)^2) + (xdatarot(:,:,2)-y0rot).^2/(2*x(5)^2) )    );

% figure(3)
% alpha(0)
% imagesc(F)
% colormap('gray')
% figure(gcf)%bring current figure to front
% drawnow
% beep
% pause %Wait for keystroke
end

