function [] = saveloctrackdata(savefolder, name, loctracks, settings, figff)
%SAVELOCTRACKDATA Saves loc track data to a folder.

for i=1:length(loctracks)
    loctracks(i).pf.w=[];
    loctracks(i).pf.particles=[];
end

save([savefolder '/' name '_loctracks.mat'], 'loctracks', 'settings')
hgsave(figff, [savefolder '/' name '_track_plot.fig'], '-v7.3');
saveas(figff, [savefolder '/' name '_track_plot.png']);

end

