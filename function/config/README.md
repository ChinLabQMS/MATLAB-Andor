# Configuring Andor CCDs
The CCD settings used to image atoms/calibrate DMD will be stored in the functions in this folder.

## Functions

### Initializing and shutting down CCDs

- `initializeCCD`: Initialize the CCDs
- `shutDownCCD`: Shut down the CCDs
- `setCurrentCCD`: Select the CCD to use, input parameter `CCD` = `Upper` or `Lower`

### CCD configurations for imaging atoms in a lattice
There are several different settings for imaging atoms in an optical lattice.
To set up the CCD with different modes, use `setCCDMode` with input parameter `mode` = `DataLive1`, ..., `DataLive8`, `DataLive1Cropped`, `DMDLive`, `Analysis`.

- **DataLive** mode: collecting live single-site resolved atom images with an input parameter `exposure`
    - `DataLive1`: Full frame mode
    - `DataLive2`: Fast kinetic mode, with 2 half frame subframes taken continuously
    - `DataLive4`: Fast kinetic mode, with 4 subframes
    - `DataLive8`: Fast kinetic mode, with 8 subframes
    - `DataLive1Cropped`: Cropped mode to get single frame image

- **DMDLive** mode: collecting live DMD images with an input paramemeter `exposure`
    - `DMDLive`: Full frame mode

- **Analysis** mode: analyze the data taken in `DataLive` mode, do not trigger CCD
    - `Analysis`

