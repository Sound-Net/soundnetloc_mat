function [ click_events ] = load_event_clicks( sqlLite_dB, binaryfolder, startDate, endDate, varargin)
%LOAD_EVENT_CLICKS Convenience function to load event clicks from a database.
%  Loads annotated clicks from PAMGuard. The inputs are a path to the
%  sqlite database and a binary file folder containing all the clicks. The
%  function returns a structure of click events including the annotated
%  clicks.
%
%  CLICK_EVENTS = LOAD_EVENT_CLICKS(SQLLITE_DB, BINARYFOLDER, STARTDATE,
%  ENDDATE, NAME, VALUE...) loads the events with at least one click
%  between STARTDATE and ENDDATE.
%
% INPUTS
% sqlLite_dB -  path to database file
% binaryfolder - path to binary folder
% startDate - start date in MATLAB datenum ([] or not given = no limit)
% endDate - end date in MATLAB datenum ([] or not given = no limit)
%
% Name-value options:
% 'waveforms' - false drops the waveform (WAVE) of every click once it is
%               loaded, which for long deployments saves GBs. The SNR of
%               the click (dB, SNR_CLICKS) is kept in the field SNR so the
%               time delay errors can still be found (ERROR_TDOA) [true]
% 'comment'   - only load the events whose comment matches this SQL LIKE
%               pattern, e.g. 'PP1%' ['' = every event]
% 'verbose'   - print progress [true]
%
% Each binary file is read once, for the clicks of every event in it.
%
% sqlLite_dB = '/Users/jdjm/Library/CloudStorage/Dropbox/SMRU_research/2016-20 Gill nets/SoundTrap_4c/20191114_Cornwall_AK627_H3/134250533/st4c_gilllnet_Cornwall_134250533_annotated_buzzes.sqlite3';
% binaryfolder = '/Users/jdjm/Library/CloudStorage/Dropbox/SMRU_research/2016-20 Gill nets/SoundTrap_4c/20191114_Cornwall_AK627_H3/134250533/Binary';

if nargin < 3 || isempty(startDate)
    startDate = 0;
end
if nargin < 4 || isempty(endDate)
    endDate = datenum('1 Jan 2099');
end

p = inputParser;
p.addParameter('waveforms', true);
p.addParameter('comment', '');
p.addParameter('verbose', true);
p.parse(varargin{:});
keepwave = p.Results.waveforms;
verbose = p.Results.verbose;

%% first read the event table data from the database.
conn = sqlite(sqlLite_dB,'readonly');

% Event clicks can be stored in one of two formats:
%  - Legacy format: clicks are in Click_Detector_OfflineClicks with an
%    EventId column linking to Click_Detector_OfflineEvents.
%  - New format (click events subsumed into detection groups): clicks are
%    in Click_Detector_OfflineEvents_Children with parentID linking to
%    Click_Detector_OfflineEvents (Click_Detector_OfflineClicks is empty).
% Both are read (if present) and merged so either format, or a mix, works.
fileNamesAll = {};
clickNosAll = [];
clicksTimeAll = {};
eventIdH = [];

% only the events whose comment matches
where = '';
if ~isempty(p.Results.comment)
    where = sprintf(' where comment like ''%s''', strrep(p.Results.comment, '''', ''''''));
end
eventsquery = ['select Id from Click_Detector_OfflineEvents' where];

% legacy format
if (table_exists(conn, 'Click_Detector_OfflineClicks'))
    sqlquery = 'select UTC, EventId, BinaryFile, UID from Click_Detector_OfflineClicks';
    if ~isempty(where)
        sqlquery = [sqlquery ' where EventId in (' eventsquery ')'];
    end
    cursclicks = fetch(conn, sqlquery, 'DataReturnFormat', 'cellarray');
    if (~isempty(cursclicks))
        fileNamesAll=strip(cursclicks(:,3)); % database names can be padded with trailing spaces (fix from Michael Ladegaard)
        clickNosAll=double(cell2mat(cursclicks(:,4)));
        clicksTimeAll=cursclicks(:,1);
        eventIdH=double(cell2mat(cursclicks(:,2)));
    end
end
nLegacy = length(eventIdH);

% new detection group format
nNew = 0;
if (table_exists(conn, 'Click_Detector_OfflineEvents_Children'))
    sqlquery = 'select UTC, BinaryFile, UID, parentID, LongDataName from Click_Detector_OfflineEvents_Children';
    if ~isempty(where)
        sqlquery = [sqlquery ' where parentID in (' eventsquery ')'];
    end
    curschildren = fetch(conn, sqlquery, 'DataReturnFormat', 'cellarray');
    if (~isempty(curschildren))
        % detection groups can hold children from other data blocks - keep
        % only clicks (LongDataName is e.g. 'Click Detector, Clicks').
        dataNames = strip(curschildren(:,5));
        isClick = endsWith(dataNames, 'Clicks', 'IgnoreCase', true);
        if (~any(isClick))
            isClick = true(size(dataNames)); % unusual naming, keep everything
        end
        curschildren = curschildren(isClick, :);
        nNew = size(curschildren, 1);

        fileNamesAll=[fileNamesAll(:); strip(curschildren(:,2))];
        clickNosAll=[clickNosAll(:); double(cell2mat(curschildren(:,3)))];
        clicksTimeAll=[clicksTimeAll(:); curschildren(:,1)];
        eventIdH=[eventIdH(:); double(cell2mat(curschildren(:,4)))];
    end
end

if (verbose)
    disp(['Event clicks found: ' num2str(nLegacy) ' in legacy OfflineClicks table, ' ...
        num2str(nNew) ' in detection group (OfflineEvents_Children) table']);
end

% an event with clicks in the legacy table takes them from there only.
% Code that writes events to the legacy table (e.g. WRITE_TRACK_EVENTS)
% does not touch the detection group table, so where events have been
% rewritten that table can be stale and point at the wrong events.
if (nLegacy > 0 && nNew > 0)
    isNew = (1:numel(eventIdH))' > nLegacy;
    keep = ~isNew | ~ismember(eventIdH(:), eventIdH(1:nLegacy));
    % and remove any duplicates (same click in same event)
    [~, iu] = unique([eventIdH(:) clickNosAll(:)], 'rows', 'stable');
    iu = iu(keep(iu));
    fileNamesAll = fileNamesAll(iu);
    clickNosAll = clickNosAll(iu);
    clicksTimeAll = clicksTimeAll(iu);
    eventIdH = eventIdH(iu);
end

sqlquery = 'select Id, UTC, UTCMilliseconds, PCLocalTime, PCTime, ChannelBitmap, EventEnd, eventType, nClicks, ifnull(minNumber,0),  ifnull(bestNumber,0),  ifnull(maxNumber, 0),  ifnull(colour,0), ifnull(comment,"none"), channels, UID  from Click_Detector_OfflineEvents';
cursevent = fetch(conn, sqlquery, 'DataReturnFormat', 'cellarray');

close(conn)

click_events = [];
if isempty(eventIdH)
    return
end

% all the times at once - much quicker than one at a time
clickTimesAllNum = datenum(clicksTimeAll, 'yyyy-mm-dd HH:MM:SS.FFF');

%reduce processing time by removing clicks
index = (clickTimesAllNum>=startDate & clickTimesAllNum<=endDate );
fileNamesAll=fileNamesAll(index);
clickNosAll=clickNosAll(index);
eventId=eventIdH(index);
clickTimesAllNum=clickTimesAllNum(index);

eventIDs=cell2mat(cursevent(:,1));

% the events in range: at least one click strictly between the dates
inrange = clickTimesAllNum > startDate & clickTimesAllNum < endDate;
events = intersect(unique(eventId(inrange)), eventIDs);
use = ismember(eventId, events);

if (verbose)
    disp(['Number event clicks: ' num2str(sum(use)) ' in ' num2str(numel(events)) ' events']);
end

%% load the clicks: each binary file once, for every event in it
[files, ~, ifile] = unique(fileNamesAll(use));
uids = clickNosAll(use);
eventId = eventId(use);
fileclicks = cell(numel(files), 1);
for f = 1:numel(files)
    if (verbose)
        fprintf('Loading file %s %d of %d\n', files{f}, f, numel(files));
    end
    filePath = pgmatlab.utils.findBinaryFile(binaryfolder, '*.pgdf', files{f});
    if ~exist(filePath, 'file')
        fprintf(' - Unable to find file %s\n', files{f});
        continue;
    end
    fileData = pgmatlab.loadPamguardBinaryFile(filePath, 'uidlist', unique(uids(ifile == f)));
    if isempty(fileData)
        continue
    end
    [~, fName, fEnd] = fileparts(filePath);
    [fileData.binaryFile] = deal([fName fEnd]);
    if ~keepwave
        % keep the SNR, which needs the waveform, and drop the waveform
        snr = snr_clicks(fileData);
        for d = 1:numel(fileData)
            fileData(d).snr = snr(d);
        end
        fileData = rmfield(fileData, 'wave');
    end
    fileclicks{f} = fileData;
end

% the position of each click in the clicks loaded from its file (0 = not
% found)
pos = zeros(numel(uids), 1);
for f = 1:numel(files)
    if ~isempty(fileclicks{f})
        rows = find(ifile == f);
        [~, pos(rows)] = ismember(uids(rows), double([fileclicks{f}.UID]));
    end
end

%%now get data into format that we need
n=1;
for i = events(:)'
    % the clicks of the event, in file order then the order in the file,
    % as PGMATLAB.LOADPAMGUARDMULTIFILE returns them
    k = find(eventId == i & pos > 0);
    if isempty(k)
        continue
    end
    [~, order] = sortrows([ifile(k) pos(k)]);
    k = k(order);
    clicks = [];
    for f = unique(ifile(k), 'stable')'
        clicks = union_fields_concat(clicks, fileclicks{f}(pos(k(ifile(k) == f))));
    end

    indexEvent=find(eventIDs==i);
    click_events(n).clicks=clicks; %#ok<AGROW>
    click_events(n).event_id=i;
    click_events(n).date=min([clicks.date]); % for compatibility with buzz structures.
    click_events(n).end_date=max([clicks.date]); % for compatibility with buzz structures.
    click_events(n).comment=cell2mat(cursevent(indexEvent, 14));
    click_events(n).event_type=cell2mat(cursevent(indexEvent, 8));
    click_events(n).eventUID=cell2mat(cursevent(indexEvent, 15));
    click_events(n).datestr=cell2mat(cursevent(indexEvent, 2));
    n=n+1;
end

end

function exists = table_exists(conn, tableName)
%TABLE_EXISTS Check whether a table exists in an sqlite database.
res = fetch(conn, ['select name from sqlite_master where type=''table'' and name=''' tableName ''''], ...
    'DataReturnFormat', 'cellarray');
exists = ~isempty(res);
end

function out = union_fields_concat(a, b)
% concatenate struct arrays a and b, which can have different optional
% fields (e.g. signalExcess), on the union of their fields
if isempty(a)
    out = b;
    return
end
missingInB = setdiff(fieldnames(a), fieldnames(b));
missingInA = setdiff(fieldnames(b), fieldnames(a));
for k = 1:numel(missingInB)
    [b.(missingInB{k})] = deal([]);
end
for k = 1:numel(missingInA)
    [a.(missingInA{k})] = deal([]);
end
b = orderfields(b, a);
out = [a(:)' b(:)'];
end
