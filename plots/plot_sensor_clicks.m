%% Plot example of sensor data alongside angles and georeferenced clicks 

clear
close all

% % ST 16 October AK58000XXX-events
% % load wav samples
% wavsamplesdat = load([getsuperfolder() '/Gill nets 2016-20/SoundTrap_4c/20181002_Cornwall_AK580_H3/1678032921/1678032921_wavsamples.mat']);
% wavsamplesdat=wavsamplesdat.wavsamples;
% %load the clicks
% % load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20181002_Cornwall_AK580_H3/1678032921/20181004_062313_clicks_example.mat')
% % %load the clicks
% % load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20181002_Cornwall_AK580_H3/1678032921/20181002_113001_clicks_boat_example.mat')
% clicks16evnt=load([getsuperfolder() '/Gill nets 2016-20/SoundTrap_4c/20181002_Cornwall_AK580_H3/porp_events/20181003_1678032921_porp_track_AK58000030.mat']); 
% clicks16.serialnum=16; %shorthand serial number
% clicks = clicks16evnt.click_events.clicks; 
% 
% %load the sensor data (including angles)
% load([getsuperfolder() '/Gill nets 2016-20/SoundTrap_4c/20181002_Cornwall_AK580_H3/1678032921/sensor_data/sensorData.mat'])
% eulerangles=matdata.EL;
% euleroffset = 1/24; 

% % ST 13 October AK58000XXX-events
% % load wav samples
% wavsamplesdat = load([getsuperfolder() '/Gill nets 2016-20/SoundTrap_4c/20181002_Cornwall_AK580_H3/134250533/13425033_wavsamples.mat']);
% wavsamplesdat=wavsamplesdat.wavsamples;
% %load the clicks
% % load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20181002_Cornwall_AK580_H3/1678032921/20181004_062313_clicks_example.mat')
% % %load the clicks
% % load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20181002_Cornwall_AK580_H3/1678032921/20181002_113001_clicks_boat_example.mat')
% clicks13evnt=load([getsuperfolder() '/Gill nets 2016-20/SoundTrap_4c/20181002_Cornwall_AK580_H3/porp_events/20181003_134250533_porp_track_AK58000030.mat']); 
% clicks16.serialnum=16; %shorthand serial number
% clicks = clicks13evnt.click_events.clicks; 
% 
% %load the sensor data (including angles)
% load([getsuperfolder() '/Gill nets 2016-20/SoundTrap_4c/20181002_Cornwall_AK580_H3/134250533/sensor_data/sensorData_drft_fix.mat'])
% eulerangles=matdata.EL;
% % added an offset
% % eulerangles(:,2)=eulerangles(:,2)+4*5.1298e+05;
% % eulerangles(:,2)=eulerangles(:,2)+4*557022;
% eulerangles(:,2)=eulerangles(:,2);
% euleroffset = 1/24; 

 
% % ST 16 October - test clic
% % load wav samples
% wavsamplesdat = load([getsuperfolder() '/Gill nets 2016-20/SoundTrap_4c/20181002_Cornwall_AK580_H3/1678032921/1678032921_wavsamples.mat']);
% wavsamplesdat=wavsamplesdat.wavsamples;
% 
% %load the clicks
% % load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20181002_Cornwall_AK580_H3/1678032921/20181004_062313_clicks_example.mat')
% % %load the clicks
% % load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20181002_Cornwall_AK580_H3/1678032921/20181002_113001_clicks_boat_example.mat')
% load([getsuperfolder() '/Gill nets 2016-20/SoundTrap_4c/20181002_Cornwall_AK580_H3/st_location/1678032921_clks_boat_prop.mat'])
% %load the sensor data (including angles)
% load([getsuperfolder() '/Gill nets 2016-20/SoundTrap_4c/20181002_Cornwall_AK580_H3/1678032921/sensor_data/sensorData.mat'])
% eulerangles=matdata.EL;
% euleroffset = 1/24; 
 
% % % ST 16 December 2018
% load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20181130_Cornwall_AK587_H5/1678032921/1678032921_wavsamples.mat')
% %load the clicks
% load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20181130_Cornwall_AK587_H5/device_locations/1678032921_clicks_boat_prop.mat')
% clicks= click_events.clicks;
% % load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20181130_Cornwall_AK587_H5/1678032921/20181202_clicks_boat_prop_example.mat')
% %load the clicks
% % load the sensor data (including angles)
% load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20181130_Cornwall_AK587_H5/1678032921/sensor_data/1678032921.sensorData.mat')
% eulerangles=matdata.EL; 
% euleroffset = 0; 

% % ST 16 14th Novemeber 2019
% % load sensor data
% time = datenum('20191114', 'yyyymmdd'); 
% [~, ~, sensordata, wavsamplesdat, euleroffset] = get_st_data(1678032921,time); 
% eulerangles=sensordata.EL; 
% % load the clicks
% load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20191114_Cornwall_AK627_H3/1678032921/1678032921_annotated_clicks.mat')
% [clicks, eventID] = concateventclks(click_events, {'porp', 'porpbuzz'}); 
% % %boatprop
% % % load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20191114_Cornwall_AK627_H3/st_location/1678032921_clks_boat_prop.mat')
% % % clicks= click_events.clicks;


% % ST 13 11th Novemeber 2019
% % load sensor data
% time = datenum('20191111', 'yyyymmdd'); 
% [~, ~, sensordata, wavsamplesdat, euleroffset] = get_st_data(13,time); 
% eulerangles=sensordata.EL; 
% % %boatprop
% % load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20191111_Cornwall_AK625_H1/st_location/134250533_clks_boat_prop.mat');
% % clicks= click_events.clicks;
% %click train
% load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20191111_Cornwall_AK625_H1/porp_events/20191111_134250533_porp_track_AK6250002.mat');
% clicks= click_events(2).clicks;


% % ST 16 11th Novemeber 2019
% % load sensor data
% time = datenum('20191111', 'yyyymmdd'); 
% [~, ~, sensordata, wavsamplesdat, euleroffset] = get_st_data(16,time); 
% eulerangles=sensordata.EL; 
% % %boatprop
% load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20191111_Cornwall_AK625_H1/st_location/1678032921_clks_boat_prop.mat');
% clicks= click_events.clicks;

% % ST 13 14-16th Novemeber 2019
% % load sensor data
% time = datenum('20191114', 'yyyymmdd');
% [~, ~, sensordata, wavsamplesdat, euleroffset] = get_st_data(13,time);
% eulerangles=sensordata.EL;
% % load the clicks
% % load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20191114_Cornwall_AK627_H3/134250533/1342505233_annotated_clicks.mat')
% % [clicks, eventID] = concateventclks(click_events, {'porp', 'porpbuzz'});
% % %boatprop
% load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20191114_Cornwall_AK627_H3/st_location/134250533_clks_boat_prop.mat')
% clicks= click_events.clicks;
% Porpoise event AK6270001 st 13 
% clicks13evnt=load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20191114_Cornwall_AK627_H3/porp_events/20191115_134250533_porp_track_AK6270001.mat');
% clicks = tagclks2event(clicks13evnt.click_events);
% % Event 627002 which has two porpoises- see what the georeferenced
% bearings looks like 
% day_num_start = datenum('20191116 00:34:51', 'yyyymmdd HH:MM:SS');
% day_num_end = datenum('20191116 00:41:00', 'yyyymmdd HH:MM:SS');
% binaryFolder= 'C:/Users/au671271/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20191114_Cornwall_AK627_H3/134250533/Binary';
% clicks = load_clicks(binaryFolder, -1, 1, day_num_start, day_num_end, ...
%     false, 'Click_Detector_Click_Detector_Clicks_', 'Click_Detector_Click_Detector_90kHz');

%  % ST 16 14-16th Novemeber 2019
% % load sensor data
% time = datenum('20191115', 'yyyymmdd');
% [~, ~, sensordata, wavsamplesdat, euleroffset] = get_st_data(16,time);
% eulerangles=sensordata.EL;
% % load the clicks
% % load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20191114_Cornwall_AK627_H3/134250533/1342505233_annotated_clicks.mat')
% % [clicks, eventID] = concateventclks(click_events, {'porp', 'porpbuzz'});
% % % Porpoise event AK6270001 st 16
% % clicks16evnt=load('E:/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20191114_Cornwall_AK627_H3/porp_events/20191115_1678032921_porp_track_AK6270001.mat');
% % clicks = tagclks2event(clicks16evnt.click_events);
% day_num_start = datenum('20191116 00:34:51', 'yyyymmdd HH:MM:SS');
% day_num_end = datenum('20191116 00:41:00', 'yyyymmdd HH:MM:SS');
% binaryFolder= 'C:/Users/au671271/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20191114_Cornwall_AK627_H3/1678032921/Binary';
% sqlLite_dB= 'C:/Users/au671271/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/20191114_Cornwall_AK627_H3/1678032921/st4c_gilllnet_Cornwall_1678032921_annotated.sqlite3';
% click_events = load_event_clicks( sqlLite_dB, binaryFolder, day_num_start, day_num_end);
% clicks = click_events.clicks;

%the time limits
clktimes = [clicks.date];
timemin=min(clktimes);
timemax=max(clktimes);

clicks=clicks(clktimes>timemin & clktimes<timemax); 

% do the matching etc. 
disp('Matching clicks...this can take some time')
[anglesgeo, abssmplsclk, abssmpleseul, indexnotfound] = geo_ref_clks(clicks, eulerangles,...
    wavsamplesdat, euleroffset); 

%extract the click angles 
clickbearings = zeros(length(clicks), 1);
clickstimes=[clicks.date];
for i=1:length(clicks)
    clickbearings(i,1)=rad2deg(wrapToPi(clicks(i).angles(1)));
    clickbearings(i,2)=rad2deg(clicks(i).angles(2));
end

% get rid of the euler angles outwith click times. 
index=find((eulerangles(:,1)+euleroffset)>=timemin & (eulerangles(:,1)+euleroffset)<timemax);

eulerangles=eulerangles(index,:); 
abssmpleseul=abssmpleseul(index); 

%now plot it all. 
figure(1);
clf
hold on 
title('Heading Angle')
scatter(abssmpleseul(:,1), eulerangles(:,5), '.'); 
scatter(abssmplsclk(:,1), clickbearings(:,1),'.'); 
scatter(anglesgeo(:,1), anglesgeo(:,2),'.'); 
scatter(abssmpleseul(:,1), eulerangles(:,3), '.'); 
legend('Euler angles', 'loc bearings','geo-ref bearings', 'Roll')
hold off
ylabel ('heading degrees')
xlabel('Samples')


figure(2)
clf
hold on 
title('Slant Angle')
scatter(abssmpleseul(:,1), eulerangles(:,4), '.'); 
scatter(abssmpleseul(:,1), eulerangles(:,3), '.'); 
scatter(abssmplsclk(:,1), clickbearings(:,2),'.'); 
scatter(anglesgeo(:,1), anglesgeo(:,3),'.'); 
legend('Pitch', 'Roll', 'loc bearings','geo-ref bearings')
hold off
ylabel ('heading degrees')
xlabel('Samples')


figure(3);
clf
hold on
clicktimes=[clicks.date]; 
scatter(clicktimes, abssmplsclk(:,1)); 
scatter(eulerangles(:,1)+euleroffset, abssmpleseul); 
hold off
ylabel('Samples')
xlabel('Time')

print('-clipboard','-dbitmap')
