classdef SequenceRegistry < BaseObject
    % SequenceRegistry: Registry of acquisition sequences.

    properties (Constant)
        Zelux2Basic = makeSequence( ...
            ["Zelux", "Zelux", "Zelux", "Zelux"], ...
            ["Lattice_935", "Pattern_532", "Lattice_935", "Pattern_532"], ...
            ["Start+Acquire", "Start+Acquire", "Analysis", "Analysis"], ...
            ["", "", "", ""])
        Andor2Basic = makeSequence( ...
            ["Andor19330", "Andor19331", "Andor19330", "Andor19331", "Andor19330", "Andor19331"], ...
            ["Image", "Image", "Image", "Image", "Image", "Image"], ...
            ["Start", "Start", "Acquire", "Acquire", "Analysis", "Analysis"], ...
            ["", "", "", "", "", ""])
        Full4Basic = makeSequence( ...
            ["Zelux", "Zelux", "Zelux", "Zelux", "Andor19330", "Andor19331", "Andor19330", "Andor19331", "Andor19330", "Andor19331"], ...
            ["Lattice_935", "Pattern_532", "Lattice_935", "Pattern_532", "Image", "Image", "Image", "Image", "Image", "Image"], ...
            ["Start+Acquire", "Start+Acquire", "Analysis", "Analysis", "Start", "Start", "Acquire", "Acquire", "Analysis", "Analysis"], ...
            ["", "", "", "", "", "", "", "", "FitCenter", "FitCenter"])
        Full4Analysis = makeSequence( ...
            ["Zelux", "Zelux", "Zelux", "Zelux", "Andor19330", "Andor19331", "Andor19330", "Andor19331", "Andor19330", "Andor19331"], ...
            ["Lattice_935", "Pattern_532", "Lattice_935", "Pattern_532", "Image", "Image", "Image", "Image", "Image", "Image"], ...
            ["Start+Acquire", "Start+Acquire", "Analysis", "Analysis", "Start", "Start", "Acquire", "Acquire", "Analysis", "Analysis"], ...
            ["", "", "CalibLatR; binarize=0", "", "", "", "", "", "FitCenter; CalibLatR", "FitCenter; CalibLatO"])
        Full4AnalysisPSF = makeSequence( ...
            ["Picomotor",  "Picomotor",  "Picomotor", ...
             "Zelux",      "Zelux",      "Zelux",      "Zelux",   ...
             "Andor19330", "Andor19331", "Andor19330", "Andor19331", "Andor19330", "Andor19331"], ...
            ["LSVertical", "UpObjVertical", "MotorStatus", ...
             "Lattice_935","Pattern_532","Lattice_935","Pattern_532", ...
             "Image",      "Image",      "Image",      "Image",      "Image",      "Image"], ...
            ["Move",       "Move",       "Analysis", ...
             "Start+Acquire", "Start+Acquire", "Analysis", "Analysis", ...
             "Start",      "Start",      "Acquire",    "Acquire",    "Analysis",   "Analysis"], ...
            ["channel=1; scan=true; scan_start=0; scan_num_step=20; scan_step_size=1", ...
             "channel=[2, 3, 4]; scan=true; scan_start=0; scan_num_step=20; scan_step_size=10", ...
             "RecordMotorStatus", ...
             "",           "",           "CalibLatR; binarize=0",      "FitPSF; refine_method=COM; filter_gausswid_max=inf; verbose", ...
             "",           "",           "",            "",            "FitCenter; CalibLatR; FitPSF; verbose",      "FitCenter; CalibLatO; FitPSF; verbose"])
    end

    properties (Constant, Hidden)
        All_Projectors = "DMD"
        All_Cameras = ["Andor19330", "Andor19331", "Zelux"]
        All_PicomotorDrivers = "Picomotor"
    end

    methods (Static)
        function active_devices = getActiveDevices(sequence)
            active_devices = string(unique(sequence.Camera))';
            active_devices = active_devices(active_devices ~= "--inactive--");
        end

        function active_cameras = getActiveCameras(sequence)
            active_cameras = SequenceRegistry.getActiveDevices(sequence);
            active_cameras = active_cameras(~active_cameras.startsWith("DMD"));
            active_cameras = active_cameras(~active_cameras.startsWith("Picomotor"));
        end

        function active_projectors = getActiveProjectors(sequence)
            active_projectors = SequenceRegistry.getActiveDevices(sequence);
            active_projectors = active_projectors(active_projectors.startsWith("DMD"));
        end

        function active_sequence = getActiveSequence(sequence)
            active_sequence = sequence(sequence.Camera ~= "--inactive--" & ...
                ~(sequence.Type == "Analysis" & sequence.Note == ""), :);
        end

        function active_acquisition = getActiveAcquisition(sequence)
            active_sequence = SequenceRegistry.getActiveSequence(sequence);
            active_acquisition = active_sequence((active_sequence.Type == "Acquire") | ...
                (active_sequence.Type == "Start+Acquire"), :);
        end

        function active_analysis = getActiveAnalysis(sequence)
            active_sequence = SequenceRegistry.getActiveSequence(sequence);
            active_analysis = active_sequence(active_sequence.Type == "Analysis" & ...
                active_sequence.Note ~= "", :);
        end

        function active_projection = getActiveProjection(sequence)
            active_sequence = SequenceRegistry.getActiveSequence(sequence);
            active_projection = active_sequence(active_sequence.Type == "Project", :);
        end

        function active_motion = getActiveMotion(sequence)
            active_sequence = SequenceRegistry.getActiveSequence(sequence);
            active_motion = active_sequence(active_sequence.Type == "Move", :);
        end
    end

end

function sequence = makeSequence(cameras, labels, types, notes, empty_rows)
    arguments
        cameras = []
        labels = []
        types = []
        notes = []
        empty_rows = 2
    end
    num_command = length(cameras) + empty_rows;
    default_device = "--inactive--";
    all_devices = [SequenceRegistry.All_Cameras, SequenceRegistry.All_Projectors, SequenceRegistry.All_PicomotorDrivers, "--inactive--"];
    default_label = "";
    default_type = "Analysis";
    all_type = ["Start+Acquire", "Start", "Acquire", "Analysis", "Project", "Move"];
    default_note = "";
    Order = (1: num_command)';
    Camera = [cameras, repmat(default_device, 1, empty_rows)]';
    Camera = categorical(Camera, all_devices, 'Ordinal', true);
    Label = [labels, repmat(default_label, 1, empty_rows)]';
    Type = [types, repmat(default_type, 1, empty_rows)]';
    Type = categorical(Type, all_type, 'Ordinal', true);
    Note = [notes, repmat(default_note, 1, empty_rows)]';
    sequence =  table(Order, Camera, Label, Type, Note);
end
