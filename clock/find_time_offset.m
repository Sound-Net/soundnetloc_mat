function [offset, comb] = find_time_offset(tA, tB, varargin)
%FIND_TIME_OFFSET Clock offset between two devices from their click times.
%
%   [OFFSET, COMB] = FIND_TIME_OFFSET(TA, TB) runs a comb filter between
%   two sets of click times: a histogram of every click time difference
%   TB - TA within +/- maxOffset. Clicks from the same animal received on
%   both devices pile up at the clock offset (plus a small propagation
%   delay that depends on where the animal is), whereas unrelated clicks
%   spread out evenly. The histogram is smoothed over smoothWin to gather
%   the propagation delay spread into one peak.
%
%   TA, TB - click times (MATLAB datenum) on device A and B.
%   OFFSET - clock offset in SECONDS. Device B times corrected to device A
%            are TB - OFFSET/86400.
%   COMB   - struct with lags (s), counts, smoothed counts, peak and
%            background (median smoothed count) and snr (peak/background).
%
%   Name-value parameters:
%     maxOffset - largest offset searched (s) [10]
%     binWidth  - histogram bin width (s) [0.001]
%     smoothWin - smoothing window (s); should cover the largest
%                 propagation delay difference, i.e. 2*baseline/c [0.05]
%
%   See also ASSOCIATE_TRACKS

p.maxOffset = 10;
p.binWidth = 0.001;
p.smoothWin = 0.05;
for i = 1:2:numel(varargin)
    p.(varargin{i}) = varargin{i+1};
end

% seconds relative to a common origin to keep precision
t0 = min([tA(:); tB(:)]);
a = sort((tA(:) - t0)*86400);
b = sort((tB(:) - t0)*86400);

% all differences b - a within +/- maxOffset (sliding window over sorted b)
d = cell(numel(a), 1);
lo = 1;
hi = 0;
nb = numel(b);
for i = 1:numel(a)
    while lo <= nb && b(lo) < a(i) - p.maxOffset
        lo = lo + 1;
    end
    while hi < nb && b(hi+1) <= a(i) + p.maxOffset
        hi = hi + 1;
    end
    d{i} = b(lo:hi) - a(i);
end
d = vertcat(d{:});

edges = -p.maxOffset:p.binWidth:p.maxOffset;
lags = edges(1:end-1) + p.binWidth/2;
counts = histcounts(d, edges);
nSmooth = max(1, round(p.smoothWin/p.binWidth));
smoothed = movsum(counts, nSmooth);

[pk, ipk] = max(smoothed);
offset = lags(ipk);

comb.lags = lags;
comb.counts = counts;
comb.smoothed = smoothed;
comb.peak = pk;
comb.background = median(smoothed);
comb.snr = pk/max(comb.background, eps);
comb.offset = offset;
comb.params = p;
end
