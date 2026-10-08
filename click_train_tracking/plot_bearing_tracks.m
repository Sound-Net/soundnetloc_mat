function ax = plot_bearing_tracks(clktimes, bearings, res, vertical)
%PLOT_BEARING_TRACKS Plot the three stages of TRACK_BEARINGS.
%
%   AX = PLOT_BEARING_TRACKS(CLKTIMES, BEARINGS, RES) plots, in three
%   linked panels:
%     1. raw click bearings (red = flagged as echoes) with the stage 1
%        fragments (marker size ~ number of clicks, error bars = fragment sd)
%     2. fragments coloured by track with the smoothed track curves
%     3. non-echo clicks coloured by their assigned track (grey = unassigned)
%
%   AX = PLOT_BEARING_TRACKS(CLKTIMES, BEARINGS, RES, VERTICAL) adds a
%   second column showing the same three stages for the vertical angle
%   (RES must come from TRACK_BEARINGS called with VERTICAL).
%
%   CLKTIMES are datenums, angles in degrees, RES from TRACK_BEARINGS.
%
%   See also TRACK_BEARINGS

clktimes = clktimes(:);
bearings = bearings(:);
frags = res.frags;
tracks = res.tracks;
nTracks = numel(tracks);
cols = track_colours(nTracks);
grey = [0.75 0.75 0.75];

dtc = datetime(clktimes, 'ConvertFrom', 'datenum');
dtf = datetime(frags.tnum, 'ConvertFrom', 'datenum');

if all(bearings(~isnan(bearings)) >= 0)
    ylims = [0 360];
else
    ylims = [-180 180];
end

% one column per angle
ang = struct('clk', bearings, 'frag', frags.bearing, 'sd', frags.sd, ...
    'curve', 'bearing', 'raw', 'bearingRaw', 'ylims', ylims, ...
    'tick', 90, 'label', 'Bearing (deg)', 'name', 'bearing');
if nargin > 3 && ~isempty(vertical) && res.useVertical
    ang(2) = struct('clk', vertical(:), 'frag', frags.vertical, 'sd', frags.sdV, ...
        'curve', 'vertical', 'raw', 'verticalRaw', 'ylims', [-90 90], ...
        'tick', 45, 'label', 'Vertical angle (deg)', 'name', 'vertical angle');
end
nCol = numel(ang);

tl = tiledlayout(3, nCol, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = gobjects(3, nCol);
echo = res.isEcho;
nValid = sum(~isnan(bearings) & ~echo);
echoCol = [0.95 0.6 0.6];

for c = 1:nCol
    A = ang(c);

    %% 1. clicks and fragments
    a = nexttile(tl, c);
    hold(a, 'on');
    scatter(a, dtc(~echo), A.clk(~echo), 4, grey, 'filled');
    scatter(a, dtc(echo), A.clk(echo), 4, echoCol, 'filled');
    if ~isempty(frags.t)
        plot(a, [dtf(:) dtf(:)]', [A.frag - A.sd, A.frag + A.sd]', 'k-');
        scatter(a, dtf, A.frag, 8 + 2*sqrt(frags.n), 'k', 'filled');
    end
    hold(a, 'off');
    title(a, sprintf('Stage 1 (%s): %d echoes removed, %d clicks -> %d fragments', ...
        A.name, sum(echo), nValid, numel(frags.t)));
    ax(1, c) = a;

    %% 2. fragments linked into tracks
    a = nexttile(tl, nCol + c);
    hold(a, 'on');
    un = frags.track == 0;
    scatter(a, dtf(un), A.frag(un), 12, grey, 'filled');
    for k = 1:nTracks
        tr = tracks(k);
        dtt = datetime(tr.tnum, 'ConvertFrom', 'datenum');
        scatter(a, dtt, tr.(A.raw), 18, cols(k,:), 'filled');
        [xl, yl] = break_wraps(dtt, tr.(A.curve));
        plot(a, xl, yl, '-', 'Color', cols(k,:), 'LineWidth', 1.5);
        text(a, dtt(1), tr.(A.curve)(1), sprintf(' %d', k), 'Color', cols(k,:), ...
            'FontWeight', 'bold', 'VerticalAlignment', 'bottom');
    end
    hold(a, 'off');
    title(a, sprintf('Stage 2: %d tracks (%d/%d fragments assigned)', ...
        nTracks, sum(~un), numel(un)));
    ax(2, c) = a;

    %% 3. clicks grouped into tracks
    a = nexttile(tl, 2*nCol + c);
    hold(a, 'on');
    un = res.clickTrack == 0 & ~echo;
    scatter(a, dtc(un), A.clk(un), 4, grey, 'filled');
    for k = 1:nTracks
        sel = res.clickTrack == k;
        scatter(a, dtc(sel), A.clk(sel), 6, cols(k,:), 'filled');
    end
    hold(a, 'off');
    title(a, sprintf('Stage 3: %d/%d clicks assigned to tracks', ...
        sum(res.clickTrack > 0), nValid));
    ax(3, c) = a;

    for r = 1:3
        ylim(ax(r, c), A.ylims);
        yticks(ax(r, c), A.ylims(1):A.tick:A.ylims(2));
        ylabel(ax(r, c), A.label);
        box(ax(r, c), 'on');
        grid(ax(r, c), 'on');
    end
    xlabel(ax(3, c), 'Time');
    linkaxes(ax(:, c), 'y');
end
linkaxes(ax(:), 'x');

end

function [x, y] = break_wraps(x, y)
% insert NaNs where a bearing curve wraps so lines don't cross the plot
x = x(:); y = y(:);
jump = find(abs(diff(y)) > 180);
for i = numel(jump):-1:1
    j = jump(i);
    x = [x(1:j); x(j); x(j+1:end)];
    y = [y(1:j); NaN; y(j+1:end)];
end
end

function cols = track_colours(n)
% qualitative palette, cycled if there are more tracks than colours
pal = [ ...
    0.121 0.467 0.706
    1.000 0.498 0.055
    0.173 0.627 0.173
    0.839 0.153 0.157
    0.580 0.404 0.741
    0.549 0.337 0.294
    0.890 0.467 0.761
    0.737 0.741 0.133
    0.090 0.745 0.812
    0.000 0.000 0.000];
cols = pal(mod((1:n) - 1, size(pal, 1)) + 1, :);
end
