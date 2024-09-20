classdef Cameras < handle

    properties
        Andor19330 (1, 1) AndorCamera
        Andor19331 (1, 1) AndorCamera
        Zelux (1, 1) ZeluxCamera
    end

    methods
        function obj = Cameras(config)
            arguments
                config.Andor19330 = AndorCameraConfig()
                config.Andor19331 = AndorCameraConfig()
                config.Zelux = ZeluxCameraConfig()
            end
            obj.Andor19330 = AndorCamera(19330, config.Andor19330);
            obj.Andor19331 = AndorCamera(19331, config.Andor19331);
            obj.Zelux = ZeluxCamera(0, config.Zelux);
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
                s.(field{1}) = struct('Config', obj.(field{1}).Config.struct());
            end
        end
    end

    methods (Static)
        function s = getStaticConfig(config)
            arguments
                config.Andor19330 = AndorCameraConfig().struct()
                config.Andor19331 = AndorCameraConfig().struct()
                config.Zelux = ZeluxCameraConfig().struct()
            end
            s = struct();
            for field = fields(config)'
                s.(field{1}) = struct('Config', config.(field{1}));
            end
        end

        function obj = fromData(data)
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
    end

end
