classdef Cameras < BaseObject

    properties (SetAccess = immutable)
        Andor19330 (1, 1) Camera
        Andor19331 (1, 1) Camera
        Zelux (1, 1) Camera
    end

    methods
        function obj = Cameras(config)
            arguments
                config.Andor19330 = AndorCameraConfig()
                config.Andor19331 = AndorCameraConfig()
                config.Zelux = ZeluxCameraConfig()
                config.test_mode = false
            end
            if config.test_mode
                obj.Andor19330 = Camera("Andor19330", AndorCameraConfig());
                obj.Andor19331 = Camera("Andor19331", AndorCameraConfig());
                obj.Zelux = Camera("Zelux", ZeluxCameraConfig());
            else
                obj.Andor19330 = AndorCamera(19330, config.Andor19330);
                obj.Andor19331 = AndorCamera(19331, config.Andor19331);
                obj.Zelux = ZeluxCamera(0, config.Zelux);
            end
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
    end

    methods (Static)
        function obj = struct2obj(data)
            arguments
                data (1, 1) struct
            end
            args = {};
            if isfield(data, 'Andor19330')
                args{end + 1} = 'Andor19330';
                args{end + 1} =  AndorCameraConfig.struct2obj(data.Andor19330.Config);
            end
            if isfield(data, 'Andor19331')
                args{end + 1} = 'Andor19331';
                args{end + 1} =  AndorCameraConfig.struct2obj(data.Andor19331.Config);
            end
            if isfield(data, 'Zelux')
                args{end + 1} = 'Zelux';
                args{end + 1} = ZeluxCameraConfig.struct2obj(data.Zelux.Config);
            end
            obj = Cameras(args{:});
        end

        function obj = file2obj(filename)
            arguments
                filename (1, 1) string
            end
            if isfile(filename)
                s = load(filename);
                obj = Cameras.struct2obj(s);
            else
                error("File %s does not exist.", filename)
            end
        end
    end

end
