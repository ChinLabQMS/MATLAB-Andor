function fullpath = getFullPath(path, options)
arguments
    path
    options.check_exist = true
    options.format = "no_back_slash"
end
    fullpath = string(fullfile(pwd, path));
    if options.check_exist
        if exist(fullpath, 'file') ~= 2
           fullpath = string(path);
           if exist(fullpath, 'file') ~= 2
               error('File does not exist! File path: %s', path)
           end
        end
    end
    switch options.format
        case "normal"            
        case "double"
            fullpath = strrep(fullpath, "\", "\\");
        case "no_backslash"
            fullpath = strrep(fullpath, "\", "/");
    end
end
