% plot the SNR of the simulated tracks

load('/Volumes/GoogleDrive/My Drive/SMRU_research/Gill nets 2016-20/SoundTrap_4c/sim_loc_accuracy/loctracks_3000trks_40m_sep_v3.mat')

% sim tracks
load('animaltrackstest.mat')
for i =1:length(animaltracks)
loctracks(i).animaltrack = animaltracks(i); 
end


hydrophones1  = get_st_hydrophones();
hydrophones2  = get_st_hydrophones();
hydrophonestrue  = {hydrophones1+hydroorigin1, hydrophones2+hydroorigin2};


snrtrack = zeros(10000000,7); 
hyderoangerr = 1; 



n=1;
for i=1:200

    disp(['Collating SNR: ' num2str(i) ' of ' num2str(length(loctracks)) ' total n ' num2str(n)]);
    [timedelaysobs,timedelayerr, hydrophones, snr, animaltrackrmv] = track2tdoainfo(loctracks(i).animaltrack, hydrophonestrue, c, sourcelevel, noise, hyderoangerr);


    animaltrack = loctracks(i).animaltrack;

    for j =1:length(snr(:,1))

        % the horizontal and vertical angle of the animal
        if (j==1)
            startpt = animaltrack.divetrack(1,:);
            endpt = animaltrack.divetrack(2,:);
        else
            startpt = animaltrack.divetrack(j-1,:);
            endpt = animaltrack.divetrack(j,:);
        end

        horzang = atan2d((endpt(2)-startpt(2)), (endpt(1)-startpt(1)));
        vertang = asind((endpt(3)-startpt(3))/pdist([startpt; endpt],'euclidean'));

        snrtrack(n,1:3) = animaltrack.divetrack(j,:);
        snrtrack(n,4:5) =  snr(j,:);
        snrtrack(n,6) = horzang; 
        snrtrack(n,7) = vertang; 
        n=n+1;
    end

end


snrtrack=snrtrack(1:n-1,:); 

index = 7; 
errorsurfsnr = makerrsurf(snrtrack, index, 10); 

clf
[h, c] = ploterrsurf(errorsurfsnr, hydrophonestrue);
c.Label.String = 'SNR (dB)';
c.FontSize=12;
set(gca, 'FontSize', 12); 
xlim([-200,200]);
ylim([-200,200]);
caxis([0,180])
caxis([0,30])
title('Simplex localisation on single clicks')
print('-clipboard','-dbitmap')
