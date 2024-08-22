
% Generates lattice site structure and lattice-resolved count information

function [Stat,Threshold,TwoFit,Site,NumSite,Lat,MeanSum,BgOffset] = getStatFull_live(data,Bg,xc,yc,SubImg,numFK,hexrad,Options)
    arguments
        data (1024, 1024) double
        Bg (1024, 1024) double
        xc (1,1) {mustBeNumeric}
        yc (1,1) {mustBeNumeric}
        SubImg
        numFK
        hexrad

        % Options for loading calibration
        Options.LatMode = "Lower"

        % Options for PSF width for deconvolution kernel generation
        Options.Sigma = 1.86;

        % Options for setting thresholds automatically
        Options.ThresholdMode (1,:) double = 0
        Options.MaxIgnore (1,1) int16 = 1
        Options.AbsMax (1,1) double = 10000
        Options.AbsMin (1,1) double = -300
        Options.ThresholdMin (1,1) double = 200
        Options.ThresholdMax (1,1) double = 4200

        % Options for showing graphics
        Options.ShowMeanSig (1,1) logical = false
        Options.ShowFFTPeak (1,1) logical = false
        Options.ShowUpdate (1,1) logical = false
    end

    tic

    BgCenter = [50,20];
    BgR = 2;
    
    % Gaussian + Lorentzian parameters  a*exp(-(x-b)^2/(2*c^2))+d/((x-b)^2+e^2)
    funca=112;
    funcb=0;
    funcc=1.608;
    funcd=197.4;
    funce=4.015;
    funcPSF = @(x,y) (funca*exp(-(x.^2+y.^2)/(2*funcc^2))+funcd./((x.^2+y.^2)+funce^2))/(funca*2*pi*funcc+funcd*pi^2/funce);

    %funcPSF = @(x,y) exp(-0.5*(x.^2+y.^2)/Options.Sigma^2)/(2*pi*Options.Sigma^2);
    %funcPSF = @(x,y) 0.03;
    %funcPSF = @(x,y) exp(-0.5*(x.^2+y.^2)/Options.Sigma^2)/(sqrt(2*pi*Options.Sigma^2));


    % Initialize
    switch numFK
        case 1
             Lat = loadCalibration(Options.LatMode,[yc,xc]);
            %Stat.LatFormat = {'Rectangular',-10:10,-10:10};
            Stat.LatFormat= {'Hexagon',hexrad};
            %Stat.LatFormat={'Ring',ringrad}
        case {2,4}
            Lat = loadCalibration(Options.LatMode,[yc,xc]);
            %Stat.LatFormat = {'Rectangular',-10:10,-10:10};
            Stat.LatFormat= {'Hexagon',hexrad};
            %Stat.LatFormat={'Ring',ringrad}
        case 8
            Lat = loadCalibration(Options.LatMode,[60,540]);
            Stat.LatFormat = {'Rectangular',-4:4,-8:8};
    end
    
    [Site,NumSite] = prepareSite(Stat.LatFormat);
    [~,YPixels,NumSave] = size(data);
    XSize=YPixels/numFK;
    
    % Get pre-calibration with averaged data
    [Lat,BgOffset,RFFT,FFTPeakFit,MeanSum] = getPreCalibration(data,Bg,Lat,numFK);
    RFFT=[100 100];
    if Options.ShowMeanSig
        figure(Units="normalized",OuterPosition=[0.1,0.1,0.6,0.8],Name="Mean signal")
        imagesc(MeanSum)
        checkCalibration(Lat,Site,acquireMarkerSize,'w')
        daspect([1 1 1])
        colorbar
    end
    if Options.ShowFFTPeak
        showFFTPeakFit(FFTPeakFit)
    end

    % Get deconvolution pattern for background counts
    BgCSite = round((BgCenter-Lat.R)/Lat.V);
    [BgSite,NumBg] = prepareSite({'Rectangular',BgCSite(1)+(-BgR:BgR),BgCSite(2)+(-BgR:BgR)});
    BgDeconv = getDeconv(Lat,funcPSF,BgSite,XSize,YPixels);
%     assignin("base","BgDeconv",BgDeconv)

    % Perform analysis on each image
    if Options.ShowUpdate
        FigMain = figure(Units="normalized", ...
            Name="Signal images",OuterPosition=[0,0,1,1]);
    end
    LatNew = Lat;
    Stat.LatCount = zeros(NumSite,numFK,NumSave);
    Stat.LatOffset = nan(NumSave,2);
    Stat.BgCount = zeros(NumBg,numFK,NumSave);

    % for i = 1:NumSave
    %     % Get background-subtracted image
    %     Signal = double(Data.Andor19330.Image(:,:,i))-MeanBg-BgOffset;
    % 
    %     % Get new offset calibration
    %     LatNew = getCalibration(Signal,RFFT,LatNew,'Full',numFK);
    %     Stat.LatOffset(i,:) = LatNew.R;
    % 
    %     % Get deconvolution pattern for the new offset
    %     Deconv = getDeconv(LatNew,funcPSF,Site,XSize,YPixels);
    % 
    %     % Get lattice site counts for each site
    %     Stat.LatCount(:,:,i) = getCount(Signal,Data.Andor19330.SubImg,Deconv);
    %     Stat.BgCount(:,:,i) = getCount(Signal,Data.Andor19330.SubImg,BgDeconv);
    % 
    %     if Options.ShowUpdate
    %         figure(FigMain)
    %         showUpdate(Signal,Stat.LatCount(:,:,i),Site,LatNew)
    %         sgtitle(sprintf('Image %d/%d',i,NumSave))
    %         drawnow
    %     end
    % end

    % Get background-subtracted image
    Signal = data;

    % Get new offset calibration
    LatNew = getCalibration(Signal,RFFT,LatNew,'Full',numFK);
    Stat.LatOffset(:) = LatNew.R;
    % Stat.LatOffset(i,:) = LatNew.R;

    % Get deconvolution pattern for the new offset
    Deconv = getDeconv(LatNew,funcPSF,Site,XSize,YPixels);

    % Get lattice site counts for each site
    Stat.LatCount(:,:) = getCount(Signal,SubImg,Deconv);
    Stat.BgCount(:,:) = getCount(Signal,SubImg,BgDeconv);
    % Stat.LatCount(:,:,i) = getCount(Signal,Data.Andor19330.SubImg,Deconv);
    % Stat.BgCount(:,:,i) = getCount(Signal,Data.Andor19330.SubImg,BgDeconv);

    % if Options.ShowUpdate
    %     figure(FigMain)
    %     showUpdate(Signal,Stat.LatCount(:,:,i),Site,LatNew)
    %     sgtitle(sprintf('Image %d/%d',i,NumSave))
    %     drawnow
    % end

    % Find threshold value. Pass all settings
    [Threshold,TwoFit] = findThreshold(Stat.LatCount, ...
        ThresholdMode=Options.ThresholdMode,...
        MaxIgnore=Options.MaxIgnore, ...
        AbsMax=Options.AbsMax,...
        AbsMin=Options.AbsMin,...
        ThresholdMin=Options.ThresholdMin,...
        ThresholdMax=Options.ThresholdMax);
    Threshold=[];
    for ii=1:numFK
        [Threshold(ii), fidelity(ii), filling(ii)] = getThreshold(Stat.LatCount(:,ii,:));
    end
    
    % Calculate lattice occupation matrix
    [Stat.LatOccup,Stat.LatUnoccup,Stat.LatLost,Stat.LatNew,Stat.LatDiff] ...
        = getLatOccup(Stat.LatCount,Threshold);

    toc

    fprintf('Threshold:')
    fprintf('%6.1f',Threshold)
    fprintf('\nFinished getting Stat from Data!\n\n')
end

function showUpdate(Signal,Count,Site,Lat)
    % Parameters
    XR = 100;
    YR = 100;

    XPixels = size(Signal,1);
    NumSubImg = size(Count,2);
    MarkerSize = acquireMarkerSize;

    XRange = round(Lat.R(1))+(-XR:XR);
    YRange = round(Lat.R(2))+(-YR:YR);

    switch NumSubImg
        case {1,2}
            DimX = NumSubImg;
            DimY = 1;
        case {4,8}
            DimX = NumSubImg/2;
            DimY = 2;
    end

    for i = 1:NumSubImg
        XRangeBox = XRange+(i-1)*(floor(XPixels/NumSubImg));
        LatNew = Lat;
        LatNew.R = Lat.R+[(i-1)*(floor(XPixels/NumSubImg)),0];

        subplot(DimX,DimY,i)
        imagesc(YRange,XRangeBox,Signal(XRangeBox,YRange))
        checkCalibration(LatNew,Site,MarkerSize,'w')
        title(sprintf('Image %d',i))
        daspect([1 1 1])
        colorbar
    end
end

%%  loadCalibration

function Lat = loadCalibration(Mode,varargin)
    switch Mode
        case 'Upper'
%             load('LatUpperCCD_20210614.mat','Lat')
            load("Lat_CCD19330_20230216_Atoms","Lat")
        case 'Lower'
            load('precalibration_lowerccd_20240522.mat','Lat')
    end
    
    if nargin>1
        Lat.R = varargin{1};
    end
end
%% prepareSite

function [Site,NumSite] = prepareSite(LatFormat)
    switch LatFormat{1}
        case 'Rectangular'
            % Format: {[X1,X2,...,XEnd]},{[Y1,Y2,...,YEnd]}
            [Y,X] = meshgrid(LatFormat{3},LatFormat{2});
            Site = [X(:),Y(:)];
            NumSite = length(LatFormat{2})*length(LatFormat{3});
        case 'MultipleRectangular'
            % Format: {[X11,...,X1End;X21,...,X2End;,,,]},{Y}
        case 'MaskedRectangular'
            % Format: {[X1,X2,...,XEnd]},{[Y1,Y2,...,YEnd]},{[1,0,1,...,1]}
        case 'Square'
            % WIP
        case 'Hexagon'
            r=LatFormat{2};
            siteSum=1;
            for i=1:r
                siteSum = siteSum+6*i;
            end
            
            x=-r:r;
            [a, b]=meshgrid(x,x);
            Site=[a(:),b(:)];
            
            % Generating hexagon coordinates in lattice space
            for i=0:(r-1)
                for j=1:(r-i)
                    % disp([r-i, -(r-j+1)])
                    % disp([-(r-i), r-j+1])
                    if ismember([r-i, -(r-j+1)],Site,"rows")==true || ismember([-(r-i), r-j+1],Site,"rows")==true
                        [a,b]=ismember([r-i, -(r-j+1)],Site,"rows");
                        Site(b,:)=[];
                        [c,d]=ismember([-(r-i), r-j+1],Site,"rows");
                        Site(d,:)=[];
                        
                    end
                end
            end
            NumSite=numel(Site)/2;
            

        
    end
end

%% getPreCalibration

function [Lat,BgOffset,RFFT,FFTPeakFit,MeanSum] = getPreCalibration(data,Bg,Lat,numFK)

    BgOffset = cancelOffset(data,numFK);
    
    % Calculate RFFT based on the ROI center position
    YPixels = size(Bg,2);
    % YPixels = size(Bg.Data.Andor19330.Image,2);
    XSize=YPixels/numFK;
    Corner=[1,1;
        1,YPixels;
        XSize,1;
        XSize,YPixels];

    % RFFT = min(round(min(abs(Corner-Lat.R)))-12,[200 200]);
    RFFT = [100 100];
    if any(RFFT<0)
        error('Lattice center is too close to the image edge!')
    elseif any(RFFT<5)
        warning('Lattice center is too close to the image edge! RFFT = %d',min(RFFT))
    end

    % Print out old calibration results
    V1 = Lat.V(1,:);
    V2 = Lat.V(2,:);
    fprintf('\nOld lattice calibration:\n')
    fprintf('\tV1=(%4.2f, %4.2f),\t|V1|=%4.2fpx\n',V1(1),V1(2),norm(V1))
    fprintf('\tV2=(%4.2f, %4.2f),\t|V2|=%4.2fpx\n',V2(1),V2(2),norm(V2))
    fprintf('\tAngle=%4.2f deg\n\n',acosd(V1*V2'/(norm(V1)*norm(V2))))

    % Get calibration
    [Lat,FFTPeakFit,MeanSum] = getCalibration(data,RFFT,Lat,'Full',numFK);
    % [Lat,FFTPeakFit,MeanSum] = getCalibration(Data.Andor19330.Image(:,:,1),RFFT,Lat,'Full',numFK);

    % Print out new calibration results
    printCalibration(Lat)

end
%% getCalibration

function [Lat,FFTPeakFit,SignalSum] = getCalibration(Signal,RFFT,Lat,Mode,varargin)
    % Parameters
    LatChangeThreshold = 0.002;
    CalBkgMin = 20;
    CalBkgMax = 1000;
    RFit = 7;
    % NumSubImg = 1;
    
    if nargin>4
        numFK = varargin{1};
        CalBkgMin = CalBkgMin*sqrt(numFK);
        CalBkgMax = CalBkgMax*numFK;
    end

    XSize = floor(size(Signal,1)/numFK);
    SignalSum = zeros(XSize,size(Signal,2));
    for i = 1:numFK
        SignalSum = SignalSum+double(Signal((i-1)*XSize+(1:XSize),:));
    end
    [SignalBox,FFTX,FFTY] = prepareBox(SignalSum,round(Lat.R),RFFT);

    if strcmp(Mode,'Full')
        PeakPosInit = (2*RFFT+1).*Lat.K+RFFT+1;
        [PeakPos,FFTPeakFit] = signalFFT(SignalBox,PeakPosInit,RFit);
        
        Lat.K = (PeakPos-RFFT-1)./(2*RFFT+1);
        Lat.V = (inv(Lat.K(1:2,:)))';

        VDis = vecnorm(Lat.V'-Lat.V')./vecnorm(Lat.V');
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
    SignalModified = SignalBox;
    SignalModified(SignalBox<CalBkgMin | SignalBox>CalBkgMax) = 0;
    for i = 1:2
        PhaseMask = exp(-1i*2*pi*(Lat.K(i,1)*X+Lat.K(i,2)*Y));
        Phase(i) = angle(sum(PhaseMask.*SignalModified,'all'));
    end
    Lat.R = (round(Lat.R*Lat.K(1:2,:)'+Phase/(2*pi))-1/(2*pi)*Phase)*Lat.V;
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
    V1 = Lat.V(1,:);
    V2 = Lat.V(2,:);
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
%% getDeconv

function  [Deconv,DecPat] = getDeconv(Lat,funcPSF,Site,XLim,YLim)
    
    % Default deconvolution parameters
    PSFR = 10;
    RPattern = 30;
    Factor = 5;
    LatRLim = 2;
    RDeconv = 15;
    Threshold = 0.01;
    
    % Initialize
    NumSite = size(Site,1);
    Deconv = cell(NumSite,3);
    
    % Get the deconvolution pattern
    DecPat = matDeconv(Lat,funcPSF,PSFR,RPattern,Factor,LatRLim);
    %DecPat = ones(size(DecPat));
    %DecPat = DecPat/sum(DecPat,"all");
    
    % For each lattice site, find corresponding pixels and weights
    for i = 1:NumSite

        % Convert lattice X-Y index to CCD space coordinates
        Center = Site(i,:)*Lat.V+Lat.R;
        
        % Find X and Y range of pixels
        CX = round(Center(1));
        CY = round(Center(2));

        XMin = max(CX-RDeconv,1);
        XMax = min(CX+RDeconv,XLim);
        YMin = max(CY-RDeconv,1);
        YMax = min(CY+RDeconv,YLim);
        
        % Generate a list of pixel coordinates
        [Y,X] = meshgrid(YMin:YMax,XMin:XMax);
        XList = X(:);
        YList = Y(:);
        
        % Find the distance to site center
        XDis = XList-Center(1);
        YDis = YList-Center(2);
       
        % Find the cooresponding index in the deconvolution pattern
        XDeconv = round(Factor*(XDis+RPattern))+1;
        YDeconv = round(Factor*(YDis+RPattern))+1;
        XYDeconv = XDeconv+(YDeconv-1)*(2*Factor*RPattern+1);
        
        % Assign weights
        WeightList = DecPat(XYDeconv);
        Index = abs(WeightList)>Threshold;     
        Deconv{i,1} = XList(Index);
        Deconv{i,2} = YList(Index);
        Deconv{i,3} = WeightList(Index);
    end
    
end

function Pattern = matDeconv(Lat,funcPSF,PSFR,RPattern,Factor,LatRLim)
% Calculate deconvolution pattern by inverting (-LatRLim:LatRLim) PSF

    % Number of sites
    NumSite = (2*LatRLim+1)^2;

    % Number of pixels
    NumPx = (2*Factor*RPattern+1)^2;

    M = zeros(NumSite,NumPx);
    if funcPSF(PSFR,PSFR)>0.001
        warning(['Probability density at edge is significant = %.4f\nCheck' ...
            ' PSFR (radius for calculating PSF spread)'],funcPSF(PSFR,PSFR))
    end
    
    % For each lattice site, find its spread into nearby pixels
    for i = -LatRLim:LatRLim
        for j = -LatRLim:LatRLim
            
            % Site index
            Site = (i+LatRLim+1)+(j+LatRLim)*(2*LatRLim+1);

            % Lattice site coordinate
            Center = [i,j]*Lat.V;

            % Convert coordinate to magnified pixel index
            CXIndex = round(Factor*(Center(1)+RPattern))+1;
            CYIndex = round(Factor*(Center(2)+RPattern))+1;

            % Range of pixel index to run through
            xMin = CXIndex-PSFR*Factor;
            xMax = CXIndex+PSFR*Factor;
            yMin = CYIndex-PSFR*Factor;
            yMax = CYIndex+PSFR*Factor;

            % Go through all pixels and assign the spread
            x = xMin:xMax;
            y = yMin:yMax;
            Pixel = x'+(y-1)*(2*Factor*RPattern+1);
            [YP,XP] = meshgrid((y-1)/Factor-RPattern,(x-1)/Factor-RPattern);
            M(Site,Pixel) = funcPSF(XP(:)-Center(1),YP(:)-Center(2))/Factor^2;
            
        end
    end

    % Convert transfer matrix to deconvolution pattern
    MInv = (M*M')\M;
    Pattern = reshape(MInv(round(NumSite/2),:),sqrt(NumPx),[]);

    % Re-normalize deconvolution pattern
    Area = abs(det(Lat.V));
    %disp(Area);
    Pattern = Area/(sum(Pattern,"all")/Factor^2)*Pattern;
    %Pattern= Pattern/sum(Pattern,"all");
end

%% cancelOffset

function [BgOffset,STD] = cancelOffset(Signal,numFK,Name)
    arguments
        Signal
        numFK
        Name.YBgSize (1,1) double = 100
    end

    % NumSubImg = size(SubImg,1);
    [XPixels,YPixels] = size(Signal);
    XSize=YPixels/numFK;

    BgOffset = zeros(XPixels,YPixels);
    STD = zeros(numFK,2);

    if YPixels<2*Name.YBgSize+200
        warning('Not enough space to cancel background offset!')
        return
    end

    YRange1 = 1:Name.YBgSize;
    YRange2 = YPixels+((1-Name.YBgSize):0);
    for i = 1:numFK
        % XRange = SubImg(i,1):SubImg(i,2);
        XRange = 1+(i-1)*XSize:XSize+(i-1)*XSize;
        BgBox1 = Signal(XRange,YRange1);
        BgBox2 = Signal(XRange,YRange2);
        [XOut1,YOut1,ZOut1] = prepareSurfaceData(XRange,YRange1',BgBox1');
        [XOut2,YOut2,ZOut2] = prepareSurfaceData(XRange,YRange2',BgBox2');
        XOut = [XOut1;XOut2];
        YOut = [YOut1;YOut2];
        ZOut = [ZOut1;ZOut2];
        try
        XYFit = fit([XOut,YOut],ZOut,'poly11');
        catch
            assignin("caller","XOut",XOut)
            assignin("caller","YOut",YOut)
            assignin("caller","ZOut",ZOut)
            assignin("caller","XRange",XRange)
            assignin("caller","YRange1",YRange1)
            assignin("caller","YRange2",YRange2)
            assignin("caller","BgBox1",BgBox1)
            assignin("caller","BgBox2",BgBox2)
        end
        
        % Background offset canceling with fitted plane
        BgOffset(XRange,:) = XYFit.p00+XYFit.p10*XRange'+XYFit.p01*(1:YPixels);

        BgBoxNew1 = BgBox1-BgOffset(XRange,YRange1);
        BgBoxNew2 = BgBox2-BgOffset(XRange,YRange2);
        STD(i,:) = [std(BgBoxNew1(:)),std(BgBoxNew2(:))];
    end
    
    warning('off','backtrace')
    if any(BgOffset>2)
        warning('Noticable background offset: %4.2f',max(BgOffset(:)))
    end
    if any(STD>6)
        %warning('Noticable background noise: %4.2f',max(STD))
    end
    warning('on','backtrace')
end

%% getCount
function Count = getCount(Signal,XStart,Deconv)
    XPixels = size(Signal,1);
    NumSite = size(Deconv,1);
    NumSubImg = size(XStart,1);
    Count = zeros(NumSite,NumSubImg);

    for i = 1:NumSite
        List = Deconv{i,1}+XPixels*(Deconv{i,2}-1);
        if size(List,1)>0
            for j = 1:NumSubImg
                Count(i,j) = Deconv{i,3}'*Signal(List+XStart(j)-1); %only
                %line in original code
%                 Count(i,j) = ones(size(Deconv{i,3}'))*Signal(List+XStart(j)-1);
            end
        end
    end
end

%% findThreshold

function [Threshold,TwoFit] = findThreshold(LatCount,Options)
% ThresholdMode = 0: Single threshold
% ThresholdMode = [2,2]: Two threshold based on sigma of fits

% MaxIgnore: Number of ignored data for binning +1
% - increase stability with occasional bad pixels
% - need to be cautious when filling fraction is low

    arguments
        LatCount
        Options.ThresholdMode (1,:) double = 0
        Options.MaxIgnore (1,1) int16 = 1
        Options.AbsMax (1,1) double = 5000
        Options.AbsMin (1,1) double = -300
        Options.ThresholdMin (1,1) double = 200
        Options.ThresholdMax (1,1) double = 600
        Options.IgnoreSubImg (1,1) logical = false
    end

    [NumSite,NumSubImg,NumSave] = size(LatCount);
    if Options.IgnoreSubImg
        LatCount = reshape(LatCount,NumSite*NumSubImg,1,NumSave);
        NumSite = NumSite*NumSubImg;
        NumSubImg = 1;
    end

    Threshold = nan(1,NumSubImg);
    TwoThreshold = nan(2,NumSubImg);
    TwoFit = cell(1,NumSubImg);

    % Number of bins for fitting two Gaussians
    NumBinEdge = round(max(min(50,NumSite*NumSave/20),200))+1;

    for i = 1:NumSubImg

        % Filtered out 0-counts (probably because of too large ROI)
        LatCountSub = reshape(LatCount(:,i,:),1,[]);
        AllCount = LatCountSub(LatCountSub~=0);
        
        % Create bins for histogram
%         BinMin = max(floor(min(AllCount))-100,Options.AbsMin); %original
        BinMin = floor(min(AllCount))-100; %modified
%         BinMax = min(ceil(kthMax(AllCount,Options.MaxIgnore+1))+100,Options.AbsMax); %original
        BinMax = ceil(kthMax(AllCount,Options.MaxIgnore+1))+100; %modified
        Bin = linspace(BinMin,BinMax,NumBinEdge);
        BinWidth = Bin(2)-Bin(1);
        BinCenter = (Bin(1:end-1)+Bin(2:end))/2;

        HistCount = histcounts(AllCount,Bin);
        [ThresholdSingle,Fit0,Fit1] = fitTwoGaussian(BinCenter',HistCount');
        
        if ThresholdSingle<Options.ThresholdMax
            if ThresholdSingle>Options.ThresholdMin
                Threshold(i) = ThresholdSingle;
            else
                Threshold(i) = Options.ThresholdMin;
            end
        else
            Threshold(i) = Options.ThresholdMax;
        end

        N00 = integrate(Fit0,Threshold(i),Bin(1))/BinWidth;
        N01 = integrate(Fit0,Bin(end),Threshold(i))/BinWidth;
        N10 = integrate(Fit1,Threshold(i),Bin(1))/BinWidth;
        N11 = integrate(Fit1,Bin(end),Threshold(i))/BinWidth;

        TwoFit{i} = {Bin,HistCount,Fit0,Fit1,{N00,N01,N10,N11}};
        
        TwoThreshold(1,i) = min(Fit0.b1+Options.ThresholdMode(1)*Fit0.c1,Threshold(i));
        TwoThreshold(2,i) = max(Fit1.b1-Options.ThresholdMode(end)*Fit1.c1,Threshold(i));
    end
    if Options.ThresholdMode
        Threshold = TwoThreshold;
    end
end

function [ThresholdSingle,Fit0,Fit1] = fitTwoGaussian(X,Signal)

    % First fit a Gaussian to the highest peak (0-peak)
    [Max0,I0] = max(Signal);
    X0 = X(I0);
    Index0 = X<(X0+200);
    X0All = X(Index0);
    Signal0 = Signal(Index0);
    
    % Fit parameters. Nonlinear weight for rising edge
    FitOption0 = fitoptions('gauss1');
    FitOption0.Lower = [0.8*Max0,X0-100,10];
    FitOption0.Upper = [1.2*Max0,X0+100,500];
    FitOption0.StartPoint = [Max0,X0,100];
    FitOption0.Weight = exp(-(X0All-X0)/200);
    FitOption0.Display = 'off';
    
    Fit0 = fit(X0All,Signal0,'gauss1',FitOption0);

    % Fit a Gaussian to residual of 0-peak fit

    % Check the distance between 0-peak center and the max range
    Dist = (X(end)-Fit0.b1)/Fit0.c1;
    if Dist>10
        Index1 = X>(Fit0.b1+Dist/4*Fit0.c1);
    else
        Index1 = X>(Fit0.b1+1.5*Fit0.c1);
    end

    X1All = X(Index1);
    Signal1 = Signal(Index1)-Fit0(X1All);
    DistNorm = (X1All-Fit0.b1)/min(200,2*Fit0.c1);
    DistNorm(DistNorm>5) = 5;
        
    % Nonlinear weight for 1-peak
    if size(X1All,1)<5
        Fit1 = cfit(fittype('gauss1'),0,Fit0.b1+Fit0.c1,200);
        ThresholdSingle = Fit0.b1+Fit0.c1;
        warning('No signal for the 1-peak')
    else
        FitOption1 = fitoptions('gauss1');
        FitOption1.Lower = [0,Fit0.b1+100,Fit0.c1];
        FitOption1.Upper = [Max0,max(Fit0.b1+100,X1All(end)-Fit0.c1),...
            max(Fit0.c1,X1All(end)-(Fit0.b1+Fit0.c1))];
        FitOption1.StartPoint = [mean(Signal1),X1All(end)-100,200];
        FitOption1.Weight = exp(DistNorm-1);
        FitOption1.Display = 'off';
    
        Fit1 = fit(X1All,Signal1,'gauss1',FitOption1);

        FuncDif = @(x) (Fit0.a1-Fit1(Fit0.b1))*(x<Fit0.b1)+ ...
            (Fit0(x)-Fit1(x))*(x>Fit0.b1);
        FuncZero = fzero(FuncDif,(Fit0.b1+Fit1.b1)/2);

        if Dist>10
            ThresholdSingle = max([FuncZero,Fit0.b1+2*Fit0.c1, ...
                2/3*Fit0.b1+1/3*Fit1.b1,4/5*Fit0.b1+1/5*X(end)]);
        else
            ThresholdSingle = max([FuncZero,Fit0.b1+Fit0.c1]);
        end
    end
end

%% kthMAx

function Max = kthMax(A,k)
    if k>length(A(:))
        error('Index exceeds number of array elements')
    end
    M = maxk(A(:),k);
    Max = M(k);
end

%% getThreshold

function [Threshold, Fidelity, filling, afit, bfit] = getThreshold(latcounts,varargin)
%% Start function

% Prepare histcounts data
[y,edges] = histcounts(latcounts,100);
binwidth = edges(2)-edges(1);
x = edges(1:end-1)+binwidth/2;


%%
% Use a hard wall to separate left and right peaks
% Use center of mass to set initial threshold if one is not provided as
% input

com = 1/sum(y)*sum(x.*y);
% [~,indx] = max(y);
% Bigpeakcenter = x(indx);
% a=5; %nudge factor
% thresh=com-a*(Bigpeakcenter-com)
thresh=com;
%thresh=3600;

foa = fitoptions('Method','NonlinearLeastSquares',...
    'Lower',[1,x(1),binwidth],...
    'Upper',[2*max(y),thresh,thresh-min(x)],...
    'StartPoint',[max(y),thresh/2,(thresh-min(x))/2]);

fob = fitoptions('Method','NonlinearLeastSquares',...
    'Lower',[1,thresh,binwidth],...
    'Upper',[2*max(y),max(x),max(x)-min(x)],...
    'StartPoint',[max(y),thresh*3/4,(max(x)-thresh)/2]);

% gaussEqn = 'a0*exp(-(x-a1)^2/(2*a2))+b0*exp(-(x-b1)^2/(2*b2))';
% ft = fittype(gaussEqn,...
%     'independent',{'x'},...
%     'dependent',{'y'},...
%     'coefficients',{'a0','a1','a2','b0','b1','b2'},...
%     'options',fo);

gaussEqn = 'a0*exp(-(x-a1)^2/(2*a2^2))';
fta = fittype(gaussEqn,...
    'independent',{'x'},...
    'dependent',{'y'},...
    'coefficients',{'a0','a1','a2'},...
    'options',foa);
ftb = fittype(gaussEqn,...
    'independent',{'x'},...
    'dependent',{'y'},...
    'coefficients',{'a0','a1','a2'},...
    'options',fob);
lengtha = length(x(x<thresh));
lengthb = length(x)-lengtha;
[afit,agof] = fit(x(1:lengtha)',y(1:lengtha)',fta);
[bfit,bgof] = fit(x(lengtha:end)',y(lengtha:end)',ftb);

% Find new threshold
contx = linspace(-1000,3*max(x),1000);
threshx = contx(contx>afit.a1 & contx<bfit.a1);
[minval, newthreshin] = min(afit(threshx)+bfit(threshx));
Threshold = threshx(newthreshin);

if Threshold>contx(end)
    Threshold=contx(end);
end

% Calculate imaging fidelity
intatot = integrate(afit,contx(end),contx(1));
inta = integrate(afit,contx(end),Threshold);
intbtot = integrate(bfit,contx(end),contx(1));
intb = integrate(bfit,Threshold,contx(1));
Fidelity = 1-(inta+intb)/(intatot+intbtot-inta-intb);


% Calculate filling fraction
left=contx(contx<Threshold);
right=contx(contx>=Threshold);
intleft=trapz(left,afit(left));
intright=trapz(right,bfit(right));
filling=intright/(intleft+intright);

% OVERRIDE THRESHOLD WHEN FIDELITY IS TOO LOW
if Fidelity<0.95
    Threshold = bfit.a1+2*bfit.a2;
end

%% Plotting

if nargin>1
    ax=varargin{1};
    % Plot histogram
    histogram(ax,latcounts,100,'EdgeAlpha',0,'FaceAlpha',0.5);
    hold on
    
    % Plot fit and data points
    plot(ax,contx,afit(contx)+bfit(contx),'LineWidth',5);
    plot(ax,x,y,'ok','MarkerFaceColor','k');
    
    % Format plot
    xlim(ax,[min([x(1),afit.a1-5*afit.a2]),max([x(end),bfit.a1+5*bfit.a2])]);
    txl = xline(ax,Threshold,'--',{['Threshold: ',num2str(round(Threshold))]});
    txl.LabelHorizontalAlignment = 'center';
    txl.LabelOrientation = 'horizontal';
    title({['Fidelity = ',num2str(Fidelity),' (from fits)'],['Filling = ',num2str(filling),' (from fits)']});
    %fontsize(gca,scale=1.4);
    hold off
end

end

%% getLatOccup

function [LatOccup,LatUnoccup,LatLost,LatNew,LatDiff] = getLatOccup(LatCount,Threshold)
    %LatCount=LatCount(isnan(LatCount)==false);
    [~,NumSubImg,NumSave] = size(LatCount);
    
    LatOccup = LatCount>repmat(Threshold(end,1:NumSubImg),[1,1,NumSave]);
    LatUnoccup = LatCount<repmat(Threshold(1,1:NumSubImg),[1 1 NumSave]);

    LatOccupEarlier = circshift(LatOccup,-1,2);
    LatOccupEarlier(:,NumSubImg,:) = LatOccup(:,NumSubImg,:);
    LatUnoccupEarlier = circshift(LatUnoccup,-1,2);
    LatUnoccupEarlier(:,NumSubImg,:) = LatUnoccup(:,NumSubImg,:);
    
    LatLost = LatOccupEarlier & LatUnoccup;
    LatNew = LatUnoccupEarlier & LatOccup;
    LatDiff = ~LatOccup & ~LatUnoccup;
end
