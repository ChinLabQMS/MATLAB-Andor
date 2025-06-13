%%
clear; clc; close all
Lat = load("calibration/LatCalib.mat").Andor19331;
p = Preprocessor();
Signal = arrayfun(@p.process, ...
        [load("data/2025/02 February/20250218 DMD focus scan/DMD=0in_angled_cross_width=10.mat").Data;
        load("data/2025/02 February/20250218 DMD focus scan/DMD=0.2in_angled_cross_width=10.mat").Data;
        load("data/2025/02 February/20250218 DMD focus scan/DMD=0.3in_angled_cross_width=10.mat").Data;
        load("data/2025/02 February/20250218 DMD focus scan/DMD=0.4in_angled_cross_width=10.mat").Data;
        load("data/2025/02 February/20250218 DMD focus scan/DMD=0.5in_angled_cross_width=10.mat").Data;
        load("data/2025/02 February/20250218 DMD focus scan/DMD=0.6in_angled_cross_width=10.mat").Data;
        load("data/2025/02 February/20250218 DMD focus scan/DMD=0.7in_angled_cross_width=10.mat").Data;
        load("data/2025/02 February/20250218 DMD focus scan/DMD=1in_angled_cross_width=10.mat").Data;
        ]);

mean_image = arrayfun(@(x) mean(x.Andor19331.Image, 3), Signal, 'UniformOutput', false);
distance = [0, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 1] * 25.4;

%%
v1sum = cell(1, 4);
v2sum = cell(1, 4);

figure
for i = 1:length(mean_image)
    transformed = Lat.transformSignalStandardCropSite(mean_image{i}, 30);
    transformed3 = Lat.transformSignalStandardCropSite(mean_image{i}, 30, 'v1', [-1/2*sqrt(3), -1/2], 'v2', [0, 1]);
    c_obj = onCleanup(@() setLatR(Lat, Lat.R));

    old_R = Lat.R;
    Lat.init(old_R + [512, 0]);
    transformed2 = Lat.transformSignalStandardCropSite(mean_image{i}, 30);
    transformed4 = Lat.transformSignalStandardCropSite(mean_image{i}, 30, 'v1', [-1/2*sqrt(3), -1/2], 'v2', [0, 1]);

    x_sum = sum(transformed, 2);
    x_sum2 = sum(transformed2, 2);
    x_sum3 = sum(transformed3, 2);
    x_sum4 = sum(transformed4, 2);
    v1diff = x_sum2 - x_sum;
    v2diff = x_sum4 - x_sum3;
    
    gauss_eqn = 'a*exp(-(1/2*((x-b)/c)^2))+d';
    fit_range = -30:20;

    [maxv, maxi] = max(v1diff);
    i1_range = maxi + fit_range';
    v1_range = v1diff(i1_range);
    f1 = fit(i1_range, v1_range, gauss_eqn, ...
        'Start', [maxv, maxi, 20, 1000], ...
        'Upper', [maxv, i1_range(end), 50, maxv]);
    [maxv, maxi] = max(v2diff);
    i2_range = maxi + fit_range';
    v2_range = v2diff(i2_range);
    f2 = fit(i2_range, v2_range, gauss_eqn, 'Start', [maxv, maxi, 20, 1000]);

    subplot(4, length(mean_image), i)
    imagesc2(transformed)
    title(sprintf('d = %g mm', distance(i)))

    subplot(4, length(mean_image), i + length(mean_image))
    imagesc2(transformed2 - transformed)

    subplot(4, length(mean_image), i + 2*length(mean_image))
    plot(v1diff)
    hold on
    plot(f1, i1_range, v1_range)
    title('v1 sum')

    subplot(4, length(mean_image), i + 3*length(mean_image))
    plot(v2diff)
    hold on
    plot(f2, i2_range, v2_range)
    title('v2 sum')
    
    v1sum{i} = f1;
    v2sum{i} = f2;
    Lat.init(old_R);
end
%%

figure
plot(distance, arrayfun(@(x) x{1}.c, v2sum) / 10, 'o-')
hold on
plot(distance, arrayfun(@(x) x{1}.c, v1sum) / 10, 'o-')
xlabel('distance (mm)')
ylabel('sigma (lattice site)')
legend(["v1 width", "v2 width"])

figure
plot(distance, arrayfun(@(x) x{1}.b, v2sum) / 10, 'o-')
hold on
plot(distance, arrayfun(@(x) x{1}.b, v1sum) / 10, 'o-')
xlabel('distance (mm)')
ylabel('offset (lattice site)')
legend(["v1 center", "v2 center"])

%%
function setLatR(Lat, LatR)
    Lat.init(LatR)
end
