function Data = updateData(Data, Image, current)
    arguments
        Data
        Image
        current (1, 1) double
    end
    
    num_images = height(Data.SequenceTable);
    for i = 1:num_images
        camera = char(Data.SequenceTable.Camera(i));
        label = Data.SequenceTable.Label{i};
        
        if current > Data.(camera).Config.MaxImage
            Data.(camera).(label) = circshift(Data.(camera).(label), -1, 3);
            Data.(camera).(label)(:,:,end) = Image{i};
        else
            Data.(camera).(label)(:,:,current) = Image{i};
        end
    end
end