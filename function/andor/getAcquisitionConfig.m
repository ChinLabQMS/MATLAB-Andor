function [Config] = getAcquisitionConfig(options)
    arguments
        options.num_frames (1,1) double = 1
    end
    [ret, YPixels, XPixels] = GetDetector();
    CheckWarning(ret)

    [ret, exposure, accumulate] = GetAcquisitionTimings();
    CheckWarning(ret)

    if (options.num_frames > 1) || (exposure == 0)
        [ret, exposure] = GetFKExposureTime();
        CheckWarning(ret)
    end

    Config = struct('NumFrames', options.num_frames, ...
                    'Exposure', exposure, ...
                    'Accumulate', accumulate, ...
                    'XPixels', XPixels, ...
                    'YPixels', YPixels);

end