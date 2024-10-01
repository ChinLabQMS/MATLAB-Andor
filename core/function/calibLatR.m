function calibLatR()
% Extract lattice center coordinates from phase at FFT peak
    [Y,X] = meshgrid(FFTY,FFTX);
    Phase = zeros(1,2);
    SignalModified = double(SignalBox);
    SignalModified(SignalBox<CalBkgMin | SignalBox>CalBkgMax) = 0;
    for i = 1:2
        PhaseMask = exp(-1i*2*pi*(Lat.Zelux.K(i,1)*X+Lat.Zelux.K(i,2)*Y));
        Phase(i) = angle(sum(PhaseMask.*SignalModified,'all'));
    end
    Lat.Zelux.R = (round(Lat.Zelux.R*Lat.Zelux.K(1:2,:)'+Phase/(2*pi))-1/(2*pi)*Phase)*Lat.Zelux.V;

end
