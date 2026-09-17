function [locpoints,chi2, index, startlocation, locpointsfilt] = trackstartloc3(times, timedelaysobs, hydrophonesgeoref)
%TRACKSTARTLOC Localises a set of time delays using simplex loclaisation
%methods.
%   [LOCPOINTS, CHI2, INDEX] = TRACKSTARTLOC(TIMES, TIMEDELAYOBS,
%   HYDROPHONESGEO) calculates the localised position(s) for a set of
%   TIMEDELAYSOBS (seconds) and recievers HYDROPHONESGEO (cartesian). Both
%   TIMEDELAYSOBS and HYDROPHONESGEO are cell arrays with each cell
%   corresponding to one synchronised hydrophone cluster. This works by
%   finding the first 2 seconds of data that contains a click detected on
%   both PAM systems within the 2 seconds, but neceassirly at the same
%   time. These clicks are used to estimate an intial position assuming the
%   animal cannot move too far in the 2 second time window.

%Now we need to figure out a rough start location...
%Find the first points that have.
%Need to define the chi2 equation.
sdelyerr = 5/1500/100;
c=1500; %speed of sounds in water in meters per second

maxchi2 = 0.5;
maxrange = 200;
avrgtime = 2; % the number of seconds to average the start of the track to find start location

n=1;
locpoints =  zeros(length(timedelaysobs),3);
chi2 = zeros(length(timedelaysobs),1);
index = zeros(length(timedelaysobs),1);

ii=1;
while ii<length(timedelaysobs)
    %check whether there are enough points to localise
    indexchk = find(times>=times(ii) & times<times(ii)+avrgtime);
    
    timedelaysobschk = timedelaysobs(indexchk,:);
    hydrophonesgeorefchk = hydrophonesgeoref(indexchk,:);
    
    
    obsdelayerr = cell(size(timedelaysobschk));
    
%     timedelaysobschk
    %figure out which hydrophones recieved a click and make up some error values.
    detclk = zeros(length(timedelaysobschk(1,:)), 1); 
    for i=1:length(timedelaysobschk(:,1))
        for j=1:length(timedelaysobschk(i,:))
            if (~isempty(timedelaysobschk{i,j}))
                obsdelayerr{i,j} = sdelyerr*ones(length(timedelaysobschk{i,j}));
                detclk(j) = 1;
            end
        end
    end
    
    %there must be detections on at least two of the devices to attempt a
    %localisation.
    if (sum(detclk)>=2)
        disp(['Localising ' num2str(length(timedelaysobschk(:,1))) ' clicks detected on 2+ clusters: ' num2str(ii) ' of ' num2str(length(timedelaysobs))])
        chi2equation  = @(x) calc_chi2_TDOA_group(x, timedelaysobschk, obsdelayerr, hydrophonesgeorefchk, c);
        [locpoints(n,:), chi2(n)]= localise_simplex(chi2equation);
        index(n)=ii; %keep a track of the index of successfully localised points
        n=n+1;
    end
    
    ii=ii+1;
end

%now which is the first locpoint we can trust?
locpoints =  locpoints(1:n-1,:);
chi2 =  chi2(1:n-1,:);
index =  index(1:n-1,:);

% now find the first location by taking a running mean avergae...
indexchi2 = chi2<maxchi2;
locpointsfilt=locpoints(indexchi2,:);
indexfilt=index(indexchi2);
chi2filt =  chi2(indexchi2,:);

timesfilt = times(indexfilt);


if (isempty(locpointsfilt))
    locpoints=[];
    chi2=[];
    index=[];
    startlocation=[];
    return;
end

%get the mean hydrophone position
for i=1:length(hydrophonesgeoref(1,:))
    pos = []; 
    for j=1:length(hydrophonesgeoref(:,i))
        if (~isempty(hydrophonesgeoref{j,i}))
           pos =[pos;  hydrophonesgeoref{j,i}];
        end
    end
    hydrophonesgeomean{i} = mean(pos); 
end

%find the first point less than 200m range
animalrange = zeros(length(locpointsfilt(:,1)), 1);
for i=1:length(locpointsfilt(:,1))
    animaldistance = [];
    n=1;
    for j=1:length(hydrophonesgeomean(1,:))
        if (~isempty(hydrophonesgeomean{j}))
            animaldistance(n) = pdist([hydrophonesgeomean{j}; locpointsfilt(i,:)], 'euclidean');
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

