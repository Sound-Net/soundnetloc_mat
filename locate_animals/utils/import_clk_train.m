function [clicks, clickevents] = import_clk_train(sqlLite_dB ,binaryfolder, varargin)
%IMPORT_ACLICK_TRAIN Imports all clicks within a or set of click train(s).
%   [CLICKS, CLICKEVENTS] = IMPORT_ACLICK_TRAIN(SQLLITE_DB, BINARYFOLDER,
%   VARARGIN) imports a click train from paths specified to SQLLITE_DB
%   database and a BINARYFOLDER. Be default all click train will be loaded
%   from the database. Events can be filtered by VARARGIN. 'eventcomment'
%   followed by a string will select only events with the speciefied
%   comment. 'eventtype' followed by a specified event comment string will
%   only select events of a certian type. If both these are used then only
%   events with both the specified comment and type will be returned.


eventcomment=[]; % only select events with comment
eventtype=[];  %only select events with types.
iArg = 0 ;
while iArg < numel(varargin)
    iArg = iArg + 1;
    %     disp(['import_clk_train: Hello: ' num2str(length(varargin)) ' ' varargin{iArg} ' ' num2str(iArg)]);
    switch(varargin{iArg})
        %         case 'euleroffset'
        %             iArg = iArg + 1;
        %             %            timeRange = dateNumToMillis(varargin{iArg});
        %             eulerpffset = varargin{iArg};
        case 'eventcomment'
            iArg = iArg + 1;
            eventcomment = varargin{iArg};
        case 'eventtype'
            iArg = iArg + 1;
            eventtype = varargin{iArg};
        otherwise
            iArg = iArg + 1;
    end
end

[ click_events ] = load_event_clicks( sqlLite_dB, binaryfolder);

clicks=[];
clickevents=[];

if isempty(click_events)
    return;
end

nevents = length(click_events);
eventclickscell = cell(1, nevents); % clicks for each selected event
keep = false(1, nevents); % which events passed the comment/type filter

for i=1:nevents
    %     disp(['eventtype: ' eventtype ' eventcomment: ' eventcomment ' ' isempty(eventtype)]);
    if ((isempty(eventtype) || strcmp(eventtype, strtrim(click_events(i).event_type)))...
            && (isempty(eventcomment) || strcmp(eventcomment, strtrim(click_events(i).comment))))

        keep(i) = true;

        %add an eventID tag to the clicks. The clicks of an event are a
        %struct array so every click already has the same fields - the tags
        %can therefore be added to the whole event in one go instead of
        %merging clicks one by one.
        eventclicks = click_events(i).clicks;
        if ~isempty(eventclicks)
            eventclicks = reshape(eventclicks, 1, []);
            [eventclicks.eventID] = deal(i);
            [eventclicks.eventUID] = deal(click_events(i).eventUID);
            eventclickscell{i} = eventclicks;
        end
    end
end

clickevents = click_events(keep);

%different events may have been loaded from different detectors and so can
%have different fields. Keep only the fields common to every event and
%concatenate in a single pass - merging event by event would copy the
%(large) accumulated click array once per event.
eventclickscell = eventclickscell(~cellfun(@isempty, eventclickscell));

if isempty(eventclickscell)
    clicks = [];
    return;
end

common = fieldnames(eventclickscell{1});
for i = 2:numel(eventclickscell)
    common = intersect(common, fieldnames(eventclickscell{i}), 'stable');
    if isempty(common)
        clicks = [];
        return;
    end
end

for i = 1:numel(eventclickscell)
    fnames = fieldnames(eventclickscell{i});
    if ~isequal(fnames(:), common(:))
        drop = setdiff(fnames, common, 'stable');
        if ~isempty(drop)
            eventclickscell{i} = rmfield(eventclickscell{i}, drop);
        end
        eventclickscell{i} = orderfields(eventclickscell{i}, common);
    end
end

clicks = [eventclickscell{:}];

end
