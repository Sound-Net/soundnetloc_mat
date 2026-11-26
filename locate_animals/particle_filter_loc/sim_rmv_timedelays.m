function [animaltrack,timedelaysobs] = sim_rmv_timedelays(animaltrack,timedelaysobs)
%SIM_RMV_TIMEDELAYS Remove some time delay measurements from a track.
%   Detailed explanation goes here

indexrmvtrck=[];
indexrmvdelay=[];

premovetrack = 0.2; % probability of removing a track point
premovedelay = 0.6; % probability of remving a single time delay measurment

%%make the track not so ideal by removeing some points altogether and
%%removing some of the time delay measurements from one cluster
for i=1:length(animaltrack.divetrack)
    if rand(1,1)<premovetrack
        indexrmvtrck = [indexrmvtrck i];
    elseif rand(1,1)<premovedelay
        indexrmvdelay = [indexrmvdelay i];
    end
end

%do this first as whole point will be removed
for i=1:length(indexrmvdelay)
    %remove one of the delays
    if rand()>0.5
        timedelaysobs(indexrmvdelay(i),1)={[]};
    else
        timedelaysobs(indexrmvdelay(i),2)={[]};
    end
end

%remove track points
animaltrack.divetrack(indexrmvtrck,:)=[];
animaltrack.times(indexrmvtrck)=[];
timedelaysobs(indexrmvtrck,:)=[];

end

