function assoc = associate_tracks(dev, varargin)
%ASSOCIATE_TRACKS Associate bearing tracks between two devices.
%
%   ASSOC = ASSOCIATE_TRACKS(DEV) works out which bearing tracks on one
%   device come from the same animal as bearing tracks on a second device.
%   DEV is a 2 element struct array, one per device, with fields:
%       clktimes - click times (datenum), N x 1, as passed to TRACK_BEARINGS
%       res      - output of TRACK_BEARINGS for those clicks
%       location - device position [latitude longitude] in decimal degrees
%
%   The association runs in four steps:
%
%   1. Clock offset. A comb filter between the two devices' (non-echo)
%      click times finds the clock offset (FIND_TIME_OFFSET). Device 2
%      times are corrected to device 1 for every later step.
%
%   2. Bearing crossing. For every pair of tracks that overlap in time,
%      the heading (horizontal) bearings of the two tracks are compared at
%      each fragment time in the overlap. Slant angles are NOT used. For
%      each time the crossing error is the smallest change to either
%      bearing that makes the two bearing lines cross within maxRange of
%      both devices, in front of both. This allows for the bearings of a
%      distant animal being almost parallel. A pair passes if at least
%      crossFrac of its times have a crossing error <= crossTol.
%
%   3. Click timing. Clicks from the same animal arrive at the two devices
%      within the baseline travel time of each other (baseline/c), so after
%      the clock correction their time differences line up on a narrow
%      ridge, allowing it to drift slowly as the animal moves. The largest
%      number of click pairs on any such ridge (+/- delayTol) is compared
%      with the number expected by chance for the pair's click rates. A
%      pair passes if the chance probability (corrected for the number of
%      ridges searched) is below timingP and at least minMatches clicks
%      match.
%
%   4. Assignment. Pairs passing steps 2 and 3 are candidates. Any
%      remaining ambiguity (a track with more than one candidate) is
%      resolved with the Hungarian algorithm (MATCHPAIRS) using the
%      median crossing error as the cost. Unmatched tracks that are still
%      candidates of an associated track are then added to that
%      association, as long as they do not overlap in time with a track
%      already in the association on the same device. This lets one long
%      track on one device associate with several shorter track fragments
%      on the other.
%
%   Associations are labelled in time order with two letters (AA, AB, ...)
%   and the tracks in an association are numbered in time order on each
%   device, giving codes such as PP0001AA01 (species, event number,
%   association, fragment).
%
%   Name-value parameters (defaults in brackets):
%     speciesCode  - species code for the first two characters ['PP']
%     eventNumber  - broad event number for characters 3-6 [1]
%     offset       - clock offset in s; empty to estimate it [[]]
%     maxOffset    - largest clock offset searched (s) [10]
%     soundSpeed   - speed of sound (m/s) [1500]
%     maxRange     - max detection range for bearing crossings (m) [1000]
%     crossTol     - max crossing error (deg) [10]
%     crossFrac    - min fraction of times that must cross [0.5]
%     trackPad     - time each track is extended when checking overlap,
%                    in s [half the fragment window]
%     delayMargin  - extra delay allowed beyond baseline/c for clock drift
%                    and timing error (s) [0.02]
%     delayTol     - half width of the click timing ridge (s) [0.002]
%     maxDelayRate - max rate of change of the ridge delay (s/s) [0.001]
%     minMatches   - min matched clicks on the timing ridge [5]
%     timingP      - max chance probability for the timing ridge [0.01]
%     useTiming    - require the click timing check [true]
%
%   ASSOC is a struct with fields:
%     offset     - clock offset (s); device 2 time - offset = device 1 time
%     comb       - comb filter output (see FIND_TIME_OFFSET)
%     pairs      - struct array of every overlapping track pair with the
%                  crossing and timing statistics and pass/fail flags
%     groups     - struct array of associations: letters, tracks{d}
%                  (track ids on device d, time order), codes{d}
%     trackCode  - {1 x 2} cell, per device a cellstr code for each track
%                  ('' = not associated)
%     trackGroup - {1 x 2} cell, per device the association index of each
%                  track (0 = not associated)
%     xy         - device positions in local metres (east, north) [2 x 2]
%     origin     - [lat lon] of the local coordinate origin (device 1)
%     params     - parameters used
%
%   See also FIND_TIME_OFFSET, TRACK_BEARINGS, WRITE_TRACK_EVENTS,
%   PLOT_TRACK_ASSOCIATION, MATCHPAIRS

if numel(dev) ~= 2
    error('associate_tracks:devices', 'Exactly two devices are supported');
end

p = struct( ...
    'speciesCode',  'PP', ...
    'eventNumber',  1, ...
    'offset',       [], ...
    'maxOffset',    10, ...
    'soundSpeed',   1500, ...
    'maxRange',     1000, ...
    'crossTol',     10, ...
    'crossFrac',    0.5, ...
    'trackPad',     [], ...
    'delayMargin',  0.02, ...
    'delayTol',     0.002, ...
    'maxDelayRate', 0.001, ...
    'minMatches',   5, ...
    'timingP',      0.01, ...
    'useTiming',    true);
for i = 1:2:numel(varargin)
    if ~isfield(p, varargin{i})
        error('associate_tracks:badParam', 'Unknown parameter "%s"', varargin{i});
    end
    p.(varargin{i}) = varargin{i+1};
end
if isempty(p.trackPad)
    p.trackPad = dev(1).res.params.windowLen/2;
end

%% device positions in local metres (flat earth; devices are close)
origin = dev(1).location;
xy = zeros(2, 2);
for d = 1:2
    xy(d, :) = ll2xy(dev(d).location, origin);
end
baseline = norm(xy(2,:) - xy(1,:));
maxDelay = baseline/p.soundSpeed + p.delayMargin;

%% 1. clock offset from a comb filter between the click times
focal1 = dev(1).clktimes(~dev(1).res.isEcho);
focal2 = dev(2).clktimes(~dev(2).res.isEcho);
[offset, comb] = find_time_offset(focal1, focal2, 'maxOffset', p.maxOffset, ...
    'smoothWin', 2*baseline/p.soundSpeed + 0.005);
if ~isempty(p.offset)
    offset = p.offset; % user override
end

% common time base: seconds since T0, device 2 corrected to device 1
T0 = min(dev(1).clktimes);
tsec = @(tnum, d) (tnum - T0)*86400 - (d == 2)*offset;

trk = cell(1, 2);
clkT = cell(1, 2);
for d = 1:2
    clkT{d} = tsec(dev(d).clktimes(:), d);
    tr = dev(d).res.tracks;
    trk{d} = struct('t', {}, 'b', {}, 'span', {}, 'clicks', {});
    for k = 1:numel(tr)
        trk{d}(k).t = tsec(tr(k).tnum(:), d);
        trk{d}(k).b = rad2deg(unwrap(deg2rad(tr(k).bearing(:))));
        trk{d}(k).span = [trk{d}(k).t(1) - p.trackPad, trk{d}(k).t(end) + p.trackPad];
        trk{d}(k).clicks = find(dev(d).res.clickTrack == k);
    end
end
n1 = numel(trk{1});
n2 = numel(trk{2});

%% 2 & 3. crossing and click timing for every overlapping pair
pairs = struct('i', {}, 'j', {}, 'overlap', {}, 'crossErr', {}, 'crossFrac', {}, ...
    'crossXY', {}, 'xy', {}, 'nPairs', {}, 'nMatch', {}, 'expected', {}, ...
    'pval', {}, 'delay', {}, 'delayRate', {}, 'crossOK', {}, 'timingOK', {}, ...
    'candidate', {});

for i = 1:n1
    for j = 1:n2
        A = trk{1}(i);
        B = trk{2}(j);
        ov = [max(A.span(1), B.span(1)), min(A.span(2), B.span(2))];
        if ov(2) <= ov(1)
            continue
        end

        % bearings of both tracks at every fragment time in the overlap
        tq = unique([A.t; B.t]);
        tq = tq(tq >= ov(1) & tq <= ov(2));
        if isempty(tq)
            tq = mean(ov);
        end
        bA = hold_interp(A.t, A.b, tq);
        bB = hold_interp(B.t, B.b, tq);
        [err, X] = crossing_error(xy(1,:), xy(2,:), bA, bB, p.maxRange);

        % click timing within the overlap
        ca = clkT{1}(A.clicks);
        cb = clkT{2}(B.clicks);
        ca = ca(ca >= ov(1) & ca <= ov(2));
        cb = cb(cb >= ov(1) & cb <= ov(2));
        tm = timing_ridge(ca, cb, maxDelay, p);

        q = numel(pairs) + 1;
        pairs(q).i = i;
        pairs(q).j = j;
        pairs(q).overlap = ov;
        pairs(q).crossErr = median(err);
        pairs(q).crossFrac = mean(err <= p.crossTol);
        pairs(q).xy = X;
        pairs(q).crossXY = median(X, 1, 'omitnan');
        pairs(q).nPairs = tm.nPairs;
        pairs(q).nMatch = tm.nMatch;
        pairs(q).expected = tm.expected;
        pairs(q).pval = tm.pval;
        pairs(q).delay = tm.delay;
        pairs(q).delayRate = tm.rate;
        pairs(q).crossOK = pairs(q).crossFrac >= p.crossFrac;
        pairs(q).timingOK = tm.nMatch >= p.minMatches && tm.pval <= p.timingP;
        pairs(q).candidate = pairs(q).crossOK && (pairs(q).timingOK || ~p.useTiming);
    end
end

%% 4. assignment
bigCost = 1e6;
C = bigCost*ones(n1, n2);
for q = 1:numel(pairs)
    if pairs(q).candidate
        C(pairs(q).i, pairs(q).j) = pairs(q).crossErr;
    end
end

groups = struct('tracks', {}, 'letters', {}, 'codes', {});
trackGroup = {zeros(n1, 1), zeros(n2, 1)};
if n1 > 0 && n2 > 0
    % unmatched cost well above any crossing error so every candidate that
    % can be matched is; the Hungarian algorithm then picks the set of
    % matches with the lowest total crossing error
    M = matchpairs(C, 1e3);
    M = M(C(sub2ind(size(C), M(:,1), M(:,2))) < bigCost, :);
    for m = 1:size(M, 1)
        g = numel(groups) + 1;
        groups(g).tracks = {M(m,1), M(m,2)};
        trackGroup{1}(M(m,1)) = g;
        trackGroup{2}(M(m,2)) = g;
    end

    % add unmatched candidate tracks to the association of their best
    % partner if they don't overlap a track already in it on their device
    changed = true;
    while changed
        changed = false;
        for d = 1:2
            o = 3 - d; % other device
            for k = find(trackGroup{d} == 0)'
                if d == 1
                    cost = C(k, :);
                else
                    cost = C(:, k)';
                end
                [cs, order] = sort(cost);
                order = order(cs < bigCost);
                for partner = order
                    g = trackGroup{o}(partner);
                    if g == 0
                        continue
                    end
                    clash = false;
                    for kk = groups(g).tracks{d}
                        if spans_overlap(trk{d}(k).span, trk{d}(kk).span)
                            clash = true;
                        end
                    end
                    if ~clash
                        groups(g).tracks{d}(end+1) = k;
                        trackGroup{d}(k) = g;
                        changed = true;
                        break
                    end
                end
            end
        end
    end
end

%% label associations in time order: PP0001AA01
gStart = zeros(numel(groups), 1);
for g = 1:numel(groups)
    s = inf;
    for d = 1:2
        for k = groups(g).tracks{d}
            s = min(s, trk{d}(k).t(1));
        end
    end
    gStart(g) = s;
end
[~, order] = sort(gStart);
groups = groups(order);
newIdx = zeros(numel(groups), 1);
newIdx(order) = 1:numel(groups);

trackCode = {repmat({''}, n1, 1), repmat({''}, n2, 1)};
for d = 1:2
    trackGroup{d}(trackGroup{d} > 0) = newIdx(trackGroup{d}(trackGroup{d} > 0));
end
for g = 1:numel(groups)
    groups(g).letters = group_letters(g);
    for d = 1:2
        ks = groups(g).tracks{d};
        [~, o] = sort(arrayfun(@(k) trk{d}(k).t(1), ks));
        ks = ks(o);
        groups(g).tracks{d} = ks;
        groups(g).codes{d} = cell(1, numel(ks));
        for f = 1:numel(ks)
            code = sprintf('%s%04d%s%02d', p.speciesCode, p.eventNumber, ...
                groups(g).letters, f);
            groups(g).codes{d}{f} = code;
            trackCode{d}{ks(f)} = code;
        end
    end
end

assoc.offset = offset;
assoc.comb = comb;
assoc.pairs = pairs;
assoc.groups = groups;
assoc.trackCode = trackCode;
assoc.trackGroup = trackGroup;
assoc.xy = xy;
assoc.origin = origin;
assoc.baseline = baseline;
assoc.T0 = T0;
assoc.params = p;

end

%% ------------------------------------------------------------------------
function [err, X] = crossing_error(pA, pB, bA, bB, maxRange)
% Smallest change (deg) to either bearing that makes the bearing lines
% from pA and pB cross within maxRange of both devices, in front of both.
% X is the best crossing point for each time (local metres).
r = linspace(1, maxRange, 500)';
n = numel(bA);
err = inf(n, 1);
X = nan(n, 2);
for s = 1:2
    if s == 1
        p0 = pA; p1 = pB; b0 = bA; b1 = bB;
    else
        p0 = pB; p1 = pA; b0 = bB; b1 = bA;
    end
    % points along the bearing line from p0 and the bearing to them from p1
    ex = p0(1) + r*sind(b0(:)');
    ny = p0(2) + r*cosd(b0(:)');
    az = atan2d(ex - p1(1), ny - p1(2));
    e = abs(wrapdeg(b1(:)' - az));
    e(hypot(ex - p1(1), ny - p1(2)) > maxRange) = inf;
    [emin, ir] = min(e, [], 1);
    better = emin(:) < err;
    err(better) = emin(better);
    idx = sub2ind(size(ex), ir(better), find(better)');
    X(better, :) = [ex(idx)', ny(idx)'];
end
end

function tm = timing_ridge(ca, cb, maxDelay, p)
% Find the ridge of click time differences cb - ca, allowing the delay to
% drift linearly, and test it against chance.
tm = struct('nPairs', 0, 'nMatch', 0, 'expected', 0, 'pval', 1, ...
    'delay', NaN, 'rate', NaN);
if isempty(ca) || isempty(cb)
    return
end
ca = sort(ca);
cb = sort(cb);

% all pairs within +/- maxDelay
dt = cell(numel(ca), 1);
tt = cell(numel(ca), 1);
lo = 1;
hi = 0;
for i = 1:numel(ca)
    while lo <= numel(cb) && cb(lo) < ca(i) - maxDelay
        lo = lo + 1;
    end
    while hi < numel(cb) && cb(hi+1) <= ca(i) + maxDelay
        hi = hi + 1;
    end
    dt{i} = cb(lo:hi) - ca(i);
    tt{i} = repmat(ca(i), hi - lo + 1, 1);
end
dt = vertcat(dt{:});
tt = vertcat(tt{:});
tm.nPairs = numel(dt);
if tm.nPairs == 0
    return
end

% search delay ridges with a linear drift: delay = d0 + rate*(t - tmid)
binW = 0.001;
w = 2*p.delayTol;
rates = -p.maxDelayRate:p.maxDelayRate/10:p.maxDelayRate;
tmid = mean(tt);
best = 0;
for rr = rates
    e = dt - rr*(tt - tmid);
    edges = -maxDelay - p.maxDelayRate*max(abs(tt - tmid)) - binW : binW : ...
        maxDelay + p.maxDelayRate*max(abs(tt - tmid)) + binW;
    c = movsum(histcounts(e, edges), max(1, round(w/binW)));
    [mx, im] = max(c);
    if mx > best
        best = mx;
        tm.delay = edges(im) + binW/2;
        tm.rate = rr;
    end
end

% chance: pairs spread evenly over the +/- maxDelay window
tm.nMatch = best;
tm.expected = tm.nPairs*w/(2*maxDelay);
nTrials = numel(rates)*ceil(2*maxDelay/w);
pOne = gammainc(tm.expected, best); % P(Poisson(expected) >= best)
tm.pval = min(1, nTrials*pOne);
end

function yi = hold_interp(t, y, ti)
% interpolate a track curve, holding the end values flat
if numel(t) < 2
    yi = repmat(y(1), size(ti));
    return
end
[t, iu] = unique(t);
y = y(iu);
ti = min(max(ti, t(1)), t(end));
yi = interp1(t, y, ti, 'linear');
end

function tf = spans_overlap(a, b)
tf = a(1) < b(2) && b(1) < a(2);
end

function s = group_letters(g)
% 1 -> AA, 2 -> AB, ... 26 -> AZ, 27 -> BA
g = g - 1;
s = [char('A' + floor(g/26)), char('A' + mod(g, 26))];
end

function v = ll2xy(ll, origin)
% [lat lon] to local [east north] metres (flat earth)
R = 6371000;
v = [deg2rad(ll(2) - origin(2))*R*cosd(origin(1)), deg2rad(ll(1) - origin(1))*R];
end

function x = wrapdeg(x)
x = mod(x + 180, 360) - 180;
end
