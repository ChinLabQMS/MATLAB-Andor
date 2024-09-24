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
                obj.Andor19330 = Camera("Andor19330", config.Andor19330);
                obj.Andor19331 = Camera("Andor19331", config.Andor19331);
                obj.Zelux = Camera("Zelux", config.Zelux);
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
            for camera = cameras
                obj.(camera).init();
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
    end

    methods (Static)
        function obj = struct2obj(data, options)
            arguments
                data (1, 1) struct
                options.test_mode = true
            end
            args = {};
            if isfield(data, 'Andor19330')
                args = [args, {'Andor19330', AndorCameraConfig.struct2obj(data.Andor19330.Config)}];
            end
            if isfield(data, 'Andor19331')
                args = [args, {'Andor19331', AndorCameraConfig.struct2obj(data.Andor19331.Config)}];
            end
            if isfield(data, 'Zelux')
                args = [args, {'Zelux', ZeluxCameraConfig.struct2obj(data.Zelux.Config)}];
            end
            if options.test_mode
                args = [args, {'test_mode', true}];
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
