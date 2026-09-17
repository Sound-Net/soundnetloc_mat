function [georefhydros, indexnotfound] = geo_ref_hydrophones(clicks,...
    eulerangles, wavinfo, hydrophones, euleroffset, clockspeed, frametype)
%GEO_REF_HYDROPHONES Gets geo referenced hydrophone positions for each click
%
%   [GEOREFHYDROPHONES, INDEXNOTFOUND] = GEO_REF_HYDROPHONES(CLICKS,
%   EULERANGLES, WAVINFO, HYDROPHONES) calculates the geo referenced
%   hydrophone positions for every CLICK structure based on euler angles and
%   the default HYDROPHONES. HYDROPHONES is the co-ordinates of hydrophones
%   (a single synced hydrophone array) relative to the sensor package frame
%   of reference, i.e. (0,0,0) is the sensor package. Matching euler angles
%   and clicks is slightly involved because the euler angle times are not in
%   sync with the click times due to the way wav files are time stamped by
%   SoundTraps. Therefore sample numbers have to be used to sync the angles
%   and clicks using WAVINFO, a record of the samples recorded on the
%   SoundTrap from the WAVSAMPLES(FOLDER) function. EULERANGLES is an array
%   of [datenum, st clock sample, roll, pitch, heading] with angles in
%   DEGREES. GEOREFHYDROPHONES is a cell array with the rotated (x,y,z) of
%   each hydrophone for each click. INDEXNOTFOUND returns the index of
%   clicks for which no angle data could be found.
%
%   GEO_REF_HYDROPHONES(..., EULEROFFSET) adds an offset to the euler angle
%   times in days. Use this when UTC time is mixed on the SoundTrap, e.g.
%   1/24 is a one hour offset for BST and UTC time.
%
%   GEO_REF_HYDROPHONES(..., EULEROFFSET, CLOCKSPEED) specifies the number
%   of channels used. The default is 4. CLOCKSPEED affects the clock
%   frequency on the SoundTrap, e.g. 4 means the clock is 4*samplerate.
%
%   GEO_REF_HYDROPHONES(..., EULEROFFSET, CLOCKSPEED, FRAMETYPE) specifies
%   the co-ordinate frame. The default is 'xsens_pg_TD' because PAMGuard is
%   referenced to bearing = 0 degrees at x = 0 and y = inf rather than the
%   usual vice versa. Time delays never lie though...
%
%   NOTE the default frame here is NOT the frame GEO_REF_CLKS uses for
%   bearings, and the two do not agree - see GEO_REF_FRAME. Take care if the
%   bearings and these hydrophone positions are consumed together.
%
%   See also GEO_REF_FRAME, GEO_REF_CLKS, GEO_REF_VEC.

if nargin < 5
    euleroffset = 0;
end

if nargin < 6
    clockspeed = 4;
end

if nargin < 7
    frametype = 'xsens_pg_TD';
end

SR = 384000;            % SoundTrap sample rate
CLOCKMULT = 4;          % the legacy matching threshold below is in ST clock
                        % samples, not wav samples, unlike GEO_REF_CLKS
MAXMATCHSECS = 0.5;     % furthest a click may be from its euler angle
SLOPSECS = 60;          % euler angles kept either side of the click times
MAXREPORTED = 5;        % unmatched clicks to report individually

frame = geo_ref_frame(frametype);

frame

% if clicks are empty return nothing
if (isempty(clicks))
    georefhydros = {};
    indexnotfound = [];
    disp('geo_ref_hydrophones: there are no clicks to geo reference??')
    return;
end

% calculate the absolute samples
[abssmplsclk, abssmpleseul] = match_samples_legacy(clicks, eulerangles, wavinfo,...
    euleroffset, clockspeed);

% now that we have the correct absolute samples for both clicks and euler
% angles we can time align properly.

% first lets get rid of euler angles that are not within the desired time
% range. This can seriously speed up the matching process.
timemin = min([clicks.date]);
timemax = max([clicks.date]);
intimerange = (eulerangles(:,1)+euleroffset) >= (timemin-SLOPSECS/60/60/24) & ...
              (eulerangles(:,1)+euleroffset) <  (timemax+SLOPSECS/60/60/24);

%filter the abs samples and euler angles.
abssmpleseul_filt = abssmpleseul(intimerange);
eulerdata = eulerangles(intimerange,:);

nclicks = length(clicks);
nhydros = size(hydrophones,1);

% cell array containing the unique co-ordinates for each hydrophone
georefhydros = cell(nclicks,1);
eulangles_clks = zeros(nclicks, 3);

% match every click to its closest euler angle in one go
[matchidx, matchdist] = nearest_sample(abssmpleseul_filt, abssmplsclk(:,1));
notfound = matchdist > SR*CLOCKMULT*MAXMATCHSECS;
indexnotfound = find(notfound)';
nreported = 0;

for i = 1:nclicks

    if (mod(i,100)==0)
        disp(['Geo-referencing hydrophone positions ' num2str(i) ' of ' num2str(nclicks)])
    end

    if notfound(i)
        nreported = nreported + 1;
        if nreported <= MAXREPORTED
            disp(['There does not seem to be any matching angle data to geo ref hydrophones??' ...
                num2str(matchdist(i)/SR)])
        end
        continue;
    end

    eulangles_clks(i,:) = eulerdata(matchidx(i),3:5);

    % only the rotation matrix is used here, so the localisation angles
    % passed in are irrelevant - they used to be the click's own raw
    % angles, which was misleading now that GEO_REF_VEC takes a bearing.
    [~, rotm] = geo_ref_vec([0 0], ...
        deg2rad(eulangles_clks(i,:)), frame);

    %Also rotate hydrophones
    hydrophones_rot = zeros(nhydros, 3);
    for j = 1:nhydros
        hydrophones_rot(j,:) = (rotm*hydrophones(j,:)')';
    end

    georefhydros{i} = hydrophones_rot;
end

if ~isempty(indexnotfound)
    disp(['geo_ref_hydrophones: no angle data for ' num2str(numel(indexnotfound)) ...
        ' of ' num2str(nclicks) ' clicks.'])
end

end
