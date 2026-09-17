function [chi2] = st_loc_chi2(xlatlon, latlonsource, stdepths, obsangle, angletype)
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
%   'bearing', 'slant' or 'all'. The default is all


% to reduce strcmp statement angle type is a flag. 
% 0- all
% 1 - just bearing
% 2- just slant

if nargin<4
    angtype = 0;
else
    switch (angletype)
        case 'bearing'
            angtype = 1;
        case 'slant'
            angtype = 2;
        otherwise
            angtype=0;
    end
end
%calculate what the slant angles should be 
errslnt= deg2rad(3); % lets guess the error is about 3 degrees(pinger was not exactly straight); 
errbearing= deg2rad(5); % lets guess the error is about 5 degrees(pinger was not exactly straight); 

chi2=0;
for i=1:length(latlonsource(:,1))
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
        chi2=chi2+(angdiff(bearing , obsangle(i,1)))^2/errbearing^2;
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

chi2=chi2/length(latlonsource); 

end

