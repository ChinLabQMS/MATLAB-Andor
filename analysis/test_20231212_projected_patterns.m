clear
clc

data_path = 'data/r=40_calibration_pattern';
Data = load(data_path).Data;

mean_sig = mean(Data.Andor19330.Image, 3);

figure
imagesc(mean_sig)
daspect([1 1 1])
colorbar

%%
target1 = [315, 491];
target2 = [354, 454];
target3 = [367, 551];

anchor1 = [0, 0];
anchor2 = [100, 0];
anchor3 = [0, 150];

% M = [target1 - target2; target1 - target3]'/[anchor1 - anchor2; anchor1 - anchor3]';
% b = mean([target1; target2; target3] - [anchor1; anchor2; anchor3] * M;
% M, b

A = [anchor1(1), 0, anchor1(2), 0, 1, 0;
     0, anchor1(1), 0, anchor1(2), 0, 1;
     anchor2(1), 0, anchor2(2), 0, 1, 0;
     0, anchor2(1), 0, anchor2(2), 0, 1;
     anchor3(1), 0, anchor3(2), 0, 1, 0;
     0, anchor3(1), 0, anchor3(2), 0, 1;
    ];

target = [target1'; target2'; target3'];

res = A\target;
M = [res(1), res(2); res(3), res(4)]'
b = [res(5), res(6)]

%%
theta = 0:0.01:2*pi;
x1 = 40*sin(theta);
y1 = 40*cos(theta);

x2 = x1 + anchor2(1);
y2 = y1 + anchor2(2);

x3 = x1 + anchor3(1);
y3 = y1 + anchor3(2);

transformed = M * [x1; y1] + b';
x_new1 = transformed(1,:);
y_new1 = transformed(2, :);

transformed = M * [x2; y2] + b';
x_new2 = transformed(1,:);
y_new2 = transformed(2, :);

transformed = M * [x3; y3] + b';
x_new3 = transformed(1,:);
y_new3 = transformed(2, :);

figure
imagesc(mean_sig)
daspect([1 1 1])
colorbar

hold on
plot(y_new1, x_new1, Color='r')
plot(y_new2, x_new2, Color='r')
plot(y_new3, x_new3, Color='r')

plot(y_new1, x_new1+512, Color='r')
plot(y_new2, x_new2+512, Color='r')
plot(y_new3, x_new3+512, Color='r')

title('Calibration pattern on atoms')

%%
data_path = 'data/r=50_darkspot_onatoms_centered.mat';
Data = load(data_path).Data;

images = Data.Andor19330.Image;
mean_sig = mean(images, 3);

theta = 0:0.01:2*pi;
x1 = 50*sin(theta);
y1 = 50*cos(theta);

transformed = M * [x1; y1] + b';
x_new1 = transformed(1,:);
y_new1 = transformed(2, :);

figure
imagesc(mean_sig)
daspect([1 1 1])
colorbar

hold on
plot(y_new1, x_new1, Color='r')
plot(y_new1, x_new1+512, Color='r')

title('Radius=50 circle')

%%
data_path = 'data/r=20_darkspot_onatoms_centered.mat';
Data = load(data_path).Data;

images = Data.Andor19330.Image;
mean_sig = mean(images, 3);

theta = 0:0.01:2*pi;
x1 = 20*sin(theta);
y1 = 20*cos(theta);

transformed = M * [x1; y1] + b';
x_new1 = transformed(1,:);
y_new1 = transformed(2, :);

figure
imagesc(mean_sig)
daspect([1 1 1])
colorbar

hold on
plot(y_new1, x_new1, Color='r')
plot(y_new1, x_new1+512, Color='r')

title('Radius=20 circle')