function [d, dx, dy] = latLong2meters(lat_ref, long_ref, Lat2, Long2)
% takes two lat longs in decimal degrees and returns the 
% distance between them in metres.
metrespermile = 1852.;
if length(Lat2)==length(Long2)
    aveLat = abs(Lat2+lat_ref)/2;
else
    aveLat = mean(lat_ref);
end
longCorr = cos(aveLat * pi/180);
dy = (Lat2 - lat_ref) * 60 * metrespermile;
dx = (Long2 - long_ref) * 60 .* longCorr * metrespermile;
if length(dy) == length(dx)
    d = sqrt(dy.^2 + dx.^2);
else
    d = [];
end

