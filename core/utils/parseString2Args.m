% Parse the note to arguments (structure or cell)
function args = parseString2Args(note, options)
    arguments
        note (1, 1) string
        options.output_format (1, 1) string = "cell"
    end
    params = split(erase(note, " "), ",")';
    args = struct();
    for p = params
        if contains(p, "=")
            val = split(p, "=");
            if length(val) == 2
                args.(val(1)) = str2double(val(2));
            else
                error("Multiple '-' appears in the string.")
            end
        elseif p ~= ""
            args.(p) = true;
        end
    end
    if options.output_format == "struct"
        return
    elseif options.output_format == "cell"
        args = namedargs2cell(args);
    elseif options.output_format == "name-value"
        name = string(fields(args))';
        value = nan(1, length(name));
        for i = 1:length(name)
            value(i) = args.(name(i));
        end
        args = {name, value};
    else
        error("Unrecongnized output format.")
    end
end
