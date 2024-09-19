classdef Cameras < handle

    properties
        Andor19330 (1, 1) AndorCamera = AndorCamera(19330)
        Andor19331 (1, 1) AndorCamera = AndorCamera(19331)
        Zelux (1, 1) ZeluxCamera = ZeluxCamera()
    end

    methods
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
    end

end
