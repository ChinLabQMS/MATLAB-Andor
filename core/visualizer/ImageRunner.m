classdef ImageRunner < AxesRunner

    properties (Constant)
        Content_LatticeHexR = 20
        Content_TransformCropRSite = 20
        Content_TransformScaleV = 5
    end

    methods (Access = protected)
        function updateContent(obj, Live, options)
            arguments
                obj
                Live
                options.lattice_hexr = obj.Content_LatticeHexR
                options.transform_cropRsite = obj.Content_TransformCropRSite
                options.transform_scaleV = obj.Content_TransformScaleV
            end
            plotData(obj, Live)
            delete(obj.AddonHandle)
            switch obj.Config.FuncName
                case "None"
                case "Lattice"
                    plotLattice(obj, Live, 'lattice_hexr', options.lattice_hexr)
                case "Lattice All"
                    plotLatticeAll(obj, Live, 'lattice_hexr', options.lattice_hexr)
                case "Transformed with Lattice"
                    plotTransformedLattice(obj, Live, ...
                        'lattice_hexr', options.lattice_hexr, 'transform_cropRsite', options.transform_cropRsite)
                case "Transformed with Axis"
                    plotTransformedAxis(obj, Live, ...
                        'transform_cropRsite', options.transform_cropRsite, 'transform_scaleV', options.transform_scaleV)
                case "PSF"
            end
        end
    end

end

function plotData(obj, Live)
    data = Live.(obj.Config.Content).(obj.Config.CameraName).(obj.Config.ImageLabel);
    [x_size, y_size] = size(data);
    if isempty(obj.GraphHandle)
        obj.GraphHandle = imagesc(obj.AxesHandle, data);
        colorbar(obj.AxesHandle)
    else
        obj.GraphHandle.XData = [1, y_size];
        obj.GraphHandle.YData = [1, x_size];
        obj.GraphHandle.CData = data;
    end
end

function plotLattice(obj, Live, options1)
    arguments
        obj
        Live
        options1.lattice_hexr
    end
    Lat = Live.LatCalib.(obj.Config.CameraName);
    obj.AddonHandle = Lat.plot(obj.AxesHandle, ...
            Lattice.prepareSite("hex", "latr", options1.lattice_hexr), 'filter', false);
end

function plotLatticeAll(obj, Live, options1)
    arguments
        obj
        Live
        options1.lattice_hexr
    end
    Lat = Live.LatCalib.(obj.Config.CameraName);
    num_frames = Live.CameraManager.(obj.Config.CameraName).Config.NumSubFrames;
    x_size = Live.CameraManager.(obj.Config.CameraName).Config.XPixels;
    obj.AddonHandle = gobjects(num_frames, 1);
    for i = 1: num_frames
        obj.AddonHandle(i) = Lat.plot(obj.AxesHandle, ...
            Lattice.prepareSite("hex", "latr", options1.lattice_hexr), ...
            'center', Lat.R + [x_size / num_frames * (i - 1), 0], 'filter', false);
    end
end

function plotTransformedLattice(obj, Live, options)
    arguments
        obj
        Live
        options.lattice_hexr
        options.transform_cropRsite
    end
    data = Live.(obj.Config.Content).(obj.Config.CameraName).(obj.Config.ImageLabel);
    num_frames = Live.CameraManager.(obj.Config.CameraName).Config.NumSubFrames;
    signal = getSignalSum(data, num_frames, 'first_only', true);
    Lat = Live.LatCalib.(obj.Config.CameraName);
    [transformed, x_range, y_range, Lat2] = ...
        Lat.transformSignalStandardCropSite(signal, options.transform_cropRsite);
    hold(obj.AxesHandle, "on")
    obj.AddonHandle = imagesc(obj.AxesHandle, y_range, x_range, transformed);
    obj.AddonHandle(2) = Lat2.plot(obj.AxesHandle, ...
        Lattice.prepareSite("hex", "latr", options.lattice_hexr), 'filter', false);
    hold(obj.AxesHandle, "off")
end

function plotTransformedAxis(obj, Live, options)
    arguments
        obj
        Live
        options.transform_cropRsite
        options.transform_scaleV
    end
    data = Live.(obj.Config.Content).(obj.Config.CameraName).(obj.Config.ImageLabel);
    num_frames = Live.CameraManager.(obj.Config.CameraName).Config.NumSubFrames;
    signal = getSignalSum(data, num_frames, "first_only", true);
    Lat = Live.LatCalib.(obj.Config.CameraName);
    [transformed, x_range, y_range, Lat2] = ...
        Lat.transformSignalStandardCropSite(signal, options.transform_cropRsite);
    hold(obj.AxesHandle, "on")
    obj.AddonHandle = imagesc(obj.AxesHandle, y_range, x_range, transformed);
    obj.AddonHandle(2:3) = Lat2.plotV(obj.AxesHandle, 'scale', options.transform_scaleV, 'add_legend', false);
    hold(obj.AxesHandle, "off")
end
