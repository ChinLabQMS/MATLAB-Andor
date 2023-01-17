function [Data,Stat] = runAnalysis(Mode)
% Data: The raw data
% Stat: Analysis
   
    switch Mode.Dat
        case {'Data','DMD Test'}
            if strcmp(Mode.Dat,'DMD Test')
                initCCD('Live 1 Cropped',Mode.CCD,Mode.Exp)
            end                       

        case {'Live 1','Live 2','Live 4','Live 8','Live 1 Cropped'}

            % In live imaging mode
            initCCD(Mode.Dat,Mode.CCD,Mode.Exp)
                       
            
    end
end