function opt = parse_georef_args(args)
%PARSE_GEOREF_ARGS Shared option parsing for the geo referencing functions.
%
%   OPT = PARSE_GEOREF_ARGS(ARGS) parses the VARARGIN of GEO_REF_CLKS and
%   MATCH_SAMPLES into a single options struct, so that the two cannot drift
%   apart. ARGS is the raw varargin cell array.
%
%   Accepted forms:
%     - a WAVINFO struct as the first argument
%     - name/value pairs: 'EulerOffset' (or 'TimeOffset'), 'ClockSpeed',
%       'Frame', 'MatchDateTime'
%     - the legacy positional form (..., WAVINFO, EULEROFFSET, CLOCKSPEED),
%       which warns and is otherwise honoured
%
%   OPT fields: wavinfo, euleroffset, clockspeed, frame, matchdatetime.
%   matchdatetime is [] when the caller did not specify it.
%
%   Anything unrecognised is an error. Previously an unrecognised option
%   was skipped silently, which meant a mis-spelled or positional time
%   offset was dropped without any indication.
%
%   See also GEO_REF_CLKS, MATCH_SAMPLES.

opt.wavinfo       = [];
opt.euleroffset   = 0;
opt.clockspeed    = 4;
opt.frame         = 'xsens_pg_2';   % CIBBRiNA
opt.matchdatetime = [];

iArg = 0;

% optional leading wavinfo struct
if ~isempty(args) && isstruct(args{1})
    opt.wavinfo = args{1};
    iArg = 1;
end

% legacy positional form: trailing numbers meaning euleroffset, clockspeed
if numel(args) > iArg && isnumeric(args{iArg+1})
    npos = 0;
    while numel(args) > iArg && isnumeric(args{iArg+1}) && npos < 2
        iArg = iArg + 1;
        npos = npos + 1;
        if npos == 1
            opt.euleroffset = args{iArg};
        else
            opt.clockspeed = args{iArg};
        end
    end
    warning('parse_georef_args:legacyPositional', ...
        ['Positional euler offset/clock speed is deprecated - use ' ...
         '''EulerOffset'', value. Note that these positional arguments ' ...
         'used to be discarded silently and are now honoured, so results ' ...
         'will change if the offset is non zero.']);
end

while iArg < numel(args)
    iArg = iArg + 1;
    name = args{iArg};
    if ~(ischar(name) || isstring(name))
        error('parse_georef_args:badOption', ...
            'Expected an option name but got a %s.', class(name));
    end
    if iArg == numel(args)
        error('parse_georef_args:missingValue', ...
            'Option ''%s'' has no value.', name);
    end
    iArg = iArg + 1;
    switch lower(name)
        case 'clockspeed'
            opt.clockspeed = args{iArg};
        case {'euleroffset', 'timeoffset'}
            % 'TimeOffset' is what the geo_ref_clks help text has always
            % documented; 'EulerOffset' is what the code accepted.
            opt.euleroffset = args{iArg};
        case 'frame'
            opt.frame = args{iArg};
        case 'matchdatetime'
            opt.matchdatetime = args{iArg};
        otherwise
            warning('parse_georef_args:unknownOption', ...
                ['Unknown option ''' char(name) '''. Valid options are: ' ...
                 'EulerOffset (TimeOffset), ClockSpeed, Frame, MatchDateTime.']);
    end
end

end
