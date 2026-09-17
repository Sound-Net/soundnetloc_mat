function [srclocations] = interpsrcloc(intrptimes, gpsdata, recorderdepth, srcdepth)
  % INTERPSRCLOC - Calculates interpolated source locations from gps and depth
%data
  %
  % Input arguments:
  % intrptimes    - Nx1 vector of desired interpolation times (datenum or seconds)
  % gpsdata       - Mx3 or MxN array: time and position samples used for interpolation
  % recorderdepth - scalar depth of the recorder (meters)
  % srcdepth      - scalar depth of the source (meters)
  %
  % Output arguments:
  % srclocations  - interpolated source positions corresponding to intrptimes




srclocations(:,1) = interp1(gpsdata(:,1),gpsdata(:,2), intrptimes);
srclocations(:,2)  = interp1(gpsdata(:,1),gpsdata(:,3), intrptimes);

if  nargin>=4 && length(srcdepth)>1
%src depth is an array and needs interpolated
    depthoffset= interp1(srcdepth(:,1),srcdepth(:,2), intrptimes);
elseif nargin>=4
    %the src depth is just a static offset to add e.g.the presumed depth of
    %the propellor. 
    depthoffset=srcdepth; 
else 
    depthoffset = 1; %assume a 1m offset. 
end

%now work relative depths
if (isscalar(recorderdepth))
    % a single depth has been set - i.e. the depth is not dynamic. 
    srclocations(:,3) = recorderdepth - depthoffset; 
else
    srclocations(:,3)  = interp1(recorderdepth(:,1),recorderdepth(:,2), intrptimes)-depthoffset;
end

srclocations(:,3) = srclocations(:,3);
end