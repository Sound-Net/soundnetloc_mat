function [h, c,s] = ploterrsurf(errsurf,hydrophones)
%PLOTERRSURF plot an error surface. 

hold on
% h=surf(Xinterp,Yinterp,ZInterpSpeed, 'FaceColor','none', 'FaceLighting','gouraud');
h=surf(errsurf.xinterp,errsurf.yinterp,errsurf.zintererror,'FaceColor','interp','FaceLighting','gouraud','EdgeColor','none');
% scatter3(northings(:,1), northings(:,2), 1000*ones(1,length(northings(:,2))),'.')
colormap jet
c=colorbar;
c.Label.String = 'Median error (m)';
caxis([0,10])
xlabel('x (m)')
ylabel('y (m)')
colormap(inferno)
%plot hydrophone positions
for i=1:length(hydrophones)
    s=scatter3(hydrophones{i}(1,1), hydrophones{i}(1,2), 30, 'filled', 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'none');
end
hold off

end

