% Modified from MATLAB built-in function to draw filled circles
function h = viscircles2(varargin)

varargin = matlab.images.internal.stringToChar(varargin);

[ax, centers, radii, numCircles, options] = parseInputs(varargin{:});

if isempty(centers)
    h = [];
    return;
end

isHoldOn = ishold(ax);
hold(ax,'on');
cObj = onCleanup(@()preserveHold(isHoldOn,ax)); % Preserve original hold state

thetaResolution = 2; 
theta=(0:thetaResolution:360)'*pi/180;

x = radii' .* cos(theta);
x = x + (centers(:,1))';
x_nonan = x;
x = cat(1,x,nan(1,numCircles));
x = x(:);
y = radii' .* sin(theta);
y = y + (centers(:,2))';
y_nonan = y;
y = cat(1,y,nan(1,numCircles));
y = y(:);

% Create hggroup object that will contain the two circles as children
h = hggroup('Parent', ax);

if options.EnhanceVisibility
    % Draw the thicker background white circle
        
    thickEdgeColor = 'w';    
    thickLineWidth = options.LineWidth + 1;
    if (strcmpi(options.LineStyle,'none'))
        thickLineStyle = 'none';
    else
        thickLineStyle = '-';
    end

    line(x,y,'Parent',h, ...
        'Color',thickEdgeColor, ...
        'LineWidth',thickLineWidth, ...
        'LineStyle',thickLineStyle);
    
end

% Fill the circles
if options.Filled && isnumeric(options.FillColor)
    fill(x_nonan, y_nonan, options.FillColor, 'Parent', h, ...
        'LineStyle', 'none', 'HitTest', false)
else
    % Draw the thinner foreground colored circle
    line(x,y,'Parent',h, ...
       'Color',options.Color, ...
       'LineWidth',options.LineWidth, ...
       'LineStyle',options.LineStyle, 'HitTest',false);
end

end

% -------------------------------------------------------------------------

function [ax, centers, radii, numCircles, options] = parseInputs(varargin)

narginchk(2, 15);

needNewAxes = 0;

first_string = min(find(cellfun(@ischar, varargin), 1, 'first'));
if isempty(first_string)
    first_string = length(varargin) + 1;
end

if first_string == 3
    % viscircles(centers, radii)    
    needNewAxes = 1;   
    centers = varargin{1};
    radii = varargin{2};
    
elseif first_string == 4
    % viscircles(ax, centers, radii)
    ax = varargin{1};
    ax = validateAxes(ax);
    
    centers = varargin{2};
    radii = varargin{3};
    
else
    error(message('images:validate:invalidSyntax'))
end

% Handle remaining name-value pair parsing
name_value_pairs = varargin(first_string:end);

num_pairs = numel(name_value_pairs);
if (rem(num_pairs, 2) ~= 0)
    error(message('images:validate:missingParameterValue'));
end

% Do not change the order of argument names listed below
args_names = {'Color','LineWidth','LineStyle','EnhanceVisibility','Filled', 'FillColor'};
arg_default_values = {'red', 2, '-', true, false, [1, 0, 0]};

% Set default parameter values
for i = 1: numel(args_names)
    options.(args_names{i}) = arg_default_values{i};
end

% Support for older arguments - do not change the order of argument names listed below
args_names = cat(2,args_names, {'EdgeColor', 'DrawBackgroundCircle'});

for i = 1:2:num_pairs
    arg = name_value_pairs{i};
    if ischar(arg)        
        idx = find(strncmpi(arg, args_names, numel(arg)));
        if isempty(idx)
            error(message('images:validate:unknownInputString', arg))
        elseif numel(idx) > 1
            error(message('images:validate:ambiguousInputString', arg))
        elseif numel(idx) == 1
            if(idx == 7) % If 'EdgeColor' is specified
                idx = 1; % Map to 'Color' 
            elseif(idx == 8) % If 'DrawBackgroundCircle' is specified
                idx = 4; % Map to 'EnhanceVisibility'
            end
            options.(args_names{idx}) = name_value_pairs{i+1};
        end    
    else
        error(message('images:validate:mustBeString')); 
    end
end

% Validate parameter values. Let LINE do the validation for EdgeColor,
% LineStyle and LineWidth.
[centers, radii] = validateCentersAndRadii(centers, radii, first_string); 
numCircles = size(centers,1);

options.EnhanceVisibility = validateEnhanceVisibility( ...
    options.EnhanceVisibility);

% If required, create new axes after parsing
if(needNewAxes)    
    ax = gca;
end

end

% -------------------------------------------------------------------------

function preserveHold(wasHoldOn,ax)
% Function for preserving hold behavior on exit
if ~wasHoldOn
    hold(ax,'off');
end

end

function ax = validateAxes(ax)

if ~ishghandle(ax)
    error(message('images:validate:invalidAxes','AX'))
end

objType = get(ax,'type');
if ~strcmp(objType,'axes')
    error(message('images:validate:invalidAxes','AX'))
end

end

function [centers, radii] = validateCentersAndRadii(centers, radii, ...
                                                    first_string)

if(~isempty(centers))
    validateattributes(centers,{'numeric'},{'nonsparse','real', ...
        'ncols',2}, mfilename,'centers',first_string-2);
    validateattributes(radii,{'numeric'},{'nonsparse','real','nonnegative', ...
        'vector'}, mfilename,'radii',first_string-1);
    
    if(~isscalar(radii))
        if(size(centers,1) ~= length(radii))
            error(message('images:validate:unequalNumberOfRows','CENTERS','RADII'))
        end
    end
    centers = double(centers);
    radii   = double(radii(:)); % Convert to a column vector
end

end

function doEnhanceVisibility = validateEnhanceVisibility(doEnhanceVisibility)

if ~(islogical(doEnhanceVisibility) || isnumeric(doEnhanceVisibility)) ...
        || ~isscalar(doEnhanceVisibility)
    error(message('images:validate:invalidLogicalParam', ...
        'EnhanceVisibility', 'VISCIRCLES', 'EnhanceVisibility'))
end

doEnhanceVisibility = logical(doEnhanceVisibility);

end

%   Copyright 2011-2023 The MathWorks, Inc.
 
%   'EdgeColor'
%       <a href="matlab:doc('ColorSpec')">ColorSpec</a>
%       Specifies the color of the circle edges.
% 
%   'DrawBackgroundCircle'
%       Specifies whether or not to draw the contrasting background circle
%       below the colored circle. Setting the value to 'true' draws the
%       background circle and setting it to 'false' does not draw the
%       background circle. Default value is 'true'.




