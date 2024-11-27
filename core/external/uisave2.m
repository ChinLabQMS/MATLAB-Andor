function uisave2(variables, filename, fig, format)
%UISAVE GUI Helper function for SAVE  
% Copyright 1984-2023 The MathWorks, Inc.

% Check for Swing capability if web UI is disabled
import matlab.internal.capability.Capability;
if ~matlab.ui.internal.dialog.FileDialogHelper.isWebUI()
    Capability.require(Capability.Swing);
end

variables = convertStringsToChars(variables);
filename = convertStringsToChars(filename);

if nargin > 2
else
    fig = gcf();
end

save_v7 = true;
if nargin > 3
    format = convertStringsToChars(format);
    if isequal(format, '-v7.3')
        save_v7 = false;
    end
end

if ~iscellstr(variables)
    variables = cellstr(variables);
end
whooutput = evalin('caller','who','');
missing_variables = setdiff(variables, whooutput);
if ~isempty(missing_variables)
    errordlg([getString(message('MATLAB:uistring:filedialogs:DialogTheseVariablesNotFound')) sprintf('\n    ') sprintf('%s   ',missing_variables{:})]);
    return;
end

filters = {'*.mat','MAT-files (*.mat)'};
seed = filename;

% convert input string cell array into a quoted single string like this
% 'a','b','c' where a, b, and c are variable names
variables = sprintf('''%s'',',variables{:});
% trim trailing comma
variables = variables(1:end - 1);

[fn,pn,~] = uiputfile(filters, getString(message('MATLAB:uistring:filedialogs:SaveWorkspaceVariables')), seed);

if ~isequal(fn,0) % fn will be zero if user hits cancel
    % quote the variables string for eval
    fn = strrep(fullfile(pn,fn), '''', '''''');
    
    % do save and throw errordlg on error
    try
        d = uiprogressdlg(fig, 'Title', 'Please Wait', ...
            'Message', 'Saving dataset to file...', ...
            'Indeterminate','on');
        if save_v7
            evalin('caller', ['save(''' fn  ''', ' variables ');']);
            info = sprintf("Dataset saved as '%s'", fn);
        else
            evalin('caller', ['save(''' fn  ''', ' variables ', ''-v7.3'');']);
            info = sprintf("Dataset saved as '%s' in v7.3 format", fn);
        end
        disp(info)
        close(d)
    catch ex
        errordlg(ex.getReport('basic', 'hyperlinks', 'off')); 
    end
end

