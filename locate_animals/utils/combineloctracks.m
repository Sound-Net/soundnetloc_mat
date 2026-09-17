function [loctracksall] = combineloctracks(porptrk)
%COOMBINELOCTRACKS merges a cell array of locm tracks into one track. 
%   [LOCTRACKSALL]  = COOMBINELOCTRACKS(PORPTRK) combines a cell array of
%   localisation track structures (PORPTRK) into one LOCTRACKSALL structure
%   with correct times etc ( This can be useful for plotting multiple
%   tracks or meta analysis of data.

% the start time of the first loc track set
timestart = porptrk{1}.settings.timestart; 
n=1; 
for i=1:length(porptrk)
    
    secondsdiff = (porptrk{i}.settings.timestart - timestart)*60*60*24; 
    
    loctracks=porptrk{i}.loctracks; 
    
    for j=1:length(loctracks)
        loctracks(j).loctracktimes = loctracks(j).loctracktimes+secondsdiff; 
        loctracks(j).datestart = timestart;
    end
    
    %must change the second times to be referenced form the first time 
    loctracksall(n:n+length(loctracks)-1) = loctracks; 
    n=n+length(loctracks);
end
end



