function [locpoints,chi2, index, startlocation] = trackstartloc(times, timedelaysobs,hydrophonesgeoref)
%TRACKSTARTLOC Localises a set of time delays using simplex loclaisation
%methods. 
%   [LOCPOINTS, CHI2, INDEX] = TRACKSTARTLOC(TIMES, TIMEDELAYOBS,
%   HYDROPHONESGEO) calculates the localised position(s) for a set of
%   TIMEDELAYSOBS (seconds) and recievers HYDROPHONESGEO (cartesian). Both
%   TIMEDELAYSOBS and HYDROPHONESGEO are cell arrays with each cell
%   corresponding to one synchronised hydrophone cluster. This works by
%   finding the first 2 seconds of data that contains a click detected on
%   both PAM systems and then averages all loclaisation in those two
%   seconds. 

%Now we need to figure out a rough start location...
%Find the first points that have.
%Need to define the chi2 equation.
sdelyerr = 5/1500/100;
c=1500; %speed of sounds in water in meters per second

maxchi2 = 0.5; 
maxrange = 300;
avrgtime = 2; % the number of seconds to avergae the start of the track to find start location

n=1;
locpoints =  zeros(length(timedelaysobs),3);
chi2 = zeros(length(timedelaysobs),1);
index = zeros(length(timedelaysobs),1);

for i=1:length(timedelaysobs)
    %check whether there are enough points to localise
    notempty=0;
    obsdelayerr = cell(length(timedelaysobs(i,:)),1); 
    for j=1:length(timedelaysobs(i,:))
        if (~isempty(timedelaysobs{i,j}))
            obsdelayerr{j} = sdelyerr*ones(length(timedelaysobs{i,j}));
            notempty=notempty+1;
        end
    end
    %if there enough positions then localise. 
    if (notempty>=2)
        disp(['Localising clicks detected on 2+ clusters: ' num2str(i) ' of ' num2str(length(timedelaysobs))])         
        chi2equation  = @(x) calc_chi2_TDOA_clusters(x, timedelaysobs(i,:), obsdelayerr, hydrophonesgeoref(i,:), c);
        [locpoints(n,:), chi2(n)]= localise_simplex(chi2equation);
        index(n)=i; %keep a track of the index of successfully localised points
        n=n+1;
    end
end


locpoints =  locpoints(1:n-1,:); 
chi2 =  chi2(1:n-1,:); 
index =  index(1:n-1,:); 


% now find the first location by taking a running mean avergae...
locpointsfilt=locpoints(chi2<maxchi2,:);
indexfilt=index(chi2<maxchi2);

hydrophonesgeofilt=hydrophonesgeoref(index); 
hydrophonesgeofilt = hydrophonesgeofilt(chi2<maxchi2,:); 

timesfilt = times(index);
timesfilt = timesfilt(chi2<maxchi2);

chi2filt =  chi2(chi2<maxchi2,:); 

%find the first point less than 200m range
animalrange = zeros(length(locpointsfilt(:,1)), 1); 
for i=1:length(locpointsfilt(:,1))
    animaldistance = [];
    n=1; 
    for j=1:length(hydrophonesgeofilt(i,:))
        if (~isempty(hydrophonesgeofilt{i,j}))
            animaldistance(n) = pdist([hydrophonesgeofilt{i,j}(1,:); locpointsfilt(i,:)],'euclidean');
            n=n+1;
        end
    end
    animalrange(i)  = min(animaldistance); 
end

% now have the closest range to one of the devices what is the start
% location
indexrange = find(animalrange<maxrange); 

locpointsfilt   = locpointsfilt(indexrange, :); 
timesfilt       = timesfilt(indexrange); 
indexfilt       = indexfilt(indexrange); 

%average locations in the first 2 seconds of data. 
indextime =  timesfilt<min(timesfilt) + avrgtime;

locpointsfilt   = locpointsfilt(indextime, :); 

if (length(locpointsfilt(:,1))>1)
    startlocation = mean(locpointsfilt);
else
    startlocation = locpointsfilt;
end

end

