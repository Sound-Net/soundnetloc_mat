function [h, h2] = plot_chi2_surf(chi2surf, srclocations, location, limits)
%PLOT_CHI2_SURF Plotas the chi2 surface along of location grid search
%   [H] = PLOT_CHI2_SURF(CHI2SURF, SRCLOCATIONS, LOCATION, LIMITS) plots
%   a chi^2 

% ylim([50.07253712181435, 50.07538170582503])
% xlim([-5.055781672297898, -5.0534125878402])

if nargin<4
    latlims = minmax(srclocations(:,2));
    lonlims = minmax(srclocations(:,3));
else
    latlims = limits([1 2]);
    lonlims = limits([3 4]); 
end

clf

h = mesh(chi2surf.Yinterp, chi2surf.Xinterp, chi2surf.chi2); 

colormap jet
shading flat
grid off
xlabel lon; 
ylabel lat; 
zlabel chi2;
hold on 
plot3(srclocations(:,3), srclocations(:,2),...
    (max(max(chi2surf.chi2))+10)*ones(length(srclocations(:,3)), 1),...
    'Color', [0.3, 0.3, 0.3], 'LineWidth', 2);
h2 = scatter3(location(2), location(1), max(max(chi2surf.chi2)), 'filled'); 

ylim(latlims)
xlim(lonlims)

ylabel('Latitude (decimal)'); 
xlabel('Longitude (decimal)'); 

c = colorbar;
c.Label.String = 'ϒ';

hold off


end

