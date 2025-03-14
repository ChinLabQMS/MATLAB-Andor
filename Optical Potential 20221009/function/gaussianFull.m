function [Intensity,TotPol,Pol,Dir,E] = gaussianFull(Beam,R)
    NumBeam = length(Beam.Power);
    NumPoint = size(R,1);
    E = zeros(NumPoint,3);
    Pol = zeros(NumBeam,3);
    Dir = zeros(NumBeam,3);
    for i = 1:NumBeam
        AngTheta = Beam.Ang(i,1)*pi/180;
        AngPhi = Beam.Ang(i,2)*pi/180;
        PolTheta = Beam.Pol(i,1)*pi/180;
        PolPhi = Beam.Pol(i,2)*pi/180;
        Power = Beam.Power(i);
        Waist = Beam.Waist(i,:);
        Wave = Beam.Wave;
        Phase = Beam.Phase(i);
        M = [cos(AngTheta)*cos(AngPhi),-sin(AngTheta),cos(AngTheta)*sin(AngPhi);
            sin(AngTheta)*cos(AngPhi),cos(AngTheta),sin(AngTheta)*sin(AngPhi);
            -sin(AngPhi),0,cos(AngPhi)];
        RNew = R*M;
        Pol(i,:) = [cos(PolTheta),sin(PolTheta)*exp(1i*(PolPhi)),0]*M';
        Dir(i,:) = [0,0,1]*M';
        E = E+exp(1i*Phase)*gaussianSingle(Power,Waist,Wave,RNew(:,1),RNew(:,2),RNew(:,3))*Pol(i,:);
    end
    c = 2.99792458*10^8;
    epsilon0 = 8.854187817*10^-12;
    ENorm = vecnorm(abs(E),2,2);
    Intensity = 1/2*c*epsilon0*ENorm.^2;
    TotPol = E./ENorm;
end