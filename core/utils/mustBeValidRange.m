% Input argument validation
function mustBeValidRange(signal, dim, range)
    if size(signal, dim) ~= length(range)
        error("Range does not match signal dimension.")
    end
end
