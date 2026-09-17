%% Simulate porpoise tracks around a net and test the particle filter.
% Constructs a set of random dive tracks around gill nets from a number of
% different directions and then localises using a particle filter. The
% particle filter results are then compared with the true locations and an
% error surface generated. The resulting error surface is 4D so will need to be
% presented as a surface for different depth bins.

clear
clf
close all

% the number of tracks
numtracks = 5; % 5000;

devicesep = 40; %seperation of the devices in meters
maxstartrange=50; % SHOULD BE 400

%% particle filter settings
a=0.5; %std acceleeration for movement model
maxspeed = 4; %the maximum allowed speed for a porpoise

%% environmental settings
c=1500; % the speed of sound in meters per second
noise = 90; % noise in dB for calcualtion of SNR.

%% sim porpoise settings
sourcelevel = 190; % source level in dB
hyderoangerr = 1; % uniform random hydrophone heading error in degrees

plottest = true; % true to plot the dive tracks and some other bits and pieces. Should be false for a proper simulation.

% use an example reference latitude and longitude for bathymetry
reflatlon = [50.077534000000000,-5.054];

hydrophones1  = get_st_hydrophones();
hydrophones2  = get_st_hydrophones();

hydroorigin1 = [0,0 -15];
hydroorigin2 = [2,devicesep -15];

hydrophonestrue  = {hydrophones1+hydroorigin1, hydrophones2+hydroorigin2};

timestart = 737743.531772431;

hold on
[~, meshdata] = plotbathy_cornwall(reflatlon, [-200, 200], [-200 200], timestart);

% plot the gill net.
stroplength=3;
[h3, h4] = plot_gill_net(hydrophonestrue, stroplength, meshdata);
xlabel('Eastings (m)')
ylabel('Northings (m)')
zlabel('Depth (m)')

for i=1:numtracks
    
    disp(['Simulating track ' num2str(i) ' of ' num2str(numtracks)]);
    
    startlocation = [(rand(1,1)-0.5)*maxstartrange, (rand(1,1)-0.5)*maxstartrange, 0];
    %     startlocation = [-60,0,0]; %%TEMP
    
    %% test animal
    animal.starttime=0; %%nmatlab datenum
    animal.diveheight = randi([-30, -5]); % this is -depth
    
    %vertical angles
    animal.descentvertangle = randi([30 70]);
    animal.ascentvertangle = randi([30 70]);
    
    %horizontal angles
    animal.descenthorzangle = rand(1,1)*360;
    animal.ascenthorzangle = rand(1,1)*360;
    
    %speed - need to add one here so we don't get very very slow animals!
    animal.descentspeed = rand(1,1)*2+1; %meters per second;
    animal.bottomspeed = rand(1,1)*2+1; %meters per second
    animal.ascentspeed = rand(1,1)*2+1; %meters per second;
    
    animal.bottomtime = rand(1,1)*120; %seonds
    
    animal.wobblesigma = 3; %degrees
    
    %     load('animal.mat');
    animals(i)=animal; 
    
    % first % simulate a porpoise approaching the array% check if any of
    
    animaltrack = sim_porp_dive_track(animal, startlocation);
    
    %check if any of the simulated tracks are below the seabed. if so the
    %porpoise is on the seabed bottom.
    [bathydpths] = interp2(meshdata.x,meshdata.y,meshdata.z,animaltrack.divetrack(:,1), animaltrack.divetrack(:,2));
    index = find(animaltrack.divetrack(:,3)<bathydpths);
    animaltrack.divetrack(index,3) = bathydpths(index);
    
    %generate the time delays and hydrophone positions. Note that the
    %hydrophone returned are the hydrophones rotated by a degree or
    [timedelaysobs,timedelayerr, hydrophones, snr, animaltrackrmv] = track2tdoainfo(animaltrack, hydrophonestrue, c, sourcelevel, noise, hyderoangerr);
    
    simtracks(i).timedelaysobs=timedelaysobs;
    simtracks(i).timedelayserr=timedelayerr;
    simtracks(i).animaltrack=animaltrackrmv;
    simtracks(i).times = animaltrackrmv.times; %times with removed clicks removed.
    simtracks(i).snr=snr;
    simtracks(i).hydrophones=hydrophones;
    
    
    if (plottest)
        % plot the track.
        alpha = 0.3;
        cols = getdefaultcols;
        
        plot3(animaltrack.divetrack(:,1), animaltrack.divetrack(:,2), animaltrack.divetrack(:,3),...
            'Color', [cols(2,:), alpha], 'LineWidth', 2);
    end
    
end

%pre allocate for parfor array
loctracks(length(simtracks)).chi2 = [];
loctracks(length(simtracks)).xh = [];
loctracks(length(simtracks)).simerr = [];
loctracks(length(simtracks)).animaltrack=[];
loctracks(length(simtracks)).startlocation=[];

for i=1:length(simtracks)
    
    disp(['Localising track ' num2str(i) ' of ' num2str(length(simtracks))]);
    
    
    
    animaltrack = simtracks(i).animaltrack;
    timedelaysobs = simtracks(i).timedelaysobs;
    timedelayserr = simtracks(i).timedelayserr;
    snr = simtracks(i).snr;
    times =   simtracks(i).times;
    
    if (isempty(timedelaysobs) || length(timedelaysobs(:,1))<10)
        continue;
    end
    
    %hydrophones reamin static as the time delays are generted with rotated hydrophones but still
    %need to ma e a cell array for the algorohtms
    hydrophonesgeo = cell(length(timedelaysobs(:,1)), length(timedelaysobs(1,:)));
    % calulate the time delay errors from snr
    for j = 1:length(hydrophonesgeo(:,1))
        for k = 1:length(hydrophonesgeo(j,:))
            hydrophonesgeo{j,k} =  hydrophonestrue{k};
        end
    end
    
    % find the start position of the tracks.
    [locpoints, chi2smplx, index, startlocation, locpointsfilt] = trackstartloc3(times, timedelaysobs, hydrophonesgeo);
    
    timesloc = simtracks(i).animaltrack.times;
    
    if (isempty(startlocation) || length(index)<3)
        disp('The start location is empty')
        continue;
    end
    
    %make sure start location is not above the seasurface or below the
    %seabed.
    dpthstartloc = interp2(meshdata.x, meshdata.y, meshdata.z, startlocation(1), startlocation(2));
    if startlocation(3)>0
        startlocation(3)=0;
    elseif ~isnan(dpthstartloc) && startlocation(3)<dpthstartloc
        startlocation(3)=dpthstartloc;
    end
    
    % Run the particle filter on the track.
    [loctracks(i).xh ,~, loctracks(i).chi2] = partice_filter_pam(timesloc(index(1):index(end)),...
        timedelaysobs(index(1):index(end),:), hydrophonesgeo(index(1):index(end),:), startlocation, ...
        'TimeDelayErrors',  timedelayserr(index(1):index(end),:), 'Bathymetry', meshdata, 'StdAccel', a,...
        'MaxSpeed', maxspeed, 'Particles', 2000);
    
    %     if (plottest)
    %         % TEST Use this section of code for testing the algorithm
    %         acmap =colormap('Jet');
    %         [colour, cindex] = tcolormap(snr(:,1), acmap, 5, 40);
    %         scatter3(loctracks(i).xh(1,:), loctracks(i).xh(2,:), loctracks(i).xh(3,:), 20,  colour(1:length(loctracks(i).xh(3,:)),:), 'filled', 'MarkerEdgeColor', 'none');
    %     end
    
    %
    % now calculate the error between the particule filter and the
    % simulated track.
    simerrors = zeros (length(loctracks(i).xh(1,:)), 4);
    for k = 1:length(loctracks(i).xh(1,:))
        % x y and z errors
        simerrors(k,1) = loctracks(i).xh(1,k)-animaltrack.divetrack(k,1);
        simerrors(k,2) = loctracks(i).xh(2,k)-animaltrack.divetrack(k,2);
        simerrors(k,3) = loctracks(i).xh(3,k)-animaltrack.divetrack(k,3);
        % distance errors.
        distloc=pdist([loctracks(i).xh([1 2 3],k)'; hydroorigin1],'euclidean');
        disttrack=pdist([animaltrack.divetrack(k,:); hydroorigin1],'euclidean');
        
        simerrors(k,4) = distloc-disttrack;
        
    end
    
    %     figure
    %     hold on
    %     plot( loctracks(i).xh(3,:))
    %     plot( animaltrack.divetrack(:,3))
    
    loctracks(i).simerr = simerrors;
    loctracks(i).animaltrack=animaltrack;
    loctracks(i).startlocation=startlocation;
    
end

% %compare to simplex localisation
% plot_loc_v_pf

figure(1)
hold on
[p, s] = plotrawsim(simtracks, loctracks);
% grey colourmap for bathymetry
colormap gray
legend([p, s], {'Simulated track', 'Localised track'}, 'Location', 'northwest')


print('-clipboard','-dbitmap')
% create an error matrix of x,y,z xerr, yerr, zerr, disterr from all
% simualted tracks
errorall = [];
for i = 1:length(loctracks)
    if (~isempty(loctracks(i).xh))
        errorall = [errorall;  [loctracks(i).animaltrack.divetrack(1:length(loctracks(i).simerr(:,1)),:) loctracks(i).simerr]] ;
    end
end
ylim([-200,200 ])
zlim([-30,0])
% figure(2) % new figure for boxplots- bit of  hack but meh.
% error4surf=errorall(errorall(:,3)<-10,:);
% 
% % now plot a colour map of error.
% % show distance error
% hold off
% errorsurfdata = [error4surf(:,1), error4surf(:,2), abs(error4surf(:,7))];
% [ errorsurfmedian  ]   = boxplot3Daverage(errorsurfdata ,2, 2);
% 
% 
% % get rid of grid which has no actual data
% [ Xinterp, Yinterp, Xinterp_grid, Yinterp_grid] = filterSurf(errorsurfmedian, 10, 100);
% 
% % calculate the surfaces
% zintererror = griddata(errorsurfmedian(:,1),errorsurfmedian(:,2),...
%     errorsurfmedian(:,3),Xinterp,Yinterp,'natural');
% 
% figure(3)
% hold on
% % h=surf(Xinterp,Yinterp,ZInterpSpeed, 'FaceColor','none', 'FaceLighting','gouraud');
% h=surf(Xinterp,Yinterp,zintererror,'FaceColor','interp','FaceLighting','gouraud','EdgeColor','none');
% scatter3(northings(:,1), northings(:,2), 1000*ones(1,length(northings(:,2))),'.')
% colormap jet
% cb=colorbar;
% cb.Label.String = 'Median Error (m)';
% caxis([0,20])
% xlabel('x (m)')
% ylabel('y (m)')
% colormap(inferno)
% % plot hydrophone positions
% for i=1:length(hydrophones)
%     scatter3(hydrophones{i}(1,1), hydrophones{i}(1,2), 30, 'filled', 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'none');
% end
% hold off
