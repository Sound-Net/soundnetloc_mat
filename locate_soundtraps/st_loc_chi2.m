function [chi2, bearingoffset] = st_loc_chi2(xlatlon, latlonsource, stdepths, obsangle, angletype)
%ST_LOC_CHI2 Calculates a chi2 variable for the location of a soundtrap
%based on slant angles and bearings
%   [CHI2] = ST_LOC_CHI2(XLATLON, LATLONSOURCE, STDEPTHS, OBSANGLES)
%   calculates the chi2 value that a SoundTrap is located at XLATLON based
%   on a series of source locations LATLONGSOURCE and a corresponding
%   series of OBSANGLES  which are the geo referenced bearing and slant
%   angle in RADIANS respectively and STDEPTHS which is the depth
%   <i>difference<\i> between the SoundTrap and source in meters. The slant
%   angle to the source should be fairly steady.
%
%   [CHI2] = ST_LOC_CHI2(XLATLON, LATLONSOURCE, STDEPTHS, OBSANGLES, ANGELTYPE)
%   returns the CHI2 value for a specified angle type. Angle types can be
%   'bearing', 'slant', 'all' (or 'both'), 'bearing_offset' or
%   'both_offset'. The default is all.
%
%   The _offset types allow the measured bearings a systematic offset, e.g.
%   a compass heading error: the offset (the circular mean of measured -
%   true bearing) is removed before the bearing chi2 is calculated, so only
%   the shape of the bearings over the track has to match. The slant angles
%   are unaffected by a heading error so 'both_offset' uses them as they are.
%
%   [CHI2, BEARINGOFFSET] = ST_LOC_CHI2(...) also returns the bearing offset
%   (measured - true, RADIANS) removed at XLATLON. It is 0 unless an _offset
%   angle type is used.


% to reduce strcmp statement angle type is a flag. 
% 0- all
% 1 - just bearing
% 2- just slant
useoffset = false;
if nargin<5
    angtype = 0;
else
    switch (angletype)
        case 'bearing'
            angtype = 1;
        case 'slant'
            angtype = 2;
        case 'bearing_offset'
            angtype = 1;
            useoffset = true;
        case 'both_offset'
            angtype = 0;
            useoffset = true;
        otherwise
            angtype=0;
    end
end
%calculate what the slant angles should be 
errslnt= deg2rad(3); % lets guess the error is about 3 degrees(pinger was not exactly straight); 
errbearing= deg2rad(5); % lets guess the error is about 5 degrees(pinger was not exactly straight); 

nsrc = length(latlonsource(:,1));
bearingres = zeros(nsrc, 1); % measured - true bearing
chi2=0;
for i=1:nsrc
    %simple calulate here depth is one side of the triangle, horizontal
    %range is the other
    r = latLong2meters(xlatlon(1), xlatlon(2),...
        latlonsource(i,1), latlonsource(i,2));

    %%Bearing angle
    if (angtype == 0 || angtype ==1)
        % calculate the true bearing angle
        bearing = deg2rad(latLong2bearing(xlatlon(1), xlatlon(2),latlonsource(i,1), latlonsource(i,2), 'atan'));
        if (isnan(bearing))
            disp(['Bearing: ' num2str(bearing) ' latlong ' num2str(xlatlon(1)') ' srclatlon ' num2str(latlonsource(i,1))]);
             assignin('base','xlatlon',xlatlon);
             assignin('base','latlonsource',latlonsource(i,:));
        end
        bearingres(i) = angdiff(bearing , obsangle(i,1));
    end
    
    %%Slant angle 
    if (length(obsangle(1,:))>=2 && (angtype == 0 || angtype == 2))
        %get the depth
        dpth = stdepths(i);
        %slant angle in radians
        slantangle= atan(dpth/r);
        %add to chi2
        chi2=chi2+(slantangle-obsangle(i,2))^2/errslnt^2;
    end
    
    %%other chi2 variables to be added here. 
end

%the bearing offset is the circular mean of the residuals so it is not
%upset by residuals either side of +-pi
bearingoffset = 0;
if (useoffset)
    bearingoffset = angle(sum(exp(1i*bearingres)));
    bearingres = angdiff(bearingoffset, bearingres);
end
if (angtype == 0 || angtype ==1)
    chi2 = chi2 + sum(bearingres.^2)/errbearing^2;
end

chi2=chi2/length(latlonsource); 

end
