% The simplex algorthm apppears immune to hydrophone rotations - this cannot be right
clear

load('simplexanimaltrack.mat')

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

n=1;
[timedelaysobs,timedelayerr, hydrophones] = track2tdoainfo(animaltrack, hydrophonestrue, c, sourcelevel, noise, hydroangerr*1);

locresult=[];
minchi2=[];


for j=1:length(timedelaysobs(:,1))
    disp(['Localising ' num2str(j) ' of ' num2str(length(timedelaysobs(:,1)))]); 
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