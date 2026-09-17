%% run through a bunch of possible time offsets. 
clear 

gpsoffsets =-120:5:120; % set of time offsets to investigate;
% stserialno = 1678032921; 
stserialno = 134250533; 

% ST 16 and 13 October 2018
date = datenum('20181002', 'yyyymmdd'); % first full  deployment with trial.
% mincllktime=737335.424152049; 
% maxcllktime = 737335.466520648;
% latlims=[50.07, 50.076];
% lonlims=[-5.058, -5.052];

% % ST 16 December 2018 -AK587
% date = datenum('20181201', 'yyyymmdd'); % first full  deployment with trial.
% mincllktime = datenum('20181202 14:09:34','yyyymmdd HH:MM:SS');
% maxcllktime = datenum('20181202 14:13:18','yyyymmdd HH:MM:SS'); 
% %ST 13

% % %ST 13 and 16 Novemeber 11th 2019
% date = datenum('20191111', 'yyyymmdd'); 

mincllktime = -inf;
maxcllktime = inf; 

% load up the sensor data. 
[~, ~, sensordata, wavinfo, euleroffset] = get_st_data(stserialno, date);

%% load the source locations 
for i=1:length(gpsoffsets)
    
useprop=true; % propellor = true, porp pings = false;
[srclocations, clicks] = get_st_pinger(stserialno, date, useprop, gpsoffsets(i));

%%TEMP
clicks = clicks([clicks.date]> datenum('20181002 10:47:00', 'yyyymmdd HH:MM:SS')); 

% clicks = clicks([clicks.date]>=mincllktime & [clicks.date]<maxcllktime ); 
clicks = clicks([clicks.date]>=min(srclocations(:,1)) & [clicks.date]<max(srclocations(:,1)) ); 

pretext= ['Time offset: ' num2str(i) ' of ' num2str(length(gpsoffsets)) ' '];
% locate the position the SoundTrap
[location(i,:), chi2(i), chi2surf, clksgeo, srclocationclk] = locate_pos(clicks,sensordata, wavinfo, srclocations, ...
    'euleroffset', euleroffset, 'gridsize', 50, ...
     'searchtype', 'all', 'pretext', pretext);

% % plot the grid search surface 
% figure(1)
% h1 = plot_chi2_surf(chi2surf, srclocations, location);
% 
% % plot the bearings of the source compared to the bearings of the 
% % geo referenced clicks. 
% figure(2)
% h2 = plot_clk_src_bearings(location, clksgeo, srclocationclk); 

end

%%now plot the chi2 values
gpsoffsets = gpsoffsets(1:length(chi2));
intrpgpsoffset=min(gpsoffsets):0.1:max(gpsoffsets);

figure(3)
clf
hold on
plot(gpsoffsets, chi2);
interpchi2 = interp1(gpsoffsets, chi2,intrpgpsoffset, 'cubic');
plot(gpsoffsets, smooth(chi2));
hold off
xlabel('Time offset')
ylabel('Minimum chi^2 value'); 

figure(1)
clf
% plot the location with the lowest chi2 value
[~, index] = min(chi2); 
h2 = plot_clk_src_bearings(location(index,:), clksgeo, srclocationclk); 


print('-clipboard','-dbitmap')
