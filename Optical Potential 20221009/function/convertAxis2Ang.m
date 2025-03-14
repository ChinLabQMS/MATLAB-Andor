function [Theta,Phi,VecZ] = convertAxis2Ang(Axis)
    VecZ = Axis./vecnorm(Axis,2,2);
    Phi = acos(VecZ(:,3));
    GoodIndex = sin(Phi)~=0;
    Theta = zeros(length(Phi),1);
    Theta(GoodIndex) = acos(VecZ(GoodIndex,1)./sin(Phi(GoodIndex)));
    Phi = abs(Phi);
    Theta = abs(Theta);
end