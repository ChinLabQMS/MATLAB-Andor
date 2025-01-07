function fullpath = getFullPath(path, options)
arguments
    path
    options.check_exist = false
    options.format = "normal"
end
    cur_dir = pwd;
    fullpath = string(fullfile(cur_dir, path));
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
        case "no_backslash"
            fullpath = strrep(fullpath, "\", "\\");
        case "double"
            fullpath = strrep(fullpath, "\", "/");
    end
end
