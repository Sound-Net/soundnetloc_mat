function [clkindex] = matchclks(clkdatasgeo, clksearchwindow)
%MATCHCLKS Matches clicks between 4 channel soundtraps 
%    [clkindex] = matchclks(clkdatasgeo, clksearchwindow)


%now have to match up the clicks between the two soundtraps.
for i=1:length(clkdatasgeo)
    %create a copy of the click list in each event and add time offsets to
    %make sure all are within time. 
    clkdatetimes{i} = [clkdatasgeo(i).clicks.date] - clkdatasgeo(i).timeoffset/60/60/24; 
end

%index is a unknown x num soundtraps matrix indicating whihc clicks should
%be macthed e.g. [2 3 7] means 2nd click from device 1 matched 3rd click
%from device 2 and 7th click from device three etc.  0 means that there is
%no matching click from the spoecified soundtrap. 

%take a rough overestimate guess at preallocation size
clkindex = zeros(length(clkdatetimes{i})*length(clkdatetimes), length(clkdatasgeo)); 

timewindowdatenum = clksearchwindow/60/60/24; 
%now iterate through these  lists looking for the clicks that match.
n=1; 
for i=1:length(clkdatasgeo)
    clksmaster = clkdatetimes{i}; 
    for j=1:length(clksmaster)
        if (mod(j, 10)==0)
           disp(['Matching clicks: ' num2str(100*j/length(clkdatetimes{i}))...
               '%' ' Device ' num2str(i) ' of ' num2str(length(clkdatasgeo))]) 
        end
        % this is the time to search for. 
        time = clksmaster(j);
        
        
        if (ismember(j, clkindex(:,i)))
            continue
        end
        
        clkindex(n,i) =  j; 

        %search the other soundtraps for clicks
        for k=(i+1):length(clkdatasgeo)
            %not that do not need to search SoundTraps ijn the list
            %previously as they should already have matched the clicks. 
           
            %find the closest matching time;
            [mintime,index] = min(abs(clkdatetimes{k}-time));
            
            %check if the click is within a time window and that the click
            %is not already included in a previous match. 
            if (mintime<timewindowdatenum && ~ismember(index, clkindex(:,k)))
                clkindex(n,k)= index; % the match clicks 
            end
        end
        n=n+1; 
    end    
end

%get  rid of any trailling pre allocated zeros. 
clkindex = clkindex(1:n-1,:); 

end

