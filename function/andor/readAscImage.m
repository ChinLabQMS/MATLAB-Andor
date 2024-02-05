function image = readAscImage(path, file)
    image = readmatrix(fullfile(path, file), "FileType","text");
    image = flip(transpose(image(:, 2:end)));    
end