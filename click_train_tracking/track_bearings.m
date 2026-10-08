function res = track_bearings(clktimes, bearings, varargin)
%TRACK_BEARINGS Automatically split click bearings into bearing tracks.
%
%   RES = TRACK_BEARINGS(CLKTIMES, BEARINGS) groups click bearings from a
%   single device into bearing tracks (one track per animal).
%
%   RES = TRACK_BEARINGS(CLKTIMES, BEARINGS, VERTICAL) also uses the
%   vertical angle of each click, so every stage works in two dimensions
%   (bearing x vertical angle). Animals at the same bearing but different
%   vertical angles (e.g. different ranges/depths) can then be separated.
%
%   The stages are:
%
%   0. Echo removal. A click arriving within echoWindow (default 2.5 ms) of
%      the previous focal click is flagged as an echo (surface/seabed
%      reflection with a spurious angle) and ignored in all later stages.
%      Occasionally a real click from a second animal will be removed,
%      which does little harm.
%
%   1. Fragments. The clicks are split into short time windows (default 5
%      s). Within each window a kernel density of bearing (circular) and,
%      optionally, vertical angle is computed and each density peak becomes
%      a "fragment" - a cluster of clicks from (probably) one animal with a
%      robust mean angle. This averages out the messy individual porpoise
%      click bearings.
%
%   2. Tracking. Fragments are linked across windows with a constant
%      rate Kalman filter per angle. At each window the cost of
%      associating each live track with each fragment is the normalised
%      innovation (Mahalanobis distance, summed over angles) and the
%      globally optimal assignment is found with the Hungarian algorithm
%      (MATCHPAIRS). Unmatched fragments start new tracks; tracks with no
%      fragments for longer than maxGap are terminated. Tracks with fewer
%      than minTrackFrags fragments are discarded.
%
%   2b. Stitching. Tracks broken by gaps or missed gates are re-joined:
%      the end of each track is compared with the start of every track
%      beginning up to stitchGap s later (or overlapping by up to
%      stitchOverlap s). Angles are extrapolated across the gap at each
%      track's end/start rate and pairs are chosen with the Hungarian
%      algorithm. Repeated until no more joins are made.
%
%   2c. Mop-up. Unassigned fragments that the tracker missed are picked
%      up. (a) Each unassigned fragment within mopGap s of a track (or
%      inside its time span) is added to the track if it lies within
%      mopTol/mopTolV of the track's curve (extrapolated at the track's
%      end rate beyond its ends), repeated so tracks can grow fragment by
%      fragment. (b) The remaining unassigned fragments are run through the
%      tracker again, allowing gaps of up to mopGap s, to form new tracks.
%      (c) The new tracks are stitched and extended as in 2b and (a).
%
%   3. Click grouping. Every click (including those rejected as noise in
%      stage 1) is assigned to the track whose smoothed angles at the
%      click time are closest, provided it is inside the ellipse set by
%      clickTol (bearing) and clickTolV (vertical).
%
%   CLKTIMES - click times (MATLAB datenum), N x 1.
%   BEARINGS - click bearings in DEGREES, N x 1. Either -180..180 or
%              0..360; outputs use the same convention.
%   VERTICAL - (optional) click vertical angles in DEGREES, N x 1.
%
%   Name-value parameters (defaults in brackets). Parameters ending in V
%   are the vertical angle equivalents and are only used with VERTICAL.
%     echoWindow    - clicks this soon after a focal click are echoes
%                     (s); 0 turns echo removal off [0.0025]
%     windowLen     - fragment window length in seconds [5]
%     binWidth      - density bin width in degrees [1]
%     kdeSigma      - bearing density smoothing sigma (deg) [5]
%     kdeSigmaV     - vertical density smoothing sigma (deg) [5]
%     peakFrac      - min peak height as fraction of window max [0.2]
%     peakMinSep    - min bearing separation between peaks (deg) [15]
%     peakMinSepV   - min vertical separation between peaks (deg) [15]
%     fragTol       - max bearing distance of a click from its peak [10]
%     fragTolV      - max vertical distance of a click from its peak [20]
%     minFragClicks - min clicks for a fragment [5]
%     measSigmaMin  - min fragment bearing measurement sigma (deg) [3]
%     measSigmaMinV - min fragment vertical measurement sigma (deg) [5]
%     processNoise  - bearing Kalman process noise, deg^2/s^3 [0.05]
%     processNoiseV - vertical Kalman process noise, deg^2/s^3 [0.02]
%     rateSigma0    - initial bearing rate uncertainty (deg/s) [2]
%     rateSigma0V   - initial vertical rate uncertainty (deg/s) [1]
%     gateChi2      - Mahalanobis gate (squared) [9 bearing only, 11.8
%                     with vertical, i.e. ~3 sigma]
%     maxGateDeg    - absolute bearing innovation gate (deg) [20]
%     maxGateDegV   - absolute vertical innovation gate (deg) [25]
%     maxGap        - max time without a fragment before a track ends (s) [30]
%     dupMaxFrags   - a live track with this many fragments or fewer that
%                     is close to another live track is merged into it [2]
%     minTrackFrags - min fragments for a confirmed track [3]
%     stitchGap     - max gap between tracks to stitch (s) [60]
%     stitchOverlap - max time overlap between tracks to stitch (s) [10]
%     stitchTol     - bearing tolerance for stitching (deg) [20]
%     stitchTolV    - vertical tolerance for stitching (deg) [20]
%     stitchTolRate - extra stitch tolerance per second of gap (deg/s) [0.2]
%     maxStitchRate - max bearing rate used to extrapolate (deg/s) [2]
%     maxStitchRateV- max vertical rate used to extrapolate (deg/s) [1]
%     mopUp         - run the mop-up stage [true]
%     mopGap        - max time from a track to mop up a fragment (s) [60]
%     mopTol        - bearing tolerance for mopping up fragments (deg) [15]
%     mopTolV       - vertical tolerance for mopping up fragments (deg) [20]
%     smoothFrags   - moving median span for the track curves [3]
%     clickTol      - max click bearing distance from track (deg) [10]
%     clickTolV     - max click vertical distance from track (deg) [25]
%     clickPad      - time a track extends beyond its first/last
%                     fragment when grouping clicks (s) [windowLen]
%
%   RES is a struct with fields:
%     params      - parameters used
%     useVertical - true if vertical angles were used
%     t0          - datenum of time zero (first click)
%     frags       - struct of fragment vectors: t (s), tnum (datenum),
%                   bearing, sd, vertical, sdV, n, win, track (0 =
%                   unassigned), clickIdx
%     tracks      - struct array: id, t, tnum, bearing (smoothed),
%                   bearingRaw, vertical (smoothed), verticalRaw, fragIdx,
%                   rate, rateV (deg/s), nClicks
%     clickTrack  - N x 1 track id for each click (0 = unassigned or echo)
%     isEcho      - N x 1 true for clicks flagged as echoes
%
%   See also MATCHPAIRS, PLOT_BEARING_TRACKS

vertical = [];
if ~isempty(varargin) && isnumeric(varargin{1})
    vertical = varargin{1};
    varargin(1) = [];
end

p = struct( ...
    'echoWindow',    0.0025, ...
    'windowLen',     5, ...
    'binWidth',      1, ...
    'kdeSigma',      5, ...
    'kdeSigmaV',     5, ...
    'peakFrac',      0.2, ...
    'peakMinSep',    15, ...
    'peakMinSepV',   15, ...
    'fragTol',       10, ...
    'fragTolV',      20, ...
    'minFragClicks', 5, ...
    'measSigmaMin',  3, ...
    'measSigmaMinV', 5, ...
    'processNoise',  0.05, ...
    'processNoiseV', 0.02, ...
    'rateSigma0',    2, ...
    'rateSigma0V',   1, ...
    'gateChi2',      [], ...
    'maxGateDeg',    20, ...
    'maxGateDegV',   25, ...
    'maxGap',        30, ...
    'dupMaxFrags',   2, ...
    'minTrackFrags', 3, ...
    'stitchGap',     60, ...
    'stitchOverlap', 10, ...
    'stitchTol',     20, ...
    'stitchTolV',    20, ...
    'stitchTolRate', 0.2, ...
    'maxStitchRate', 2, ...
    'maxStitchRateV', 1, ...
    'mopUp',         true, ...
    'mopGap',        60, ...
    'mopTol',        15, ...
    'mopTolV',       20, ...
    'smoothFrags',   3, ...
    'clickTol',      10, ...
    'clickTolV',     25, ...
    'clickPad',      []);

for i = 1:2:numel(varargin)
    if ~isfield(p, varargin{i})
        error('track_bearings:badParam', 'Unknown parameter "%s"', varargin{i});
    end
    p.(varargin{i}) = varargin{i+1};
end

useV = ~isempty(vertical);
p.useV = useV;
if isempty(p.clickPad)
    p.clickPad = p.windowLen;
end
if isempty(p.gateChi2)
    p.gateChi2 = 9 + 2.8*useV; % ~99.7% for 1 or 2 degrees of freedom
end

clktimes = clktimes(:);
bearings = bearings(:);
if numel(clktimes) ~= numel(bearings)
    error('track_bearings:size', 'clktimes and bearings must be the same length');
end
if useV
    vertical = vertical(:);
    if numel(vertical) ~= numel(bearings)
        error('track_bearings:size', 'vertical must be the same length as bearings');
    end
else
    vertical = zeros(size(bearings)); % contributes nothing to any distance
end

% keep the input bearing convention for the outputs
is360 = all(bearings(~isnan(bearings)) >= 0);

valid = ~isnan(bearings) & ~isnan(vertical) & ~isnan(clktimes);
t0 = min(clktimes(valid));

%% Stage 0: echo removal
isEcho = false(size(clktimes));
isEcho(valid) = find_echoes(clktimes(valid), p.echoWindow);
valid = valid & ~isEcho;

t = (clktimes - t0)*86400; % seconds
b = wrapdeg(bearings);
v = vertical;

%% Stage 1: fragments
frags = find_fragments(t, b, v, valid, p);

%% Stage 2: link fragments into tracks
fragTrack = link_fragments(frags, p);

%% Stage 2b: stitch broken tracks
[fragTrack, nTracks] = stitch_tracks(frags, fragTrack, p);

%% Stage 2c: mop up fragments the tracker missed
if p.mopUp
    [fragTrack, nTracks] = mop_up(frags, fragTrack, p);
end
frags.track = fragTrack;

%% Stage 3: track curves and click grouping
tracks = repmat(struct('id', [], 't', [], 'tnum', [], 'bearing', [], ...
    'bearingRaw', [], 'vertical', [], 'verticalRaw', [], 'fragIdx', [], ...
    'rate', [], 'rateV', [], 'nClicks', []), nTracks, 1);

nClk = numel(t);
dist = inf(nClk, nTracks);

for k = 1:nTracks
    [idx, tf, bs, vs] = track_curve(frags, fragTrack, k, p);

    tracks(k).id = k;
    tracks(k).t = tf;
    tracks(k).tnum = t0 + tf/86400;
    tracks(k).bearingRaw = outwrap(frags.bearing(idx), is360);
    tracks(k).bearing = outwrap(bs, is360);
    tracks(k).fragIdx = idx;
    tracks(k).rate = fit_rate(tf, bs);
    if useV
        tracks(k).verticalRaw = frags.vertical(idx);
        tracks(k).vertical = vs;
        tracks(k).rateV = fit_rate(tf, vs);
    end

    % normalised distance of every click in the track's span from the curve
    inspan = valid & t >= tf(1) - p.clickPad & t <= tf(end) + p.clickPad;
    tc = min(max(t(inspan), tf(1)), tf(end)); % hold ends flat
    bi = interp_curve(tf, bs, tc);
    vi = interp_curve(tf, vs, tc);
    db = wrapdeg(b(inspan) - bi)/p.clickTol;
    dv = (v(inspan) - vi)/p.clickTolV;
    dist(inspan, k) = sqrt(db.^2 + dv.^2);
end

clickTrack = zeros(nClk, 1);
if nTracks > 0
    [dmin, kmin] = min(dist, [], 2);
    ok = dmin <= 1;
    clickTrack(ok) = kmin(ok);
end
for k = 1:nTracks
    tracks(k).nClicks = sum(clickTrack == k);
end

frags.bearing = outwrap(frags.bearing, is360);
frags.tnum = t0 + frags.t/86400;
if ~useV
    frags = rmfield(frags, {'vertical', 'sdV'});
end

res.params = p;
res.useVertical = useV;
res.t0 = t0;
res.frags = frags;
res.tracks = tracks;
res.clickTrack = clickTrack;
res.isEcho = isEcho;

end

%% ------------------------------------------------------------------------
function isEcho = find_echoes(clktimes, echoWindow)
% Flag clicks that arrive within echoWindow seconds of the previous focal
% (non-echo) click. Measuring from the focal click rather than the
% previous click stops a train of echoes being chained together.
isEcho = false(size(clktimes));
if echoWindow <= 0
    return
end
[ts, order] = sort(clktimes*86400);
lastFocal = -inf;
for i = 1:numel(ts)
    if ts(i) - lastFocal <= echoWindow
        isEcho(order(i)) = true;
    else
        lastFocal = ts(i);
    end
end
end

%% ------------------------------------------------------------------------
function frags = find_fragments(t, b, v, valid, p)
% Split clicks into time windows and find clusters in each window using a
% kernel density estimate - circular in bearing and, if used, linear in
% vertical angle.

edges = -180:p.binWidth:180;
centres = edges(1:end-1) + p.binWidth/2;
nb = numel(centres);

% circular Gaussian kernel centred on bin 1
d = (0:nb-1)*p.binWidth;
d = min(d, 360 - d);
G = fft(exp(-0.5*(d/p.kdeSigma).^2));

if p.useV
    edgesV = -90:p.binWidth:90;
    kx = -ceil(3*p.kdeSigmaV):p.binWidth:ceil(3*p.kdeSigmaV);
    kv = exp(-0.5*(kx/p.kdeSigmaV).^2)';
else
    edgesV = [-1 1]; % a single vertical bin
    kv = 1;
end
centresV = edgesV(1:end-1) + diff(edgesV)/2;

win = nan(size(t));
win(valid) = floor(t(valid)/p.windowLen);
wins = unique(win(valid));

F.t = []; F.bearing = []; F.sd = []; F.vertical = []; F.sdV = [];
F.n = []; F.win = []; F.clickIdx = {};

for w = wins(:)'
    ci = find(win == w);
    if numel(ci) < p.minFragClicks
        continue
    end
    bw = b(ci);
    vw = min(max(v(ci), edgesV(1)), edgesV(end));

    % density: rows = vertical, columns = bearing
    h = histcounts2(vw, bw, edgesV, edges);
    dens = real(ifft(fft(h, [], 2).*G, [], 2));
    dens = conv2(kv, 1, dens, 'same');

    % local maxima: circular in bearing, padded in vertical
    pad = -inf(1, nb);
    up = [pad; dens(1:end-1, :)];
    dn = [dens(2:end, :); pad];
    ispk = dens >= p.peakFrac*max(dens(:)) & dens > 0;
    for sh = {circshift(dens, 1, 2), circshift(dens, -1, 2), up, dn, ...
            circshift(up, 1, 2), circshift(up, -1, 2), ...
            circshift(dn, 1, 2), circshift(dn, -1, 2)}
        ispk = ispk & dens >= sh{1};
    end
    [iv, ib] = find(ispk);
    if isempty(iv)
        continue
    end

    % suppress peaks close to a higher peak
    pkh = dens(sub2ind(size(dens), iv, ib));
    [~, order] = sort(pkh, 'descend');
    pkb = centres(ib(order))';
    pkv = centresV(iv(order))';
    keep = true(size(pkb));
    for i = 2:numel(pkb)
        hi = find(keep(1:i-1));
        dd = hypot(wrapdeg(pkb(i) - pkb(hi))/p.peakMinSep, ...
            (pkv(i) - pkv(hi))/p.peakMinSepV);
        if any(dd < 1)
            keep(i) = false;
        end
    end
    pkb = pkb(keep);
    pkv = pkv(keep);

    % assign clicks to nearest peak (normalised distance)
    dd = hypot(wrapdeg(bw - pkb')/p.fragTol, (v(ci) - pkv')/p.fragTolV);
    [dmin, ipk] = min(dd, [], 2);

    for j = 1:numel(pkb)
        sel = ipk == j & dmin <= 1;
        if sum(sel) < p.minFragClicks
            continue
        end
        [mb, sd] = circstats(bw(sel));
        F.t(end+1, 1) = mean(t(ci(sel)));
        F.bearing(end+1, 1) = mb;
        F.sd(end+1, 1) = sd;
        F.vertical(end+1, 1) = mean(v(ci(sel)));
        F.sdV(end+1, 1) = std(v(ci(sel)));
        F.n(end+1, 1) = sum(sel);
        F.win(end+1, 1) = w;
        F.clickIdx{end+1, 1} = ci(sel);
    end
end

frags = F;
end

%% ------------------------------------------------------------------------
function fragTrack = link_fragments(frags, p)
% Link fragments into tracks using constant rate Kalman filters (one for
% bearing, one for vertical angle) and Hungarian (matchpairs) assignment
% at each window.

nF = numel(frags.t);
fragTrack = zeros(nF, 1);

bigCost = 1e6;
costUnmatched = p.gateChi2/2; % matched pair must cost < 2*costUnmatched

% track state: x/P bearing filter, xv/Pv vertical filter
T = struct('x', {}, 'P', {}, 'xv', {}, 'Pv', {}, 'tLast', {}, ...
    'alive', {}, 'frags', {});

wins = unique(frags.win);
for w = wins(:)'
    fi = find(frags.win == w);
    tNow = mean(frags.t(fi));

    % terminate tracks that have gone quiet
    for k = 1:numel(T)
        if T(k).alive && tNow - T(k).tLast > p.maxGap
            T(k).alive = false;
        end
    end
    act = find([T.alive]);

    % cost matrix: live tracks x fragments
    C = bigCost*ones(numel(act), numel(fi));
    for a = 1:numel(act)
        k = act(a);
        for j = 1:numel(fi)
            [d2, ok] = innovation(T(k), frags, fi(j), p);
            if ok
                C(a, j) = d2;
            end
        end
    end

    if isempty(act)
        M = zeros(0, 2);
        uF = (1:numel(fi))';
    else
        [M, ~, uF] = matchpairs(C, costUnmatched);
        % guard against a gated-out pair being forced into a match
        bad = C(sub2ind(size(C), M(:,1), M(:,2))) >= bigCost;
        uF = [uF; M(bad, 2)];
        M = M(~bad, :);
    end

    % update matched tracks
    for m = 1:size(M, 1)
        k = act(M(m, 1));
        f = fi(M(m, 2));
        dt = frags.t(f) - T(k).tLast;
        [T(k).x, T(k).P] = kf_step(T(k).x, T(k).P, dt, frags.bearing(f), ...
            meas_var(frags, f, p, false), p.processNoise, true);
        if p.useV
            [T(k).xv, T(k).Pv] = kf_step(T(k).xv, T(k).Pv, dt, frags.vertical(f), ...
                meas_var(frags, f, p, true), p.processNoiseV, false);
        end
        T(k).tLast = frags.t(f);
        T(k).frags(end+1) = f;
    end

    % start new tracks from unmatched fragments
    for j = uF(:)'
        f = fi(j);
        k = numel(T) + 1;
        T(k).x = [frags.bearing(f); 0];
        T(k).P = diag([meas_var(frags, f, p, false), p.rateSigma0^2]);
        if p.useV
            T(k).xv = [frags.vertical(f); 0];
            T(k).Pv = diag([meas_var(frags, f, p, true), p.rateSigma0V^2]);
        end
        T(k).tLast = frags.t(f);
        T(k).alive = true;
        T(k).frags = f;
    end

    % merge duplicate tracks: a stray fragment near an existing track can
    % start a new track that then takes it in turns with the original to
    % steal the same animal's fragments. If a young track (<= dupMaxFrags
    % fragments) is close to another live track it is merged into it,
    % keeping its fragments and the most recently updated filter state.
    % Established tracks are never merged, so crossing animals survive.
    act = find([T.alive]);
    for i = 1:numel(act)
        for j = i+1:numel(act)
            ki = act(i); kj = act(j);
            if ~T(ki).alive || ~T(kj).alive
                continue
            end
            dd = abs(wrapdeg(T(ki).x(1) - T(kj).x(1)))/p.peakMinSep;
            if p.useV
                dd = hypot(dd, (T(ki).xv(1) - T(kj).xv(1))/p.peakMinSepV);
            end
            nMin = min(numel(T(ki).frags), numel(T(kj).frags));
            if dd < 1 && nMin <= p.dupMaxFrags
                if numel(T(ki).frags) >= numel(T(kj).frags)
                    T = merge_tracks(T, ki, kj);
                else
                    T = merge_tracks(T, kj, ki);
                end
            end
        end
    end
end

% confirm tracks with enough fragments
nTracks = 0;
for k = 1:numel(T)
    if numel(T(k).frags) >= p.minTrackFrags
        nTracks = nTracks + 1;
        fragTrack(T(k).frags) = nTracks;
    end
end

end

function T = merge_tracks(T, keep, drop)
% merge track drop into track keep; the most recently updated filter
% state is kept and drop is ended with no fragments
if T(drop).tLast > T(keep).tLast
    T(keep).x = T(drop).x;
    T(keep).P = T(drop).P;
    T(keep).xv = T(drop).xv;
    T(keep).Pv = T(drop).Pv;
    T(keep).tLast = T(drop).tLast;
end
T(keep).frags = [T(keep).frags T(drop).frags];
T(drop).frags = [];
T(drop).alive = false;
end

function [d2, ok] = innovation(trk, frags, f, p)
% squared Mahalanobis distance of fragment f from the track prediction,
% summed over bearing and (if used) vertical angle, plus gate check
dt = frags.t(f) - trk.tLast;

[xp, Pp] = kf_predict(trk.x, trk.P, dt, p.processNoise, true);
S = Pp(1,1) + meas_var(frags, f, p, false);
e = wrapdeg(frags.bearing(f) - xp(1));
d2 = e^2/S;
ok = abs(e) <= p.maxGateDeg;

if p.useV
    [xp, Pp] = kf_predict(trk.xv, trk.Pv, dt, p.processNoiseV, false);
    S = Pp(1,1) + meas_var(frags, f, p, true);
    e = frags.vertical(f) - xp(1);
    d2 = d2 + e^2/S;
    ok = ok && abs(e) <= p.maxGateDegV;
end

ok = ok && d2 <= p.gateChi2;
end

%% ------------------------------------------------------------------------
function [fragTrack, nTracks] = stitch_tracks(frags, fragTrack, p)
% Join track ends to later track starts when the angles line up across
% the gap. Uses Hungarian assignment so each track end joins at most one
% track start. Tracks are renumbered in order of start time.

for pass = 1:10
    n = max([fragTrack; 0]);
    if n < 2
        break
    end

    ts = zeros(n, 1); te = ts;
    bStart = ts; bEnd = ts; rStart = ts; rEnd = ts;
    vStart = ts; vEnd = ts; rvStart = ts; rvEnd = ts;
    curves = cell(n, 3);
    for k = 1:n
        [~, tf, bs, vs] = track_curve(frags, fragTrack, k, p);
        ts(k) = tf(1);
        te(k) = tf(end);
        bStart(k) = bs(1);
        bEnd(k) = bs(end);
        rStart(k) = end_rate(tf, bs, true, p.maxStitchRate);
        rEnd(k) = end_rate(tf, bs, false, p.maxStitchRate);
        vStart(k) = vs(1);
        vEnd(k) = vs(end);
        rvStart(k) = end_rate(tf, vs, true, p.maxStitchRateV);
        rvEnd(k) = end_rate(tf, vs, false, p.maxStitchRateV);
        curves(k, :) = {tf, bs, vs};
    end

    C = 1e6*ones(n);
    for a = 1:n
        for c = 1:n
            gap = ts(c) - te(a);
            if a == c || gap > p.stitchGap || gap < -p.stitchOverlap || ts(c) <= ts(a)
                continue
            end
            if gap >= 0
                % meet in the middle of the gap
                db = wrapdeg((bEnd(a) + rEnd(a)*gap/2) - (bStart(c) - rStart(c)*gap/2));
                dv = (vEnd(a) + rvEnd(a)*gap/2) - (vStart(c) - rvStart(c)*gap/2);
            else
                % overlap: compare track a's curve at the start of track c
                db = wrapdeg(interp_curve(curves{a, 1}, curves{a, 2}, ts(c), 'extrap') - bStart(c));
                dv = interp_curve(curves{a, 1}, curves{a, 3}, ts(c), 'extrap') - vStart(c);
            end
            db = abs(db)/(p.stitchTol + p.stitchTolRate*max(gap, 0));
            dv = abs(dv)/(p.stitchTolV + p.stitchTolRate*max(gap, 0));
            if db <= 1 && dv <= 1
                C(a, c) = sqrt((db^2 + p.useV*dv^2)/(1 + p.useV));
            end
        end
    end

    M = matchpairs(C, 0.5); % joins cost < 1
    M = M(C(sub2ind(size(C), M(:,1), M(:,2))) < 1, :);
    if isempty(M)
        break
    end

    lab = (1:n)';
    for m = 1:size(M, 1)
        lab(lab == lab(M(m, 2))) = lab(M(m, 1));
    end
    assigned = fragTrack > 0;
    fragTrack(assigned) = lab(fragTrack(assigned));
    [~, ~, fragTrack(assigned)] = unique(fragTrack(assigned));
end

% renumber in order of start time
n = max([fragTrack; 0]);
ts = zeros(n, 1);
for k = 1:n
    ts(k) = min(frags.t(fragTrack == k));
end
[~, order] = sort(ts);
newlab = zeros(n, 1);
newlab(order) = 1:n;
assigned = fragTrack > 0;
fragTrack(assigned) = newlab(fragTrack(assigned));
nTracks = n;

end

%% ------------------------------------------------------------------------
function [fragTrack, nTracks] = mop_up(frags, fragTrack, p)
% Pick up unassigned fragments the tracker missed: extend existing tracks,
% build new tracks from the leftovers with a longer allowed gap, then
% stitch and extend again.

fragTrack = extend_tracks(frags, fragTrack, p);

% new tracks from leftover fragments, allowing longer gaps
left = find(fragTrack == 0);
if numel(left) >= p.minTrackFrags
    sub = subset_frags(frags, left);
    p2 = p;
    p2.maxGap = p.mopGap;
    newTrack = link_fragments(sub, p2);
    nOld = max([fragTrack; 0]);
    isNew = newTrack > 0;
    fragTrack(left(isNew)) = nOld + newTrack(isNew);
end

[fragTrack, nTracks] = stitch_tracks(frags, fragTrack, p);
fragTrack = extend_tracks(frags, fragTrack, p);
end

function fragTrack = extend_tracks(frags, fragTrack, p)
% Add unassigned fragments to the track whose curve they fit best. Only
% one fragment per track per window. Repeated so tracks grow outwards one
% fragment at a time with updated curves and end rates.

for pass = 1:50
    n = max([fragTrack; 0]);
    un = find(fragTrack == 0);
    if n == 0 || isempty(un)
        break
    end

    cand = zeros(0, 3); % fragment, track, normalised distance
    for k = 1:n
        [idx, tf, bs, vs] = track_curve(frags, fragTrack, k, p);
        ts = tf(1); te = tf(end);
        rb = [end_rate(tf, bs, true, p.maxStitchRate), end_rate(tf, bs, false, p.maxStitchRate)];
        rv = [end_rate(tf, vs, true, p.maxStitchRateV), end_rate(tf, vs, false, p.maxStitchRateV)];
        usedWin = frags.win(idx);

        for f = un(:)'
            tq = frags.t(f);
            if tq < ts - p.mopGap || tq > te + p.mopGap || any(usedWin == frags.win(f))
                continue
            end
            if tq < ts
                gap = ts - tq;
                bp = bs(1) - rb(1)*gap;
                vp = vs(1) - rv(1)*gap;
            elseif tq > te
                gap = tq - te;
                bp = bs(end) + rb(2)*gap;
                vp = vs(end) + rv(2)*gap;
            else
                gap = 0;
                bp = interp_curve(tf, bs, tq);
                vp = interp_curve(tf, vs, tq);
            end
            db = abs(wrapdeg(frags.bearing(f) - bp))/(p.mopTol + p.stitchTolRate*gap);
            dv = 0;
            if p.useV
                dv = abs(frags.vertical(f) - vp)/(p.mopTolV + p.stitchTolRate*gap);
            end
            d = hypot(db, dv);
            if d <= 1
                cand(end+1, :) = [f, k, d]; %#ok<AGROW>
            end
        end
    end
    if isempty(cand)
        break
    end

    % accept best candidates first: each fragment once, each track once
    % per window
    [~, order] = sort(cand(:, 3));
    cand = cand(order, :);
    taken = false(size(fragTrack));
    trackWin = zeros(0, 2);
    for c = 1:size(cand, 1)
        f = cand(c, 1); k = cand(c, 2);
        if taken(f) || any(trackWin(:, 1) == k & trackWin(:, 2) == frags.win(f))
            continue
        end
        fragTrack(f) = k;
        taken(f) = true;
        trackWin(end+1, :) = [k, frags.win(f)]; %#ok<AGROW>
    end
end
end

function sub = subset_frags(frags, idx)
% fragments idx as a new fragment struct
sub = frags;
for fn = fieldnames(frags)'
    if size(frags.(fn{1}), 1) == numel(frags.t)
        sub.(fn{1}) = frags.(fn{1})(idx, :);
    end
end
end

function r = end_rate(tf, y, atStart, maxRate)
% rate of change over the first/last few fragments of a track, clamped
nf = min(numel(tf), 5);
if nf < 2
    r = 0;
    return
end
if atStart
    sel = 1:nf;
else
    sel = numel(tf)-nf+1:numel(tf);
end
tt = tf(sel) - tf(sel(1));
if tt(end) == tt(1)
    r = 0;
    return
end
pf = polyfit(tt, y(sel), 1);
r = max(min(pf(1), maxRate), -maxRate);
end

function [idx, tf, bs, vs] = track_curve(frags, fragTrack, k, p)
% time-sorted fragments of track k with smoothed (unwrapped) bearing and
% vertical angle curves
idx = find(fragTrack == k);
[tf, order] = sort(frags.t(idx));
idx = idx(order);
bu = rad2deg(unwrap(deg2rad(frags.bearing(idx))));
bs = movmedian(bu, p.smoothFrags);
if p.useV
    vs = movmedian(frags.vertical(idx), p.smoothFrags);
else
    vs = zeros(size(bs));
end
end

function yi = interp_curve(tf, y, ti, extrap)
% interpolate a track curve, tolerating single/duplicate fragment times
[tu, iu] = unique(tf);
if numel(tu) < 2
    yi = repmat(y(1), size(ti));
elseif nargin > 3
    yi = interp1(tu, y(iu), ti, 'linear', extrap);
else
    yi = interp1(tu, y(iu), ti, 'linear');
end
end

function r = fit_rate(tf, y)
if numel(tf) > 1 && tf(end) > tf(1)
    pf = polyfit(tf - tf(1), y, 1);
    r = pf(1);
else
    r = 0;
end
end

%% ------------------------------------------------------------------------
function [xp, Pp] = kf_predict(x, P, dt, q, circ)
F = [1 dt; 0 1];
Q = q*[dt^3/3 dt^2/2; dt^2/2 dt];
xp = F*x;
if circ
    xp(1) = wrapdeg(xp(1));
end
Pp = F*P*F' + Q;
end

function [x, P] = kf_step(x, P, dt, z, R, q, circ)
% predict + update of a constant rate filter; circ wraps the angle
H = [1 0];
[xp, Pp] = kf_predict(x, P, dt, q, circ);
S = H*Pp*H' + R;
K = Pp*H'/S;
e = z - xp(1);
if circ
    e = wrapdeg(e);
end
x = xp + K*e;
if circ
    x(1) = wrapdeg(x(1));
end
P = (eye(2) - K*H)*Pp;
end

function R = meas_var(frags, f, p, vert)
% fragment measurement variance: standard error of the mean, floored
% because click angle errors are correlated (e.g. wrong correlation peak)
if vert
    R = max(p.measSigmaMinV, frags.sdV(f)/sqrt(frags.n(f)))^2;
else
    R = max(p.measSigmaMin, frags.sd(f)/sqrt(frags.n(f)))^2;
end
end

function [mb, sd] = circstats(b)
% circular mean and standard deviation in degrees
s = mean(sind(b));
c = mean(cosd(b));
mb = atan2d(s, c);
Rbar = min(hypot(s, c), 1);
sd = rad2deg(sqrt(-2*log(max(Rbar, eps))));
end

function x = wrapdeg(x)
% wrap to [-180 180)
x = mod(x + 180, 360) - 180;
end

function x = outwrap(x, is360)
if is360
    x = mod(x, 360);
else
    x = wrapdeg(x);
end
end
