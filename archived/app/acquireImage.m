function Image = acquireImage(Acquisition, Handle)
    arguments
        Acquisition (1, 1) struct
        Handle (1, 1) struct = struct()
    end
    
    num_images = height(Acquisition.SequenceTable);
    Image = cell(1, num_images);

    % Send "start acquisition" commands
    for i = 1:num_images
        camera = char(Acquisition.SequenceTable.Camera(i));
        switch camera
            case {'Andor19330', 'Andor19331'}
                freeAndorMemory(camera, Handle)
                acquireAndorImage("mode",1);
            case 'Zelux'
        end
    end

    % Acquire images
    for i = 1:num_images
        camera = char(Acquisition.SequenceTable.Camera(i));
        switch camera
            case {'Andor19330', 'Andor19331'}
                setCurrentAndor(camera, Handle,"verbose",false);
                Image{i} = acquireAndorImage("mode",2,"timeout",Acquisition.Timeout,"refresh",Acquisition.Pooling);
            case 'Zelux'
                Image{i} = acquireZeluxImage(Handle.Zelux{2}, "timeout",Acquisition.Timeout,"refresh",Acquisition.Pooling,"verbose",false);
        end
    end
end