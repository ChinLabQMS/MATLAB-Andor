DataFile1 = 'data_L0=0_J0=0.5.txt';
DataFile2 = 'data_L0=1_J0=1.5.txt';

FileID1 = fopen(DataFile1,'r');
FileID2 = fopen(DataFile2,'r');
Data1 = fscanf(FileID1,'%d%c%d/%d %f %f',[6,Inf])';
Data2 = fscanf(FileID2,'%d%c%d/%d %f %f',[6,Inf])';
fclose(FileID1);
fclose(FileID2);

% Convert 1/wavelength to SI unit
Data1(:,5) = 100*Data1(:,5);
Data2(:,5) = 100*Data2(:,5);

% Transition energy
ExState0 = Data1(:,1)==6 & Data1(:,2)==double('P') & Data1(:,3)==3 & Data1(:,4)==2;
Data2(:,5) = Data2(:,5)-Data1(ExState0,5);

NumState1 = size(Data1,1);
NumState2 = size(Data2,1);

% Find corresponding transition linewidth (in the unit of 1/wavelength)
e = 1.602176634*10^-19;
a0 = 0.5291772083*10^-10;
epsilon0 = 8.854187817*10^-12;
h = 6.62606876*10^-34;
c = 2.99792458*10^8;
Factor = 8*pi^2*e^2*a0^2/(3*h*epsilon0);

Data1 = [repmat([6 0 0.5],NumState1,1),Data1(:,1),getL(Data1(:,2)), ...
    Data1(:,3)./Data1(:,4),Data1(:,[5 6])];
Data2 = [repmat([6 1 1.5],NumState2,1),Data2(:,1),getL(Data2(:,2)), ...
    Data2(:,3)./Data2(:,4),Data2(:,[5 6])];
Data1Decay = Factor*Data1(:,7).^3.*Data1(:,8).^2./(2*Data1(:,6)+1);
Data2Decay = max(Factor*Data2(:,7).^3.*Data2(:,8).^2./(2*Data2(:,6)+1),zeros(NumState2,1))+Data1Decay(ExState0,1);
Data = [Data1,Data1Decay;Data2,Data2Decay];

% Energy = 1/wavelength, linewidth is in (2*pi) Hz
LineData = array2table(Data,'VariableNames',{'N0','L0','J0','N','L','J','Energy','DipElm','Linewidth'});
save('linedata\CsLineData.mat','LineData')

function L = getL(Code)
    NumData = length(Code);
    L = nan(NumData,1);
    for i = 1:NumData
        switch char(Code(i))
            case 'S'
                L(i) = 0;
            case 'P'
                L(i) = 1;
            case 'D'
                L(i) = 2;
        end
    end
end