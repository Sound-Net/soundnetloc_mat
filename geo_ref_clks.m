function [anglesgeo, abssmplsclk, abssmpleseul, indexnotfound] = geo_ref_clks(clicks,...
    eulerangles, varargin)
%GEO_REF_CLKS Geo references clicks using euler angles.
%
%   [ANGLESGEO, ABSSMPLSCLK, ABSSMPLSEUL, INDEXNOTFOUND] =
%   GEO_REF_CLKS(CLICKS, EULERANGLES) calculates the geo referenced
%   localisation angles for every CLICK structure. CLICKS is an input array
%   of click structures in the usual format and EULERANGLES is an array of
%   EULER angles with [datenum, st clock sample, roll, pitch, heading] with
%   angles in DEGREES. ANGLESGEO are the geo referenced localisation angles
%   [sampletime, bearing, slant angle] with angles in DEGREES. ABSSMPLSCLK
%   is the absolute sample number of all the clicks and ABSSMPLSEUL is the
%   absolute sample number of all the EULERANGLES. INDEXNOTFOUND is an
%   index of clicks for which no euler angle could be found. Note the data
%   must be processed with zeropad selected for this to work.
%
%   GEO_REF_CLKS(CLICKS, EULERANGLES, WAVINFO). If SoundTrap data has been
%   processed without zero padding then it is best to match times based on
%   samples. Angles are synced with clicks using WAVINFO, a record of the
%   samples recorded on the SoundTrap from the WAVSAMPLES(FOLDER) function.
%   This must include ALL sud or wav files recorded on the SoundTrap during
%   the deployment period, and must refer to NON zero fill drop out
%   samples. Absolute sample number references the total samples since the
%   SoundTrap was switched on and does NOT include zero fill drop outs.
%
%   GEO_REF_CLKS(..., 'TimeOffset', EULEROFFSET) adds an offset to the euler
%   angle times in days. Use this when UTC time is mixed on the SoundTrap,
%   e.g. 1/24 is a one hour offset for BST and UTC time. 'EulerOffset' is
%   accepted as a synonym.
%
%   GEO_REF_CLKS(..., 'Frame', FRAME) specifies how angles are converted
%   from relative to the array to true angles relative to north. This
%   depends on how the hydrophones are arranged in PAMGuard's array
%   manager. See GEO_REF_FRAME for the available frames. The default is
%   'xsens_pg_2' (CIBBRiNA project, post 2024); 'xsens_pg' is the DEFRA
%   project, i.e. pre 2024.
%
%   GEO_REF_CLKS(..., 'ClockSpeed', CLOCKSPEED) specifies the number of
%   channels used. The default is 4. CLOCKSPEED affects the clock frequency
%   on the SoundTrap, e.g. 4 means the clock is 4*samplerate.
%
%   See also GEO_REF_FRAME, GEO_REF_VEC, MATCH_SAMPLES, CLKSTRUCT2BEARINGS.

SR = 384000;            % SoundTrap sample rate
MAXMATCHSECS = 0.5;     % furthest a click may be from its euler angle
MAXREPORTED = 5;        % unmatched clicks to report individually

opt = parse_georef_args(varargin);

frame = geo_ref_frame(opt.frame);


% if clicks are empty return nothing
if (isempty(clicks))
    anglesgeo = [];
    abssmplsclk = [];
    abssmpleseul = [];
    indexnotfound = [];
    disp('geo_ref_clks: there are no clicks to geo reference??')
    return;
end

% calculate the absolute samples
matchargs = {};
if ~isempty(opt.wavinfo)
    matchargs{end+1} = opt.wavinfo;
end
matchargs = [matchargs, {'EulerOffset', opt.euleroffset, ...
    'ClockSpeed', opt.clockspeed}];
if ~isempty(opt.matchdatetime)
    matchargs = [matchargs, {'MatchDateTime', opt.matchdatetime}];
end

[abssmplsclk, abssmpleseul] = match_samples(clicks, eulerangles, matchargs{:});

% convert the raw angle pairs held in the binary files into PAMGuard
% bearings and slant angles, in DEGREES - column 2 is the bearing measured
% clockwise from +y and column 3 the slant angle, positive upwards. This is
% the same conversion, and the same numbers, as the bearings plotted
% everywhere else, so the geo referencing now starts from the angles that
% PAMGuard itself would show rather than from the raw file values.
clickbearings = clkstruct2bearings(clicks);

% now that we have the correct absolute samples for both clicks and euler
% angles we can time align properly.

% first lets get rid of euler angles that are outside the click times. This
% can seriously speed up the matching process.
timemin = min([clicks.date]) - 2/60/60/24;
timemax = max([clicks.date]) + 2/60/60/24;
intimerange = (eulerangles(:,1)+opt.euleroffset) >= timemin & ...
              (eulerangles(:,1)+opt.euleroffset) <  timemax;

%filter the abs samples and euler angles.
abssmpleseul_filt = abssmpleseul(intimerange);
eulerdata = eulerangles(intimerange,:);

nclicks = length(clicks);
anglesgeo = zeros(nclicks, 3);
eulangles_clks = zeros(nclicks, 3);

% match every click to its closest euler angle in one go
[matchidx, matchdist] = nearest_sample(abssmpleseul_filt, abssmplsclk(:,1));
notfound = matchdist > SR*MAXMATCHSECS;
indexnotfound = find(notfound)';
nreported = 0;

for i = 1:nclicks

    if (mod(i,100)==0)
        disp(['Geo-referencing click bearings ' num2str(i) ' of ' num2str(nclicks)])
    end

    anglesgeo(i,1) = abssmplsclk(i,1);

    if notfound(i)
        %only report the first few - a bad time offset makes every click
        %fail and the old code printed a line for each one
        nreported = nreported + 1;
        if nreported <= MAXREPORTED
            disp(['There does not seem to be any matching angle data?? ' ...
                num2str(matchdist(i)/SR) '  ' datestr(clicks(i).date)])
        end
        continue;
    end

    eulangles_clks(i,:) = eulerdata(matchidx(i),3:5);

    loc_vec_rot = geo_ref_vec(deg2rad(clickbearings(i,2:3)), ...
        deg2rad(eulangles_clks(i,:)), frame);

    %add geo referenced angles. These should be relative to north.
    [anglesgeo(i,2), anglesgeo(i,3)] = locvec2angles(loc_vec_rot);

    %The vector transformation handles combining the loc and sensor angles
    %well but we can still have an offset in the horizontal bearings. The
    %offset depends on the position of the hydrophones on the device and
    %how they have been set in PAMGuard. Both the offset and the sign are
    %properties of the frame - see GEO_REF_FRAME.
    anglesgeo(i,2) = frame.bearingsign * ...
        rad2deg(wrapToPi(anglesgeo(i,2) + frame.horzoffset));

    anglesgeo(i,3) = rad2deg(anglesgeo(i,3));

end

if ~isempty(indexnotfound)
    disp(['geo_ref_clks: no angle data within ' num2str(MAXMATCHSECS) ...
        's for ' num2str(numel(indexnotfound)) ' of ' num2str(nclicks) ...
        ' clicks. Check the euler angle time offset if this is unexpected.'])
end

end
