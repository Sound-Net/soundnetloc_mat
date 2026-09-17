function [timedelaysobs,timedelayerr,hydrophones,snr, animaltrack] = track2tdoainfo(animaltrack, ...
    hydrophonestrue, c, sourcelevel, noise, hyderoangerr)
%TRACK2TDOAINFO Converts an animal track to a set of time delays with added
%errors. 
%   Detailed explanation goes here

minsnr = 12; 

% minsnr = -140000; 


if nargin<6
   hyderoangerr=0;  
end
    

%randomly orientate hydrophones by 1 degree
    %important to use the xsens_pg_TD frame here because PG is referenced
    %to bearing =0 degrees @ x=0 and y = inf rather than the usual vice
    %versa. Time delays never lie though...
    for k = 1:length(hydrophonestrue)
        % remeber that heading is the last angle. Because upside down roll
        % is 180
        [~, rotm] = geo_ref_vec([0,0], deg2rad([180 rand(1,1)*0, 2*(rand(1,1)-0.5)*hyderoangerr]),...
            'xsens_pg_TD');
        
        hydrophones_rot{k}  = get_st_hydrophones();
        %Also rotate hydrophones
        for j=1:length(hydrophones_rot{k}(:,1))
            hydrophones_rot{k}(j,:)=(rotm*hydrophones_rot{k}(j,:)')';
        end
        
        hydroorigin = hydrophonestrue{k}- get_st_hydrophones(); 
        hydrophones{k} = hydrophones_rot{k} + hydroorigin; 
        
        
    end
            
    % calulate the observed time delays
    [timedelaysobs] = track_time_delays(animaltrack.divetrack, hydrophones, c);
    
%     % remove some of the time delays
%     [animaltrack,timedelaysobs] = sim_rmv_timedelays(animaltrack,timedelaysobs);
    
    % simulate the recieved SNR
    [snr] = sim_SNR(animaltrack, hydrophones, sourcelevel, noise);    

    %filter the points so only time delays from simulated clicks above a
    %minsnr are included. 
    [animaltrack,timedelaysobs, snr] = remvtimedelayssnr(animaltrack,timedelaysobs, snr, minsnr);

    if (isempty(snr))
        %no clicks above SNR
        timedelaysobs=[];
        timedelayerr=[];
        return;
    end
    
    timedelayerr = cell(length(snr(:,1)), length(snr(1,:)));
    
    % calculate the time delay errors from snr
    for j = 1:length(snr(:,1))
        for k = 1:length(snr(j,:))
            err =  2*snr2TDOAerr(snr(j,k), 1);
            timedelayerr{j,k} =  err*ones(length(timedelaysobs{j,k}),1)*1e-6;
%            timedelayerr{j,k} =  ones(length(timedelaysobs{j,k}),1)*1e-8; %% TEMP TEMP TEMP

            % add a random offset to the actual time delays from the time
            % delay error 
            timedelays = timedelaysobs{j,k};
            for m=1:length(timedelays)
                 timedelays(m) = normrnd(timedelays(m),0.5*err*1e-6); 
            end
            timedelaysobs{j,k} = timedelays; 
        end
    end
end

