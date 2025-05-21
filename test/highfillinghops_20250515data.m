% load in all of the vector data
folder = "data/2025/05 May/20250515/";
%fileList = dir(fullfile(folder,'vec2_width5_offset=*.mat'));
fileList = dir(fullfile(folder,'tryinggreenduring*.mat'))
%filename = "vec2_width5_offset=5.mat";
%%
figure('Units','pixels','Position',[100,100,2000,900]);hold on;
colors = lines(length(fileList));
offsets =[];
sigmasdip = [];
contrasts = [];
fitcs = [];
for i = 1:length(fileList)
%for i = 1:2
    %Data = load(strcat("data/2025/05 May/20250516/",filename)).Data;
    Data = load(fullfile(folder,fileList(i).name)).Data;
    
    p = Preprocessor();
Signal = p.process(Data);
signal = Signal.Andor19331.Image;


counter = SiteCounter("Andor19331");
ps = counter.PointSource;
lat = counter.Lattice;
counter.configGrid("SiteFormat", "Hex", "HexRadius", 8)
tic
stat = counter.process(signal, 2, 'calib_mode', 'offset');
toc

avgImg = mean(signal, 3);
avgImg1 = avgImg(513:1024,400:912);
% rotate image so that V2 is along X axis
a = lat.K(1,1);
b = lat.K(1,2);

theta = -atan2(b,a)*(180/pi);

rotatedimage = imrotate(avgImg1,theta,'bilinear','crop');

yproj = sum(rotatedimage,2);

 % name = fileList(i).name;
 %    fprintf('Parsing filename: %s\n', name);
 %    % REGEX to extract offset (including negative numbers)
 %    tokens = regexp(name, 'offset=(-?\d+)', 'tokens');
 %    disp('Tokens:');
 %    disp(tokens);
 %    if ~isempty(tokens)
 %        offset = str2double(tokens{1}{1});
 %        fprintf('Extracted offset: %d\n\n', offset);
 %    else
 %        warning('Offset not found in filename: %s\n', name);
 %        offset = NaN;
 %    end

subplot(2,length(fileList),i)
imagesc(rotatedimage);
daspect([1 1 1]);
%title(strcat('Offset = ',num2str(offset)))

subplot(2,length(fileList),i+length(fileList))
plot(yproj,'DisplayName',sprintf('Offset = %d',offset),'Color',colors(i,:))
xlim([0 600])
ylim([0 10000])
%title(strcat('Offset = ',num2str(offset)))
title(fileList(i).name)
hold on

% crop it to just the dip
xstart = 255;
xend = 310;
y = yproj(xstart:xend);
x = 1:length(y);
x = x(:);
A0 = max(y);
C0 = 8000;
x0=x(y==min(y));
x1=x(y==min(y));
sigma0 = 5;
sigma1 = 5;
%params0 = [A0,C0,x0,x1,sigma0,sigma1];
% model with big Gauss minus little Gauss
%fitModel = @(p,x) p(1)*exp(-(x-p(3)).^2/(2*p(5)^2)) - p(2)*exp(-(x-p(4)).^2/(2*p(6)^2))
% model with just an upside down Gaussian
fitModel = @(p,x) p(1)- p(2)*exp(-(x-p(3)).^2/(2*p(4)^2))
params1 = [A0,C0,x0,sigma0];
% least squares fit
options = optimset('Display','off');
%paramsFit = lsqcurvefit(fitModel,params0,x,y,[],[],options);
paramsFit = lsqcurvefit(fitModel,params1,x,y,[],[],options);
A_fit = paramsFit(1);
C_fit = paramsFit(2);
x0fit = paramsFit(3);
%x1fit = paramsFit(4);
sigma0fit = paramsFit(4);
%sigma1fit = paramsFit(6);
plot(x+xstart,fitModel(paramsFit,x))
% Compute contrast ratio
contrast = C_fit / A_fit;
% Format the annotation string
annotationText = sprintf('\\sigma_{dip} = %.2f\nContrast = %.2f', sigma0fit, contrast);
% Add to plot (position it near top-left; adjust as needed)
xText = x(1) + 10;                       % a bit from the left
yText = max(y) - 0.1 * range(y);         % a bit below top
text(0.5, -0.25, annotationText, 'Units','normalized','HorizontalAlignment','center','FontSize', 12, 'BackgroundColor', 'white', 'EdgeColor', 'black');
sprintf(strcat('sigma width = ',num2str(sigma0fit)))
sigmasdip(end+1)=sigma0fit;
offsets(end+1) = offset;
contrasts(end+1) = contrast;
fitcs(end+1) = C_fit;
end
%%
sgtitle('20 shot averaged image and integrated counts perpendicular to lattice vec2')
xlabel('Distance perpendicular to vec2 (Andor pixels)')
%% plot contrast vs. offset, sigma vs offset
[sorted_offsets,sort_idx]=sort(offsets);
sorted_sigmas = sigmasdip(sort_idx);
sorted_contrasts = contrasts(sort_idx);
sorted_cfits = fitcs(sort_idx);

figure;
subplot(3,1,1);
plot(sorted_offsets,sorted_sigmas,'-o','LineWidth',2);
xlabel('Offset (DMD pixels)')
ylabel('Dip sigma width in Andor pixels')
title('Dip width vs offset')
subplot(3,1,2);
plot(sorted_offsets,sorted_cfits,'-o','LineWidth',2);
xlabel('Offset (DMD pixels)')
ylabel('Dip depth (counts)')
title('Dip depth vs offset')
subplot(3,1,3);
plot(sorted_offsets,sorted_contrasts,'-o','LineWidth',2);
xlabel('Offset (DMD pixels)')
ylabel('Dip contrast')
title('Dip contrast vs offset')

%%
p = Preprocessor();
Signal = p.process(Data);
signal = Signal.Andor19331.Image;


counter = SiteCounter("Andor19331");
ps = counter.PointSource;
lat = counter.Lattice;
counter.configGrid("SiteFormat", "Hex", "HexRadius", 8)
tic
stat = counter.process(signal, 2, 'calib_mode', 'offset');
toc
%%
figure
imagesc2(mean(signal, 3))
counter.Lattice.plot()
title("offset = -2px")
% clim([0, 60])
% counter.Lattice.plot(SiteGrid.prepareSite("MaskedRect", "mask_Lattice", counter.Lattice))

%%
figure
imagesc2(signal(:, :, 10))
counter.Lattice.plot()

%%
close all
figure
scatter(reshape(stat.LatCount(:, 1, 10), [], 1), reshape(stat.LatCount(:, 2, 10), [], 1))
xline(stat.LatThreshold)
axis("equal")

figure
histogram(stat.LatCount(:, :, 1), 100)
xline(stat.LatThreshold)

desc = counter.describe(stat.LatOccup, 'verbose', true);

%%
shot1tot = sum(stat.LatOccup(:,1,:),1);
shot1fill = shot1tot/size(stat.LatOccup,1);
shot1fillavg = sum(shot1fill)/size(shot1fill,3);

%%
shot2tot = sum(stat.LatOccup(:,2,:),1);
shot2fill = shot2tot/size(stat.LatOccup,1);
shot2fillavg = sum(shot2fill)/size(shot2fill,3);

%%
bothfillavg = (shot1fillavg+shot2fillavg)/2;

%% Integrate the counts along the lattice vector 2 direction
% find the dip and then characterize its width and the contrast

avgImg = mean(signal, 3);
avgImg1 = avgImg(513:1024,400:912);
% rotate image so that V2 is along X axis
a = lat.K(1,1);
b = lat.K(1,2);

theta = -atan2(b,a)*(180/pi);

rotatedimage = imrotate(avgImg1,theta,'bilinear','crop');

figure;
imagesc(rotatedimage)
daspect([1 1 1])

yproj = sum(rotatedimage,2);

figure;
subplot(1,2,1);
imagesc(rotatedimage)
daspect([1 1 1])
title(filename)
subplot(1,2,2);
plot(yproj);
xlabel('Distance perpendicular to lattice vec2')
ylabel('Integrated counts')
title(strcat('Projection perpendicular to lat vec2 ',filename))