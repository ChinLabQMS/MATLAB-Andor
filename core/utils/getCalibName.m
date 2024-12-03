function [calib_name, wavelength] = getCalibName(camera, label)
arguments
    camera (1, 1) string
    label (1, 1) string
end
    if label.contains("_")
        wavelength = label.extractAfter("_");
    else
        wavelength = "852";
    end
    calib_name = camera + "_" + wavelength;
    wavelength = double(wavelength) / 1000;
end
