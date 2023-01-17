function [Signal,Data] = getSignal(Data,DataInfo,i)

    if DataInfo.ModeLive
        Image = acquireCCDImage(DataInfo.XPixel,DataInfo.YPixel,DataInfo.NumSubImg);
        Data.Img(:,:,i) = Image;

        switch DataInfo.ModeBkg
                case 'None'
                    Signal = Image;
                case 'Current'
                    Background = acquireCCDImage(DataInfo.XPixel,DataInfo.YPixel,DataInfo.NumSubImg);
                    Data.Bg(:,:,i) = Background;
                    Signal = Image-Background;
                otherwise
                    Background = acquireCCDImage(DataInfo.XPixel,DataInfo.YPixel,DataInfo.NumSubImg);
                    Data.Bg(:,:,i) = Background;
                    Signal = Image-DataInfo.MeanBg;
        end
    else
        
    end

    if ModeCln
        Signal = Signal-cancelOffset(Signal,DataInfo.NumSubImg);
    end

end