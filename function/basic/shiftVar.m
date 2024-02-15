function [Data, Live] = shiftVar(Data, Live)
    if isfield(Data, 'Image')
        Data.Image = circshift(Data.Image,-1,3);
    end
    if isfield(Data, 'Background')
        Data.Background = circshift(Data.Background,-1,3);
    end

    Stat.LatOffset = circshift(Stat.LatOffset,-1,1);
    Stat.LatCount = circshift(Stat.LatCount,-1,3);
end