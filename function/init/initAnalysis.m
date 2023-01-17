function [Data,Stat,Live] = initAnalysis(Data,DataInfo)
    
    Stat = struct();
    Live = struct();
    if ~strcmp(DataInfo.ModeCal,'None')
        Stat = initStat(DataInfo);
        if Mode.Fig
            Live = initLive(DataInfo,Stat,Mode.Center,Mode.Radius,Mode.Threshold);
        end
    end
    
    
end