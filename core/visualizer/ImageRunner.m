classdef ImageRunner < AxesRunner

    methods (Access = protected)
        function updateContent(obj, data, info)
            if isempty(obj.GraphHandle)
                obj.GraphHandle = imagesc(obj.AxesHandle, data);
                colorbar(obj.AxesHandle)
            else
                [x_size, y_size] = size(data);
                obj.GraphHandle.XData = [1, y_size];
                obj.GraphHandle.YData = [1, x_size];
                obj.GraphHandle.CData = data;
            end
            delete(obj.AddonHandle)
            switch obj.Config.FuncName
                case "None"
                case "Lattice"
                    Lat = info.LatCalib.(obj.Config.CameraName);
                    obj.AddonHandle = Lat.plot(obj.AxesHandle, Lattice.prepareSite("hex", "latr", 20), ...
                        'x_lim', [1, size(data, 1)], 'y_lim', [1, size(data, 2)]);
                case "Lattice All"
            end
        end
    end

end
