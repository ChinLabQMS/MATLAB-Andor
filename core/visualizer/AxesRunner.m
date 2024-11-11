classdef (Abstract) AxesRunner < BaseRunner
    %AXESRUNNER Runner for updating axes with live data
    
    properties (SetAccess = immutable)
        AxesHandle
    end

    properties (SetAccess = protected)
        GraphHandle
        AddonHandle
        LiveHandle
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
            obj.LiveHandle = Live;
            if isprop(Live, obj.Config.Content) && isfield(Live.(obj.Config.Content), obj.Config.CameraName) && ...
                    isfield(Live.(obj.Config.Content).(obj.Config.CameraName), obj.Config.ImageLabel)
                obj.updateContent(Live)
                return
            elseif ~isempty(Live.LastData)
                LastLive = Live.LastData;
                if isfield(LastLive, obj.Config.Content) && isfield(LastLive.(obj.Config.Content), obj.Config.CameraName) && ...
                        isfield(LastLive.(obj.Config.Content).(obj.Config.CameraName), obj.Config.ImageLabel)
                    obj.updateContent(LastLive)
                    return
                end
            end
            obj.warn("[%s %s] Not found in Live data.", obj.Config.CameraName, obj.Config.ImageLabel)           
        end

        function config(obj, varargin)
            config@BaseRunner(obj, varargin{:})
            if ~isempty(obj.LiveHandle)
                obj.update(obj.LiveHandle)
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
