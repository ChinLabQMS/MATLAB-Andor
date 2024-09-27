% Zelux lattice calibration script.

load('zeluxlatdata.mat');
Data = zeluxlatdata;

figure;
imagesc(zeluxlatdata)
daspect([1 1 1]);

%% use the function zeluxCalibLat
load('calibration/precalibration_zelux_20240926.mat');
%%
[Lat,PeakPos] = zeluxCalibLat(Data, Lattice, "RFFT", [510, 510]);
% going to need a pre-calibration
%%
% %% Overlay site positions with data to check lattice calibration
[Y, X] = meshgrid(-100:100, -100:100);
Y = Y(:);
X = X(:);
corr = [Y, X] * Lat.Zelux.V + Lat.Zelux.R;
signal = Data;
figure
imagesc(signal)
hold on
scatter(corr(:, 2), corr(:, 1),'r')
daspect([1 1 1])
colorbar

signal = zeluxlatdata(1:1080,:); % square crop it
FFT2 = abs(fftshift(fft2(signal)));

figure
imagesc((FFT2))
daspect([1 1 1])
colorbar
hold on
scatter(PeakPos(:,1),PeakPos(:,2))


%% getPreCalibration

function [Lat,PeakPos,RFFT,FFTPeakFit,MeanSum] = zeluxCalibLat(Data,Lattice,Options)
    arguments
        Data
        Lattice
        Options.RFFT = [500, 500]
    end
    
    % Calculate RFFT based on the ROI center position
    YPixels = size(Data,2);
    XSize=YPixels;
    Corner=[1,1;
        1,YPixels;
        XSize,1;
        XSize,YPixels];

    % RFFT = min(round(min(abs(Corner-Lat.R)))-12,[200 200]);
    Options.RFFT = [500 500];
    if any(Options.RFFT<0)
        error('Lattice center is too close to the image edge!')
    elseif any(Options.RFFT<5)
        warning('Lattice center is too close to the image edge! RFFT = %d',min(Options.RFFT))
    end

    % Print out old calibration results
    V1 = Lattice.Zelux.V(1,:);
    V2 = Lattice.Zelux.V(2,:);
    fprintf('\nOld lattice calibration:\n')
    fprintf('\tV1=(%4.2f, %4.2f),\t|V1|=%4.2fpx\n',V1(1),V1(2),norm(V1))
    fprintf('\tV2=(%4.2f, %4.2f),\t|V2|=%4.2fpx\n',V2(1),V2(2),norm(V2))
    fprintf('\tAngle=%4.2f deg\n\n',acosd(V1*V2'/(norm(V1)*norm(V2))))

    % Get calibration
    [Lat,FFTPeakFit,MeanSum,PeakPos] = getCalibration(Data,Options.RFFT,Lattice,'Full');

    % Print out new calibration results
    printCalibration(Lat)

end
%% getCalibration

function [Lat,FFTPeakFit,SignalSum,PeakPos] = getCalibration(Signal,RFFT,Lat,Mode,varargin)
    % Parameters
    LatChangeThreshold = 0.002;
    CalBkgMin = 20;
    CalBkgMax = 1000;
    RFit = 7;


    XSize = floor(size(Signal,1));
    SignalSum = Signal;
    [SignalBox,FFTX,FFTY] = prepareBox(SignalSum,round(Lat.Zelux.R),RFFT);

    if strcmp(Mode,'Full')
        PeakPosInit = (2*RFFT+1).*Lat.Zelux.K+RFFT+1;
        [PeakPos,FFTPeakFit] = signalFFT(SignalBox,PeakPosInit,RFit);
     
        Lat.Zelux.K = (PeakPos-RFFT-1)./(2*RFFT+1);
        Lat.Zelux.V = (inv(Lat.Zelux.K(1:2,:)))';

        VDis = vecnorm(Lat.Zelux.V'-Lat.Zelux.V')./vecnorm(Lat.Zelux.V');
        if any(VDis>LatChangeThreshold)
            warning('off','backtrace')
            warning('Lattice vector length changed significantly by %.2f%%.',...
                100*(max(VDis)))
            warning('on','backtrace')
            A = [confint(FFTPeakFit{1}{1},0.95);...
                confint(FFTPeakFit{2}{1},0.95);...
                confint(FFTPeakFit{3}{1},0.95)];
            A = (A([2,4,6],[5,6])-A([1,3,5],[5,6]));
            A = A./(vecnorm(Lat.K')'*(2*RFFT+1));
            if all(A<LatChangeThreshold)
                save(sprintf('NewLatCal_%s.mat',datestr(now,'yyyymmdd')),'Lat')
                fprintf('\nNew lattice calibration saved\n')
            end
        end
    else
        FFTPeakFit = cell(0);
    end
    
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

function [PeakPos,FFTPeakFit] = signalFFT(Data,PeakPosInit,RFit)
       
    PeakPos = PeakPosInit;
    FFTPeakFit = cell(1,3);
    
    FFT = abs(fftshift(fft2(Data)));    
    for i = 1:3       
        XC = round(PeakPosInit(i,1));
        YC = round(PeakPosInit(i,2));
        PeakX = XC+(-RFit(1):RFit(1));
        PeakY = YC+(-RFit(end):RFit(end));
        PeakData = FFT(PeakX,PeakY);
        
        % Fitting FFT peaks
        [PeakFit,GOF,X,Y,Z] = fit2DGaussian(PeakData,-RFit(1):RFit(1),-RFit(end):RFit(end)); 
        FFTPeakFit{i} = {PeakFit,[X,Y],Z,GOF};

        if GOF.rsquare<0.5
            PeakPos = PeakPosInit;
            warning('off','backtrace')
            warning('FFT peak fit might be off (rsquare=%.2f), not updating.',...
                GOF.rsquare)
            warning('on','backtrace')
            return
        else
            PeakPos(i,:) = [PeakFit.u0,PeakFit.v0]+[XC,YC];
        end
    end
end

%% printCalibration

function printCalibration(Lat)
    V1 = Lat.Zelux.V(1,:);
    V2 = Lat.Zelux.V(2,:);
    V3 = V1+V2;
    fprintf('\nNew lattice calibration:\n')
    fprintf('\tV1=(%4.2f, %4.2f),\t|V1|=%4.2fpx\n',V1(1),V1(2),norm(V1))
    fprintf('\tV2=(%4.2f, %4.2f),\t|V2|=%4.2fpx\n',V2(1),V2(2),norm(V2))
    fprintf('\tV3=(%4.2f, %4.2f),\t|V3|=%4.2fpx\n',V3(1),V3(2),norm(V3))
    fprintf('\tAngle<V1,V2>=%4.2f deg\n',acosd(V1*V2'/(norm(V1)*norm(V2))))
    fprintf('\tAngle<V1,V3>=%4.2f deg\n\n',acosd(V1*V3'/(norm(V1)*norm(V3))))
end
%% prepareBox

function [DataBox,DataX,DataY] = prepareBox(Data,RC,R)
    DataX = RC(1)+(-R(1):R(1));
    DataY = RC(2)+(-R(end):R(end));
%     disp(DataX);
%     disp(RC(1));
%     disp(R);
    DataBox = Data(DataX,DataY);

end

%% fit2DGaussian

function [Fit,GOF,X,Y,Z] = fit2DGaussian(Signal,varargin)
    [XSize,YSize] = size(Signal);

    switch nargin
        case 3
            XRange = varargin{1};
            YRange = varargin{2};
            XSize = XRange(end)-XRange(1);
            YSize = YRange(end)-YRange(1);
        case 2
            XRange = varargin{1};
            YRange = varargin{1};
            XSize = XRange(end)-XRange(1);
            YSize = XSize;
        case 1
            XRange = 1:XSize;
            YRange = 1:YSize;
        otherwise
            error("Wrong number of inputs")
    end

    [Y,X,Z] = prepareSurfaceData(YRange,XRange,Signal);
    Max = max(Signal(:))+1;
    Min = min(Signal(:))-1;
    Diff = Max-Min;

    % Define 2D Gaussian fit type
    PeakFT = fittype('a*exp(-0.5*((u-u0)^2/b^2+(v-v0)^2/c^2))+d',...
                    'independent',{'u','v'},...
                    'coefficient',{'a','b','c','d','u0','v0'});
    PeakFO = fitoptions(PeakFT);

    PeakFO.Upper = [5*Diff,XSize,YSize,Max,XRange(end),YRange(end)];
    PeakFO.Lower = [0,0,0,Min,XRange(1),YRange(1)];
    PeakFO.StartPoint = [Diff,XSize/10,YSize/10,Min, ...
        (XRange(1)+XRange(end))/2,(YRange(1)+YRange(end))/2];
    PeakFO.Display = "off";

    [Fit,GOF] = fit([X,Y],Z,PeakFT,PeakFO);
end