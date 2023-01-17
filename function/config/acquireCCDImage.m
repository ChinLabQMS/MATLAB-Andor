function Image = acquireCCDImage(XPixels,YPixels,NumSubImg,Options)
    arguments
        XPixels (1,1) double = 1024
        YPixels (1,1) double = 1024
        NumSubImg (1,1) double = 1
        Options.TimeOutSecond = 30
    end

    % Taking data from Andor camera
    [ret] = StartAcquisition();
    CheckWarning(ret);
    [ret] = WaitForAcquisitionTimeOut(1000*Options.TimeOutSecond);
    CheckWarning(ret);
    [ret,ImgData,~,~] = GetImages(1,NumSubImg,YPixels*XPixels);
    CheckWarning(ret);
    
    if ret == 20002
        Image = flip(transpose(reshape(ImgData,YPixels,XPixels)),1);
    else
        error('Acquisition error!');
    end
    
    % -----------Temporary test code--------------
%     if Options.ImageType
%         load("saved\TestImage.mat","TestImage")
%     else
%         load("saved\TestBackground.mat","TestImage")
%     end
%     Image = TestImage(1:XPixels,1:YPixels);
    %--------------------------------------------

end