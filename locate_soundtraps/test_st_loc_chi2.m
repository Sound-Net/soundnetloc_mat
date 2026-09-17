% test the minimisation searh algorithm
clear

npoints=30; 

% the true location
stlatlong = get_st_pos(134250533, 737335.440616609);
depth=10; 

% options for minimisation search
options=optimset;
options.PlotFcns=[@optimplotfval];
% options.Display='iter';
options.TolFun=0.0000001;

% create simulated points
n=1; 
for i=-npoints/2:npoints/2
    if (i==0)
       continue; 
    end
    sourcelocations(n,:)=[stlatlong(1)+i*0.0001+0.001 , stlatlong(2)+i*0.0001]; 
    r(n) = pos2dist(stlatlong(1), stlatlong(2),...
        sourcelocations(n,1), sourcelocations(n,2))*1000;
    slantangles(n)=tan(depth/r(n)); 
    bearings(n) = deg2rad(latLong2bearing(sourcelocations(n,1), sourcelocations(n,2), stlatlong(1), stlatlong(2)));

    n=n+1; 
end


% depths 
depths = ones(length(slantangles),1)*depth; 

%random start locations
x0latlon= [stlatlong(1)+rand(1,1)*0.01 stlatlong(2)+rand(1,1)*0.01];

% fmin search algorithm 
location_simplex = fminsearch(@(x) st_loc_chi2(x,...%x is the variable to change
    sourcelocations, depths, slantangles, bearings),... % input variables
    x0latlon, options);

chi2boat    = st_loc_chi2(location_simplex, sourcelocations, depths, slantangles, bearings); 
chi2boat    = st_loc_chi2(stlatlong, sourcelocations, depths, slantangles, bearings); 


figure(2)
hold on
scatter(sourcelocations(:,1), sourcelocations(:,2), '.'); 
scatter(location_simplex(:,1), location_simplex(:,2), 'filled'); 
scatter(stlatlong(:,1), stlatlong(:,2), '*'); 
hold off



