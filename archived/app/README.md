# Data schema for the image acquisition and analysis code

## Main data structures

### `Data` structure
`Data` is a structure that contains all the data for an acquisition session. It is ususally saved as a `.mat` file from the `ImageAcquisition` app.

The fields of the `Data` structure are:
- `Data.SequenceTable`: A table that contains the sequence of images to be acquired.
- `Data.Andor19330`: A structure that contains the Andor camera (serial #: 19330) configuration and data.
    - `Data.Andor19330.Config`: A structure that contains the Andor camera configuration.
        
    - `Data.Andor19330.Image`: A structure that contains the raw images.

- `Data.Andor19331`: A structure that contains the Andor camera (serial #: 19331) configuration and data.
    - `Data.Andor19331.Config`: A structure that contains the Andor camera configuration.
        
    - `Data.Andor19331.Image`: A structure that contains the raw images.

- `Data.Zelux`: A structure that contains the Thorlabs Zelux camera configuration and data.
    - `Data.Zelux.Config`: A structure that contains the Thorlabs Zelux camera configuration.        
    - `Data.Zelux.Image`: A structure that contains the raw images.

The camera fields (`Data.Andor19330`, `Data.Andor19331`, `Data.Zelux`) are optional. If the camera is not connected, the corresponding field will not exist in the `Data` structure.

### `Setting` structure
`Setting` is a structure that contains the settings for the image acquisition.

The fields of the `Setting` structure are:
- `Setting.Andor19330`: A structure that contains the Andor camera (serial #: 19330) settings.
- `Setting.Andor19331`: A structure that contains the Andor camera (serial #: 19331) settings.
- `Setting.Zelux`: A structure that contains the Thorlabs Zelux camera settings.
- `Setting.Acquisition`: A structure that contains the acquisition settings.
- `Setting.Analysis`: A structure that contains the analysis settings.

### `Live` structure
`Live` is a structure that contains the live data for the real-time image analysis.

The fields of the `Live` structure are:
- `CurrentIndex`: The index of the current image in the sequence.
- `Image`: The current images from the cameras.
- `Background`: The background images for the cameras.
- `Signal`: The signal images for the cameras after background and offset subtraction.