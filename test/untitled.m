clear; clc; close all

% Data = load("data/2025/03 March/20250326/dense_no_green.mat").Data;
% Data = load("data/2025/02 February/20250220 gray static patterns/no_dmd_dense.mat").Data;
% Data = load("data/2025/02 February/20250220 gray static patterns/no_dmd_sparse.mat").Data;
Data = load("data/2025/02 February/20250225 modulation frequency scan/no_532.mat").Data;

%%
p = Preprocessor();
Signal = p.process(Data);
load("calibration/LatCalib.mat")

%%
signal = mean(Signal.Andor19331.Image(:, :, 1), 3);

%%
counter = SiteCounter("Andor19331");

%%
stat1 = counter.process(signal, 2, 'plot_diagnostic', true, 'count_method', "circle_sum");

%%
stat2 = counter.process(signal, 2, 'plot_diagnostic', true, 'count_method', "center_signal");

%%
figure
histogram(stat1.LatCount, 100)

figure
histogram(stat2.LatCount, 100)

%%
figure
scatter(stat2.LatCount(:, 1), stat2.LatCount(:, 2))

%%
figure
subplot(1, 2, 1)
imagesc2(y_range, x_range, signal)

subplot(1, 2, 2)
imagesc2(y_range, x_range, signal)
Andor19331.plot()
Andor19331.plotV()
Andor19331.plotOccup(stat2.SiteInfo.Sites(stat2.LatOccup, :), stat2.SiteInfo.Sites(~stat2.LatOccup, :))

%%
sites = SiteGrid.prepareSite("Rect", "latx_range", -20:5:20, "laty_range", -20: 5: 20);
Andor19331.plot(sites, 'color', 'w', 'norm_radius', 0.5, 'filter', true, 'x_lim', [x_range(1), x_range(end)], 'y_lim', [y_range(1), y_range(end)])

%%
Zelux.calibrateR(Signal.Zelux.Pattern_532(:, :, 1))

figure
imagesc2(Signal.Zelux.Pattern_532(:, :, 1))
Zelux.plot()
Zelux.plotV()

%%
psf = counter.PointSource.PSF;
lat = counter.Lattice;

%%
function [deconv_func, deconv_pat, x_range, y_range] = getDeconv(lat, psf, options)
    arguments
        lat
        psf
        options.placeholder
    end
end

%%
[pattern, x_range, y_range] = matDeconv(lat, psf, 10, 30, 4, 2);
imagesc2(y_range, x_range, pattern)
lat.plot('center', [0, 0])

function [Pattern, x_range, y_range] = matDeconv(Lat,funcPSF,PSFR,RPattern,Factor,LatRLim)
% Calculate deconvolution pattern by inverting (-LatRLim:LatRLim) PSF

    % Number of sites
    NumSite = (2*LatRLim+1)^2;

    % Number of pixels
    NumPx = (2*Factor*RPattern+1)^2;
    x_range = -RPattern: 1/Factor : RPattern;
    y_range = -RPattern: 1/Factor : RPattern;

    M = zeros(NumSite,NumPx);
    if funcPSF(PSFR,PSFR)>0.001
        warning(['Probability density at edge is significant = %.4f\nCheck' ...
            ' PSFR (radius for calculating PSF spread)'],funcPSF(PSFR,PSFR))
    end
    
    % For each lattice site, find its spread into nearby pixels
    for i = -LatRLim:LatRLim
        for j = -LatRLim:LatRLim
            
            % Site index
            Site = (i+LatRLim+1)+(j+LatRLim)*(2*LatRLim+1);

            % Lattice site coordinate
            Center = [i,j]*Lat.V;

            % Convert coordinate to magnified pixel index
            CXIndex = round(Factor*(Center(1)+RPattern))+1;
            CYIndex = round(Factor*(Center(2)+RPattern))+1;

            % Range of pixel index to run through
            xMin = CXIndex-PSFR*Factor;
            xMax = CXIndex+PSFR*Factor;
            yMin = CYIndex-PSFR*Factor;
            yMax = CYIndex+PSFR*Factor;

            % Go through all pixels and assign the spread
            x = xMin:xMax;
            y = yMin:yMax;
            Pixel = x'+(y-1)*(2*Factor*RPattern+1);
            [YP,XP] = meshgrid((y-1)/Factor-RPattern,(x-1)/Factor-RPattern);
            val = funcPSF(XP(:)-Center(1),YP(:)-Center(2))/Factor^2;
            try
                M(Site,Pixel) = val;
            catch
            end
        end
    end

    % Convert transfer matrix to deconvolution pattern
    MInv = (M*M')\M;
    Pattern = reshape(MInv(round(NumSite/2),:),sqrt(NumPx),[]);

    % Re-normalize deconvolution pattern
    Area = abs(det(Lat.V));
    %disp(Area);
    Pattern = Area/(sum(Pattern,"all")/Factor^2)*Pattern;
    %Pattern= Pattern/sum(Pattern,"all");
end


