% Plot localisation results from particle filter and clicks - but messy and
% repeats code but meh.
% clear 
% close all
% 
% 
% load('G:\My Drive\SMRU_research\Gill nets 2016-20\SoundTrap_4c\sim_loc_accuracy\loctracks_3000trks_40m_sep_v3.mat')
% % load('/Users/au671271/Google Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/sim_loc_accuracy/loctracks_1000trks_50m_sep_v2.mat')
% load('C:\Users\au671271\Google Drive\SMRU_research\Gill nets 2016-20\SoundTrap_4c\sim_loc_accuracy\loctracks_5000trks.mat')

sourcelevel = 190; % source level in dB
noise = 90; % noise in dB

hydrophones1  = get_st_hydrophones();
hydrophones2  = get_st_hydrophones();

hydroorigin1 = [0,0 -15];
hydroorigin2 = [2,40 -15];
hydroangerr=1; 

surfbin = 10; %the resolution of the error surface in meters 

hydrophonestrue  = {hydrophones1+hydroorigin1, hydrophones2+hydroorigin2};
c=1500;



% Particle filter error..
% create an error matrix of x,y,z xerr, yerr, zerr, disterr from all
% simualted tracks
hold off % - in case the box plots plot with hold on and everything grinds to halt
errorpf = [];
for i = 1:length(loctracks)
    if (~isempty(loctracks(i).xh))
    errorpf = [errorpf;  [loctracks(i).animaltrack.divetrack(1:length(loctracks(i).simerr(:,1)),:) loctracks(i).simerr]] ;
    end
end


mindepth = -20; % near the net
errorpfall=errorpf; 
% filter by depth
errorpf = errorpf(errorpf(:,3)<mindepth,:); 
errorsurfpf = makerrsurf(errorpf,7, surfbin);


% errorpf = errorpf(errorpf(:,3)>-20 & errorpf(:,3)<-10,:); 


figure(1)
clf
subplot(2,1,1)
[h, cbar] = ploterrsurf(errorsurfpf, hydrophonestrue);
cbar.FontSize=12;
set(gca, 'FontSize', 12); 
ylim([-200,200])
xlim([-200, 200])
caxis([0,10])
title('Particle filter localisation on click trains')



% localisation error
errorsimplex = zeros(10000000, 7); 
n=1;
for i = 1:length(loctracks)
    
    animaltrack = loctracks(i).animaltrack; 
    
    if (isempty(animaltrack))
        continue;
    end 
    
    disp(['Localising track using simplex ' num2str(i) ' of ' num2str(length(loctracks)) ' Total n ' num2str(n)]);
    [timedelaysobs,timedelayerr, hydrophones] = track2tdoainfo(animaltrack, hydrophonestrue, c, sourcelevel, noise, hydroangerr*1);
    
    locresult=[];
    minchi2=[];
    
    if (isempty(timedelaysobs))
        continue
    end
    
    for j=1:length(timedelaysobs(:,1))
        ndet=0;
        for k=1:length(timedelaysobs(1,:))
            if (~isempty(timedelaysobs{j,k}))
                ndet=ndet+1;
            end
        end
        
        if ndet>1
            % Note: for those not so familiar with MATLAB this creates a reference to a
            % fucntion rather than a variable.
            chi2  = @(source) calc_chi2_TDOA_clusters(source, timedelaysobs(j,:), timedelayerr(j,:), hydrophonestrue, c);
            %locresult is the localised position and minchi2 is the chi^2 value
            [locresult(j,:), minchi2(j,:)] = localise_simplex(chi2);
            
            
            % distance errors.
            distloc=pdist([locresult(j,:); hydroorigin1],'euclidean');
            disttrack=pdist([animaltrack.divetrack(j,:); hydroorigin1],'euclidean');
            
            % error array x,y,z xerr, yerr, zerr, disterr
            
            errorsimplex(n,:) = [animaltrack.divetrack(j,1), animaltrack.divetrack(j,2), animaltrack.divetrack(j,3)...
                animaltrack.divetrack(j,1) - locresult(j,1), animaltrack.divetrack(j,2) - locresult(j,2), animaltrack.divetrack(j,3) - locresult(j,3),...
                distloc-disttrack];
           n=n+1;
        else
            
        end
    end
end

    
errorsimplex = errorsimplex(1:n-1, :); 
errorsimplexall=errorsimplex; 

hold off
errorsimplex = errorsimplex(errorsimplex(:,3)<mindepth,:); 

% errorsimplex = errorsimplex(errorsimplex(:,3)>-20 & errorsimplex(:,3)<-10,:); 

errorsurfsmplx = makerrsurf(errorsimplex, 7, surfbin); 


subplot(2,1,2)
[h, cbar] = ploterrsurf(errorsurfsmplx, hydrophonestrue);
cbar.FontSize=12;
set(gca, 'FontSize', 12); 
xlim([-200,200]);
ylim([-200,200]);
caxis([0,10])
title('Simplex localisation on single clicks')
print('-clipboard','-dbitmap')
