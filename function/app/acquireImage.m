function image = acquireImage(app)
    if strcmp(app.Data.Config.Serial, 'Zelux')
        image = acquireZeluxImage(app.Handle{2});
    else
        image = acquireAndorImage();
    end
end