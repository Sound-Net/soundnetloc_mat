function [location, hpr, chi2val, grdsurf] = grdsrch_pos_hpr(clkgeobearings, srclocations, reflocation, varargin)
%GRDSRCH_POS_HPR Fine grid search for the position and orientation of a
% platform.
%
% [LOCATION, HPR, CHI2VAL, GRDSURF] = GRDSRCH_POS_HPR(CLKGEOBEARINGS,
% SRCLOCATIONS, REFLOCATION) refines the position of a small hydrophone
% array by searching a metre spaced grid around REFLOCATION [lat, lon]
% whilst at the same time searching over the heading, pitch and roll of the
% platform. This is a five dimensional version of GRDSRCH_POS and is
% intended to be run after a coarse search has found an approximate
% location and an approximate heading has been applied to CLKGEOBEARINGS.
%
% CLKGEOBEARINGS is an [N x 2] array of [horizontal angle, slant angle] in
% RADIANS in the platform frame. SRCLOCATIONS is the corresponding [N x 3]
% list of [latitude, longitude, depth] for each click, where depth is the
% difference in depth between the platform and the source, <i>not<i> the
% absolute depth.
%
% [...] = GRDSRCH_POS_HPR(..., VARARGIN) adds extra string argument pairs:
% * 'gridlims' - two number array of the limits of the position search in
%   METRES relative to REFLOCATION. Default [-10 10].
% * 'gridspacing' - spacing of the position grid in METRES. Default 1.
% * 'headinglims', 'pitchlims', 'rolllims' - two number arrays of the
%   limits of the orientation search in DEGREES. Default [-5 5]. These are
%   the orientations passed to ROTATE_BEARINGS, so if an approximate
%   heading is already known the search should be bounded around it, e.g.
%   'headinglims', heading + [-5 5], rather than rotating CLKGEOBEARINGS by
%   the heading beforehand. Heading, pitch and roll are a single rotation
%   applied in that order, so a pitch and roll searched on top of an
%   already rotated set of bearings would not be the pitch and roll of the
%   platform.
% * 'anglestep' - step size of the orientation search in DEGREES.
%   Default 1.
% * 'searchtype' - the type of angles to use in the search, 'bearing',
%   'slant' or 'all'. Default 'all'.
% * 'errbearing', 'errslant' - the assumed angular errors in DEGREES used
%   to weight the two angle types. Defaults 5 and 3, the same as
%   ST_LOC_CHI2.
% * 'maxchi2' - chi2 values above this are clipped in GRDSURF. This only
%   affects plotting. Default inf.
% * 'pretext' - text to prepend to the progress messages.
%
% LOCATION is the best [latitude, longitude] and HPR the best [heading,
% pitch, roll] in DEGREES. CHI2VAL is the chi2 value at that solution.
% GRDSURF contains the search surfaces:
% * Xinterp, Yinterp, chi2 - the latitude, longitude and chi2 of the
%   position grid, minimised over all orientations, in the same format as
%   GRDSRCH_POS so it can be passed straight to PLOT_CHI2_SURF.
% * hprchi2 - the [heading x pitch x roll] chi2 surface minimised over all
%   positions, with the axes headings, pitches and rolls.
% * chi2all - the full [position x orientation] chi2 surface with the
%   corresponding hprgrid, latgrid and longrid.
%
% The bearing term of chi2 uses 2*(1-cos(difference)) rather than the
% squared angular difference used by ST_LOC_CHI2. The two are the same for
% small differences but the cosine form can be evaluated as a matrix
% product, which is what makes a search of this size practical.
%
% See also GRDSRCH_POS, ROTATE_BEARINGS, ST_LOC_CHI2

gridlims = [-10 10];
gridspacing = 1;
headinglims = [-5 5];
pitchlims = [-5 5];
rolllims = [-5 5];
anglestep = 1;
srchtype = 'all';
errbearing = 5;
errslant = 3;
maxchi2 = inf;
pretxt = '';

iArg = 0;
while iArg < numel(varargin)
    iArg = iArg + 1;
    switch(varargin{iArg})
        case 'gridlims'
            iArg = iArg + 1;
            gridlims = varargin{iArg};
        case 'gridspacing'
            iArg = iArg + 1;
            gridspacing = varargin{iArg};
        case 'headinglims'
            iArg = iArg + 1;
            headinglims = varargin{iArg};
        case 'pitchlims'
            iArg = iArg + 1;
            pitchlims = varargin{iArg};
        case 'rolllims'
            iArg = iArg + 1;
            rolllims = varargin{iArg};
        case 'anglestep'
            iArg = iArg + 1;
            anglestep = varargin{iArg};
        case 'searchtype'
            iArg = iArg + 1;
            srchtype = varargin{iArg};
        case 'errbearing'
            iArg = iArg + 1;
            errbearing = varargin{iArg};
        case 'errslant'
            iArg = iArg + 1;
            errslant = varargin{iArg};
        case 'maxchi2'
            iArg = iArg + 1;
            maxchi2 = varargin{iArg};
        case 'pretext'
            iArg = iArg + 1;
            pretxt = varargin{iArg};
        otherwise
            error('grdsrch_pos_hpr:badarg', ...
                'Unknown argument in position %i', iArg);
    end
end

usebearing = strcmp(srchtype, 'bearing') || strcmp(srchtype, 'all');
useslant = strcmp(srchtype, 'slant') || strcmp(srchtype, 'all');

errbearing = deg2rad(errbearing);
errslant = deg2rad(errslant);

nclk = size(clkgeobearings, 1);

%% the position grid - metres north and east of the reference location
dnorth = gridlims(1):gridspacing:gridlims(2);
deast = gridlims(1):gridspacing:gridlims(2);

latgrid = meters2LatLong(reflocation(1), reflocation(2), dnorth(:), 0);
[~, longrid] = meters2LatLong(reflocation(1), reflocation(2), 0, deast(:));

[Xinterp, Yinterp] = ndgrid(latgrid, longrid);
npos = numel(Xinterp);

%% the orientation grid
headings = headinglims(1):anglestep:headinglims(2);
pitches = pitchlims(1):anglestep:pitchlims(2);
rolls = rolllims(1):anglestep:rolllims(2);

[HH, PP, RR] = ndgrid(headings, pitches, rolls);
hprgrid = [HH(:), PP(:), RR(:)];
nhpr = size(hprgrid, 1);

%% the true angles from each grid position to each source location
% these do not depend on the orientation of the platform so are calculated
% once. [npos x nclk] arrays.
costrubear = zeros(npos, nclk*usebearing);
sintrubear = zeros(npos, nclk*usebearing);
truslant = zeros(npos, nclk*useslant);

for i = 1:npos
    [r, dx, dy] = latLong2meters(Xinterp(i), Yinterp(i), ...
        srclocations(:,1), srclocations(:,2));

    if usebearing
        trubear = atan2(dx, dy);
        costrubear(i,:) = cos(trubear);
        sintrubear(i,:) = sin(trubear);
    end

    if useslant
        truslant(i,:) = atan(srclocations(:,3)./r);
    end
end

sumtruslant2 = sum(truslant.^2, 2);

%% search over every position and orientation
% the chi2 for every combination is a set of matrix products, so the
% orientations are done in chunks to keep the arrays a sensible size
chi2 = zeros(npos, nhpr);

chunk = max(1, floor(4e6/nclk));

for k = 1:chunk:nhpr

    kindex = k:min(k+chunk-1, nhpr);

    disp([pretxt 'Running grid search: ' num2str(kindex(end)) ' of ' ...
        num2str(nhpr) ' orientations']);

    %rotate the observed angles by each orientation in this chunk
    obsbear = zeros(nclk, length(kindex));
    obsslant = zeros(nclk, length(kindex));
    for j = 1:length(kindex)
        rotangles = rotate_bearings(clkgeobearings, hprgrid(kindex(j),:));
        obsbear(:,j) = rotangles(:,1);
        obsslant(:,j) = rotangles(:,2);
    end

    chi2chunk = zeros(npos, length(kindex));

    if usebearing
        %sum of 2*(1-cos(true-observed)) over all the clicks
        chi2chunk = chi2chunk + 2*(nclk - ...
            (costrubear*cos(obsbear) + sintrubear*sin(obsbear)))/errbearing^2;
    end

    if useslant
        %sum of (true-observed)^2 over all the clicks
        chi2chunk = chi2chunk + (sumtruslant2 + sum(obsslant.^2, 1) ...
            - 2*(truslant*obsslant))/errslant^2;
    end

    chi2(:,kindex) = chi2chunk/nclk;
end

%% the best solution
[chi2val, index] = min(chi2(:));
[posindex, hprindex] = ind2sub(size(chi2), index);

location = [Xinterp(posindex), Yinterp(posindex)];
hpr = hprgrid(hprindex, :);

%% the search surfaces
chi2pos = reshape(min(chi2, [], 2), size(Xinterp));
chi2pos(chi2pos>maxchi2) = maxchi2;

grdsurf.Xinterp = Xinterp;
grdsurf.Yinterp = Yinterp;
grdsurf.chi2 = chi2pos;

grdsurf.headings = headings;
grdsurf.pitches = pitches;
grdsurf.rolls = rolls;
grdsurf.hprchi2 = reshape(min(chi2, [], 1), size(HH));

grdsurf.latgrid = latgrid;
grdsurf.longrid = longrid;
grdsurf.hprgrid = hprgrid;
grdsurf.chi2all = chi2;

end
