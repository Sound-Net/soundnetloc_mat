function [bearingsdec, keepindex] = decimate_bearings(clickbearings, maxpersec)
%DECIMATE_BEARINGS thins a list of click bearings to a maximum number of
% points per second, evenly spread through each second.
%
% DECIMATE_BEARINGS(CLICKBEARINGS) takes an array of [time (MATLAB
% datenum), horz angle, slant angle] and keeps a maximum of 5 points per
% second, returning an array in the same format sorted by time.
%
% DECIMATE_BEARINGS(CLICKBEARINGS, MAXPERSEC) keeps a maximum of MAXPERSEC
% points per second instead of 5.
%
% [BEARINGSDEC, KEEPINDEX] = DECIMATE_BEARINGS(...) also returns the row
% indices of CLICKBEARINGS which were kept, so other per-click data can be
% thinned in the same way.
%
% Each second is split into MAXPERSEC equal sub-intervals and the click
% closest to the centre of each sub-interval is kept. Sub-intervals with no
% clicks contribute nothing, so seconds with sparse or clumped detections
% return fewer than MAXPERSEC points.

if nargin < 2
    maxpersec = 5;
end

bearingsdec = clickbearings;
keepindex = (1:size(clickbearings, 1))';

if isempty(clickbearings) || maxpersec < 1
    return;
end

%time in seconds - datenums are large so this keeps ~10 microsecond
%resolution, which is plenty for binning within a second
tsecs = clickbearings(:,1)*24*60*60;

%which second each click falls in and where in that second it sits (0-1)
whichsec = floor(tsecs);
frac = tsecs - whichsec;

%which sub-interval of the second each click falls in
whichbin = min(floor(frac*maxpersec) + 1, maxpersec);

%distance from the centre of that sub-interval
bindist = abs(frac - (whichbin - 0.5)/maxpersec);

%unique second/sub-interval combination
[~, ~, group] = unique([whichsec, whichbin], 'rows');

%keep the click closest to the centre of each occupied sub-interval
[~, order] = sortrows([group, bindist]);
isfirst = [true; diff(group(order)) ~= 0];
keepindex = sort(order(isfirst));

bearingsdec = clickbearings(keepindex, :);

%make sure the output is in time order
[~, index] = sort(bearingsdec(:,1));
bearingsdec = bearingsdec(index, :);
keepindex = keepindex(index);

end
