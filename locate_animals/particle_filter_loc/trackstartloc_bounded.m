function [startlocation, index, info] = trackstartloc_bounded(times, timedelaysobs, timedelayserr, hydrophonesgeo, varargin)
%TRACKSTARTLOC_BOUNDED Start location of a track for the particle filter, kept inside the water.
%
%   [STARTLOCATION, INDEX] = TRACKSTARTLOC_BOUNDED(TIMES, TIMEDELAYSOBS,
%   TIMEDELAYSERR, HYDROPHONESGEO) finds where an animal was at the start
%   of a track from the time delays measured on two (or more) devices. The
%   inputs are those of the particle filter (see PARTICE_FILTER_PAM): TIMES
%   in seconds and cell arrays with one row per click and one column per
%   device. STARTLOCATION is [x y z] (m) and INDEX the row it belongs to,
%   from which the particle filter should be run. STARTLOCATION is empty
%   if no start location was found.
%
%   It does the job of TRACKSTARTLOC3, which localises the clicks in a
%   short window with an unbounded simplex search. The devices of a pair
%   are tens of metres apart and each one only measures a direction, so the
%   range comes from how much the two directions converge. When they are
%   parallel or diverge - an animal far away, or a few degrees of heading
%   error - nothing stops the simplex and it runs off to millions of
%   metres with a perfectly good fit. TRACKSTARTLOC3 then rejects the
%   window for being beyond its range limit, and with it the whole track.
%
%   Here the search is kept inside the water: below the surface, above the
%   seabed and within maxRange of the devices. A window gives a start
%   location if its best fit is good enough and is NOT pushed up against
%   the range limit, the surface or the seabed, i.e. the directions from
%   the devices cross in the water column. That is the only case in which
%   the range is really measured. The windows are tried in turn right
%   through the track until one does, and the particle filter is started
%   from there. If none does the animal is taken to be too far away to
%   localise.
%
%   The misfit is the mean squared time delay residual over the error,
%   where the error is TIMEDELAYSERR and an allowance for the heading error
%   (angleError) added in quadrature, so a misfit of about 1 is a good fit.
%
%   Name-value parameters (defaults in brackets):
%     maxRange   - largest horizontal range from the middle of the devices
%                  (m) [500]
%     minRange   - a start location closer than this to a device is taken
%                  to be held at the device and is not accepted (m). A
%                  device fits any source along its own direction, so when
%                  the directions do not cross the fit can slide down to
%                  the device itself [0 = no limit]
%     bathymetry - seabed: a struct of x, y, z meshes (z negative down), a
%                  single depth (negative), or [] for none [[]]
%     avrgTime   - length of a window (s) [2]
%     maxChi2    - largest misfit of a start location [4]
%     angleError - heading error allowed for in the misfit (deg) [5]
%     edgeFrac   - a fit beyond this fraction of maxRange is taken to be
%                  against the limit [0.95]
%     constraints - the kinds of start location accepted, see INFO
%                  [{'crossing'}]
%     clampDepth - true to search with the depth free, only the range
%                  bounded. Where the directions cross above the surface or
%                  below the seabed the start location is put at the
%                  surface or the seabed and is of kind 'surface' or
%                  'seabed': it is where the directions cross horizontally,
%                  not where they leave the water. Accept them with
%                  constraints [false]
%     maxWindows - windows tried before giving up [inf = the whole track]
%     boundTol   - a start location within this of the surface or the
%                  seabed is taken to be held there by the bound (m) [1]
%     soundSpeed - (m/s) [1500]
%     delayFunction - function handle TAU = F(X, H1, H2) predicting the
%                  time delays of hydrophone pairs (rows of H1, H2) for a
%                  source at X, e.g. ray traced propagation; [] for
%                  straight lines at soundSpeed [[]]
%
%   INFO is a struct with fields:
%     reason  - 'ok', or why there is no start location: 'no clicks on both
%               devices', 'bearings do not cross' (the fits were good but
%               held at the range limit, the surface or the seabed: the
%               animal is too far away to localise) or 'poor fit'
%     constraint - what fixes the range of the start location:
%               'crossing' - the directions from the devices cross in the
%                            water column, the only case in which the
%                            range is really measured
%               'surface', 'seabed' - the best fit is held at the surface
%                            or the seabed. The directions do not cross
%                            inside the water; the range is where they
%                            leave it, so it is a limit, not a measurement
%     windows - [index x y z chi2 range kind] of every window tried; kind
%               is 1 crossing, 2 surface, 3 seabed, 4 range limit, 5 at a
%               device (closer than minRange)
%     converge - median convergence of the horizontal directions of the
%               first two devices over the windows tried (deg). Positive
%               = they cross in front of the devices; an animal at range r
%               broadside to a baseline L converges by about L/r radians
%
%   See also TRACKSTARTLOC3, PARTICE_FILTER_PAM.

p.maxRange = 500;
p.minRange = 0;
p.bathymetry = [];
p.avrgTime = 2;
p.maxChi2 = 4;
p.angleError = 5;
p.edgeFrac = 0.95;
p.constraints = {'crossing'};
p.clampDepth = false;
p.maxWindows = inf;
p.boundTol = 1;
p.soundSpeed = 1500;
p.delayFunction = [];
for i = 1:2:numel(varargin)
    if ~isfield(p, varargin{i})
        error('trackstartloc_bounded:badParam', 'Unknown parameter "%s"', varargin{i});
    end
    p.(varargin{i}) = varargin{i+1};
end

startlocation = [];
index = [];
info.reason = 'no clicks on both devices';
info.windows = zeros(0, 7);
info.converge = NaN;
info.constraint = '';

nd = size(timedelaysobs, 2);
has = ~cellfun(@isempty, timedelaysobs);

% centre of each device and of them all
centre = nan(nd, 3);
for d = 1:nd
    r = find(has(:,d), 1);
    if ~isempty(r)
        centre(d,:) = mean(hydrophonesgeo{r,d}, 1);
    end
end
middle = mean(centre, 1, 'omitnan');

% direction of each click from its own device (plane wave), for the
% candidate start points and the convergence
dirn = cell(size(timedelaysobs));
for d = 1:nd
    for r = find(has(:,d))'
        dirn{r,d} = plane_wave(hydrophonesgeo{r,d}, timedelaysobs{r,d}, p.soundSpeed);
    end
end

ranges = logspace(1, log10(p.maxRange), 20);
opts = optimset('Display', 'off', 'TolFun', 1e-4, 'TolX', 0.05, 'MaxFunEvals', 600);
conv = zeros(0, 1);
ntried = 0;
tnext = -inf;
for ii = 1:numel(times)
    if times(ii) < tnext
        continue
    end
    rows = find(times >= times(ii) & times < times(ii) + p.avrgTime);
    % there must be detections on at least two of the devices
    if sum(any(has(rows,:), 1)) < 2
        continue
    end
    tnext = times(ii) + p.avrgTime/2; % windows overlap by half
    ntried = ntried + 1;

    D = window_data(rows, timedelaysobs, timedelayserr, hydrophonesgeo, has, p);
    fun = @(x) misfit(bound(x, middle, p), D, p.soundSpeed, p.delayFunction) + penalty(x, middle, p);

    % candidates: along the mean direction from each device
    cand = zeros(0, 3);
    u = nan(nd, 3);
    for d = 1:nd
        v = vertcat(dirn{rows(has(rows,d)), d});
        if isempty(v)
            continue
        end
        u(d,:) = mean(v, 1)/norm(mean(v, 1));
        cand = [cand; centre(d,:) + ranges'.*u(d,:)]; %#ok<AGROW>
    end
    c2 = arrayfun(@(k) fun(cand(k,:)), (1:size(cand, 1))');
    [~, order] = sort(c2);
    best = inf;
    for k = order(1:min(3, end))'
        [x, f] = fminsearch(fun, cand(k,:), opts);
        if f < best
            best = f;
            xbest = bound(x, middle, p);
        end
    end
    chi2 = misfit(xbest, D, p.soundSpeed, p.delayFunction);
    rng = norm(xbest(1:2) - middle(1:2));
    % with clampDepth the fit is where the directions cross, in or out of
    % the water: it is brought to the surface or the seabed
    zfit = xbest(3);
    if p.clampDepth
        xbest(3) = min(xbest(3), 0);
        bedfit = seabed(xbest, p);
        if ~isnan(bedfit)
            xbest(3) = max(xbest(3), bedfit);
        end
    end
    conv(end+1, 1) = convergence(u, centre); %#ok<AGROW>

    % what holds the fit where it is
    kinds = {'crossing', 'surface', 'seabed', 'range limit', 'device'};
    bed = seabed(xbest, p);
    if rng >= p.edgeFrac*p.maxRange
        kind = 4;
    elseif min(vecnorm(xbest - centre, 2, 2)) < p.minRange
        kind = 5;
    elseif (~p.clampDepth && xbest(3) > -p.boundTol) || (p.clampDepth && zfit > 0)
        kind = 2;
    elseif ~isnan(bed) && ((~p.clampDepth && xbest(3) < bed + p.boundTol) || (p.clampDepth && zfit < bed))
        kind = 3;
    else
        kind = 1;
    end
    info.windows(end+1,:) = [ii, xbest, chi2, rng, kind];

    if chi2 <= p.maxChi2 && ismember(kinds{kind}, p.constraints)
        startlocation = xbest;
        index = ii;
        info.reason = 'ok';
        info.constraint = kinds{kind};
        break
    end
    if ntried >= p.maxWindows
        break
    end
end
info.converge = median(conv, 'omitnan');
if isempty(startlocation) && ntried > 0
    if any(info.windows(:,5) <= p.maxChi2)
        info.reason = 'bearings do not cross';
    else
        info.reason = 'poor fit';
    end
end
end

%% ------------------------------------------------------------------------
function D = window_data(rows, tdobs, tderr, hydros, has, p)
% the hydrophone pairs, delays and errors of every click in a window
D.h1 = zeros(0, 3);
D.h2 = zeros(0, 3);
D.tau = zeros(0, 1);
D.err = zeros(0, 1);
for d = 1:size(tdobs, 2)
    for r = rows(has(rows,d))'
        h = hydros{r,d};
        pr = nchoosek(1:size(h, 1), 2); % PAMGuard order: 0-1, 0-2, ...
        tau = tdobs{r,d}(:);
        e = tderr{r,d}(:);
        if isscalar(e)
            e = repmat(e, size(tau));
        end
        % a heading error of angleError moves a delay by up to this much
        sep = vecnorm(h(pr(:,2),:) - h(pr(:,1),:), 2, 2);
        aperr = sep*sind(p.angleError)/p.soundSpeed;
        D.h1 = [D.h1; h(pr(:,1),:)];
        D.h2 = [D.h2; h(pr(:,2),:)];
        D.tau = [D.tau; tau];
        D.err = [D.err; hypot(e, aperr)];
    end
end
end

function c = misfit(x, D, c0, delayfun)
% mean squared time delay residual over its error. A delay is positive if
% the sound reaches the first hydrophone of the pair first.
if isempty(delayfun)
    model = (vecnorm(x - D.h2, 2, 2) - vecnorm(x - D.h1, 2, 2))/c0;
else
    model = delayfun(x, D.h1, D.h2);
end
c = mean(((D.tau - model)./D.err).^2);
end

function x = bound(x, middle, p)
% the nearest point inside the water and within maxRange
x = x(:)';
h = x(1:2) - middle(1:2);
r = norm(h);
if r > p.maxRange
    x(1:2) = middle(1:2) + h*p.maxRange/r;
end
if p.clampDepth
    return
end
x(3) = min(x(3), 0);
bed = seabed(x, p);
if ~isnan(bed)
    x(3) = max(x(3), bed);
end
end

function pen = penalty(x, middle, p)
% grows with the distance outside the bounds, to bring the simplex back
pen = 0.01*norm(x(:)' - bound(x, middle, p))^2;
end

function bed = seabed(x, p)
bed = NaN;
if isstruct(p.bathymetry)
    bed = interp2(p.bathymetry.x, p.bathymetry.y, p.bathymetry.z, x(1), x(2));
    if isnan(bed)
        bed = min(p.bathymetry.z(:));
    end
elseif ~isempty(p.bathymetry)
    bed = p.bathymetry;
end
end

function u = plane_wave(h, tau, c0)
% unit vector towards the source from the delays of one device
pr = nchoosek(1:size(h, 1), 2);
A = -(h(pr(:,2),:) - h(pr(:,1),:))/c0;
u = (A\tau(:))';
u = u/norm(u);
end

function c = convergence(u, centre)
% how much the horizontal directions of devices 1 and 2 converge (deg)
c = NaN;
if size(u, 1) < 2 || any(isnan(u(1:2,1)))
    return
end
b = atan2d(u(1:2,1), u(1:2,2));                    % bearings
az = atan2d(centre(2,1) - centre(1,1), centre(2,2) - centre(1,2));
dphi = mod(b(2) - b(1) + 180, 360) - 180;
pm = atan2d(sum(sind(b)), sum(cosd(b)));           % mean bearing
c = dphi*sign(sind(pm - az));
end
