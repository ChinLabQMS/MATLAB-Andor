function alpha = aNLJ(Mode,N,L,J,Wavelength,varargin)
    switch Mode
        case 's'
            alpha = 1./sqrt(3*(2*J+1))*aNLJK(0,N,L,J,Wavelength,varargin{:});
        case 'v'
            if nargin == 6 && strcmp(varargin{1},'ExpBFict')
                % alpha*Intensity*polarization_vector = effective field in G
                
                muB = 9.27400899e-24;
                S = 1/2;
                gS = 2;
                gL = 1;
                gJ = gL*(J*(J+1)+L*(L+1)-S*(S+1))/(2*J*(J+1))+gS*(J*(J+1)+S*(S+1)-L*(L+1))/(2*J*(J+1));
                alpha = -sqrt(2*J/(J+1)/(2*J+1))*aNLJK(1,N,L,J,Wavelength,'Exp')/(2*muB*gJ*J)*1e4;
            else               
                alpha = -sqrt(2*J/(J+1)/(2*J+1))*aNLJK(1,N,L,J,Wavelength,varargin{:});
            end
        case 'T'
            alpha = -sqrt(2*J*(2*J-1)/3/(J+1)/(2*J+1)/(2*J+3))*aNLJK(2,N,L,J,Wavelength,varargin{:});
    end
end