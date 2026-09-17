function [p, s] = plotrawsim(simtracks, loctracks)
%PLOTRAWSIM Plot the raw particle filter loc points alongside sim tracks.


cols = getdefaultcols();
colsim =cols(2,:);

snrcollims = [5 40];

hold on
for i=1:length(loctracks)
    
    % plot the track.
    alpha = 0.7;

    if (isempty(loctracks(i).chi2))
        continue;
    end
    
    p =  plot3(loctracks(i).animaltrack.divetrack(:,1), loctracks(i).animaltrack.divetrack(:,2), loctracks(i).animaltrack.divetrack(:,3),...
        'Color', [colsim, alpha], 'LineWidth', 2);
    
    % Use this section of code for testing the algorithm
    acmap =colormap('Jet');
    [colour, cindex] = tcolormap(simtracks(i).snr(:,1), acmap, snrcollims(1), snrcollims(2));
    scatter3(loctracks(i).xh(1,:), loctracks(i).xh(2,:), loctracks(i).xh(3,:), 20,  colour(1:length(loctracks(i).xh(3,:)),1:3), 'filled', 'MarkerEdgeColor', 'none');
    
    %plot the start location
    s = scatter3(loctracks(i).startlocation(1), loctracks(i).startlocation(2), loctracks(i).startlocation(3), 40, 'filled', 'MarkerEdgeColor', 'none');
   
   
    %HACK allows the color bar to be plotted without the altering the general
    %colourmap
    ticks = linspace(0, 1, 5);
    ticksstring = linspace(snrcollims(1),snrcollims(2), 5);
    for i=1:length(ticksstring)
        ticksnamestr{i}=num2str(ticksstring(i), '%.0f');
    end
    
    
    % HACK to allow a surface to be plotted of a different colour.
    c = colorbar('Ticks', ticks,...
        'TickLabels',ticksnamestr);
    
    acmap = colormap('Jet');
    c.Colormap = acmap;
    c.Ticks = linspace(c.Limits(1), c.Limits(2), 5);
    
    c.Label.String = 'Recieved SNR (dB)';
end


