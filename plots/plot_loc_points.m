function [h1] = plot_loc_points(locpoints,times, minmaxtimes, size, varargin)
%PLOT_LOC_POINTS Plot localisation points

acmap= colormap('Jet');

iArg = 0;

iremove=[]; 
while iArg < numel(varargin)
    iArg = iArg + 1;
    switch(varargin{iArg})
        case 'timecmap'
            iremove = [iArg iArg+1, iremove]; 

            iArg = iArg + 1;
            acmap = colormap(varargin{iArg});
    end
end

%nnow we need to remove non scatter function arguments from varargin

varargin(iremove)=[]; 


if nargin<2
    times=[];
end

if nargin<4
    size=20;
end


if nargin<3
    mintime = min(times);
    maxtime = max(times); 
else
    mintime=minmaxtimes(1);
    maxtime=minmaxtimes(2);
end

cols = getdefaultcols();
if (isempty(times))
    h1=scatter3(locpoints(:,1), locpoints(:,2), locpoints(:,3), ...
        'MarkerEdgeColor', cols(2,:),  'MarkerFaceColor', cols(2,:));
else
    
    
    [cols, ~] = tcolormap(times, acmap, mintime, maxtime); 
   

    h1=scatter3(locpoints(:,1), locpoints(:,2), locpoints(:,3),size, cols(:,[1:3]), varargin{:});
end


end

