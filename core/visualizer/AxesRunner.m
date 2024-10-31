classdef (Abstract) AxesRunner < BaseRunner
    %AXESRUNNER Runner for updating axes with live data
    
    properties (SetAccess = immutable)
        AxesHandle
    end

    properties (SetAccess = protected)
        GraphHandle
        AddonHandle
        Live = struct.empty
    end

    methods
        function obj = AxesRunner(ax, config)
            arguments
                ax = []
                config = AxesConfig()
            end
            obj@BaseRunner(config)
            obj.AxesHandle = ax;
        end

        function init(~)
        end

        function update(obj, Live)
            obj.Live = Live;
            try
                data = Live.(obj.Config.Content).(obj.Config.CameraName).(obj.Config.ImageLabel);
            catch
                obj.warn("[%s %s] Not found in Live.", obj.Config.CameraName, obj.Config.ImageLabel)
                return
            end
            info = Live.Info;
            obj.updateContent(data, info)
        end

        function config(obj, varargin)
            config@BaseRunner(obj, varargin{:})
            if ~isempty(obj.Live)
                obj.update(obj.Live)
            end
        end

        function clear(obj)
            cla(obj.AxesHandle)
            obj.GraphHandle = [];
        end

        function uisave(obj)
            if isempty(obj.GraphHandle)
                return
            end
            PlotData.XData = obj.GraphHandle.XData; 
            PlotData.YData = obj.GraphHandle.YData; 
            PlotData.Config = obj.Config.struct(); %#ok<STRNU>
            uisave("PlotData", "PlotData.mat")
        end
    end

    methods (Access = protected, Abstract)
        updateContent(obj, data, info)
    end

end
