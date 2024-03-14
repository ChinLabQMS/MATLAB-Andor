function displayAxesContent(Axes, Content, Live)
    arguments
        Axes
        Content (1,1) struct
        Live (1,1) struct
    end

    switch Content.Style

        case 'Image'
            switch Content.ImageFormat
                case 'Raw'
                    content = Live.Image{Content.ImageIndex};
                case 'Background-subtracted'
                    content = Live.Image{Content.ImageIndex} - Live.Background{Content.ImageIndex};
            end
            
            imagesc(Axes, content)
            colorbar(Axes)

        case 'Plot'
            
    end
end