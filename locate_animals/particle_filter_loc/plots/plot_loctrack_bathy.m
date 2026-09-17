function [h2, h3, h4, c] = plot_loctrack_bathy(loctracks, hydrophonesgeo, ...
    varargin)
%PLOT_LOCTRACK_BATHY Plots a localisation track alongside bathymetry and
% representation of the gill net.

p = inputParser;
addParameter(p, 'reflatlon', [], @(x) isnumeric(x) || isstring(x));
addParameter(p, 'timelims', [], @isnumeric);
addParameter(p, 'datenumstart', [], @isnumeric);
addParameter(p, 'showlegend', true, @islogical);
addParameter(p, 'showcolorbar', true, @islogical);
addParameter(p, 'showtitle', true, @islogical);
addParameter(p, 'timecmap', true);
addParameter(p, 'netheighfunc',  []);

parse(p, varargin{:});


reflatlon   = p.Results.reflatlon;
timelims = p.Results.timelims;
datenumstart    = p.Results.datenumstart;

showlegend   = p.Results.showlegend;
showcolorbar = p.Results.showcolorbar;
showtitle    = p.Results.showtitle;
timecmap    = p.Results.timecmap;
netheighfunc = p.Results.netheighfunc;

hold on
[~, meshdata] = plotbathy_cornwall(reflatlon, [-200, 200], [-200 200], datenumstart);
stroplength = 3;

if isempty(netheighfunc)
    [h3, h4] = plot_gill_net(hydrophonesgeo, stroplength, meshdata);
else
    [h3, h4] = plot_gill_net(hydrophonesgeo, stroplength, meshdata, netheighfunc);
end

hold on
[h2, c] = plot_loc_track(loctracks, 'timelimits', timelims, 'showtitle', ...
    showtitle, 'showcolourbar', showcolorbar, 'timecmap', timecmap);
colormap('Gray')
xlim([-200, 200])
ylim([-200, 200])
hold off

if showlegend
    legend([h2, h3, h4], {'Porpoise Track', 'Hydrophones', 'Gill net headline'});
end
