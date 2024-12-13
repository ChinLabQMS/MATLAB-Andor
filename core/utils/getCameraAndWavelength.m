function [camera, wavelength] = getCameraAndWavelength(calib_name)
    if calib_name.contains("_")
        camera = extractBefore(calib_name, "_");
        wavelength = double(extractAfter(calib_name, "_")) / 1000;
    else
        camera = calib_name;
        wavelength = 852;
    end
end
