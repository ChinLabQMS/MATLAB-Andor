function alpha = aNLJK(K,N,L,J,Wavelength,varargin)
% Wavelength in um

    e = 1.602176634e-19;
    a0 = 0.5291772083e-10;
    h = 6.62606876e-34;
    c = 2.99792458e8;
    me = 9.10938188e-31;
    epsilon0 = 8.854187817e-12;

    Photon = 1./Wavelength*10^6;
    
    load('linedata\CsLineData.mat','LineData')
    Transition = LineData(LineData.N0==N & LineData.L0==L & LineData.J0==J,:);
    NumState = size(Transition,1);
    Jpw6j = w6j(K,J);
    alpha0 = 0;
    for i = 1:NumState
        Jp = Transition.J(i);
        TransEnergy = Transition.Energy(i);
        DipElm = Transition.DipElm(i);
        Linewidth = Transition.Linewidth(i)/c;
        alpha0 = alpha0+(-1)^(K+J+1)*sqrt(2*K+1)*(-1)^Jp*Jpw6j(Jp+1/2)*abs(DipElm)^2 ...
        *real(1./(TransEnergy-Photon-1i*Linewidth/2)+(-1)^K./(TransEnergy+Photon+1i*Linewidth/2));
    end
    
    % Convert to SI unit (default)
    % The potential is alpha*|E|^2/4;
    alpha = e^2*a0^2/(h*c)*alpha0;
    
    % Convert to a.u.
    if nargin>5 
        switch varargin{1}
            case 'AU'
                au = e^2*a0^2/(me*e^4/((2*epsilon0*h)^2));
                alpha = alpha/au;
            case 'Exp'
                % The potential is alpha*Intensity in SI unit
                alpha = alpha/(2*c*epsilon0);
            case 'ExpuK'
                % The potential is alpha*Intensity in kB*uK
                kB = 1.3806503e-23;
                alpha = alpha/(2*c*epsilon0*kB)*1e6;
            case 'ExpHz'
                % The potential is alpha*Intensity in h*Hz
                alpha = alpha/(2*c*epsilon0*h);
            case 'ExpRec'
                % The potential is alpha*Intensity in ERecoil
                if nargin == 6
                    Lambda = 0.852e-6;
                else
                    Lambda = varargin{2}*1e-6;
                end
                mCs = 2.20694650e-25;
                ERec = h^2/(2*mCs*Lambda^2);
                alpha = alpha/(2*c*epsilon0*ERec);
        end
    end
end

function Jpw6j = w6j(K,J)
    Jpw6j = zeros(1,3);
    for Jp = 0.5:2.5
        Jpw6j(Jp+1/2) = wigner6j(1,K,1,J,Jp,J);
    end
end