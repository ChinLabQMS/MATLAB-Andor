function [ContentSetting, Live] = displayAxesContent(Axes, ContentSetting, Live)
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
                    display_content = double(Live.Image{ContentSetting.ImageIndex}) - Live.Background{ContentSetting.ImageIndex};
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
            
    end
end