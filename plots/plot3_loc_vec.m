function [h1] = plot3_loc_vec(storigin, anglesgeo, linelength, varargin)
%PLOT3_LOC_VEC Plots the 3D geo referenced localisation vectors bearings for a single
%4 channel SoundTrap
%   [H1] = PLOT3_LOC_VEC(STORIGIN, ANGLESGEO, LINELENGTH, VARARGIN) plots
%   the 3D vectors of bearing and slant angles (ANGLESGEO) recieved by a
%   device at STORIGIN (northings, eastings, depth). STORIGIN can be either
%   one location or a location corresposinding to each click in
%   ANGLESGEO. LINELENGTH is the length of the line. The vectors are
%   coloured by time.

if nargin<2
    linelength = 300;
end

if (isempty(anglesgeo))
    return;
end

clicktimes = anglesgeo(:,1);

colourscheme = 1;
minmaxtimes =[];


iArg = 0;
while iArg < numel(varargin)
    iArg = iArg + 1;
    switch(varargin{iArg})
        case 'timelimits'
            iArg = iArg + 1;
            minmaxtimes = varargin{iArg};
        case 'customcolors'
            iArg = iArg + 1;
            % must be the same length as clicks
            clkcolours = varargin{iArg};
            colourscheme = 2;
    end
end


switch colourscheme
    case 1
        %colour by time
        if isempty(minmaxtimes)
            mintime=min(clicktimes);
            maxtime=max(clicktimes);
        else
            mintime = minmaxtimes(1);
            maxtime = minmaxtimes(2);
        end
end


% plot angles with time coloured...
[loc_vec] = angles2locvec(deg2rad(anglesgeo(:,3)), deg2rad(anglesgeo(:,4)));

%st orgin can be a list of locations or just one location. If just one
%location
if (length(storigin(:,1)) == 1 && length(anglesgeo(:,1))>1)
    storigin=storigin.*ones(length(anglesgeo(:,1)), 3);
end

% generate a colourmap.
colormap jet
acmap = colormap();

hold on
for i=1:length(loc_vec(:,1))

    %work out origin of device. %TODO
    origin=[storigin(i,1) ,storigin(i,2), storigin(i,3)];

    vecpos=linelength*loc_vec(i,:)+origin;

    switch colourscheme
        case 1
            %colour by time
            if (maxtime - mintime>0)
                colour = tcolormap(clicktimes(i), acmap, mintime, maxtime);
            else
                colour = acmap(1,:);
            end
        case 2
            %colour by event
            %             disp(['Colour for ' num2str(i) 'No. cols = ' num2str(length(clkcolours(:,1)))])
            colour = clkcolours(i,:);
    end

    %     plot3([origin(1), vecpos(1)], [origin(2), vecpos(2)], ...
    %         [origin(3), vecpos
    % (3)], 'Color', [colour 0.4]);

    colour(4)=0.1;
    h1 = plot3([origin(1), vecpos(1)], [origin(2), vecpos(2)], ...
        [origin(3), vecpos(3)], 'Color', colour);

    if (i==length(loc_vec))
        scatter3(origin(1), origin(2), origin(3), 'filled', 'MarkerFaceColor', 'k');
    end

    %     disp(['Plotting' num2str(i)])

end

% xlabel ('x (m)')
% ylabel ('y (m)');
% zlabel ('z (m)');
% hold off

end

