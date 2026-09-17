function [clkdatastruct] = makelocstruct(clkdatastruct, smploffset)
%MAKELOCSTRUCT Add additional information to click data struct for
%loclaisation
%   [CLKDATASTRCUT] = MAKELOCSTRUCT(CLKDATASTRCUT) adds information for
%   localisation to a CLKDATASTRCUT contianing a list of clicks
%   (CLKDATASTRCUT.CLICKS) and a serial number for the SoundTrap
%   (CLKDATASTRCUT.SERIALNUM)
%
%   [CLKDATASTRCUT] = MAKELOCSTRUCT(CLKDATASTRCUT, SMPLOFFSET) adds a
%   smaple offset to the Euler angles. Note that 4 chan soundtraps this
%   will be 4*samplerate. This can be useful if there has been an error on
%   the recording leading to a consistant sample offset between sound files
%   and the sensor files. 

if nargin<2
   smploffset = 0;  
end

hydrophones= get_st_hydrophones();

%make sure the clicks in chronological order - just makes life easier. 
[~, index] = sort([clkdatastruct.clicks.date]); 
clkdatastruct.clicks = clkdatastruct.clicks(index); 

%get the associated data
[~, ~, clkdatastruct.sensordata, clkdatastruct.wavinfo, ...
    clkdatastruct.euleroffset] = get_st_data(clkdatastruct.serialnum, clkdatastruct.clicks(1).date);
 clkdatastruct.euleroffset
 
 % add a sample offset. 
clkdatastruct.sensordata.EL(:,2) = clkdatastruct.sensordata.EL(:,2) + smploffset; 

%calculate the geo referenced click bearings
[anglesgeo, ~, ~, ~] = geo_ref_clks(clkdatastruct.clicks, clkdatastruct.sensordata.EL,...
    clkdatastruct.wavinfo, clkdatastruct.euleroffset);

clkdatastruct.clkanglesgeo = anglesgeo;


%calculate the geo referenced hydrophones
[georefhydros, indexnotfound] = geo_ref_hydrophones(clkdatastruct.clicks, clkdatastruct.sensordata.EL,...
    clkdatastruct.wavinfo, hydrophones,clkdatastruct.euleroffset);

clkdatastruct.clkhydrosgeo = georefhydros;

%for convenience depths of only for click train segment to speed up finding
%depths.
clktimes = [clkdatastruct.clicks.date]; 
timemin  = min(clktimes); 
timemax  = max(clktimes);
sensordepths = clkdatastruct.sensordata.PT;

% disp(['Sensor depths before: ' num2str(length(sensordepths))]); 

%for speed
index=find((sensordepths(:,1)+ clkdatastruct.euleroffset)>=timemin & (sensordepths(:,1)+ clkdatastruct.euleroffset)<timemax);
sensordepths = sensordepths(index,:);

% disp(['Sensor depths after: ' num2str(length(sensordepths)) + ' euleroffset' ' min: ' datestr(timemin) ' max: ' datestr(timemax)]); 

%now find closest depth for each click.
for j = 1:length(clkdatastruct.clicks)
    [~,index] = min(abs(sensordepths(:,1)+ clkdatastruct.euleroffset - clkdatastruct.clicks(j).date));
    clkdatastruct.depths(j,:) = sensordepths(index,:);
end

%convert pressure to depth
clkdatastruct.depths(:,3)=-millibar2depth(clkdatastruct.depths(:,3));

%%origin
[latlong, northings, reflatlon] = get_st_pos(clkdatastruct.serialnum, clkdatastruct.clicks(1).date);


clkdatastruct.latlong =latlong;
clkdatastruct.northings =northings;
clkdatastruct.reflatlon =reflatlon;

end

