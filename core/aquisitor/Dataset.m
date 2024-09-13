classdef Dataset < dynamicprops
    properties
        AcquisitionConfig
    end

    methods
        function obj = Dataset(config, cameras)
            obj.AcqusitorConfig = config;
            % sequence_table = obj.AcqusitorConfig.SequenceTable;
            % cameras = unique(sequence_table.Camera);
            % for i = 1:length(cameras)
            %     camera = cameras{i};
            %     obj.addprop(camera);
            %     obj.(camera) = struct();
            % end
            % for i = 1:length(sequence_table.Camera)
            %     camera = sequence_table.Camera(i);
            %     label = sequence_table.Label(i);
            %     note = sequence_table.Note(i);
                
            % end
        end

        function update(obj, index, new_data)
        end

        function save(obj)
        end

    end
end
