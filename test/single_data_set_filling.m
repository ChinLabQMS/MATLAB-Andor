clear; clc; close all

% Data = load("data/2025/03 March/20250326/dense_no_green.mat").Data;
% Data = load("data/2025/02 February/20250220 gray static patterns/no_dmd_dense.mat").Data;
% Data = load("data/2025/02 February/20250220 gray static patterns/no_dmd_sparse.mat").Data;
% Data = load("data/2025/02 February/20250225 modulation frequency scan/no_532.mat").Data;
% Data = load("data/2025/04 April/20250408 mod freq scan/sparse_no_green.mat").Data;
% Data = load("data/2025/04 April/20250411/counter_not_working_somehow.mat").Data;
%Data = load("data/2025/04 April/20250411/dense_no_green.mat").Data;
%Data = load("data/2025/04 April/20250430/startofday20250430.mat").Data;
%Data = load("data/2025/05 May/aftgeroptimg.mat").Data;
%Data = load("data/2025/05 May/20250501/endofday.mat").Data;
%Data = load("data/2025/05 May/20250505/startofday20250505.mat").Data;
%Data = load("data/2025/05 May/20250505/largeset2.mat").Data;
%Data = load("data/2025/05 May/20250506/r=10_whitespotarray_pulseonbetween.mat").Data;
%Data = load("data/2025/05 May/20250508/vec2lineonatoms.mat").Data;
%Data = load("data/2025/05 May/20250515/triangle.mat").Data;
%Data = load("data/2025/05 May/20250515/r=25array_inverted.mat").Data;
%Data = load("data/2025/05 May/20250508/imgopt.mat").Data;
%Data = load("data/2025/05 May/20250515/nogreen.mat").Data;
%Data = load("data/2025/05 May/20250515/width10stripes_greenbeforeandduringimg1.mat").Data;
%Data = load("data/2025/05 May/20250515/width10stripes_greenbeforeandduringimg1_again.mat").Data;
%Data = load("data/2025/05 May/20250515/tryinggreenduringnormalsp.mat").Data;
Data = load("data/2025/05 May/20250516/vec2_width5_offset=-2.mat").Data;
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

%% error and loss
