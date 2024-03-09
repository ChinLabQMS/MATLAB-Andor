function image = readAscImage(path, file)
    image = readmatrix(fullfile(path, file), "FileType","text");
    image = uint16(flip(transpose(image(:, 2:end))));
end