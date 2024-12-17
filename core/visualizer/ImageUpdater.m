classdef ImageUpdater < AxesUpdater

    properties (SetAccess = {?BaseObject})
        CameraName = "Andor19330"
        ImageLabel = "Image"
        Content = "Signal"
        FuncName = "None"
    end

    properties (Constant)
        PlotLattice_HexR = 20
        PlotLattice_TransformCropRSite = 20
        PlotLattice_TransformScaleV = 5
        PlotPSF_ScaleV = 1
    end

    properties (SetAccess = protected)
        ColorbarHandle
        AddonHandle
    end

    methods (Access = protected)
        function resetAddon(obj)
            if ~isempty(obj.AddonHandle)
                delete(obj.AddonHandle)
                obj.AddonHandle = [];
            end
        end

        function updateContent(obj, Live, options)
            arguments
                obj
                Live
                options.transform_cropRsite = obj.PlotLattice_TransformCropRSite
                options.transform_scaleV = obj.PlotLattice_TransformScaleV
            end
            c_obj = onCleanup(@()preserveHold(ishold(obj.AxesHandle), obj.AxesHandle)); % Preserve original hold state
            plotData(obj, Live)
            obj.resetAddon()
            switch obj.FuncName
                case "None"
                case "Lattice"
                    obj.plotLattice(Live)
                case "Lattice All"
                    obj.plotLatticeAll(Live)
                case "Transformed with Lattice"
                    obj.plotTransformedLattice(Live)
                case "PSF"
                    obj.plotPSF(Live)
                otherwise
                    obj.error('Unrecongnized add-on name %s.', obj.FuncName)
            end
        end

        function plotData(obj, Live)
            data = Live.(obj.Content).(obj.CameraName).(obj.ImageLabel);
            [x_size, y_size] = size(data);
            if isempty(obj.GraphHandle)
                obj.GraphHandle = imagesc(obj.AxesHandle, data);
                obj.ColorbarHandle = colorbar(obj.AxesHandle);
            else
                obj.GraphHandle.XData = [1, y_size];
                obj.GraphHandle.YData = [1, x_size];
                obj.GraphHandle.CData = data;
            end
        end
        
        function plotLattice(obj, Live, options)
            arguments
                obj
                Live
                options.lattice_hexr = obj.PlotLattice_HexR
            end
            Lat = getLatCalib(obj, Live);
            obj.AddonHandle = Lat.plot(obj.AxesHandle, ...
                    Lattice.prepareSite("hex", "latr", options.lattice_hexr), 'filter', false);
        end
        
        function plotLatticeAll(obj, Live, options)
            arguments
                obj
                Live
                options.lattice_hexr = obj.PlotLattice_HexR
            end
            Lat = getLatCalib(obj, Live);
            num_frames = Live.CameraManager.(obj.CameraName).Config.NumSubFrames;
            x_size = Live.CameraManager.(obj.CameraName).Config.XPixels;
            for i = 1: num_frames
                obj.AddonHandle(i) = Lat.plot(obj.AxesHandle, ...
                    Lattice.prepareSite("hex", "latr", options.lattice_hexr), ...
                    'center', Lat.R + [x_size / num_frames * (i - 1), 0], 'filter', false);
            end
        end
        
        function plotTransformedLattice(obj, Live, options)
            arguments
                obj
                Live
                options.lattice_hexr = obj.PlotLattice_HexR
                options.transform_cropRsite = obj.PlotLattice_TransformCropRSite
                options.transform_scaleV = obj.PlotLattice_TransformScaleV
            end
            data = Live.(obj.Content).(obj.CameraName).(obj.ImageLabel);
            num_frames = Live.CameraManager.(obj.CameraName).Config.NumSubFrames;
            signal = getSignalSum(data, num_frames, 'first_only', true);
            Lat = getLatCalib(obj, Live);
            [transformed, x_range, y_range, Lat2] = ...
                Lat.transformSignalStandardCropSite(signal, options.transform_cropRsite);
            hold(obj.AxesHandle, "on")
            obj.AddonHandle = imagesc(obj.AxesHandle, y_range, x_range, transformed);
            obj.AddonHandle(2) = Lat2.plot(obj.AxesHandle, ...
                Lattice.prepareSite("hex", "latr", options.lattice_hexr), 'filter', false);
            obj.AddonHandle(3:4) = Lat2.plotV(obj.AxesHandle, 'scale', options.transform_scaleV, 'add_legend', false);
        end
        
        function plotPSF(obj, Live, options)
            arguments
                obj
                Live
                options.scale_V = obj.PlotPSF_ScaleV
            end
            try
                PS = Live.PSFCalib.(obj.CameraName);
                centers = PS.DataLastStats.RefinedCentroid;
                radius = PS.DataLastStats.MaxRefinedWidth;
                hold(obj.AxesHandle, "on")
                obj.AddonHandle(1) = viscircles(obj.AxesHandle, centers, radius, 'LineWidth', 0.5);
                obj.AddonHandle(2) = PS.plot(obj.AxesHandle);
                obj.AddonHandle(3:4) = PS.plotV(obj.AxesHandle, "scale", options.scale_V);
            catch
                obj.warn2("[%s %s] Can not find last PSF fitting data. Please check if 'fitPSF' exists in SequenceTable.", obj.CameraName, obj.ImageLabel)
            end
        end

    end

end

%% Other utilities functions

function Lat = getLatCalib(obj, Live)
    Lat = Live.LatCalib.(obj.CameraName);
end
