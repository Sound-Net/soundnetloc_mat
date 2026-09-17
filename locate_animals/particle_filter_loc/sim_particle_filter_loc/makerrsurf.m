function [errorsurf] = makerrsurf(error4surf, index, binsize)
% Make error surface from scattered error data. 

% 7 = range, 6 = depth, 5, = y, 4 = x
if nargin<2
    index = 7;
end

if nargin<3
binsize = 2; 
end

figure(1) % for box plots. 

% now plot a colour map of error.
% show distance error
errorsurfdata = [error4surf(:,1), error4surf(:,2), abs(error4surf(:,index))];
[ errorsurfmedian  ]   = boxplot3Daverage(errorsurfdata ,binsize, 2);


% get rid of grid which has no actual data
[ Xinterp, Yinterp, Xinterp_grid, Yinterp_grid] = filterSurf(errorsurfmedian, 10, 50);

% calculate the surfaces
zintererror = griddata(errorsurfmedian(:,1),errorsurfmedian(:,2),...
    errorsurfmedian(:,3),Xinterp,Yinterp,'natural');

% the error surface
errorsurf.xinterp = Xinterp;
errorsurf.yinterp = Yinterp;
errorsurf.zintererror = zintererror;


end