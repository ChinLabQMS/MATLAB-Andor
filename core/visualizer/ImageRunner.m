classdef ImageRunner < AxesRunner

    methods (Access = protected)
        function updateContent(obj, Live)
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
            delete(obj.AddonHandle)
            switch obj.Config.FuncName
                case "None"
                case "Lattice"
                    Lat = Live.LatCalib.(obj.Config.CameraName);
                    obj.AddonHandle = Lat.plot(obj.AxesHandle, ...
                        Lattice.prepareSite("hex", "latr", 20), ...
                        'x_lim', [1, x_size], 'y_lim', [1, y_size]);
                case "Lattice All"
                    Lat = Live.LatCalib.(obj.Config.CameraName);
                    num_frames = getNumFrames(Live.CameraManager.(obj.Config.CameraName).Config);
                    obj.AddonHandle = gobjects(num_frames, 1);
                    for i = 1: num_frames
                        obj.AddonHandle(i) = Lat.plot(obj.AxesHandle, ...
                            Lattice.prepareSite("hex", "latr", 20), ...
                            'center', Lat.R + [x_size / num_frames * (i - 1), 0], ...
                            'x_lim', [1, x_size], 'y_lim', [1, y_size]);
                    end
                case "PSF"
                    
            end
        end
    end

end
