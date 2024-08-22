% function ContentSetting  = displayAxesContent(Axes, ContentSetting, Live, ImageSettings, AnalysisSettings)
function ContentSetting  = displayAxesContent(Axes, ContentSetting, Live, ImageSettings)
    arguments
        Axes
        ContentSetting (1,1) struct
        Live (1,1) struct
        ImageSettings
        % AnalysisSettings
    end

    numFK=ImageSettings.NumFrames;
    hexrad=8;

    % In app ROI selection/analysis - unfinished
    % if ContentSetting.ImageIndex=Axes1 and if Axes1 is plotting
    % Andor19330 data, then run analysis
    % hexrad = AnalysisSetting.ROIRadius
    % if AnalysisSettings.ToggleROI = 1

    % disp(ContentSetting.ImageIndex)
    % hexrad=5;
    % data=Live.Signal{ContentSetting.ImageIndex};
    % disp(size(data))
    % Bg=Live.Background{ContentSetting.ImageIndex};
    % [xcenter, xwidth, ycenter, ywidth,xlimits,ylimits] = funFitGaussXY(data, numFK);
    % 
    % % Creating SubImg
    % SubImg = zeros(numFK, 2);
    % for i = 1:numFK
    %     SubImg(i, 1) = 1+(i-1)*1024/numFK;
    %     SubImg(i, 2) = i*1024/numFK;
    % end
    % 
    % [Stat,Threshold,TwoFit,Site,NumSite,Lat,MeanSum,BgOffset] = getStatFull_live(data,Bg,xcenter,ycenter,SubImg, numFK, hexrad);
    % 
    % % PT3=Site*Lat.V+Stat.LatOffset+[(numFK-1)*(1024/numFK),0];
    % PT3=Site*Lat.V+Stat.LatOffset;
    % 
    % % % Plotting to check fit
    % figure
    % imagesc(data);daspect([1 1 1]); hold on;
    % colorbar
    % hold on;
    % scatter(PT3(:,2),PT3(:,1), "filled", 'or');
    % hold off
    % 
    % Occup=sum(Stat.LatOccup(:, 1))
    % Filling=Occup/NumSite

    display_content=1;
    switch ContentSetting.Style
        case 'Image'
            switch ContentSetting.ImageFormat
                case 'Raw'
                    display_content = Live.Image{ContentSetting.ImageIndex};
                case 'Background-subtracted'
                    display_content = Live.Signal{ContentSetting.ImageIndex};
                case 'Background offset'
                    display_content = Live.Offset{ContentSetting.ImageIndex};
            end
            if isempty(ContentSetting.ImageObj)
                ContentSetting.ImageObj = imagesc(Axes, display_content);
                colorbar(Axes)
            else
                [x_size, y_size] = size(display_content);
                ContentSetting.ImageObj.XData = [1, y_size];
                ContentSetting.ImageObj.YData = [1, x_size];
                ContentSetting.ImageObj.CData = display_content;
            end
        
        case 'Plot'
            switch ContentSetting.PlotContent
                case 'MeanCount'
                    display_content = mean(Live.Signal{ContentSetting.ImageIndex}, 'all');
                    disp('meancount')
                case 'MaxCount'
                    display_content = max(Live.Signal{ContentSetting.ImageIndex}, [], 'all');
                case 'Filling'
                    data=Live.Signal{ContentSetting.ImageIndex};
                    disp(size(data));
                    Bg=Live.Background{ContentSetting.ImageIndex};
                    [xcenter, xwidth, ycenter, ywidth,xlimits,ylimits] = funFitGaussXY(data, numFK);

                    % disp('xcenter is')
                    % xcenter
                    % disp('ycenter is')
                    % ycenter

                    % Creating SubImg
                    SubImg = zeros(numFK, 2);
                    for i = 1:numFK
                        SubImg(i, 1) = 1+(i-1)*1024/numFK;
                        SubImg(i, 2) = i*1024/numFK;
                    end
                    % Data.Andor19330.SubImg=SubImg;
                    [Stat,Threshold,TwoFit,Site,NumSite,Lat,MeanSum,BgOffset] = getStatFull_live(data,Bg,xcenter,ycenter,SubImg, numFK, hexrad);

                    % PT3=Site*Lat.V+Stat.LatOffset+[(numFK-1)*(1024/numFK),0];
                    PT3=Site*Lat.V+Stat.LatOffset;

                    % Plotting to check fit
                    % figure
                    % imagesc(data);daspect([1 1 1]); hold on;
                    % colorbar
                    % hold on;
                    % scatter(PT3(:,2),PT3(:,1), "filled", 'or');
                    % hold off

                    Occup=sum(Stat.LatOccup(:, 1))
                    Filling=Occup/NumSite
                    display_content = Filling;

                case 'GaussXCenter'
                    % fit is giving good center coords but bad widths
                    data=Live.Signal{ContentSetting.ImageIndex};
                    Bg=Live.Background{ContentSetting.ImageIndex};
                    [xcenter, xwidth, ycenter, ywidth,xlimits,ylimits] = funFitGaussXY(data, numFK); % May need to improve fit
                    display_content = xcenter;
            end
            % disp('display content is')
            % disp(size(display_content))
            if isempty(ContentSetting.PlotObj)
                ContentSetting.PlotObj = plot(Axes, display_content, '--o', 'LineWidth', 3);
            else
                ContentSetting.PlotObj.XData = [ContentSetting.PlotObj.XData, ContentSetting.PlotObj.XData(end)+1];
                ContentSetting.PlotObj.YData = [ContentSetting.PlotObj.YData, display_content];
            end
    end
end