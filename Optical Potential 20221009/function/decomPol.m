function [PolCir,PolReg] = decomPol(Pol,Axis)
% PolCir = [p0,p+,p-]
% PolReg = [px,py,pz/p0]
    if ~isreal(Axis)
        error('Axis coodinates have complex component!')
    end
    [Theta,Phi,VecZ] = convertAxis2Ang(Axis);
    VecX = [cos(Theta)*cos(Phi),sin(Theta)*cos(Phi),-sin(Phi)]';
    VecY = [-sin(Theta),cos(Theta),0]';
    PolReg = Pol*[VecX,VecY,VecZ'];
    PolCir = Pol*[VecZ',(VecX+1i*VecY)/sqrt(2),(VecX-1i*VecY)/sqrt(2)];
end

