classdef Acquisitor < BaseObject

    properties (SetAccess = protected, Transient)
        Cameras
        Data
    end

    methods
        function obj = Acquisitor(config, cameras)
            arguments
                config (1, 1) AcquisitionConfig = AcquisitionConfig()
                cameras (1, 1) Cameras = Cameras()
            end
            obj@BaseObject(config);
            obj.Cameras = cameras;
        end

        function vargout = init(obj)
            obj.initCameras();
            obj.Data = Dataset(obj.Config, obj.Cameras);
            if nargout > 0
                vargout{1} = obj.Data;
            end
        end

        function config(obj, varargin)
            config@BaseObject(obj, varargin{:})
            obj.init()
        end

        function initCameras(obj)
            obj.Cameras.init(obj.Config.ActiveCameras);
        end

        function new_images = acquireImage(obj)
            timer = tic;
            sequence_table = obj.Config.ActiveSequence;
            new_images = cell(1, height(obj.Config.ActiveAcquisition));
            index = 1;
            for i = 1:height(sequence_table)
                camera = obj.Cameras.(char(sequence_table.Camera(i)));
                type = char(sequence_table.Type(i));
                switch type
                    case 'Start'
                        camera.startAcquisition();
                    case 'Acquire'
                        new_images{index} = camera.acquire('refresh', obj.Config.Refresh, 'timeout', obj.Config.Timeout);
                        index = index + 1;
                    case 'Full'
                        camera.startAcquisition();
                        new_images{index} = camera.acquire('refresh', obj.Config.Refresh, 'timeout', obj.Config.Timeout);
                        index = index + 1;
                end
            end
            fprintf("%s: Acquisition completed in %.3f s.\n", obj.CurrentLabel, toc(timer))
        end

        function acquire(obj)
            obj.Data = obj.Data.add(obj.acquireImage());
        end

        function run(obj)
            obj.initCameras();
            obj.Data = Dataset(obj.Config, obj.Cameras);
            for i = 1:obj.Config.NumAcquisitions
                obj.acquire();
            end
        end

    end

end
