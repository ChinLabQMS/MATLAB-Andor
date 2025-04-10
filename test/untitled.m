clear; clc; close all

% Data = load("data/2025/03 March/20250326/dense_no_green.mat").Data;
% Data = load("data/2025/02 February/20250220 gray static patterns/no_dmd_dense.mat").Data;
% Data = load("data/2025/02 February/20250220 gray static patterns/no_dmd_sparse.mat").Data;
% Data = load("data/2025/02 February/20250225 modulation frequency scan/no_532.mat").Data;
% Data = load("data/2025/04 April/20250408 mod freq scan/sparse_no_green.mat").Data;
Data = load("data/2025/04 April/20250409/sparse_freqOP=-2.6_Bx=-0.79_By=2.08_Bz=1.4_OPAM=1.mat").Data;

p = Preprocessor();
Signal = p.process(Data);

% signal = mean(Signal.Andor19331.Image(:, :, 1), 3);
signal = Signal.Andor19331.Image;
counter = SiteCounter("Andor19331");
ps = counter.PointSource;
lat = counter.Lattice;
counter.SiteGrid.config("SiteFormat", "Hex", "HexRadius", 25)

max_signal = maxk(reshape(signal, [], size(signal, 3)), 10, 1);
disp(mean(max_signal(:)))

%%
tic
counter.precalibrate(signal, 2)
toc

%%
tic
stat = counter.process(signal, 2, 'plot_diagnostic', 0, 'classify_threshold', 1300, 'calib_mode', 'none');
toc

close all
figure
scatter(reshape(stat.LatCount(:, 1, :), [], 1), reshape(stat.LatCount(:, 2, :), [], 1))
xline(stat.LatThreshold)
axis("equal")

desc = describe(stat.LatOccup);

function description = describe(occup, options)
    arguments
        occup
        options.verbose = true
    end
    [num_sites, num_frames, num_acq] = size(occup, 1:3);
    total = reshape(sum(occup, 1), num_frames, num_acq);
    description.N = total;
    description.F = total / num_sites;
    description.MeanSub.N = mean(total, 1);
    description.MeanSub.F = description.MeanSub.N / num_sites;
    description.MeanAcq.N = mean(total, 2);
    description.MeanAcq.F = description.MeanAcq.N / num_sites;
    description.MeanAll.N = mean(total, 'all');
    description.MeanAll.F = description.MeanAll.N / num_sites;
    if num_frames ~= 1
        early = occup(:, 2:end, :);
        later = occup(:, 1:(end - 1), :);
        description.N1 = reshape(sum(early, 1), num_frames-1, num_acq);
        description.N2 = reshape(sum(later, 1), num_frames-1, num_acq);
        description.N11 = reshape(sum(early & later, 1), num_frames-1, num_acq);
        description.N10 = reshape(sum(early & ~later, 1), num_frames-1, num_acq);
        description.N01 = reshape(sum(~early & later, 1), num_frames-1, num_acq);
        description.N00 = reshape(sum(~early & ~later, 1), num_frames-1, num_acq);
        description.Loss = description.N1 - description.N2;
        description.MeanSub.LossRate = reshape(sum(description.Loss, 1) ./ sum(description.N1, 1), 1, []);
        description.MeanSub.ErrorRate = reshape(sum(description.N10, 1) ./ sum(description.N1, 1), 1, []);
        description.MeanAcq.LossRate = sum(description.Loss, 2) ./ sum(description.N1, 2);
        description.MeanAcq.ErrorRate = sum(description.N10, 2) ./ sum(description.N1, 2);
        description.MeanAll.LossRate = sum(description.Loss, 'all') ./ sum(description.N1, 'all');
        description.MeanAll.ErrorRate = sum(description.N10, 'all') ./ sum(description.N1, 'all');
    end
    if options.verbose
        disp(description.MeanAll)
    end
end
