classdef Picomotor < BaseProcessor
    
    properties (SetAccess = immutable)
        ID
        USBAddress
        NPUSBHandle
    end

    properties (SetAccess = {?BaseObject})
        TargetPosition
    end
    
    methods
        function obj = Picomotor(id, handle, address)
            arguments
                id {mustBeMember(id, [1, 2, 3, 4])}
                handle = []
                address = 1
            end
            obj@BaseProcessor('init', false, 'reset_fields', false)
            obj.ID = id;
            obj.NPUSBHandle = handle;
            obj.USBAddress = address;
        end
        
        function set.TargetPosition(obj, pos)
            obj.NPUSBHandle.Write(obj.USBAddress, sprintf('%d PA %d', obj.ID, pos)); %#ok<MCSUP>
        end

        function val = get.TargetPosition(obj)
            querydata = System.Text.StringBuilder(64);
            obj.NPUSBHandle.Query(obj.USBAddress, sprintf('%d PA?', obj.ID), querydata);
            val = double(string(ToString(querydata)));
        end

        function setCurrentHome(obj)
            obj.NPUSBHandle.Write(obj.USBAddress, sprintf('%d DH', obj.ID));
        end
    end

end
