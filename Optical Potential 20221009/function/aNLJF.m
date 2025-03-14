function alpha = aNLJF(Mode,N,L,J,F,Wavelength,varargin)
    I = 7/2;
    switch Mode
        case 's'
            alpha = 1./sqrt(3*(2*J+1))*aNLJK(0,N,L,J,Wavelength,varargin{:});
        case 'v'
            alpha = (-1)^(J+I+F)*sqrt(2*F*(2*F+1)/(F+1))* ...
                wigner6j(F,1,F,J,I,J)*aNLJK(1,N,L,J,Wavelength,varargin{:});
        case 'T'
            alpha = -(-1)^(J+I+F)*sqrt(2*F*(2*F-1)*(2*F+1)/3/(F+1)/(2*F+3))* ...
                wigner6j(F,2,F,J,I,J)*aNLJK(2,N,L,J,Wavelength,varargin{:});
    end
end