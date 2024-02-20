function saveData(Data, Live, path)
    arguments
        Data
        Live = struct()
        path = pwd
    end
    uisave({'Data', 'Live'}, fullfile(path, 'Data'))
end