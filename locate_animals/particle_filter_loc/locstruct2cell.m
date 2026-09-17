function [timessrt, hydrophonesgeo, timedelaysobs, timedelayserr, clkindexsrt, timesdate] = locstruct2cell(clkdatasgeo, clkindex, timestart)
%LOCSTRUCT2CELL Converts an array of loclaisation structures and matched
%index clicks to a format that can be accepted for a particle filter tracking algorithm.
%   [TIMESRT, HYDROPHONESGEO, TIMEDELAYOBS, TIMDEDELAYSERR] =
%   LOCSTRUCT2CELL(CLKDATAGEO, CLKINDEX) converts a list of CLKDATAGEO
%   structures to cell arrays of time delays and hydrophone positions using
%   matched clicks identified by CLKINDEX. CLKINDEX is an index array where
%   each row is indicates matched clicks and each column identifies the
%   click position in the list of clicks for each soundtrap i.e. the data
%   in CLKDATAGEO. The outputs correspond to CLKINDEX (each row being a set
%   of matched clicks and each column data from a different soudntrap).
%   TIMES srt is a 1D array of times, HYDROPHONESGEO is a cell array of
%   hydrophjone positions corresponding to CLKINDEX and TIMEDELAYSOBS is a
%   cell arrya of time delays corresponding to CLKINDEX. Empty cells
%   indicate no detected click. CLKINDEXSRT is the same array as CLKINDEX
%   sorted by time. 

%now have to match up the clicks between the two soundtraps.
for i=1:length(clkdatasgeo)
    %create a copy of the click list in each event and add time offsets to
    %make sure all are within the same time time. 
    clkdatetimes{i} = [clkdatasgeo(i).clicks.date] + clkdatasgeo(i).timeoffset/60/60/24; 
end

%% Create input for a particle filter to track the animal
times = zeros(length(clkindex(:,1)), length(clkindex(1,:)));

timessrt = zeros(length(clkindex(:,1)), 1);
timesdate = zeros(length(clkindex(:,1)), 1);

timedelaysobs=cell(length(clkindex(:,1)), length(clkindex(1,:))); 
timedelayserr=cell(length(clkindex(:,1)), length(clkindex(1,:))); 
hydrophonesgeo=cell(length(clkindex(:,1)), length(clkindex(1,:)));

for i=1:length(clkindex(:,1))
    %times is in second...
    for j=1:length(clkindex(i,:))

%                     disp(['clkindex ' num2str(i) ' ' num2str(j) '  val: ' num2str(clkindex(i,j))])

        if (clkindex(i,j)~=0)
            
            times(i,j) = (clkdatetimes{j}(clkindex(i, j))-timestart)*60*60*24; %seconds
           
            timessrt(i) = (clkdatetimes{j}(clkindex(i, j))-timestart)*60*60*24; % an array to allow us to easily sort times. 
            timesdate(i) = clkdatetimes{j}(clkindex(i, j)); %keep a track of the datetime. 

            if (isfield(clkdatasgeo(j).clicks(clkindex(i,j)), 'timeDelays'))
                timedelaysobs{i,j}  = clkdatasgeo(j).clicks(clkindex(i,j)).timeDelays;
            else
                timedelaysobs{i,j}  = clkdatasgeo(j).clicks(clkindex(i,j)).delays;
            end
            timedelayserr(i,j) =  error_TDOA(clkdatasgeo(j).clicks(clkindex(i,j)));
            
            %hydrophones are a little complictaed. Have to add the
            %soundtrap locations from the boat circlinh (static) and depths
            %(dynamic) from sensor data.
            hydrophones = clkdatasgeo(j).clkhydrosgeo{clkindex(i,j)};
            
            if (isempty(hydrophones))
                timedelaysobs{i,j}  = [];
                hydrophonesgeo{i,j} = [];
                timedelayserr{i,j}  = []; 
                continue;
            end

            hydrophones(:,1) = hydrophones(:,1)+clkdatasgeo(j).northings(1); 
            hydrophones(:,2) = hydrophones(:,2)+clkdatasgeo(j).northings(2);
            hydrophones(:,3) = hydrophones(:,3)+clkdatasgeo(j).depths(clkindex(i,j),3); 
            %find the minimum depth. 
            hydrophonesgeo{i,j} = hydrophones; 
        else
            timedelaysobs{i,j}  = [];
            timedelayserr{i,j}  = [];
            hydrophonesgeo{i,j} = []; 
        end
    end
end


%must sort everything by time or particle filter will go crazy. 
[~, index] = sort(timessrt);
times=times(index,:);
timesdate = timesdate(index);
timessrt = timessrt(index); 
timedelaysobs = timedelaysobs(index,:); 
timedelayserr = timedelayserr(index,:); 
hydrophonesgeo = hydrophonesgeo(index,:); 
clkindexsrt=clkindex(index,:); 



end

