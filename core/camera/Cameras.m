classdef Cameras < handle

    properties
        Andor19330 (1, 1) AndorCamera = AndorCamera(19330)
        Andor19331 (1, 1) AndorCamera = AndorCamera(19331)
        Zelux (1, 1) ZeluxCamera = ZeluxCamera()
    end

    methods
        function obj = Cameras()
        end

        function init(obj, cameras)
            arguments
                obj
                cameras (1, :) string = properties(obj)
            end
            for i = 1:length(cameras)
                camera = obj.(cameras{i});
                camera.init();
            end
        end

        function close(obj)
            cameras = properties(obj);
            for i = 1:length(cameras)
                camera = obj.(cameras{i});
                camera.close();
            end
        end

        function config(obj, varargin)
            cameras = properties(obj);
            for i = 1:length(cameras)
                camera = obj.(cameras{i});
                camera.config(varargin{:});
            end
        end

        function delete(obj)
            obj.close();
        end

        function s = struct(obj)
            s = struct();
            for field = properties(obj)'
                s.(field{1}) = struct('Config', obj.(field{1}).Config);
            end
        end
    end

    methods (Static)
        function s = getStaticConfig(config)
            arguments
                config.Andor19330 = AndorCameraConfig()
                config.Andor19331 = AndorCameraConfig()
                config.Zelux = ZeluxCameraConfig()
            end
            s = struct();
            for field = fields(config)'
                s.(field{1}) = struct('Config', config.(field{1}));
            end
        end
    end

end
