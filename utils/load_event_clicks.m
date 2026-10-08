function [ click_events ] = load_event_clicks( sqlLite_dB, binaryfolder, startDate, endDate)
%LOAD_EVENT_CLICKS Convenience fun ction to load event clicks from a database.
%  Loads annotated clicks from PAMGuard. The inputs are a path to the
%  sqlite database and a binary file folder containing all the clicks. The
%  function returns a structure of click events including the annotated
%  clicks.
% INPUTS
% sqlLite_dB -  path to database file
% binaryfolder - path to binary folder
% startDate - star date in MATLAB datenum
% endDate- end date in MATLAB datenum
%
%
% sqlLite_dB = '/Users/jdjm/Library/CloudStorage/Dropbox/SMRU_research/2016-20 Gill nets/SoundTrap_4c/20191114_Cornwall_AK627_H3/134250533/st4c_gilllnet_Cornwall_134250533_annotated_buzzes.sqlite3';
% binaryfolder = '/Users/jdjm/Library/CloudStorage/Dropbox/SMRU_research/2016-20 Gill nets/SoundTrap_4c/20191114_Cornwall_AK627_H3/134250533/Binary';

verbose = 1; 
% if nargin<1
%     [deviceinfo] = device_lookup(1678303270);
%     sqlLite_dB=deviceinfo.database;
%     binaryfolder=deviceinfo.binaryfolder;
%     startDate=datenum('22-02-2018 00:00:00', 'dd-mm-yyyy HH:MM:SS' );
%     endDate=datenum('24-02-2018 23:59:59', 'dd-mm-yyyy HH:MM:SS' );
% end
% 
if nargin < 3
     startDate  = 0;
     endDate = datenum('1 Jan 2099');
end
% 
if nargin < 4
     endDate = datenum('1 Jan 2099');
end


%% first read the event table data from the database.
conn = sqlite(sqlLite_dB,'readonly');
% conn = sqlitedatabase(sqlLite_dB);

% setdbprefs('DataReturnFormat','cellarray') %<- does not work on 2018 above?

sqlquery = 'select Id, UTC, UTCMilliseconds, PCLocalTime, PCTime, EventId, BinaryFile, ClickNo, Amplitude, Channels, UID, ChannelBitmap, parentID, parentUID, LongDataName from Click_Detector_OfflineClicks';
% curs = fetch(conn, sqlquery, 'DataReturnFormat','cellarray'); % does not work on 2017 below
cursclicks = fetch(conn, sqlquery, 'DataReturnFormat', 'cellarray');
fileNamesAll=cursclicks(:,7);
clickNosAll=cell2mat(cursclicks(:,11));
clicksTimeAll=cursclicks(:,2);
eventIdH=cell2mat(cursclicks(:,6));

% disp('Found the following event IDs');
% disp(num2str(unique(eventId)))

sqlquery = 'select Id, UTC, UTCMilliseconds, PCLocalTime, PCTime, ChannelBitmap, EventEnd, eventType, nClicks, ifnull(minNumber,0),  ifnull(bestNumber,0),  ifnull(maxNumber, 0),  ifnull(colour,0), ifnull(comment,"none"), channels, UID  from Click_Detector_OfflineEvents';
% cursevent = fetch(conn, sqlquery, 'DataReturnFormat','cellarray'); % does not work on 2017 below
cursevent = fetch(conn, sqlquery, 'DataReturnFormat', 'cellarray');

close(conn)

clickTimesAllNum=zeros(length(clicksTimeAll), 1);
for j=1:length(clicksTimeAll)
    clickTimesAllNum(j)=datenum(clicksTimeAll{j}, 'yyyy-mm-dd HH:MM:SS.FFF');
end


%reduce procesisng time by removing clicks
index = (clickTimesAllNum>=startDate & clickTimesAllNum<=endDate );
fileNamesAll=fileNamesAll(index);
clickNosAll=clickNosAll(index);
clicksTimeAll=clicksTimeAll(index);
eventId=eventIdH(index);
clickTimesAllNum=clickTimesAllNum(index);

eventIDs=cell2mat(cursevent(:,1));


%%now get data into format that we need

%now extract some clicks
disp(['Number event clicks: ' num2str(length(eventIdH))]);


n=1;
for i=1:max(eventIDs)

    index=find(eventId==i);
    if (isempty(index))
        continue;
    end

    indexEvent=find(eventIDs==i);

    %find event info
    %%TODO add more event info
    comment=cell2mat(cursevent(indexEvent, 14));
    type=cell2mat(cursevent(indexEvent, 8));
    eventUID=cell2mat(cursevent(indexEvent, 15));
    eventdatestr=cell2mat(cursevent(indexEvent, 2));

    files=fileNamesAll(index);
    clickNo=clickNosAll(index);
    %     clickTimes=clicksTimeAll(index);
    clickTimesNum=clickTimesAllNum(index);

    %%now check the event is within time range. To be in time range at
    %%least one click must be between startTime and endTime
    if (isempty(clickTimesNum(clickTimesNum > startDate & clickTimesNum <endDate)))
        disp(['Clicks out of time range: ' datestr(clickTimesNum(1))])
        continue;
    end

    %     clickTimesNum=zeros(length(clickTimes), 1);
    %     for j=1:length(clickTimes)
    %         clickTimesNum(j)=datenum(clickTimes{j}, 'yyyy-mm-dd HH:MM:SS.FFF');
    %     end

    eventrange=[min(clickTimesNum) max(clickTimesNum)];

    disp(['Loading event clicks: ' num2str(i) ' of ' num2str(max(eventIDs)) ' between '  datestr(eventrange(1)) ' and ' datestr(eventrange(2))])

    try
       
        clicks = pgmatlab.loadPamguardMultiFile(binaryfolder, files, clickNo, verbose);

        if (isempty(clicks))
            continue
        end
        
        % clicks=loadEventClicks(binaryfolder, files, clickNo, eventrange);
        click_events(n).clicks=clicks;
        click_events(n).event_id=i;
        click_events(n).date=min([clicks.date]); % for compatibility with buzz structures.
        click_events(n).end_date=max([clicks.date]); % for compatibility with buzz structures.
        click_events(n).comment=comment;
        click_events(n).event_type=type;
        click_events(n).eventUID=eventUID;
        click_events(n).datestr=eventdatestr;


        n=n+1;
    catch e
        rethrow(e)
        warning(['Could notload event ' num2str(i)])
    end


end

if n==1
    click_events=[];
end
% end
