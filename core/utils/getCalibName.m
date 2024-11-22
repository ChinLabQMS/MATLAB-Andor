function [calib_name, wavelength] = getCalibName(camera, label)
    if label.contains("_")
        wavelength = label.extractAfter("_");
    else
        wavelength = "852";
    end
    calib_name = camera + "_" + wavelength;
    wavelength = double(wavelength);
end
