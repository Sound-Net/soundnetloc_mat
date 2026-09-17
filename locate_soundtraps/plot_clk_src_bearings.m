function [h, srcbearings, axout] = plot_clk_src_bearings(location_final, clks, srclocations, varargin)
%PLOT_CLK_SRC_BEARINGS Plot bearings to source and geo ref click bearings
%
%   [h, srcbearings] = plot_clk_src_bearings(location_final, clks, srclocations)
%   clears the current figure and draws the horizontal and vertical bearing
%   panels as a 2x1 subplot. This is the original behaviour.
%
%   [...] = plot_clk_src_bearings(..., 'parent', p) draws into p instead and
%   does NOT clear the figure, so the function can be called repeatedly to
%   fill a tiledlayout. p may be:
%       - a tiledlayout object: a nested 2x1 layout is created inside it, in
%         the next free tile (or the tile given by the 'tile' option).
%       - a 1x2 array of axes handles: the panels are drawn into them
%         directly, top axes first.
%
%   Additional name-value options:
%       'tile'   - tile index to use when 'parent' is a tiledlayout.
%                  Default: the next free tile.
%       'title'  - title string for the pair of panels. Default: none.
%       'legend' - show the legend. Default: true when standalone, false
%                  when nested (legends swamp a multi-tile grid).
%
%   axout is returned as [ax1 ax2] so the caller can restyle the axes.

p = inputParser;
p.addParameter('parent', []);
p.addParameter('tile', []);
p.addParameter('title', '');
p.addParameter('legend', []);
p.parse(varargin{:});
parent = p.Results.parent;
nested = ~isempty(parent);

showlegend = p.Results.legend;
if isempty(showlegend)
    showlegend = ~nested;
end

bearing=zeros(length(srclocations(:,2)), 2);
for i=1:length(srclocations(:,2))
    bearing(i,1)= latLong2bearing( location_final(1),  location_final(2), ...
        srclocations(i,2),...
        srclocations(i,3), 'atan');
    
     range = latLong2meters(location_final(1),  location_final(2), ...
        srclocations(i,2),...
        srclocations(i,3));
   
    bearing(i,2) =  atand(srclocations(i, 4)/range);
end
cols = getdefaultcols(); 

if ~nested
    % Original behaviour: we own the whole figure.
    clf
    ax1 = subplot(2,1,1);
    ax2 = subplot(2,1,2);
    fontsize = 12;
elseif isa(parent, 'matlab.graphics.axis.Axes')
    % Caller handed us axes to draw into (e.g. from two nexttile calls).
    if numel(parent) ~= 2
        error('plot_clk_src_bearings:badParent', ...
            '''parent'' given as axes must be a 1x2 array [horizontal vertical].');
    end
    ax1 = parent(1);
    ax2 = parent(2);
    fontsize = 10;
else
    % Nest a 2x1 layout inside the caller's tiledlayout. Work out which tile
    % to claim BEFORE creating the nested layout - a freshly created child is
    % immediately parented and sits on tile 1 by default, so asking after the
    % fact would count it as occupying a tile and shift everything along by one.
    tile = nextfreetile(parent, p.Results.tile);
    inner = tiledlayout(parent, 2, 1, 'TileSpacing', 'tight', 'Padding', 'tight');
    inner.Layout.Tile = tile;
    ax1 = nexttile(inner);
    ax2 = nexttile(inner);
    fontsize = 10;
    if ~isempty(p.Results.title)
        title(inner, p.Results.title);
    end
end

hold(ax1, 'on')
h(1) = scatter(ax1, datetime(clks(:,1), 'ConvertFrom', 'datenum'), clks(:,2),'MarkerFaceColor',cols(1,:),'MarkerEdgeColor','none',...
    'MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2); 
scatter(ax1, datetime(srclocations(:,1), 'ConvertFrom', 'datenum'), wrapTo180(bearing(:,1)), '.'); 
if showlegend
    legend(ax1, 'Geo referenced localised bearing', 'True bearing')
end
hold(ax1, 'off')
title(ax1, 'Horizontal Bearing')
ylabel(ax1, 'Heading (degrees)')
datetick(ax1, 'x')
set(ax1, 'FontSize', fontsize)

hold(ax2, 'on')
title(ax2, 'Vertical Bearing')
h(2) = scatter(ax2, datetime(clks(:,1), 'ConvertFrom', 'datenum'), clks(:,3), 'MarkerFaceColor',cols(1,:),'MarkerEdgeColor','none',...
    'MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2); 
scatter(ax2, datetime(srclocations(:,1), 'ConvertFrom', 'datenum'), bearing(:,2), '.'); 
ylim(ax2, [-10,90])
ylabel(ax2, 'Slant (degrees)')
xlabel(ax2, 'Time')
datetick(ax2, 'x')
set(ax2, 'FontSize', fontsize)

hold(ax2, 'off')

srcbearings = bearing; 
axout = [ax1, ax2];

linkaxes([ax1, ax2], 'x'); 

end


function tile = nextfreetile(parent, requested)
%NEXTFREETILE Index of the next tile to fill in a tiledlayout.
%   Call this BEFORE parenting the new child. Tiles are filled sequentially,
%   so the next one is simply one past however many children are already
%   there; that is more robust than trying to reverse the row-major tile
%   numbering out of each child's Layout.Tile.
if ~isempty(requested)
    tile = requested;
    return
end

tile = numel(parent.Children) + 1;

ntiles = prod(parent.GridSize);
if tile > ntiles
    error('plot_clk_src_bearings:noFreeTile', ...
        'The parent tiledlayout (%dx%d) has no free tiles left for tile %d.', ...
        parent.GridSize(1), parent.GridSize(2), tile);
end
end
