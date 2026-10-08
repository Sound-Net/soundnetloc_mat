function [ bearing ] = latLong2bearing( lat1, lon1, lat2, lon2, algorithm)
%LATLONG2BEARING Calculate the bearing between two latitude and longitude
%points. Wrapper for several other functions. 
%
%    [ BEARING ] = LATLONG2BEARING( LAT1, LONG1, LAT2, LONG2 ) returns the
%    BEARING in degrees from north between two points (LAT, LONG) in
%    decimal DEGREES.
%
%    [ BEARING ] = LATLONG2BEARING( LAT1, LONG1, LAT2, LONG2, ALGORITHM)
%    calculates a bearing with a specified ALGORITHM. The default is
%    'greatcircle'. 'atan' is a faster alternative but only for close
%    points. 'azimuth' is also likely faster than 'greatcircle' but is part
%    of the mapping toolbox.

if nargin<5
    %faster than switch statement?
    [~,~,~,bearing]=greatcircle(lat1, lon1, lat2, lon2);
    bearing  = bearing(1); 
    return; 
end

switch algorithm
    case 'azimuth'
        bearing = azimuth(lat1,lon1,lat2,lon2); % NEEDS MAPPING TOOLBOX;
    case 'greatcircle'
        % great circle is most accurate
        [~,~,~,bearing]=greatcircle(lat1, lon1, lat2, lon2);
        bearing=bearing(1);
    case 'atan'
        % this is the quick and dirty method but fast
        [~, dx, dy] = latLong2meters(lat1, lon1, lat2, lon2);
        bearing = atan2d(dx, dy);
end


end

