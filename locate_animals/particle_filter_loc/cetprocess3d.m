function [xk] = cetprocess3d(k, xkm1, uk, T, varargin)
%CETPROCESS3D process equation for 3D movment of a cetacena
%   [XK] = CETPROCESS3D(K, XKML, VK. TIMES) returns the new state XK at time K
%   given the old state XKML and a function UK to generate system noise
%   (e.g.@(u)normrnd(0,sigma_u). T are the times to use from k=1 -> k=N.
%
%   This is used with particule_filter.m

%test
% xk = xkm1/2 + 25*xkm1/(1+xkm1^2) + 8*cos(1.2*k) + uk; % (returns column vector)

%bathymtry data
bathymetry =[];
%the maximum allowed speed in meters per second
maxspeed = 6; % they can swin up to 6ms-1
%2ms-1 %Based on: Kastelien et al 2018: swimming Speed of a Harbor Porpoise (Phocoena phocoena) During Playbacks of Offshore Pile Driving Sounds
% how far above the sea surface an animal can be.
mindepth = 0.5; % 0.5m above sea surface

iArg = 0; 
while iArg < numel(varargin)
    iArg = iArg + 1;
    switch(varargin{iArg})
        case 'Bathymetry'
            iArg = iArg + 1;
            %can be a single depth or a surface
            bathymetry = varargin{iArg};
        case 'MaxSpeed'
            iArg = iArg + 1;
            %            timeRange = dateNumToMillis(varargin{iArg});
            maxspeed = varargin{iArg};
        case 'MinDepth'
            iArg = iArg + 1;
            %            timeRange = dateNumToMillis(varargin{iArg});
            mindepth = varargin{iArg};
    end
end


xkm1 = checklimits(xkm1);

% the change in time.
dt = T(k)-T(k-1);

%% Define update equations in 3-D. (Coefficent matrices): A physics based model where we expect the animal to be [state transition (state + velocity)] + [input control (acceleration)]
A = [1 0 0 dt 0 0; ...
    0 1 0 0 dt 0; ...
    0 0 1 0 0 dt; ...
    0 0 0 1 0 0; ...
    0 0 0 0 1 0;...
    0 0 0 0 0 1;]; %state update matrice

B = [(dt^2/2);...
    (dt^2/2);...
    (dt^2/2);...
    dt;...
    dt;...
    dt];

% C = [1 0 0 0 0 0;...
%     0 1 0 0 0 0;...
%     0 0 1 0 0 0];  %this is our measurement function C, that we apply to the state estimate Q to get our expect next/new measurement

% update to the next state
xk = A*xkm1 + B.*[uk; uk];


xk = checklimits(xk);

% if (isnan(xk))
%     disp(['xk ' num2str(xk(1)) ' k ' num2str(k)]); 
% end

    function xk = checklimits(xk)
        %CHECKLIMITS - check the particle filter is within realistic
        %limits.
        
        % a marine mammal cannot fly!
        if (xk(3)>mindepth)
            xk(3) =  mindepth;
        end
        
        for i=4:6
            if (xk(i)>maxspeed)
                xk(i)=maxspeed;
            end
            if (xk(i)<-maxspeed)
                xk(i)=-maxspeed;
            end
        end
        
        if (~isempty(bathymetry))
            if (isstruct(bathymetry))
                %surface interpolation
                maxdepth = qinterp2(bathymetry.x,bathymetry.y,bathymetry.z,xk(1),xk(2));
            else
                maxdepth=bathymetry;
            end
            if (xk(3)<maxdepth)
                xk(3) =  maxdepth;
            end
        else
        end
    end

end

