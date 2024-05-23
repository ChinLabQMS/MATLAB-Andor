function [Signal, Offset] = subtractBackground(Image, Background, Setting)
    arguments
        Image
        Background
        Setting (1,1) struct
    end
    num_images = height(Setting.Acquisition.SequenceTable);

    Signal = cell(1, num_images);
    Offset = cell(1, num_images);
    for i = 1:num_images
        camera = char(Setting.Acquisition.SequenceTable.Camera(i));
        if strcmp(camera, 'Zelux')
            Signal{i} = double(Image{i});
            Offset{i} = zeros("like", Image{i});
        else
            num_frames = Setting.(camera).NumFrames;
            subtracted = double(Image{i}) - Background{i};
            offset = cancelOffset(subtracted,num_frames,'note',camera);
            
            Signal{i} = subtracted - offset;
            Offset{i} = offset;
        end
    end
end