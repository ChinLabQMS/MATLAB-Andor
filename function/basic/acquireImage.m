function Image = acquireImage(Setting, ZeluxHandle)
    arguments
        Setting (1, 1) struct
        ZeluxHandle = {}
    end

    num_cameras = length(Setting.ActiveCameras);
    Image = cell(1, num_cameras);
    for i = 1:num_cameras
        camera = Setting.ActiveCameras{i};
        names = Setting.(camera).Acquisition;
        Image{i} = struct();
        switch camera
            case {'Andor19330', 'Andor19331'}
                setCurrentAndor(camera)
                for j = 1:length(names)
                    name = names{j};
                    Image{i}.(name) = acquireAndorImage("timeout", Setting.Timeout);
                end
            case 'Zelux'
                for j = 1:length(names)
                    name = names{j};
                    Image{i}.(name) = acquireZeluxImage(ZeluxHandle{2}, "timeout", Setting.Timeout);
                end
        end
    end
end