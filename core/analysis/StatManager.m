classdef StatManager < BaseStorage
    % STATMANAGER Class to store analysis results

    methods
        function obj = StatManager(config, cameras)
            arguments
                config = AcquisitionConfig()
                cameras = CameraManager('test_mode', 1)
            end
            obj@BaseStorage("stat", config, cameras)
        end
    end

end
