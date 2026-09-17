clear
close all

%% load the source locations 
stserialno = 1678032921; 
% stserialno = 134250533; 
c=1500; %default sound speed in meters per second. 

% % ST 16 and 13 October 2018
% date = datenum('20181002', 'yyyymmdd'); % first full  deployment with trial.
% c=1507; %measured sound speed for that deploymnet
% latlims=[50.07, 50.076];
% lonlims=[-5.058, -5.052];

% % ST 16 02 December 2018 (30th Novemeber deployment) AK_587
% date = datenum('20181201', 'yyyymmdd'); % first full  deployment with trial.
% %for ST 16 - search type should be 'all'
% mincllktime = datenum('20181202 14:09:34','yyyymmdd HH:MM:SS'); 
% maxcllktime = datenum('20181202 14:13:18','yyyymmdd HH:MM:SS'); 

%for ST 13 - searchtype should be 'slant'
% mincllktime = -inf;
% maxcllktime = inf;

% % %ST 13 and 16 Novemeber 11th 2019 AK625
% date = datenum('20191111', 'yyyymmdd'); 
% mincllktime = -inf;
% maxcllktime = inf;

% %ST 13 and 16 November 14th 2019 (Bycatch incident) AK627
date = datenum('20191114', 'yyyymmdd'); 
mincllktime = datenum('20191114 10:05:00','yyyymmdd HH:MM:SS'); 
maxcllktime = datenum('20191114 10:15:00','yyyymmdd HH:MM:SS'); 

useprop=true; % propellor = true, porp pings = false;
[srclocations, clicks, gpsoffset] = get_st_pinger(stserialno, date, useprop);
[~, ~, sensordata, wavinfo, euleroffset] = get_st_data(stserialno,date);

%%TEMP
% clicks = clicks([clicks.date]> datenum('20181002 10:47:00', 'yyyymmdd HH:MM:SS')); 

% %%TEMP%%
% mincllktime = min(srclocations(:,1));
% maxcllktime =  max(srclocations(:,1));
% %%%%%%%%

%IMPORTANT to filter by source locations or clicks outwith the first or
%last src time will get matched to the first and last clicks leading to
%false data for the GPS...i.e. the first set of clicks might all be tagged with
%the first GPS location unitll GPS click times overlap. 
clicks = clicks([clicks.date]>=min(srclocations(:,1)) & [clicks.date]<max(srclocations(:,1)) ); 

% locate the position the SoundTrap
[location, chi2, chi2surf, clksgeo, srclocationclk] = locate_pos(clicks,...
    sensordata, wavinfo, srclocations,'euleroffset', euleroffset,...
    'gridsize', 100, 'searchtype', 'all', 'minamp', 100, 'SoundSpeed', c, ...
    'useTDBearings', false);

% 'latlims', [50.0738, 50.075], 'lonlims', [-5.05555, -5.05416]);

% plot the grid search surface 
% location = [50.0743246231156	-5.05518678391960]; 
figure(1)
clf
h1 = plot_chi2_surf(chi2surf, srclocations, location);
hold on
scatter3(srclocationclk(:,3), srclocationclk(:,2),...
    (max(max(chi2surf.chi2))+10)*ones(length(srclocationclk(:,3)), 1),'.')
caxis([0,5])
set(gca, 'FontSize', 12)

% plot the bearings of the source compared to the bearings of the 
% geo referenced clicks. 
figure(2)
clf
[h2, srcbearings]  = plot_clk_src_bearings(location, clksgeo, srclocationclk); 
set(gca, 'FontSize', 14)


figure(3)
bearingdiff = srcbearings(:,1)-clksgeo(:,2); 
slantdiff = srcbearings(:,2)-clksgeo(:,3); 
boxplot([bearingdiff slantdiff], {'Bearing', 'Slant'});
ylabel('Error (degrees)')
slantdelta = [median(slantdiff) std(slantdiff)];
bearingdelta = [median(bearingdiff) std(bearingdiff)];

print('-clipboard','-dbitmap')
