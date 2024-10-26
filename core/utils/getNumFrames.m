function num_frames = getNumFrames(config)
    if (isfield(config, "FastKinetic") || isprop(config, "FastKinetic")) && config.FastKinetic
        num_frames = config.FastKineticSeriesLength;
    else
        num_frames = 1;
    end
end
