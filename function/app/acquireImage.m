function Image = acquireImage(Acquisition, ZeluxHandle)
    arguments
        Acquisition (1, 1) struct
        ZeluxHandle = {}
    end
    
    num_images = height(Acqusition.SequenceTable);
    Image = cell(1, num_images);
    for i = 1:num_images
        camera = char(Acquisition.SequenceTable.Camera(i));
        switch camera
            case {'Andor19330', 'Andor19331'}
                setCurrentAndor(camera)
                Image{i} = acquireAndorImage("timeout", Acquisition.Timeout);
            case 'Zelux'
                Image{i} = acquireZeluxImage(ZeluxHandle{2}, "timeout", Acquisition.Timeout);
        end
    end
end