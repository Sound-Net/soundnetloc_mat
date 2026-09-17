function [h] = plot_bearings_hydrogeo(times, timedelaysobs, hydrophonesgeo)
%PLOT_BEARINGS_HYDROGEO Plots bearing to each click

nplots= length(times(1,:));

mintime = min(min(times)); 
maxtime = max(max(times)); 

for i=1:nplots
    
    % define the subplot to plot.
    subplot(nplots, 1, i);

    [anglesgeohydro, chi2] = locbearings(timedelaysobs(:,i), hydrophonesgeo(:,i));
    n=1;
    anglesgeo=zeros(length(anglesgeohydro), 3); 
    for k=1:length(anglesgeohydro)
        if (~isempty(anglesgeohydro{k}))
            anglesgeo(n,1) = times(k,i);
            anglesgeo(n,2) = anglesgeohydro{k}(1); %horizontal angle
            anglesgeo(n,3) = anglesgeohydro{k}(2); %slant angle
        end
        n=n+1;
    end
    
    anglesgeo=anglesgeo(1:n-1,:); %get rid of trialling zeros from pre allocation
    
    h(i) = scatter(anglesgeo(:,1), rad2deg(anglesgeo(:,2)), '.'); 
    ylabel('Bearing (degrees)')
    xlabel('Time')
    xlim([mintime, maxtime]);
    ylim([-180, 180])

end


    function [anglesgeohydro, chi2] = locbearings(timedelays, georefhydros)
        %% Calculate the bearings using rotated hydrophones
        % now calculate the bearing.
        anglesgeohydro=cell(length(timedelays),1);
        for j=1:length(timedelays)
            
            if (isempty(timedelays))
                anglesgeohydro{j}=[];
                continue;
            end
            
            if (mod(j,5)==0)
                disp(['Calculating click bearings for hydrophones: ' num2str(j) ' of ' num2str(length(timedelays))])
            end
            obstimedelays = timedelays{j};
            %%localaise
            if (~isempty(georefhydros{j}))
                [anglesgeohydro{j}, chi2] = localise_bearing_simplex(georefhydros{j}, obstimedelays);
            end
        end
    end

end

