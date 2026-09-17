function [trackfragments] = fragmenttracks(timessrt, timedelaysobs, timedelayserr, hydrophonesgeo, maxtimegap)
%FRAGMENTTRACKS Break a track into fragments that can be run through a
%particle filter.
%   [TRACKFRAGMENTS] = FRAGMENTTRACKS(TIMESRT,
%   TIMEDELAYSOBS,HYDROPHONESGEO) breaks input data for the partcile filter
%   into fragments if there are large data gaps. The particle filter can be
%   weird if there are large data gaps because it will keep on moving in
%   the last direction...Thus the tracks need fragmented. TIMESRT is a list
%   of detection times in seconds. TIMEDELAOBS is a corresponding cell
%   array of time delays with each column indicating time delays from one
%   synchronised device. HYDROPHONESGEO is a corresponding cell array with
%   each column representing the position of hydrophones. The default
%   maxtime before a fragemtn is created is 5 seconds and there must be a
%   minimum of 5 clicks in a fragment and minimum click rate of 1 click/s.
%   TRACKFRAGMENTS is a strcut array with each struct containing TIMESRT,
%   TIMEDELAYOB and HYDROPHONESGEO for each fragment.

if nargin<5
    maxtimegap = 5; %seconds
end
minclickrate = 1; %clicks per second
minnoclks = 10; %minimum number of clicks in a fragment.

% for pinger trials
% maxtimegap = 50; %seconds
% minclickrate = 0.1; %clicks per second
% minnoclks = 10; %minimum number of clicks in a fragment.


timestartindx = 1;

n=1;
for i=2:length(timessrt)
    if ((timessrt(i) - timessrt(i-1))>maxtimegap || i==length(timessrt))
        
        %get the data for the chunk
        timesrtchnk         = timessrt(timestartindx:i-1);
        timedelaysobschnk   = timedelaysobs(timestartindx:i-1,:);
        timedelayserrchnk   = timedelayserr(timestartindx:i-1,:);
        hydrophonesgeochnk  = hydrophonesgeo(timestartindx:i-1,:);
        
        %         disp(['Hello: ' num2str(diff(minmax(timesrtchnk)))])
        %         disp(['Hello: ' num2str(length(timesrtchnk))])
        
        %check whether atrack is completely empty on one device.
        ndets =zeros(length(timedelaysobschnk(1,:)),1);
        for j=1:length(timedelaysobschnk(:,1))
            for k=1:length(timedelaysobschnk(j,:))
                ndets(k)=ndets(k)+ ~isempty(timedelaysobschnk{j,k});
            end
        end
        
        %%add to strcut
        % note if there is a matrix dimensions must agree then minmax may
        % not be the correct minmax - should be the function doug wrote not
        % from neural net toolbox.
        if (length(timesrtchnk)/diff(minmax(timesrtchnk))>minclickrate &&...
                length(timesrtchnk)>=minnoclks && ~ismember(0, ndets))
            trackfragstruct.timessrt=timesrtchnk;
            trackfragstruct.timedelaysobs=timedelaysobschnk;
            trackfragstruct.timedelayserr=timedelayserrchnk;
            trackfragstruct.hydrophonesgeo=hydrophonesgeochnk;
            
            trackfragstruct = checkemptyrows(trackfragstruct);
            
            trackfragments(n)  = trackfragstruct;
            n=n+1;
        end
        % the new start index
        timestartindx=i;
    end
end


    function trackfragstruct = checkemptyrows(trackfragstruct)
        % add an additional check to make sure that there are no rows that are
        % empty.
        indexremove=[];
        nn=1;
        for ii=1:length(trackfragstruct.timedelaysobs(:,1))
            numempty = 0;
            for jj = 1:length(trackfragstruct.timedelaysobs(ii,:))
                if (isempty(trackfragstruct.timedelaysobs{ii,jj}))
                    numempty=numempty+1;
                end
            end
            
            if (numempty==length(trackfragstruct.timedelaysobs(ii,:)))
                indexremove(nn) = ii;
                nn=nn+1;
            end
        end
        
        trackfragstruct.timessrt(indexremove,:) = [];
        trackfragstruct.timedelaysobs(indexremove,:) = [];
        trackfragstruct.timedelayserr(indexremove,:) = [];
        trackfragstruct.hydrophonesgeo(indexremove,:) = [];
    end

end

