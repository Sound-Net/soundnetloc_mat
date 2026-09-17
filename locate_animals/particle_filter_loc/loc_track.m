%% LOCALISE CETACEAN TRACK
% Works out the 3D track of an animal from time delay measurements for
% SoundNet 4 channel devices. Should be able to deal with two or more
% devices on a net.

% clear
% clf
% % get the porpoise event - comment out if using loc_track_all
 eventserialID = 'AK62700043A';
[clkdatas, clksearchwindow, smploffset] = get_porp_events(eventserialID);

%porpoise
c=1500; 
a=0.5; %st acceleeration for movement model
maxspeed = 4;
nruns= 10; %the number of runs for the particle filter. 
particles = 2000;

%% Analysis %%
timestart = min([min([clkdatas(1).clicks.date]) min([clkdatas(2).clicks.date])]); % rough time to get correct st data

%pinger trials
% a=0.5/10; %st acceleeration for movement model
% maxspeed = 2;

%% Create data structures
%%iterate through data structures (each structure is data from a soundtrap)
for i = 1:length(clkdatas)
    %add relevent loc data  to struct
    clkdatastruct = makelocstruct(clkdatas(i), smploffset(i));
    %struct has new fields.
    clkdatasgeo(i) = clkdatastruct;
end

%% Match Clicks
[clkindex] = matchclks(clkdatasgeo, clksearchwindow);

%% Create input for a particle filter to track the animal
[timessrt, hydrophonesgeo, timedelaysobs, timedelayserr, clkindex, timesdate] = ...
    locstruct2cell(clkdatasgeo, clkindex, timestart); %%now need to sort by time.

%% Break apart the tracks if the time between clicks is too large
trackfragments = fragmenttracks(timessrt, timedelaysobs, timedelayserr, hydrophonesgeo);

%% bathymetry
[~, meshdata] = plotbathy_cornwall(clkdatasgeo(1).reflatlon, [-200, 200], [-200 200], timestart);

%% Run the particle filter.
allchi2=[];
for i=1:length(trackfragments)
    
    %Find the start location for the particle filter.
    % run simplex loclaisation for all points
    [locpoints, chi2smplx, index, startlocation] = trackstartloc3(trackfragments(i).timessrt, trackfragments(i).timedelaysobs,trackfragments(i).hydrophonesgeo);
    
    timesloc = trackfragments(i).timessrt(index);
    
    if (isempty(startlocation) || length(index)<3)
        disp('The start location is empty')
        continue;
    end

%     %%%% TEMP %%%%% 
%     locpoints=[];
%     chi2smplx=[]; 
%     timesloc = [];
%     time=timesdate(1) + trackfragments(i).timessrt(1)/60/60/24; 
%     startloclatlon = [interp1(srclocations(:,1), srclocations(:,2), time), interp1(srclocations(:,1), srclocations(:,3), time)]; 
%     startlocation = latLong2Northings(startloclatlon, clkdatasgeo(1).reflatlon); 
%     startlocation = [startlocation -5]; 
%     index = 1:length(trackfragments(i).timessrt); 
%     %%%%%

    
    %make sure start location is not above the seasurface or below the
    %seabed.
    dpthstartloc = interp2(meshdata.x, meshdata.y, meshdata.z, startlocation(1), startlocation(2));
    if startlocation(3)>0
        startlocation(3)=0;
    elseif ~isnan(dpthstartloc) && startlocation(3)<dpthstartloc
        startlocation(3)=dpthstartloc;
    end
    
    % run the particle filter on multiple locations. 
%     clear loctracks
    for ii=1:nruns
        % Run the particle filter on the track.
        [loctracksmulti(ii).xh ,loctracksmulti(ii).pf, loctracksmulti(ii).chi2] = partice_filter_pam(trackfragments(i).timessrt(index(1):index(end)),...
            trackfragments(i).timedelaysobs(index(1):index(end),:), trackfragments(i).hydrophonesgeo(index(1):index(end),:), startlocation, ...
            'TimeDelayErrors',  trackfragments(i).timedelayserr(index(1):index(end),:), 'Bathymetry', meshdata, 'StdAccel', a, ...
            'MaxSpeed', maxspeed, 'SoundSpeed', c, 'Particles', particles);

        %    % Run the particle filter on the track.
        %     [loctracks(i).xh ,loctracks(i).pf, loctracks(i).chi2] = partice_filter_pam(trackfragments(i).timessrt(index(1):index(end)),...
        %         trackfragments(i).timedelaysobs(index(1):index(end),:), trackfragments(i).hydrophonesgeo(index(1):index(end),:), startlocation, ...
        %         'Bathymetry', meshdata, 'StdAccel', a);

        %save the simplex data.
        loctracksmulti(ii).loctracktimes = trackfragments(i).timessrt(index(1):index(end),:);
        loctracksmulti(ii).locsimplex = locpoints;
        loctracksmulti(ii).timeslocsimplex = timesloc;
        loctracksmulti(ii).startlocation = startlocation;

        %keep a record of the track start date
        trackstartdates=timesdate(timessrt == trackfragments(i).timessrt(1));
        loctracksmulti(ii).datestart =  trackstartdates(1);
        loctracksmulti(ii).dateend =  trackstartdates(1) + max(loctracksmulti(ii).loctracktimes )/60/60/24;
        loctracksmulti(ii).reflatlon =  clkdatasgeo(1).reflatlon;
    end

    [aloctrack, err] = avrgloctracks(loctracksmulti);
    aloctrack.err=err; 
   
    loctracks(i) = aloctrack; 
    
end

if (exist('loctracks', 'var') && ~isempty(loctracks))
    %% Plot a map of locations
    figff = figure( 'Position', [0,0, 1100, 700]);
    acmap = colormap('Jet');
    
    clf
    hold on
    reflatlon=clkdatasgeo(1).reflatlon;
    
    timelims = [min(timessrt) max(timessrt)];
    plot_loctrack_bathy(loctracks, hydrophonesgeo, reflatlon, timelims, timestart)
    zlim([min(clkdatasgeo(1).depths(:,3))-20, 5])
    view([30,45])
    set(gca, 'FontSize', 14); 
    
    hold off
    %print('-clipboard','-dbitmap')
end


% figure(2)
% chi2vals =[];
% for i = 1:length(loctracks)
%     chi2vals = [chi2vals loctracks(i).chi2];
% end
%
% histogram(chi2vals);
% ylabel('N')
% xlabel('chi2^2')
% title(['Mean chi2 ' num2str(mean(chi2vals)) ' median: ' num2str(median(chi2vals))])