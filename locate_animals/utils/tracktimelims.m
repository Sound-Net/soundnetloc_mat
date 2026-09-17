function [timelims] = tracktimelims(loctracks)
%TRACTIMELIMS Get the maximum and minimum time from a struct array of loc
%tracks

%find min and max time tracks
timelims=[Inf -Inf];
for i=1:length(loctracks)
    mintime=min(loctracks(i).loctracktimes); 
    if (mintime<timelims(1))
       timelims(1)=mintime; 
    end
    maxtime=max(loctracks(i).loctracktimes);
    if (maxtime>timelims(2))
        timelims(2)=mintime;
    end
end

end

