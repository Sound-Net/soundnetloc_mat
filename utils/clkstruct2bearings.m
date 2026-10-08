function clickbearings = clkstruct2bearings(clicks)
%CLKSTRUCT2BEARINGS converts an bclick structures to an array of
% time and bearings. 
%
% CLKSTRUCT2BEARINGS(CLICKS) takes a standard PAMGuard struct of CLICKS and
% returns the bearing information as an array  [time, horz angle, slant
% angle] all in DEGREES. Note that the bearings are transformed so tney
% conform to how the bearings would be shown in PAMGuard.


clickbearings = zeros(length(clicks), 1);
for i=1:length(clicks)
    % 
    % if (isempty(clicks(i).date))
    %     continue;
    % end
    clickbearings(i,1)=clicks(i).date(1);

    %convert to a PAMGuard bearing i.e. references from y pointing north
    clickbearings(i,2) = -rad2deg(wrapToPi(clicks(i).angles(1)-pi/2));
    % clickbearings(i,2)=rad2deg(wrapToPi(clicks(i).angles(1)));
    clickbearings(i,3)=rad2deg(clicks(i).angles(2));
end

end