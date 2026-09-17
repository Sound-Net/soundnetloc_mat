%% PLOT BEARINGS FROM 2+ SOUNTRAPS
% PLOTS BEARINGS FROM TWO OR MORE SOUNDTRAPS ON A SUBPLOT
%% Plot bearings from two or more soundtraps on a subplot. 


%intial variables. 
eventcomment='pclk_train_0001';
% eventtype='prpbzz'; 

eventtype=[]; 

euleroffset=0; 

time = datenum('20181201', 'yyyymmdd');

% the video start and end time
starttime = datenum('2018-12-01 17:49:02','yyyy-mm-dd HH:MM:SS'); 
endtime = datenum('2018-12-01 17:54:23','yyyy-mm-dd HH:MM:SS'); 


%% ST13
stseria13 = 134250533;

[sqlitedB, binaryfolder, sensordata13, wavinfo] = get_st_data(stseria13,time);
eulerangles13=sensordata13.EL;

[anglesgeo13, clicks13] = geo_ref_clktrain(sqlitedB, binaryfolder,... 
    wavinfo, eulerangles13, 'euleroffset', euleroffset, ...
    'eventtype', eventtype, 'eventcomment', eventcomment); 

[storigin13] = st_origin([clicks13.date], sensordata13.PT, stseria13, euleroffset);

clickbearings13 = [[clicks13.date] ; rad2deg([clicks13.angles])]';

%% ST16
stseria16 = 1678032921;

[sqlitedB, binaryfolder, sensordata16, wavinfo] = get_st_data(stseria16,time);
eulerangles16=sensordata16.EL;

[anglesgeo16, clicks16] = geo_ref_clktrain(sqlitedB, binaryfolder,... 
wavinfo, eulerangles16, 'euleroffset', euleroffset, ...
'eventtype', eventtype, 'eventcomment', eventcomment);

clickbearings16 = [[clicks16.date] ; rad2deg([clicks16.angles])]';

timelims=[min(clickbearings16(:,1)) max(clickbearings16(:,1))]; 

subplot(2,1,1)
[h1] = plotbearingtime(clickbearings16, anglesgeo16, eulerangles16, 'timelimits', timelims);
datetick x

subplot(2,1,2)
[h2] = plotbearingtime(clickbearings13, anglesgeo13, eulerangles13, 'timelimits', timelims); 
datetick x
