function [idx, dist] = nearest_sample(refsamples, querysamples)
%NEAREST_SAMPLE Index of the closest reference sample for each query sample.
%
%   [IDX, DIST] = NEAREST_SAMPLE(REFSAMPLES, QUERYSAMPLES) returns, for
%   every entry of QUERYSAMPLES, the index IDX of the closest entry in
%   REFSAMPLES and the absolute difference DIST.
%
%   This replaces the per-click MIN(ABS(ref - query)) search used when
%   matching euler angles to clicks, which was O(nclicks * nangles). When
%   REFSAMPLES is sorted a binary search is used instead; otherwise it falls
%   back to the original linear scan. Both paths return exactly the same
%   answer, including the tie-break: a query exactly between two reference
%   samples, or matching several identical reference samples, takes the
%   lowest index, which is what MIN does.
%
%   See also GEO_REF_CLKS, GEO_REF_HYDROPHONES.

refsamples = refsamples(:);
querysamples = querysamples(:);
n = numel(refsamples);

idx = zeros(numel(querysamples), 1);
dist = inf(numel(querysamples), 1);

if n == 0
    % nothing to match against - report everything as infinitely far away
    % so callers treat it as "not found" rather than indexing into nothing.
    return;
end

if ~issorted(refsamples)
    % fall back to the original search
    for i = 1:numel(querysamples)
        [dist(i), idx(i)] = min(abs(refsamples - querysamples(i)));
    end
    return;
end

% bin edges are the reference samples themselves, so k tells us that
% refsamples(k-1) <= query < refsamples(k)
k = discretize(querysamples, [-inf; refsamples; inf]);

lo = min(max(k-1, 1), n);
hi = min(max(k,   1), n);

dlo = abs(refsamples(lo) - querysamples);
dhi = abs(refsamples(hi) - querysamples);

idx = lo;
takehi = dhi < dlo;          % strict, so a tie keeps the lower index
idx(takehi) = hi(takehi);
dist = min(dlo, dhi);

% if the reference contains repeated values, MIN would have returned the
% first of them - do the same.
[~, firstofvalue] = unique(refsamples, 'first');
groupid = cumsum([true; diff(refsamples) ~= 0]);
idx = firstofvalue(groupid(idx));

end
