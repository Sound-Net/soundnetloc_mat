function [tdovarience] = error_TDOA(clicks)
%ERROR_TDOA Calculatyes the likely error for a a click struct.
%   TDOAVARIENCE = ERROR_TDOA(CLICKS) calculates the predicated TDOA
%   measurement for a list of CLICK structs. The error is based on
%   Gillespie and Macaulay 2019.  Time of arrival difference estimation
%   of narrow band high frequency eqcholocation clicks. JASA express
%   letters. The tdoaerror is in SECONDS.

% now that the SNR is calculated  back to time delays

%%TODO- add uncertainty due to soundspeed. 

snr = snr_clicks(clicks);

soundspeederr = 10/1500; % 10ms-1 

tdovarience = cell(length(clicks),1);
for i=1:length(snr)
    % doubling it brings it about to the right level
    err =  2*snr2TDOAerr(snr(i,1), 1);
    
%     disp(['SNR: ' num2str(snr(i,1)) '  ' num2str(err)])
    
    % now also add an arror due to the fact the xsens senor might not be
    % exact. - have mutliplied by two for now. 
    
    err = err+err*soundspeederr;
    
    %      %% TEMP %%%
%      % testing the algorothm
%     err = 1e6*5/1500/100;
%     %%%%%%%%%%%%%%%%

    % should be in seconds but is in  micros seconds.
    if (isfield(clicks(i), 'numTimeDelays'))
        tdovarience{i} = err*ones(clicks(i).numTimeDelays,1)*1e-6;
    else
        tdovarience{i} = err*ones(length(clicks(i).delays),1)*1e-6;
    end

       
    % tdoaerror{i} = err*ones(clicks(i).numTimeDelays,1);
end

end

