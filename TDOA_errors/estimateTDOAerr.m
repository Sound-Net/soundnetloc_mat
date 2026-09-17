%% compare the TDOA error simulations to actual TDOA errors recieved duribng the calibration experiment.

clear

c=1500;
% load the boat GPS data.
load('E:\Google Drive\SMRU_research\Gill nets 2016-20\SoundTrap_4c\20181002_Cornwall_AK580_H3\gps_boat\androsensordata.mat');
% %ST16
% % load wav samples
load('E:\Google Drive\SMRU_research\Gill nets 2016-20\SoundTrap_4c\20181002_Cornwall_AK580_H3\1678032921\1678032921_wavsamples.mat')
% %load the clicks
load('E:\Google Drive\Programming\MATLAB\research_SMRU\gill_nets\soundtrap_4c\deployments\20181002_trial\loc_calibration\st16_clicks_loc_cal_UID_NBHF_only.mat')
% % load('E:\Google Drive\SMRU\Programming\MATLAB\research_SMRU\gill_nets\soundtrap_4c\localisation\loc_calibration\st16_clicks_loc_cal_nonzerofill.mat')
% %load the angles
load('E:\Google Drive\SMRU_research\Gill nets 2016-20\SoundTrap_4c\20181002_Cornwall_AK580_H3\1678032921\sensor_data\sensorData.mat')
serialnumber = 1678032921;

%import the trigger data,
load('E:\Google Drive\Programming\MATLAB\research_SMRU\gill_nets\soundtrap_4c\localisation\TDOA_errors\20181002_st16_clktrigger.mat')

% the matdata.
eulerangles=matdata.EL;
euleroffset=1/24;

depths = matdata.PT;
depths(:,3)=millibar2depth(depths(:,3));
%only use depths we need to make search faster
depths = depths(depths(:,1)>min([clicks.date]) & depths(:,1)<max([clicks.date]),:);

% get the locations of the pinger.
[srclocations, clks] = get_st_pinger(serialnumber, clicks(1).date, false);

% get the location of the soundtrap
[~, stpos, reflatlon] = get_st_pos(serialnumber, clicks(1).date);

%calculate the SNR of the clicks.
[~, snrclks] = snr_clicks(clicks);

% work out hydrophone positions.
[georefhydros, indexnotfound] = geo_ref_hydrophones(clicks,...
    eulerangles, wavsamples, get_st_hydrophones(), euleroffset);

%convert the gps data to northing
srcnorthings = latLong2Northings(srclocations(:, [2 3]), reflatlon);

%% Better way to calculate clk SNR %%
clksnr = zeros(length(snrclks),1);
for i=1:length(snrclks)
    noise = interp1(clktriggerdat(:,1), clktriggerdat(:,2), clicks(i).date, 'linear');
    clksnr(i) = 20*log10(snrclks(i,3)/(2*noise))+5; % the amplitude of clicks
end
%%%%%%%%%%%%%

%% now work out the time delay erros for each snr
tderrs = [];
for i=1:length(clicks)
    
    if (mod(i, 100)==0)
        disp(['Clicks: ' num2str(i) ' of  ' num2str(length(clicks))])
    end
    
    hydrophonepos = georefhydros{i};
    if (isempty(hydrophonepos))
        continue;
    end
        
    %what is the depth of the soundtrap?
    [~, index] = min(abs(depths(:,1)-clicks(i).date));
    adepth  = depths(index,3);
    astpos = [stpos adepth];

    hydrophonepos=hydrophonepos+astpos;

    [~, indexsrc] = min(abs(srclocations(:,1)-clicks(i).date));
    
    %what would be the time delay generated for those clicks?
    sourcpos  = [srcnorthings(indexsrc,:) srclocations(indexsrc,4)];
    
    %calculate the time delays
    simdelays = calc_time_delays(hydrophonepos, sourcpos, c, 'cartesian');
    obsdelay = clicks(i).delays;
    
    tderr = [clksnr(i)*ones(length(obsdelay),1) simdelays-obsdelay'];
    
    tderrs=[tderrs;tderr];
end

%%now we need to make a plot of snr versus time delay errors
%this is for 15cm travel 
tderrorsstruct = load('E:\Google Drive\Programming\MATLAB\localisation\tdoa_error\tdoa_nbhf_lookup.mat');
snrvals = abs(tderrorsstruct.snr);
tderrors = tderrorsstruct.errvaluesstd(:,4)*10e-3/3; %microseconds

%group TDOA errorrr by snr
snrbin=abs(snrvals(2)-snrvals(1)); 

for i=1:length(snrvals)
    index = find(tderrs(:,1)>(snrvals(i)-snrbin) & tderrs(:,1)<(snrvals(i)+snrbin));
    
    tderrvals = tderrs(index,2); 
    
    
    tderrorsobs(i,1) = (mean(abs(tderrvals))); 
    tderrorsobs(i,2) = std(tderrvals); 
end

%plot simulated data
hold on


tderrsplt=tderrs(tderrs(:,1)>10,:);
scatter(tderrs(:,1), tderrs(:,2), '.', 'MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2)
set(gca,'yscale','log')

semilogy(snrvals, tderrors, 'LineWidth', 2)
semilogy(snrvals, tderrorsobs(:,1), 'LineWidth', 2)
% semilogy(snrvals, tderrorsobs(:,2))

xlabel ('SNR (dB)' )
ylabel (['Time Delay Error (' char(181) 's)'])
legend('Time delay error', 'Simulated standard time delay error', 'Mean observed time delay error');
hold off








