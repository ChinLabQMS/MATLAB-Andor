function content = getAxesContent(Content, Image)
    arguments
        Content (1,1) struct
        Image
    end
    switch Content.Style
        case 'Image'
            switch Content.ImageFormat
                case 'Raw'
                    content = Image{Content.ImageIndex};
                otherwise
                    content = Image{Content.ImageIndex};
            end
        case 'Plot'
            content = [];
    end
end