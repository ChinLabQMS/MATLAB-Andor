function acquireOneImage
    Image = acquireCCDImage;
    
    figure(Name="Signal",Units="normalized",WindowState="maximized")
    imagesc(Image)
    daspect([1 1 1])
    colorbar
end