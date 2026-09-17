%A conveneince script with functions or loading marked out event for SondTraps
clear 

% %ST16 - Novemeber/December 2018
% [sqlitedB, binaryfolder, sensordata, wavinfo, euleroffset] = ...
%     get_st_data(1678032921,datenum('20181130', 'yyyymmdd')); 
% 
%ST16 - 14th Novemeber 2019
% [sqlitedB, binaryfolder, sensordata, wavinfo, euleroffset] = ...
%     get_st_data(1678032921,datenum('20191114', 'yyyymmdd')); 
%ST13 - 14th Novemeber 2019
[sqlitedB, binaryfolder, sensordata, wavinfo, euleroffset] = ...
    get_st_data(134250533,datenum('20191114', 'yyyymmdd')); 


% loadSt Data data
[ click_events ] = load_event_clicks(sqlitedB, binaryfolder); 

