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
% Convert initial guess to Gaussian parameters
% gauss2d = @(params, coords) ...
%     params(1)*exp(-((x-params(2)).^2/(2*params(4).^2)+((y-params(3)).^2/(2*params(5).^2))))+params(6)
% %params(1)*exp(-((x-x0)^2/(2*sigma_x^2)+((y-y0)^2/(2*sigma_y^2))))
% % params: [A, x0, y0, sigma_x, sigma_y, theta, offset]
% Gaussian function: [A, x0, y0, sigma_x, sigma_y, offset]
gauss2d = @(params, coords) ...
    params(1) .* exp(
        - (((coords(:,1) - params(2)).^2 / (2*params(4)^2)) ...
        - ((coords(:,2) - params(3)).^2 / (2*params(5)^2)) ...
    ) + params(6);

gauss2dt = @(params, coords) ...
    params(1) * exp( 
        - ((
        ((coords(:,1)-params(2))*cos(params(6)) + (coords(:,2)-params(3))*sin(params(6))).^2 ) / (2*params(4)^2) + 
            ( ((-(coords(:,1)-params(2))*sin(params(6)) + (coords(:,2)-params(3))*cos(params(6))).^2 ) / (2*params(5)^2))) + params(7);

params0 = [A0, x0, y0, sigma_x, sigma_y, theta, offset];
% Fit using lsqcurvefit (Optimization Toolbox)
opts = optimset('Display','off');
[params_fit, ~] = lsqcurvefit(gauss2dt, params0, xdata, zdata, [],[], opts);
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

