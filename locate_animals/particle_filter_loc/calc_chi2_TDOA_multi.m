function [chi2] = calc_chi2_TDOA_multi(source, obstimedelays, obsdelayerr, hydrophones, c)
%CALC_CHI2_TDOA_CLUSTERS Calculates the chi2 value from synchronised
%clusters of hydrophones
%   [CHI2] = CALC_CHI2_TDOA_CLUSTERS(SOURCE, OBSTIMEDELAYS, OBSDEALYERR,
%   HYDROPHONES, C) calculates the chi2 value for an unsynchronised
%   clusters of hydrophones for multiple detections. Each cluster is an
%   array of [x,y, z] within the a cell row HYDROPHONES. Corresponding
%   OBSTIMEDELAYS and OBSDEALYERR rows contain cells each with a set of
%   observed time delays and time delays errors respectively. SOURCE is the
%   source location to compare time delay measurents to and C is the speed
%   of sound.
%   The algorithm calculates the chi" value for each row and then

chi2=0; 
for i=1:length(obstimedelays(:,1))
    chi2 = chi2 + calc_chi2_TDOA_clusters(source, obstimedelays(i,:), obsdelayerr(i,:), hydrophones(i,:), c); 
end

% the mean chi2 value. 
chi2=chi2/length(obstimedelays);


end

