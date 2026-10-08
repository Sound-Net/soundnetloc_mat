function enc = find_encounters(t, varargin)
%FIND_ENCOUNTERS Split click times into encounters.
%
%   ENC = FIND_ENCOUNTERS(T) groups the click times T (datenum, e.g. the
%   porpoise clicks of every device on one clock) into encounters: periods
%   with animals around, separated by periods with none.
%
%   Classified clicks are never all porpoise, so a lone click does not
%   make or extend an encounter. Time is cut into minutes and a minute is
%   ACTIVE if it has at least minPerMin clicks. An encounter is a run of
%   active minutes with no gap between them of more than maxGap minutes,
%   extended by pad either side. An encounter longer than maxDuration is
%   split at the longest silence in its middle, as long as that silence is
%   at least splitGap, so that a busy night is not one enormous encounter.
%   Encounters with fewer than minClicks clicks are dropped.
%
%   Name-value parameters (defaults in brackets):
%     minPerMin   - clicks in a minute for it to be active [10]
%     maxGap      - encounters are separated by more than this many
%                   minutes with no active minute [5]
%     pad         - time added either side of an encounter (min) [1]
%     minClicks   - min clicks in an encounter [200]
%     maxDuration - encounters longer than this are split if they can be
%                   (min) [60]
%     splitGap    - shortest silence at which a long encounter may be
%                   split (s) [30]
%     exclude     - [n x 2] time limits (datenum); clicks inside them are
%                   ignored, e.g. boat calibration trials [[]]
%     tlims       - only clicks between these times are used [-inf inf]
%
%   ENC is a struct array, in time order, with fields:
%     tlims    - start and end of the encounter (datenum)
%     nClicks  - number of clicks in it
%     duration - length (min)
%
%   See also TRACK_BEARINGS, ASSOCIATE_TRACKS.

p.minPerMin = 10;
p.maxGap = 5;
p.pad = 1;
p.minClicks = 200;
p.maxDuration = 60;
p.splitGap = 30;
p.exclude = zeros(0, 2);
p.tlims = [-inf inf];
for i = 1:2:numel(varargin)
    if ~isfield(p, varargin{i})
        error('find_encounters:badParam', 'Unknown parameter "%s"', varargin{i});
    end
    p.(varargin{i}) = varargin{i+1};
end

enc = struct('tlims', {}, 'nClicks', {}, 'duration', {});
t = sort(t(:));
t = t(t >= p.tlims(1) & t <= p.tlims(2));
for i = 1:size(p.exclude, 1)
    t = t(t < p.exclude(i,1) | t > p.exclude(i,2));
end
if isempty(t)
    return
end

% active minutes
m0 = floor(t(1)*1440);
m = floor(t*1440) - m0 + 1;
active = find(accumarray(m, 1) >= p.minPerMin);
if isempty(active)
    return
end
% runs of active minutes
brk = [0; find(diff(active) > p.maxGap); numel(active)];
lims = zeros(numel(brk) - 1, 2);
for k = 1:numel(brk) - 1
    lims(k,:) = (m0 + [active(brk(k) + 1) - 1, active(brk(k+1))])/1440;
end

% split the long ones at their longest silence
k = 1;
while k <= size(lims, 1)
    if diff(lims(k,:))*1440 > p.maxDuration
        tk = t(t >= lims(k,1) & t <= lims(k,2));
        gap = diff(tk)*86400;
        mid = tk(1:end-1) + diff(tk)/2;
        % not in the first or last 5 minutes, which would leave a stub
        gap(mid < lims(k,1) + 5/1440 | mid > lims(k,2) - 5/1440) = 0;
        [g, ig] = max(gap);
        if ~isempty(g) && g >= p.splitGap
            lims = [lims(1:k-1,:); lims(k,1), tk(ig); tk(ig+1), lims(k,2); lims(k+1:end,:)];
            continue % look at the first half again
        end
    end
    k = k + 1;
end

% pad, without running into the neighbours
padded = lims + [-1 1]*p.pad/1440;
for k = 1:size(lims, 1) - 1
    if padded(k,2) > padded(k+1,1)
        mid = mean([lims(k,2), lims(k+1,1)]);
        padded(k,2) = mid;
        padded(k+1,1) = mid;
    end
end

for k = 1:size(padded, 1)
    n = sum(t >= padded(k,1) & t <= padded(k,2));
    if n >= p.minClicks
        enc(end+1).tlims = padded(k,:); %#ok<AGROW>
        enc(end).nClicks = n;
        enc(end).duration = diff(padded(k,:))*1440;
    end
end
end
