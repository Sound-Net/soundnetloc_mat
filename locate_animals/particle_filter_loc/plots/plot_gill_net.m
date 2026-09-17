function [h3, h4] = plot_gill_net(hydrophonesgeo, stroplength,  bathymetry, netheighfunc)
%PLOT_HYDROPHONES_GEO Plots hydrophones and the gill net.
%   [H1] = PLOT_HYDROPHONES_GEO(HYDROPHONESGEO, STROPLENGTH, BATHYMETRY)
%   plots a net on a surface. The net will follow 2.5m aboive the BATHYMTRY
%   and intersect HYDROPHONE%
%
%   [H1] = PLOT_HYDROPHONES_GEO(HYDROPHONESGEO, STROPLENGTH, BATHYMETRY, NETIHEIGHFUNC)
%   adds a specific NETHEIGHFUCN function that defines the headline of the
%   net (rather than the defult 2.5m). This fucntion has inputs
%   NETHEIGHTFUNCT(X(i), Y(i), BATHYMETRY) were X and Y are the current
%   location of net to calcule Z for. 

if nargin<2
    stroplength=3; %meters;
end

if nargin<3
    bathymetry =  [];
end

if nargin<4
    netheighfunc=[];
end

hold on
meshsizex = 2*4; %mesh size to plot the net as (purely for visual purposes)
meshsizey = 0.2*2; %mesh size to plot the net as (purely for visual purposes)

% plot the first hydrophone positions for each cluster
for i=1:length(hydrophonesgeo(1,:))
    for j=1:length(hydrophonesgeo(:,i))
        hydrophones = hydrophonesgeo{j,i};
        if (~isempty(hydrophones))
            netpos(i,:) = hydrophones(1,:);
            break;
        end
    end
end



% now draw the gill net.

%equation of a line
coefficients = polyfit(netpos(:,1), netpos(:,2), 1);
a = coefficients (1);
b = coefficients (2);

%equation of a line
coefficients = polyfit(netpos(:,1), netpos(:,3)-stroplength, 1);
az = coefficients (1);
bz = coefficients (2);


netheight =2.5; %meters



if (isempty(bathymetry))
    
    x= [-200, 200];
    h4 = plot3(x, x*a + b, x*az + bz, 'k', 'Linewidth', 2);
    
    meshy = 0:meshsizey:netheight;
    for i=1:length(meshy)
        plot3(x, x*a + b, (x*az + bz)-meshy(i), 'k', 'Linewidth', 1);
    end
    
    
    meshvert = min(x):meshsizex:max(x);
    for i=1:length(meshvert)
        xpos = meshvert(i);
        ypos = xpos*a + b;
        zpos=xpos*az + bz;
        plot3([xpos xpos], [ypos  ypos], [zpos (zposnetheight)], 'k', 'Linewidth', 1);
    end
    
    
    % %plot line from hydrophones to net
    % for i=1:length(netpos(:,1))
    %     plot3([netpos(i,1) netpos(i,1)], [netpos(i,2)  netpos(i,2)], [netpos(i,3) (netpos(i,3)-stroplength)], 'k', 'Linewidth', 1);
    % end
    
else
    
    % slower calculation using bathmetry
    usex = abs(netpos(1,1)-netpos(2,1))>abs(netpos(1,2)-netpos(2,2));
    %make sure the line is plotted correctly - if the net is facing north
    %or east then we can get astrange effects so must comensate for this by
    %seeing which direction the net is roughly in.
    if (usex)
        x= -200: 0.5: 200; % does not work very well
        y =  x*a + b;
    else
        y=-200: 0.5: 200;
        x=(y-b)./a;
    end
    
    recdepth=[]; 
    for i =1:length(x)
        if nargin<4 || isempty(netheighfunc)
            % default behavior: sample bathymetry and add netheight
            z(i) = interp2(bathymetry.x, bathymetry.y, bathymetry.z, x(i), y(i)) + netheight;
        else
            % user-supplied function handle: call with (x,y,netheight,bathymetry)
            [z(i),  netheight, recdepth]= netheighfunc(x(i), y(i), bathymetry);
        end
        %         if (y(i)<100 && y(i)>-100)
        %             z(i)
        %         end
       
    end

    % --note: sometimes get confused with animal tags library. 
    z = smooth(z);
    
    %if error here remove animal tags path for smooth so default MATLAB us used^
    h4 = plot3(x, x*a + b, z, 'k', 'Linewidth', 2);
    
    %plot horizontal gill net sections.
    meshy = 0:meshsizey:netheight;
    for i=1:length(meshy)
        plot3(x, y, z-meshy(i), 'k', 'Linewidth', 1);
    end
    
    % plot vertical gill net sections
    if (usex)
        meshvert = min(x):meshsizex:max(x);
    else
        meshvert = min(y):meshsizex:max(y);
    end
    for i=1:length(meshvert)
        if (usex)
            xpos = meshvert(i);
            ypos = xpos*a + b;
            zpos= interp1(x, z, xpos);
        else
            ypos = meshvert(i);
            xpos = (ypos-b)/a;
            zpos= interp1(y, z, ypos);
        end
        plot3([xpos xpos], [ypos  ypos], [zpos (zpos-netheight)], 'k', 'Linewidth', 1);
    end
    
    %plot line from hydrophones to net
    for i=1:length(netpos(:,1))
        dpth = netpos(i,3); 
        %but if we have a custom net function we can take the recorder
        %depth from there. 
        if (~isempty(recdepth) && ~isnan(recdepth(i)))
              dpth = recdepth(i); 
        end

        h3=scatter3(netpos(i,1), netpos(i,2), dpth,'filled', ...
                'MarkerEdgeColor', 'g',  'MarkerFaceColor', 'g');
        zpos = interp2(bathymetry.x,bathymetry.y,bathymetry.z,netpos(i,1),netpos(i,2) + netheight);
        plot3([netpos(i,1) netpos(i,1)], [netpos(i,2)  netpos(i,2)], [dpth zpos], 'k', 'Linewidth', 1);
    end
    
    
    
end


end

