function image = acquireImage(app)
    if strcmp(app.Data.Config.Serial, 'Zelux')
        image = acquireZeluxImage(app.Handle{2}, "timeout",app.AcquisitiontimeoutsSpinner.Value);
    else
        image = acquireAndorImage("timeout",app.AcquisitiontimeoutsSpinner.Value);
    end
end