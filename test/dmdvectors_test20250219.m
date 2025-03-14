% fitting "DMD vectors" on the lower CCD atom image using the averaged
% image of 15 pixel cross on the atoms

coords = [477 209; 590 314; 471 335; 587 216]; % 20241004 calibration (DMD on atoms, placed cursors along each line of a cross pattern)
coords = [604 238; 690 386]; % 20250219 calibration (DMD line on atoms, placed cursors along one line, using -17.1 angle

coords = [627 270; 661 325] % 20250219 angle -14.1 placed cursors

coords1 = [coords(:,2),coords(:,1)];

slope1 = (coords1(1,2)-coords1(2,2))/(coords1(1,1)-coords1(2,1));
%slope2 = (coords1(3,2)-coords1(4,2))/(coords1(3,1)-coords1(4,1));

vec1 = [1;slope1];
%vec2=[1;slope2];

% these are vectors in Andor 19330 space. can compare to lattice vectors in
% Andor 19330 space and see how far we have to rotate in order to match a
% lattice vector. V2 appears to be the closest

% Plot the lattice vectors with the DMD vectors

latvec2 = Andor19331.V(2,:);
latvec1 = Andor19331.V(1,:);

% make lines corresponding to each of these vectors, originating at R
center = Andor19331.R;
xvals = linspace(0,100,100)+center(1);
linedmd1 = linspace(1,100,100)*slope1+center(2);
%linedmd2 = linspace(1,100,100)*slope2+center(2);
linelat1 = linspace(1,100,100)*latvec1(2)/latvec1(1)+center(2);
linelat2 = linspace(1,100,100)*latvec2(2)/latvec2(1)+center(2);


% load some data to plot the vectors on top.
%load('data/2024/10 October/20241003/gray_cross_on_blackwidth=15_angle=0.bmp.mat')
load('data/2025/02 Feburary/20250219/lines_width=5_large_spacing.mat')

%%
figure
imagesc(mean(Data.Andor19331.Image,3))
daspect([1 1 1]);

%%
hold on
scatter(linedmd1,xvals);
hold on
%scatter(linedmd2,xvals);
hold on
scatter(linelat1,xvals);
hold on
scatter(linelat2,xvals);
legend('dmd1','lat1','lat2');
%%
% find the angle between DMD vec 1 and lat vec 2
angle = acosd(latvec2*vec1/norm(latvec2)/norm(vec1))-180;

%% now we have some DMD on atoms grid!! transform to get the scaling to know where to move the center so DMD pattern is centered on atoms
dmdcenter=[260, 539];
atomcenter = [216, 537];
%distance to shift pattern in camera space
distcam = atomcenter-dmdcenter;
% finding the grid separations in camera space
dist140xdmd=sqrt((556-480)^2+(240-242)^2); % when you look at the dmd straight on before transforming, dmd real space not aligned with dmd axes
dist140ydmd = sqrt((560-556)^2+(316-240)^2);
% we want distdmd
% dmd 140 px = 76 camera pix
distdmd = distcam.*[140/dist140xdmd,140/dist140ydmd];
distxdmdpix = ((distdmd(1)-distdmd(2)))/sqrt(2);
distydmdpix=((distdmd(1)+distdmd(2)))/sqrt(2);
centerdmdpix = [distxdmdpix,distydmdpix];

%%
dmdvec = [666, 874] - [621, 276];
dmdvec = dmdvec(:, 2:-1:1);
latvec = Zelux.V(1, :);

acosd((dmdvec * latvec') / norm(dmdvec) / norm(latvec)) - 180

%%
dmdvec2 = [915, 796] - [194, 437];
dmdvec2 = dmdvec2(:, 2:-1:1);
latvec2 = Zelux.V(2, :);

acosd((dmdvec2 * latvec2') / norm(dmdvec2) / norm(latvec2))
