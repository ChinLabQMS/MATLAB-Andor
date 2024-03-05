function Image = acquireImage(Acquisition, Handle)
    arguments
        Acquisition (1, 1) struct
        Handle (1, 1) struct = struct()
    end
    
    num_images = height(Acquisition.SequenceTable);
    Image = cell(1, num_images);
    for i = 1:num_images
        camera = char(Acquisition.SequenceTable.Camera(i));
        switch camera
            case {'Andor19330', 'Andor19331'}
                setCurrentAndor(camera, Handle);
                Image{i} = acquireAndorImage("timeout", Acquisition.Timeout);
            case 'Zelux'
                Image{i} = acquireZeluxImage(Handle.Zelux{:}, "timeout", Acquisition.Timeout);
        end
    end
end