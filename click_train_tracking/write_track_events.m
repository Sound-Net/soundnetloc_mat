function nWritten = write_track_events(dbfile, clicks, clickTrack, trackCode, varargin)
%WRITE_TRACK_EVENTS Write associated bearing tracks as PAMGuard click events.
%
%   N = WRITE_TRACK_EVENTS(DBFILE, CLICKS, CLICKTRACK, TRACKCODE) adds one
%   offline click event to the PAMGuard database DBFILE for every track
%   with a code (e.g. 'PP0001AA01'), so an analyst can inspect and edit
%   them in the PAMGuard viewer. The code is stored in the event comment.
%   Returns the number of events written.
%
%   CLICKS     - click structs loaded from the PAMGuard binary files (needs
%                UID, millis, channelMap and fileName).
%   CLICKTRACK - track id of each click (0 = none), e.g. res.clickTrack
%                from TRACK_BEARINGS.
%   TRACKCODE  - cellstr code for each track ('' = not written), e.g.
%                assoc.trackCode{d} from ASSOCIATE_TRACKS.
%
%   Name-value parameters:
%     eventType - PAMGuard event type code (Lookup table) ['pp']
%     overwrite - if events whose comment starts with the same species and
%                 event number (e.g. 'PP0001') already exist they are
%                 deleted, with their clicks, before writing. If false an
%                 error is thrown instead so analyst edits are never
%                 overwritten by accident [false]
%     colours   - colour index for each track [association index]
%     amplitude - amplitude of each click (dB) for the Amplitude column.
%                 PAMGuard works it out from the waveform, which the clicks
%                 here usually no longer have; it must not be left empty
%                 though, or LOAD_EVENT_CLICKS cannot read the table [0]
%
%   Rows are written to Click_Detector_OfflineEvents and
%   Click_Detector_OfflineClicks. ClickNo is the click's index within its
%   binary file, derived from the UID (UID = file number*1e6 + index + 1).
%
%   See also ASSOCIATE_TRACKS, TRACK_BEARINGS

p.eventType = 'pp';
p.overwrite = false;
p.amplitude = [];
p.colours = [];
for i = 1:2:numel(varargin)
    p.(varargin{i}) = varargin{i+1};
end

clickTrack = clickTrack(:);
trackCode = trackCode(:);
toWrite = find(~cellfun(@isempty, trackCode));
nWritten = 0;
if isempty(toWrite)
    return
end
if isempty(p.colours)
    % colour from the association letters (AA = 1, AB = 2, ...) so an
    % association has the same colour on every device
    p.colours = zeros(size(trackCode));
    for k = toWrite(:)'
        c = trackCode{k};
        p.colours(k) = (c(7) - 'A')*26 + (c(8) - 'A') + 1;
    end
end

prefixes = unique(cellfun(@(c) c(1:6), trackCode(toWrite), 'UniformOutput', false));

conn = sqlite(dbfile);
cleanup = onCleanup(@() close(conn));

%% existing events with the same prefix
for i = 1:numel(prefixes)
    like = ['''' prefixes{i} '%'''];
    old = fetch(conn, ['select Id from Click_Detector_OfflineEvents where comment like ' like]);
    if height(old) > 0
        if ~p.overwrite
            error('write_track_events:exists', ['%d events with comment %s... already ' ...
                'exist in %s. Use ''overwrite'', true to replace them.'], ...
                height(old), prefixes{i}, dbfile);
        end
        execute(conn, ['delete from Click_Detector_OfflineClicks where EventId in ' ...
            '(select Id from Click_Detector_OfflineEvents where comment like ' like ')']);
        execute(conn, ['delete from Click_Detector_OfflineEvents where comment like ' like]);
    end
end

%% next free Ids / UIDs
ev = fetch(conn, 'select ifnull(max(Id), 0) as maxId, ifnull(max(UID), 0) as maxUID from Click_Detector_OfflineEvents');
nextId = max([0, value(ev.maxId), value(ev.maxUID)]) + 1;
ck = fetch(conn, 'select ifnull(max(Id), 0) as maxId from Click_Detector_OfflineClicks');
nextClickId = max([0, value(ck.maxId)]) + 1;

pcTime = fmt_time(datetime('now', 'TimeZone', 'UTC'));
millis = double([clicks.millis]');
uids = double([clicks.UID]');
chans = double([clicks.channelMap]');
if isempty(p.amplitude)
    p.amplitude = zeros(numel(clicks), 1);
end
amps = double(p.amplitude(:));

evRows = cell(numel(toWrite), 1);
ckRows = cell(numel(toWrite), 1);
for n = 1:numel(toWrite)
    k = toWrite(n);
    ci = find(clickTrack == k);
    if isempty(ci)
        continue
    end
    [~, o] = sort(millis(ci));
    ci = ci(o);
    evId = nextId;
    nextId = nextId + 1;
    chanMap = bitor_all(chans(ci));

    tStart = ms2datetime(millis(ci(1)));
    tEnd = ms2datetime(millis(ci(end)));
    evRows{n} = table(evId, evId, {fmt_time(tStart)}, mod(millis(ci(1)), 1000), ...
        {fmt_time(tStart)}, {pcTime}, chanMap, {fmt_time(tEnd)}, {p.eventType}, ...
        numel(ci), p.colours(k), trackCode(k), chanMap, ...
        'VariableNames', {'Id', 'UID', 'UTC', 'UTCMilliseconds', 'PCLocalTime', ...
        'PCTime', 'ChannelBitmap', 'EventEnd', 'eventType', 'nClicks', 'colour', ...
        'comment', 'channels'});

    nc = numel(ci);
    tc = arrayfun(@(m) fmt_time(ms2datetime(m)), millis(ci), 'UniformOutput', false);
    ckRows{n} = table((nextClickId:nextClickId+nc-1)', uids(ci), tc, ...
        mod(millis(ci), 1000), tc, repmat({pcTime}, nc, 1), chans(ci), ...
        repmat(evId, nc, 1), repmat(evId, nc, 1), ...
        repmat({'Click Detector, Clicks'}, nc, 1), {clicks(ci).fileName}', ...
        repmat(evId, nc, 1), mod(uids(ci), 1e6) - 1, amps(ci), chans(ci), ...
        'VariableNames', {'Id', 'UID', 'UTC', 'UTCMilliseconds', 'PCLocalTime', ...
        'PCTime', 'ChannelBitmap', 'parentID', 'parentUID', 'LongDataName', ...
        'BinaryFile', 'EventId', 'ClickNo', 'Amplitude', 'Channels'});
    nextClickId = nextClickId + nc;
    nWritten = nWritten + 1;
end

evTable = vertcat(evRows{:});
ckTable = vertcat(ckRows{:});
if ~isempty(evTable)
    sqlwrite(conn, 'Click_Detector_OfflineEvents', evTable);
    sqlwrite(conn, 'Click_Detector_OfflineClicks', ckTable);
end

end

function v = value(x)
% database max() of an empty table comes back missing/NaN
if iscell(x)
    x = x{1};
end
if isempty(x) || (isnumeric(x) && isnan(x)) || ismissing(x)
    v = 0;
else
    v = double(x);
end
end

function b = bitor_all(x)
b = 0;
for i = 1:numel(x)
    b = bitor(b, x(i));
end
end

function t = ms2datetime(ms)
t = datetime(ms/1000, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');
end

function s = fmt_time(t)
s = char(datetime(t, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
end
