function [snr] = sim_SNR(animaltrack, hydrophones, sourcelevel, noise, beamprofile)
%SIM_SNR calculate the SNR of recieved clicks for an animal track.
%   [SNR] = SIM_SNR(ANIMALTRACK, SOURCELEVEL, NOISE, BEAMPROFILE)
%   caluclates the recieved SNR for a simulated ANIMALTRACK assuming a
%   specified SOURCELEVEL, background NOISE and BEAMPROFILE (horizontal
%   angle, vertical angle, TL surface).

spreadingcoeff = 20;
alpha = 0.04; % absorption coefficient dB/m

if nargin<5
    %%create a porpoise beam profile based on Koblitz et al 2012 and a few
    %%assumptions about SL behind and perpindicular to animal.
    type = 'porp_measured';
    [ Xq,Yq,dBq] = create_beam_profile(type, 'aperture', 0.065/2);
    dBq(isnan(dBq)) = -40;
else
    Xq = beamprofile.Xq;
    Yq = beamprofile.Xq;
    dBq = beamprofile.Xq;    
end

recieved_dB = zeros(length(animaltrack.divetrack(:,1)), length(hydrophones));

for i = 1:length(animaltrack.divetrack(:,1))
    
    % the horizontal and vertical angle of the animal
    if (i==1)
       startpt = animaltrack.divetrack(1,:);
       endpt = animaltrack.divetrack(2,:);
    else
       startpt = animaltrack.divetrack(i-1,:);
       endpt = animaltrack.divetrack(i,:);
    end
    
    %calcualte the animal angle based on track in degrees. 
    horz_angle_animal = atan2d((endpt(2)-startpt(2)), (endpt(1)-startpt(1)));
    vert_anlge_animal = asind((endpt(3)-startpt(3))/pdist([startpt; endpt],'euclidean'));
    
%      disp(['Horz angle animal: ' num2str(horz_angle_animal) ' Vert angle: ' num2str(vert_anlge_animal)])
    
    animal_pos = animaltrack.divetrack(i,:);
    
    for j = 1:length(hydrophones)
        
        pos_reciever = hydrophones{j}(1,:);
        
        % calculae the source level
        recieved_dB(i,j) = calc_recieved_level(pos_reciever, animal_pos, ...
            horz_angle_animal, vert_anlge_animal, sourcelevel, spreadingcoeff, alpha, Xq, Yq, dBq);
        
        if isnan(recieved_dB(i,j))
            distance=pdist([animal_pos; pos_reciever],'euclidean'); 
            disp(['Recieved level is nan' num2str(distance)])
        end
        
    end
    
end

snr = recieved_dB-noise;


end

