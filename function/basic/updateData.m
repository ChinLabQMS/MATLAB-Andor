function Data = updateData(Data, Image, current)
    arguments
        Data
        Image
        current (1, 1) double
    end
    for i = 1:length(Data)
        shift = false;
        if current > Data{i}.Config.MaxImage
            shift = true;
        end

        names = Data{i}.Config.Acquisition;
        for j = 1:length(names)
            name = names{j};
            if shift
                Data{i}.(name) = circshift(Data{i}.(name), -1, 3);
                Data{i}.(name)(:, :, end) = Image{i}.(name);
            else
                Data{i}.(name)(:, :, current) = Image{i}.(name);
            end
        end
    end
end