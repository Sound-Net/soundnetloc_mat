function [h] = plotbearingtime(clickbearings, anglesgeo, eulerangles, varargin)
%PLOTBEARINGTIME Plot bearing time of clicks, geo referewnced clicks and euler angles
%   [H] = PLOTBEARINGTIME(CLICKBEARINGS, ANGLESGEO, EULERANGLES) plots CLICKBEARINGS [time (MALTAB datenum), heading angle
%   (DEGREES), slant angle (DEGREES)], corresponding geo referenced clicks
%   (time (absolute samples), heading angle (DEGREES), slant angle
%   (DEGREES)) and headings from EULERANGLES sensor data (defaults sensor
%   import (see sensorcsv2mat.m)) and corresponding absolute euler sample
%   times.
%
%   [H] = PLOTBEARINGTIME(CLICKBEARINGS, ANGLESGEO, EULERANGLES,
%   ABSMPLEEUL, VARARGIN) adds additional VARARGIN arguments. These are;
%%
%
% * 'timelimits' - time limits [start, end] in MATLAB datenum
% * 'usesamples' - use samples for the time axis instead of datenum
% (default is false)
% * 'euleroffset' - add a euleroffset for weird SoundTrap' non utc times
%

euleroffset = 0;
timelims = [min(clickbearings(:,1)), max(clickbearings(:,1))];
usesamples = false;
onlygeo=false;
bearingtype = 1; % | 1 - bearings | 2 - slant |

iArg=0;
while iArg < numel(varargin)
    iArg = iArg + 1;
    %      disp(['Hello: ' num2str(length(varargin)) ' ' varargin{iArg} ])
    switch(varargin{iArg})
        case 'timelimits'
            iArg = iArg + 1;
            timelims = varargin{iArg};
        case 'euleroffset'
            iArg = iArg + 1;
            euleroffset = varargin{iArg};
        case 'usesamples'
            iArg = iArg + 1;
            usesamples = varargin{iArg};
        case 'onlygeo'
            iArg = iArg + 1;
            onlygeo = varargin{iArg};
        case 'bearingtype'
            iArg = iArg + 1;
            bearingtype = varargin{iArg};
        otherwise
            iArg = iArg + 1;
    end
end

clktimes = clickbearings(:,1);

% get rid of the euler angles outwith click times.
index=find((eulerangles(:,1)+euleroffset)>=timelims(1) & (eulerangles(:,1)+euleroffset)<timelims(2));

euleranglesplt=eulerangles(index,:);
abssmpleseulplt=eulerangles(:,2);

index=find((clktimes+euleroffset)>=timelims(1) & (clktimes+euleroffset)<timelims(2));

bearingindex = -1;
eulerindex = -1;
switch (bearingtype)
    case 1
        bearingindex = 2;
        eulerindex = 5;
    case 2
        bearingindex = 3;
        eulerindex = 4;
end
clickbearingsplt  = clickbearings(index,:);
abssmplsclkplt    = anglesgeo(index,1);
anglesgeoplt      = anglesgeo(index,:);

hold on
if usesamples
    % time is absolute samples - morte accurate
    scatter(abssmpleseulplt(:,1), euleranglesplt(:,eulerindex), '.');
    if (~onlygeo)
        scatter(abssmplsclkplt, clickbearingsplt(:,bearingindex)','.');
    end
    h = scatter(anglesgeoplt(:,1), anglesgeoplt(:,bearingindex),'.');
else
    %time is datenum - less accurate but should still work for larger time
    %scales
    scatter(datetime(euleranglesplt(:,1), 'ConvertFrom', 'datenum'), euleranglesplt(:,eulerindex), '.');
    if (~onlygeo)
        scatter(datetime(clickbearingsplt(:,1), 'ConvertFrom', 'datenum'), clickbearingsplt(:,bearingindex)','.');
    end
    h= scatter(datetime(clickbearingsplt(:,1), 'ConvertFrom', 'datenum'), anglesgeoplt(:,bearingindex),'.');
end

legend('Euler angles', 'loc bearings','geo-ref bearings')
hold off

switch (bearingtype)
    case 1
        ylabel ('Heading (degrees)')
    case 2
        ylabel ('Slant (degrees)')
end

if (usesamples)
    xlabel('Samples')
else
    xlabel('Time');
end

switch (bearingtype)
    case 1
        ylim([-180, 180])
    case 2
        ylim([-90, 90])
end

xlim(datetime([timelims(1), timelims(2)], 'ConvertFrom', 'datenum'));


% add custom tooltip
dcmObj = datacursormode;
set(dcmObj,'UpdateFcn',@datestrTxt);

end

