function ContentSetting  = displayAxesContent(Axes, ContentSetting, Live)
    arguments
        Axes
        ContentSetting (1,1) struct
        Live (1,1) struct
    end

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
                case 'MaxCount'
                    display_content = max(Live.Signal{ContentSetting.ImageIndex}, [], 'all');
            end
            if isempty(ContentSetting.PlotObj)
                ContentSetting.PlotObj = plot(Axes, display_content);
            else
                ContentSetting.PlotObj.XData = [ContentSetting.PlotObj.XData, ContentSetting.PlotObj.XData(end)+1];
                ContentSetting.PlotObj.YData = [ContentSetting.PlotObj.YData, display_content];
            end
    end
end