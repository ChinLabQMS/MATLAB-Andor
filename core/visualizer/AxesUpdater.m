classdef (Abstract) AxesUpdater < BaseProcessor
    %AXESRUNNER Runner for updating axes with live data

    properties (Abstract, SetAccess = {?BaseObject})
        CameraName
        ImageLabel
        Content
        FuncName
    end
    
    properties (SetAccess = immutable)
        AxesID
        AxesHandle
    end

    properties (SetAccess = protected)
        GraphHandle
        LiveHandle
    end

    methods
        function obj = AxesUpdater(ax, id, varargin)
            arguments
                ax = []
                id = "TestAxes"
            end
            arguments (Repeating)
                varargin
            end
            obj@BaseProcessor(varargin{:})
            obj.AxesHandle = ax;
            obj.AxesID = id;
        end

        function update(obj, Live)
            if isempty(obj.AxesHandle)
                obj.AxesHandle = axes();
            end
            obj.LiveHandle = Live;
            if isprop(Live, obj.Content) && isfield(Live.(obj.Content), obj.CameraName) && ...
                    isfield(Live.(obj.Content).(obj.CameraName), obj.ImageLabel)
                obj.updateContent(Live)
                return
            elseif ~isempty(Live.LastData)
                LastLive = Live.LastData;
                if isfield(LastLive, obj.Content) && isfield(LastLive.(obj.Content), obj.CameraName) && ...
                        isfield(LastLive.(obj.Content).(obj.CameraName), obj.ImageLabel)
                    obj.updateContent(LastLive)
                    return
                end
            end
            obj.warn("[%s %s] Not found in Live data.", obj.CameraName, obj.ImageLabel)           
        end

        function clear(obj)
            if isempty(obj.AxesHandle)
                return
            end
            cla(obj.AxesHandle)
            obj.GraphHandle = [];
        end

        function uisave(obj)
            if isempty(obj.GraphHandle)
                return
            end
            PlotData.XData = obj.GraphHandle.XData; 
            PlotData.YData = obj.GraphHandle.YData; 
            PlotData.Config = obj.struct(obj.ConfigurableProp); %#ok<STRNU>
            uisave("PlotData", "PlotData.mat")
        end
    end

    methods (Access = protected)
        function init(obj)
            if ~isempty(obj.LiveHandle)
                obj.update(obj.LiveHandle)
            end
        end
    end

    methods (Access = protected, Abstract)
        updateContent(obj, data, info)
    end

end
