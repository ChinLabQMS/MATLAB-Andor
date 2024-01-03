function Config = getAcquisitionConfig()
    [ret, Config.exposure, accumulate, kinetic] = GetAcquisitionTimings();
    CheckWarning(ret)
end