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

    Config = struct('num_frames', options.num_frames, ...
                    'exposure', exposure, ...
                    'accumulate', accumulate, ...
                    'x_size', XPixels, ...
                    'y_size', YPixels);

end