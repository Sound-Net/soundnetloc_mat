function [animaltrack,timedelaysobs, snr] = remvtimedelayssnr(animaltrack,timedelaysobs, snr, minsnr)
%REMVTIMEDELAYSSNR Remove some time delay measurements from a track if
%they fall below an SNR threshold
%   [ANIMALTRACK, TIMEDELAYSOBS] = REMVTIMEDELAYSSNR(ANIMALTRACK,
%   TIMEDELAYSOBS, SNR, MINSNR) removes time delays from TIMEDELAYSOBS which below
%   MINSNR. SNR is matrix of SNR corresponding to the TIMEDELYASOBS matric
%   of time delays. ANIMALTRACK is the animal track structue - if all time
%   delays for a detection are removed then that point in the dive
%   structure is deleted.

%do this first as whole point will be removed
indexrmvtrck=[];
for i=1:length(timedelaysobs)
    n=0;
    for j=1:length(timedelaysobs(i,:))
        %remove one of the delays
        if (snr(i,j)<minsnr)
            timedelaysobs(i,j)={[]};
            n=n+1;
        end
    end
    if (n==length(timedelaysobs(i,:)))
        indexrmvtrck=[indexrmvtrck,i];
    end
end

%remove track points where neither time delays are detected.

animaltrack.divetrack(indexrmvtrck,:)=[];
animaltrack.times(indexrmvtrck)=[];
timedelaysobs(indexrmvtrck,:)=[];
snr(indexrmvtrck,:) =[]; 
end

