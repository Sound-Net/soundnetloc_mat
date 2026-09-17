function [location, chi2, chi2surf, clksgeo, srcclklocation] = locate_pos(clicks,sensordata, wavsamples, srclocations, varargin)
%LOCATE_POS Locate the postion of an acoustic sensor from recieved clicks
%location
% [LOCATION, CHI2, CHI2SURF, CLKSGEO, SRCCLKLOCATION] =
% LOCATE_POS(CLICKS,SENSORDATA, SRCLOCATIONS) calculates the location of a
% micro aperture hydrophone array capable of calculating bearings and slant
% angles based on recieved CLICKS (PAMGuard struct format)from a source at
% known SRCLOCATIONS (time, latitude, longitude, depth). SENSORDATA is IMU
% and depth data from a SENSOR in struct format. CLKSGEO is geo referenced
% angles of the clicks (time, bearings, slant angle) used in the location
% calculation. SRCCLKLOCATION is the source location for every recieved
% click [time, latitude, longitude, depth  _difference_ ]
%
% [LOCATION, CHI2, CHI2SURF, ANGLESGEO] = LOCATE_POS(CLICKS,SENSORDATA,
% SRCLOCATIONS, VARARGIN) adds additional arguments. These are;
% *'latlims'    - two element array with latitude limits in degrees
% *'lonlims'    - two element array with longitude limits in degrees
% *'gridsize'   - the size of the search grid. Higher number is a finder
%                 grid. 
% *'maxchi2'    - the maximum chi2 value for the chi2 surface - only
% *'latlims'    - two element array with latitude limits in degrees
% *'gpsoffset'  - offset in gps time (in seconds) between the SRCLOCATIONS
%                 and CLICKS
% *'euleroffset'- offset in euler angles in days - usually 1/24 or 0.  
% *'timerange'  - time range of CLICKS to perform analysis on. Two element
%                 datenum vector. 
% *'vp2p'       - the peak to peak voltage in volts. Default is 2V 
% *'sens'       - sensitivity of hydrophones in dB re 1V/uPa. Default =
%                 -201
% *'gain'       - the gain in dB. Default is 20 dB. 
% *'minamp'     - the minimum amplitude of clicks in dB re 1uPa pp. 
% *'searchtype' - the type of angles to use in search 'bearing', 'slant'
%                 or 'all' Default is 'all'; 
% *'useTDBearings' - calculate georef bearings from rotated hydrophone
%                   array and a simplex bearing calculation. Will take
%                   longer. 
%src locations
latlims = minmax(srclocations(:,2));
lonlims = minmax(srclocations(:,3));

clktimes = [clicks.date];

%time limits
timestart   = min(clktimes);
timeend     = max(clktimes);

% click amplitude variables 
vp2p=2;
sens=-201;
gain =20;
minamp = 118; %dB the minimum amplitude to use for detected clicks.
c=1500; 

%environmental varibales
patmosphere=1024;
euleroffset = 0; %euler offset- happens during BST and depdning on 
%which PG and SoundTrap host is being used.

% grid search stuff. 
maxchi2=200; 
gridsize = 200; 
srchtype = 'all' ;  %bearing, slant, all (both bearing and slant)
pretxt=''; 
%time offsets
gpsoffset = 0; % the offset in boat gps data compared to the soundtrap.
stdpthoffset = 0.5; % the depth offset of the soundtrap in meters 
%(if pressure sensor not calibrated well)

%true to use the time delays instead of the bearing measurements to locate
%the soundtraps. 
useTDBearings = false; 

iArg = 0;
while iArg < numel(varargin)
    iArg = iArg + 1;
    switch(varargin{iArg})
        case 'latlims'
            iArg = iArg + 1;
            latlims = varargin{iArg};
        case 'lonlims'
            iArg = iArg + 1;
            lonlims = varargin{iArg};
        case 'gridsize'
            iArg = iArg + 1;
            gridsize = varargin{iArg};
        case 'maxchi2'
            iArg = iArg + 1;
            maxchi2 = varargin{iArg};
        case 'gpsoffset'
            iArg = iArg + 1;
            gpsoffset = varargin{iArg};
        case 'euleroffset'
            iArg = iArg + 1;
            euleroffset = varargin{iArg};
        case 'timerange'
            iArg = iArg + 1;
            timerange = varargin{iArg};
            timestart   = timerange(1);
            timeend     = timerange(2);
        case 'vp2p'
            iArg = iArg + 1;
            vp2p = varargin{iArg};
        case 'sens'
            iArg = iArg + 1;
            sens = varargin{iArg};
        case 'gain'
            iArg = iArg + 1;
            gain = varargin{iArg};
        case 'minamp'
            iArg = iArg + 1;
            minamp = varargin{iArg};
        case 'searchtype'
            iArg = iArg + 1;
            srchtype = varargin{iArg};
        case 'pretext'
            iArg = iArg + 1;
            pretxt = varargin{iArg};
        case 'useTDBearings'
            iArg = iArg + 1;
            useTDBearings = varargin{iArg};
        case 'SoundSpeed'
            iArg = iArg + 1;
            c = varargin{iArg};
    end
    
end

%% input variables
% the matdata.
eulerangles = sensordata.EL;
pt = sensordata.PT;

clicks=clicks([clicks.date]>timestart & [clicks.date]<=timeend);

%% match euler angles to pinger clicks
anglesgeo = geo_ref_clks(clicks, eulerangles, wavsamples, euleroffset);

if (useTDBearings)
    hydrophones = get_st_hydrophones; 
    %do the same thing but instead converting positions of hydrophones.
    [georefhydros] = geo_ref_hydrophones(clicks,eulerangles, wavsamples,...
        hydrophones,euleroffset);
    for i=1:length(clicks)
        if (mod(i,5)==0)
            disp(['Calculating click bearings for hydrophones: ' num2str(i) ' of ' num2str(length(clicks))])
        end
        obstimedelays = clicks(i).timeDelays;
        
        %replace angle geo bearings.
        if (~isempty(georefhydros{i}))
            % for some reason the simplex bearing estimation does not work so well
%             [anglesgeo(i, [2 3]), ~ ] = localise_bearing_simplex(georefhydros{i}, obstimedelays, [], c);
%             anglesgeo(i,2)=rad2deg(anglesgeo(i,2));
%             anglesgeo(i,3)=rad2deg(anglesgeo(i,3));

            [vec_result, ~ ] = localise_bearing_gridsearch(georefhydros{i}, obstimedelays, c, 10000);
            anglesgeo(i,2) = atan2d(vec_result(1), vec_result(2));
            anglesgeo(i,3) = atand(vec_result(3)/sqrt(vec_result(1)^2+vec_result(2)^2));


        end
    end
end


%% prep data for min search
%calculate the click amplitudes and match to a depth


%filter clicks by amplitude
clickdB = click_amplitudes(clicks, vp2p, sens, gain);
indexfilt = clickdB>minamp & anglesgeo(:,3)>0;

clicks_filt=clicks(indexfilt);

times_filt  = [clicks.date];
times_filt = times_filt(indexfilt);

slantangles_filt=anglesgeo(indexfilt, 3);
bearing_angles_filt=anglesgeo(indexfilt, 2);

% clksgeo array for functin output
clksgeo = [times_filt'  bearing_angles_filt, slantangles_filt]; 

srcclklocation=zeros(length(clicks_filt), 2);

for i=1:length(clicks_filt)
    % print progress
    if (mod(i,50)==0)
        disp([pretxt 'Matching clicks ' num2str(i) ' of ' num2str(length(clicks_filt))])
    end
    
    %find the dive computer depths and the euler angle depths
    [minval, index]=min(abs(clicks_filt(i).date-srclocations(:,1)));
    dpthsrc=srclocations(index,4);
    
    %find location of boat
    [minval, index]=min(abs(clicks_filt(i).date-(srclocations(:,1)+gpsoffset/60/60/24)));
    srcclklocation(i, [1 2])=[srclocations(index,2), srclocations(index,3)];
    
    %find depth of soundtrap
    [minval, index]=min(abs(clicks_filt(i).date-(pt(:,1)+euleroffset)));
    srcclklocation(i,3)=millibar2depth(pt(index,3),patmosphere)+stdpthoffset - dpthsrc;
end

%convert to radians
clkgeobearings = [deg2rad(bearing_angles_filt) deg2rad(slantangles_filt)];

% now use a grid search to calculate the location.
[location, chi2, chi2surf] = ...
    grdsrch_pos(clkgeobearings, srcclklocation, 'maxchi2', maxchi2, ...
    'gridsize', gridsize, 'lonlims', lonlims, 'latlims', latlims,...
    'searchtype', srchtype, 'pretext', pretxt);

%add time to array for function output
srcclklocation = [[clicks_filt.date]' srcclklocation];
end

