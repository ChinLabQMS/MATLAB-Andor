classdef Projector < BaseRunner

    properties (SetAccess = immutable)
        ID
    end

    properties (SetAccess = {?BaseObject})
        Initialized = false
    end
    
    properties (SetAccess = protected)
        StaticPattern
        StaticPatternReal
    end

    methods
        function obj = Projector(id, config)
            arguments
                id = "Test"
                config = DMDConfig()
            end
            obj@BaseRunner(config)
            obj.ID = id;
        end

        function init(obj)
            obj.Initialized = true;
            obj.info('Projector window initialized.')
        end

        function close(obj)
            obj.Initialized = false;
            obj.info('Projector window closed.')
        end

        function plot(obj)
            obj.Config.plot()
        end

        function delete(obj)
            obj.close()
            delete@BaseRunner(obj)
        end
    end

end
