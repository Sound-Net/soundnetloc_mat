function [anglesgeo, clicks] = geo_ref_clktrain(sqlLite_dB, binaryfolder,...
     eulerangles, varargin)
%GEO_REF_CLLKTRAIN Returns the geo referenced angles and associated clicks
%for a click train event.
%   [ANGLESGEO, CLICKS] = GEO_REF_CLKTRAIN(SQLITE_DB, BINARYFOLDER,
%   EULERANGLES, VARARGIN) imports click strains from a database specified
%   by SQLITE_DB and associated BINARUFOLDER. The clicks imported are then
%   geo referenced using EULERANGLES. VARAGIN is extra arguments. Events
%   can be filtered by VARARGIN. 'eventcomment' followed by a string will
%   select only events with the speciefied comment. 'eventtype' followed by
%   a specified event comment string will only select events of a certian
%   type. If both these are used then only events with both the specified
%   comment and type will be returned. 'euleroffset' is the euler angles
%   offset in days i.e. can be added to climate change.
%   
%   [ANGLESGEO, CLICKS] = GEO_REF_CLKTRAIN(SQLITE_DB, BINARYFOLDER,
%   EULERANGLES, 'wavsamples', wavinfo) will geo-reference using legacy
%   method where WAVINFO is a struct containing the information on
%   soundtrap samples and the binary have have been processed with zero
%   padding disabled NOT RECOMENDED. 


euleroffset=0;
% eventcomment=[]; % only select wvents with comment
% eventtype=[];  %only select events with types.
iArg=0;
timelims = []; 

wavinfo=[]; 
while iArg < numel(varargin)
    iArg = iArg + 1;
%     disp(['Hello: ' num2str(length(varargin)) ' ' varargin{iArg} ])
    switch(varargin{iArg})
        case 'euleroffset'
            iArg = iArg + 1;
            %            timeRange = dateNumToMillis(varargin{iArg});
            euleroffset = varargin{iArg};
            %        case 'eventcomment'
            %            iArg = iArg + 1;
            %            eventcomment = varargin{iArg};
            %        case 'eventtype'
            %            iArg = iArg + 1;
            %            eventtype = varargin{iArg};
        case 'wavsamples'
            iArg = iArg + 1;
            %            timeRange = dateNumToMillis(varargin{iArg});
            wavinfo = varargin{iArg};
        case 'timelimits'
            iArg = iArg + 1;
            %            timeRange = dateNumToMillis(varargin{iArg});
            timelims = varargin{iArg};
        otherwise
            iArg = iArg + 1;
    end
end

% import the click train
[clicks, ~] = import_clk_train(sqlLite_dB ,binaryfolder, varargin{:});

if (isempty(clicks))
    warning('There were no clicks loaded from the event')
end

%filter the clicks by time if time limits are available. 
if ~isempty(timelims)
    clktimes = [clicks.date];
    index = clktimes>timelims(1) & clktimes<timelims(2);
    clicks = clicks(index); 
end

% do the matching etc.
disp('Matching clicks...this can take some time')

if (isempty(wavinfo))
    %modern method
    [anglesgeo, ~, ~, ~] = geo_ref_clks(clicks, eulerangles,...
        'TimeOffset', euleroffset, varargin{:});
else
    %legacy method - only use with old data if sud files not available. 
    [anglesgeo, ~, ~, ~] = geo_ref_clks(clicks, eulerangles,...
        wavinfo, 'TimeOffset', euleroffset, varargin{:});
end


end

