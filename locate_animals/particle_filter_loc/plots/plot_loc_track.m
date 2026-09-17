function [h, c] = plot_loc_track(loctracks, varargin)
%PLOT_LOC_TRACK Plots localisation tracks
%    [H1] = PLOT_LOC_TRACK(PLOTLOCTRACK) plots the loc tracks and
%    hydrophone positions.

if (~isempty(loctracks))
    % date start and end
    datestart = [loctracks.datestart];
    dateend = [loctracks.dateend];

    %find min and max time tracks
    timelims=tracktimelims(loctracks);
end
%

timecmap = 'Jet';

iArg = 0;
while iArg < numel(varargin)
    iArg = iArg + 1;
    switch(varargin{iArg})
        case 'timelimits'
            iArg = iArg + 1;
            timelims = varargin{iArg};
        case 'showcolourbar'
            iArg = iArg + 1;
            showcolourbar = varargin{iArg};
        case 'showtitle'
            iArg = iArg + 1;
            showtitle = varargin{iArg};
        case 'timecmap'
            iArg = iArg + 1;
            timecmap = varargin{iArg};
    end
end

if (~isempty(loctracks))
    for i=1:length(loctracks)
        %     if (~isempty(loctrack(i).locsimplex))
        %         %     %plot simple loc points
        %         [h1] = plot_loc_points(loctrack(i).locsimplex,loctrack(i).timeslocsimplex, timelims);
        %     end

        if (~isempty(loctracks(i).xh))

            %plot the particle filter track.
            [h] = plot_loc_points(loctracks(i).xh',loctracks(i).loctracktimes, timelims, 20, 'filled','timecmap', timecmap );

            % h1=scatter3(xh(1,:), xh(2,:), xh(3,:), 'MarkerEdgeColor', cols(2,:),  'MarkerFaceColor', cols(2,:));
            %want the plot line to be coloured too...how do we do this....?
            %we make an interp scatter
            interptimes=min(loctracks(i).loctracktimes):0.005:max(loctracks(i).loctracktimes);

            [times, index] = unique(loctracks(i).loctracktimes);

            if length(times)>1
                % do nit use any spline type of interpolation etc as cause very
                % weird artefacts in tracks sometimes.
                xhinterp = interp1(times, loctracks(i).xh(1,index), interptimes,'linear');
                yhinterp = interp1(times, loctracks(i).xh(2,index)', interptimes, 'linear');
                zhinterp = interp1(times, loctracks(i).xh(3,index)', interptimes, 'linear');
            else
                xhinterp = loctracks(i).xh(1,index);
                yhinterp = loctracks(i).xh(2,index);
                zhinterp = loctracks(i).xh(3,index);

            end
            %         xhinterp = smooth(xhinterp);
            %         yhinterp = smooth(yhinterp);
            %         zhinterp = smooth(zhinterp);
            %
            %         figure(3)
            %         hold on
            %         plot(times, loctracks(i).xh(1,index))
            %         plot(interptimes, xhinterp)
            %         hold off
            %         figure

            plot_loc_points([xhinterp; yhinterp; zhinterp]', interptimes, timelims, 5, 'filled', 'timecmap', timecmap );
            %         plot3(loctracks(i).xh(1,:), loctracks(i).xh(2,:), loctracks(i).xh(3,:));
        end
    end

else 
   h = plot(0,0); 
end


if showcolourbar
    ticks = linspace(0, 1, 5);
    ticksstring = linspace(timelims(1), timelims(2), 5);
    for i=1:length(ticksstring)
        ticksnamestr{i}=num2str(ticksstring(i)-timelims(1), '%.0f');
    end


    % HACK to allow a surface to be plotted of a different colour.
    c = colorbar('Ticks', ticks,...
        'TickLabels',ticksnamestr);

    acmap = colormap(timecmap);
    c.Colormap = acmap;
    c.Ticks = linspace(c.Limits(1), c.Limits(2), 5);

    c.Label.String = 'Track Time (seconds)';
else
    c=[];
end

if showtitle
    title(['Track: ' datestr(datestart(1), 'yyyy-mm-dd HH:MM:SS') ...
        ' to ' datestr(dateend(1),'HH:MM:SS')])
end

xlabel('x(m)')
ylabel('y(m)')
zlabel('Depth(m)')
hold off

end

