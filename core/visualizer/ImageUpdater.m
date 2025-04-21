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
        PlotOccupied_PlotUnoccup = true
        PlotOccupied_OccupColor = 'y'
        PlotOccupied_UnoccupColor = 'b'
        PlotOccupied_CircleRadius = 0.1
        PlotHopLoss_HopColor = 'b'
        PlotHopLoss_LossColor = 'r'
        PlotHopLoss_GoodColor = 'y'
        PlotHopLoss_CircleRadius = 0.1
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

        function updateContent(obj, live, varargin)
            arguments
                obj
                live
            end
            arguments (Repeating)
                varargin
            end
            % Preserve original hold state upon exit
            c_obj = onCleanup(@()preserveHold(ishold(obj.AxesHandle), obj.AxesHandle));
            plotData(obj, live)
            obj.resetAddon()
            switch obj.FuncName
                case "None"
                case "Lattice All"
                    obj.plotLatticeAll(live, varargin{:})
                case "Transformed"
                    obj.plotTransformed(live, varargin{:})
                case "Transformed with Lattice"
                    obj.plotTransformedLattice(live, varargin{:})
                case "PSF"
                    obj.plotPSF(live, varargin{:})
                case "Occupied Sites"
                    obj.plotOccupied(live, varargin{:})
                case "Hop/Loss Sites"
                    obj.plotHopLoss(live, varargin{:})
                otherwise
                    obj.error('Unrecongnized add-on name %s.', obj.FuncName)
            end
        end

        function plotData(obj, live)
            data = live.(obj.Content).(obj.CameraName).(obj.ImageLabel);
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
        
        function plotLatticeAll(obj, live, options)
            arguments
                obj
                live
                options.lattice_hexr = obj.PlotLattice_HexR
            end
            Lat = getLatCalib(obj, live);
            num_frames = live.CameraManager.(obj.CameraName).Config.NumSubFrames;
            x_shift = (live.CameraManager.(obj.CameraName).Config.XPixels / num_frames) * (0: (num_frames - 1));
            R_shift = [x_shift', zeros(num_frames, 1)]; % shift only in X
            obj.AddonHandle = Lat.plot(obj.AxesHandle, ...
                SiteGrid.prepareSite('Hex', "latr", options.lattice_hexr), ...
                'center', Lat.R + R_shift, 'filter', false);
        end

        function plotTransformed(obj, live, options)
            arguments
                obj
                live
                options.transform_cropRsite = obj.PlotLattice_TransformCropRSite
            end
            [transformed, x_range, y_range] = getTransformed(obj, live, options.transform_cropRsite);
            hold(obj.AxesHandle, "on")
            obj.AddonHandle = imagesc(obj.AxesHandle, y_range, x_range, transformed);
        end
        
        function plotTransformedLattice(obj, live, options)
            arguments
                obj
                live
                options.lattice_hexr = obj.PlotLattice_HexR
                options.transform_cropRsite = obj.PlotLattice_TransformCropRSite
                options.transform_scaleV = obj.PlotLattice_TransformScaleV
            end
            [transformed, x_range, y_range, Lat2] = getTransformed(obj, live, options.transform_cropRsite);
            hold(obj.AxesHandle, "on")
            obj.AddonHandle = imagesc(obj.AxesHandle, y_range, x_range, transformed);
            obj.AddonHandle(2) = Lat2.plot(obj.AxesHandle, ...
                SiteGrid.prepareSite('Hex', 'latr', options.lattice_hexr), 'filter', false);
            obj.AddonHandle(3:4) = Lat2.plotV(obj.AxesHandle, 'scale', options.transform_scaleV, 'add_legend', false);
        end
        
        function plotPSF(obj, live, options)
            arguments
                obj
                live
                options.scale_V = obj.PlotPSF_ScaleV
            end
            try
                PS = live.PSFCalib.(obj.CameraName);
                centers = PS.DataLastStats.RefinedCentroid;
                radius = PS.DataLastStats.MaxRefinedWidth;
                hold(obj.AxesHandle, "on")
                obj.AddonHandle(1) = viscircles(obj.AxesHandle, centers, radius, 'LineWidth', 0.5);
                obj.AddonHandle(2) = PS.plot(obj.AxesHandle);
                obj.AddonHandle(3:5) = PS.plotV(obj.AxesHandle, 'scale', options.scale_V, 'add_legend', true);
            catch me
                obj.warn2("[%s %s] Can not find last PSF fitting data (error: %s). Please check if 'FitPSF' appears in SequenceTable.", ...
                    obj.CameraName, obj.ImageLabel, me.message)
            end
        end
        
        function plotOccupied(obj, live, options)
            arguments
                obj
                live
                options.plot_unoccup = obj.PlotOccupied_PlotUnoccup
                options.occup_color = obj.PlotOccupied_OccupColor
                options.unoccup_color = obj.PlotOccupied_UnoccupColor
                options.radius = obj.PlotOccupied_CircleRadius
            end
            Lat = getLatCalib(obj, live);
            num_frames = live.CameraManager.(obj.CameraName).Config.NumSubFrames;
            x_shift = (live.CameraManager.(obj.CameraName).Config.XPixels / num_frames) * (0: (num_frames - 1));
            args = namedargs2cell(options);
            if isfield(live.Temporary, obj.CameraName) && isfield(live.Temporary.(obj.CameraName), obj.ImageLabel) ...
                && isfield(live.Temporary.(obj.CameraName).(obj.ImageLabel), "SiteStat")
                stat = live.Temporary.(obj.CameraName).(obj.ImageLabel).SiteStat;
            else
                obj.warn2("[%s %s] Unable to find SiteStat in live data. Please check if 'ReconstructSites' and 'AnalyzeOccup' appears in SequenceTable.", ...
                    obj.CameraName, obj.ImageLabel)
                return
            end
            for j = 1: num_frames
                center = Lat.R + [x_shift(j), 0];
                sites_occupied = stat.SiteInfo.Sites(stat.LatOccup(:, j), :);                
                sites_unoccupied = stat.SiteInfo.Sites(~stat.LatOccup(:, j), :);
                h = Lat.plotOccup(obj.AxesHandle, ...
                                   sites_occupied, sites_unoccupied, ...
                                   'center', center, 'filter', false, args{:});
                obj.AddonHandle(end + 1 : end + length(h)) = h;
            end
        end

        function plotHopLoss(obj, live, options)
            arguments
                obj
                live
                options.hop_color = obj.PlotHopLoss_HopColor
                options.loss_color = obj.PlotHopLoss_LossColor
                options.good_color = obj.PlotHopLoss_GoodColor
                options.radius = obj.PlotHopLoss_CircleRadius
            end
            Lat = getLatCalib(obj, live);
            num_frames = live.CameraManager.(obj.CameraName).Config.NumSubFrames;
            x_shift = (live.CameraManager.(obj.CameraName).Config.XPixels / num_frames) * (0: (num_frames - 1));
            if isfield(live.Temporary, obj.CameraName) && isfield(live.Temporary.(obj.CameraName), obj.ImageLabel) ...
                && isfield(live.Temporary.(obj.CameraName).(obj.ImageLabel), "SiteStat")
                stat = live.Temporary.(obj.CameraName).(obj.ImageLabel).SiteStat;
            else
                obj.warn2("[%s %s] Unable to find SiteStat in live data. Please check if 'ReconstructSites' and 'AnalyzeOccup' appears in SequenceTable.", ...
                    obj.CameraName, obj.ImageLabel)
                return
            end
            for j = 1: (num_frames - 1)
                center = Lat.R + [x_shift(j), 0];
                sites11 = stat.SiteInfo.Sites(stat.LatOccup(:, j) & stat.LatOccup(:, j + 1), :);
                sites10 = stat.SiteInfo.Sites(~stat.LatOccup(:, j) & stat.LatOccup(:, j + 1), :);
                sites01 = stat.SiteInfo.Sites(stat.LatOccup(:, j) & ~stat.LatOccup(:, j + 1), :);
                h = [Lat.plot(obj.AxesHandle, sites11, 'center', center, 'diff_origin', false, ...
                              'norm_radius', options.radius, 'color', options.good_color), ...
                     Lat.plot(obj.AxesHandle, sites10, 'center', center, 'diff_origin', false, ...
                              'norm_radius', options.radius, 'color', options.loss_color), ...
                     Lat.plot(obj.AxesHandle, sites01, 'center', center, 'diff_origin', false, ...
                              'norm_radius', options.radius, 'color', options.hop_color)];
                obj.AddonHandle(end + 1 : end + length(h)) = h;
            end
            center = Lat.R + [x_shift(end), 0];
            sites = stat.SiteInfo.Sites(stat.LatOccup(:, end), :);
            h = Lat.plot(obj.AxesHandle, ...
                sites, 'center', center, 'diff_origin', false, ...
                'norm_radius', options.radius, 'color', options.good_color);
            obj.AddonHandle(end + 1 : end + length(h)) = h;
        end
    end

end

%% Other utilities functions

function Lat = getLatCalib(obj, Live)
    Lat = Live.LatCalib.(obj.CameraName);
end

function [transformed, x_range, y_range, Lat2] = getTransformed(obj, Live, cropRsite)
    data = Live.(obj.Content).(obj.CameraName).(obj.ImageLabel);
    num_frames = Live.CameraManager.(obj.CameraName).Config.NumSubFrames;
    signal = getSignalSum(data, num_frames, 'first_only', true);
    Lat = getLatCalib(obj, Live);
    [transformed, x_range, y_range, Lat2] = ...
        Lat.transformSignalStandardCropSite(signal, cropRsite);
end
