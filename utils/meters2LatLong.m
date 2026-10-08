function [ new_latitude, new_longitude ] = meters2LatLong( lat, lon, dy, dx )
%METERS2LATLONG adds meters north and meters east to lat long
% lat - origin latitude
% long origin longitude
% dy meters to add north
% dx meters to add east. 

% %earth's radius
% dy=dy/1000;
% dx=dx/1000;
% r_earth=6378;
% 
% new_latitude  = lat  + (dy / r_earth) * (180 / pi);
% new_longitude = lon + (dx / r_earth) * (180 / pi) / cos(lat * 180/pi);

 %Earth’s radius, sphere
 R=6378137;

 %offsets in meters
 dn = dy;
 de = dx;

 %Coordinate offsets in radians
 dLat = dn/R;
 dLon = de/(R*cos(pi*lat/180));

 %OffsetPosition, decimal degrees
 new_latitude = lat + dLat * 180/pi;
 new_longitude = lon + dLon * 180/pi;


end

