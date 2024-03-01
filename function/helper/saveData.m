function saveData(Data, Live, options)
    arguments
        Data
        Live = struct()
        options.path = pwd
        options.note = ''
        options.verbose = true
    end

    if isempty(Data)
        if options.verbose
            warning('No Data to save!')
        end
        return
    end
    uisave({'Data', 'Live'}, fullfile(options.path, sprintf('Data_%s', note)))
end