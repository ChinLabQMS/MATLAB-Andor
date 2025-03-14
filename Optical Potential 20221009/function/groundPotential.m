function [Static,EffB] = groundPotential(Mode,Beams,R)
    NumWave = length(Beams);
    NumPoint = size(R,1);
    
    Static = zeros(NumPoint,1);
    EffB = zeros(NumPoint,3);
    for i = 1:NumWave
        [Intensity,TotPol] = gaussianFull(Beams{i},R);
        Static = Static+aNLJ('s',6,0,1/2,Beams{i}.Wave,'Exp')*Intensity;
        EffB = EffB+aNLJ('v',6,0,1/2,Beams{i}.Wave,'ExpBFict')* ...
            1i*Intensity.*cross(conj(TotPol),TotPol,2);
    end
    
    
end