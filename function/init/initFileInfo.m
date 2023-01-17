function FileInfo = initFileInfo()
% FileInfo.File: cell array of file name
% FileInfo.Path: file path
% FileInfo.NumFile: number of file
% FileInfo.Var: variable name
% FileInfo.NumVar: number of variables
% FileInfo.VarTable: table of variable values for each data file

    FileInfo = getFileInfo(acquireDataPath,'*.mat','Please select Data Files');

    Answer = questdlg('Would you like to add parameter for the files?', ...
            'Variable Info', 'Yes','No','No');
    switch Answer
        case 'Yes'
            FileInfo = getVarInfo(FileInfo);
        case 'No'
            FileInfo.Var = {''};
            FileInfo.NumVar = 0;
            FileInfo.VarTable = nan(FileInfo.NumFile,0);
    end
    
end

function FileInfo = getFileInfo(DefaultPath,FileExtension,Text)

    [File,Path] = uigetfile(FileExtension,Text,DefaultPath,MultiSelect="on");
    if isnumeric(File) && File == 0
        FileInfo.File = {''};
        FileInfo.Path = DefaultPath;
        FileInfo.NumFile = 0;
    else
        if ischar(File)
            FileInfo.File = {File};
            FileInfo.Path = Path;
            FileInfo.NumFile = 1;
        else
            FileInfo.File = File;
            FileInfo.Path = Path;
            FileInfo.NumFile = numel(File);
        end
    end
end

function FileInfo = getVarInfo(FileInfo)
    
    FileInfo.Var = inputdlg({ ...
        'Enter the names of parameters (each occupies a new line):'},...
        'Parameters',[5,100],{''});
    if ~isempty(FileInfo.Var) && ~isempty(FileInfo.Var{1}) 
        FileInfo.Var = cellstr(FileInfo.Var{1});
        FileInfo.NumVar = numel(FileInfo.Var);
    else
        FileInfo.Var = {''};
        FileInfo.NumVar = 0;
    end
    
    FileInfo.VarTable = nan(FileInfo.NumFile,FileInfo.NumVar);
    if FileInfo.NumVar>0
        for i = 1:FileInfo.NumFile
            Prompt = cell(1,FileInfo.NumVar);
            for j = 1:FileInfo.NumVar
                Prompt{j} = sprintf('Value of %s for file %s', ...
                    FileInfo.Var{j},FileInfo.File{i});
            end
            FileInfo.VarTable(i,:) = cellfun(@str2double,inputdlg(Prompt,'Parameters',[1,50]));
        end
    end

end