function [xh,pf, chi2] = partice_filter_pam(times, timedelaysobs, hydrophones, startlocation, varargin)
%PARTICE_FILTER_PAM POarticle filter tracking algorihtm
%   [XH,P,CHI2] = PARTICLE_FILTER_PAM(TIMEDELAYSOBS, HYDROPHONES, STARTLOCATION)
%   is an implementation of a particle filter which tracks toothed whales
%   based on recieved voclasisation on one or more synchronised HYDROPHONES
%   array(s). TIMEDELAYSOBS is a cell array of time delay measurements
%   corresponding to each HYDROPHONE cluster (also a cell array). XH is an
%   array  with each row corresponding to (x (m), y(m), z(m), velocity x
%   (m/s), velocity y (m/s) velocity z(m/s)). PF is a struct the raw data from the
%   particle filter. CHI2 is a list of CHI2 values for each calculated mean
%   ppoint on the track. 
%
%   'DelayFunction' (optional) is a function handle TAU = F(X, H1, H2)
%   predicting the time delays of hydrophone pairs for a source at X, e.g.
%   ray traced propagation (see CETWEIGHTTD). Default [] is straight line
%   propagation at 'SoundSpeed'.
%
%   'Likelihood' (optional) is how the time delay chi2 of a particle
%   becomes its weight (see CETWEIGHTTD): 'inverse' (default) or
%   'gaussian'.

c=1500;

bathymetry = []; %empty means no bathy limits. 
maxspeed = 2; %meters per second 
accelsigma = 0.5; 
timedelayserr = 5/100/1500; % one uniform time delay error in seconds. 
particles = 500; 
delayfun = []; % straight line propagation
likelihood = 'inverse'; % see CETWEIGHTTD

iArg = 0 ; 
while iArg < numel(varargin)
   iArg = iArg + 1;
   switch(varargin{iArg})
       case 'Bathymetry'
           iArg = iArg + 1;
           bathymetry = varargin{iArg};
       case 'MaxSpeed'
           iArg = iArg + 1;
           maxspeed = varargin{iArg};
       case 'StdAccel'
           iArg = iArg + 1;
           accelsigma = varargin{iArg};
      case 'TimeDelayErrors'
           iArg = iArg + 1;
           timedelayserr = varargin{iArg};
       case 'SoundSpeed'
           iArg = iArg + 1;
           c = varargin{iArg};
       case 'Particles'
           iArg = iArg + 1;
           particles = varargin{iArg};
       case 'DelayFunction'
           iArg = iArg + 1;
           delayfun = varargin{iArg};
       case 'Likelihood'
           iArg = iArg + 1;
           likelihood = varargin{iArg};
   end          
end

%% Observed data
%Hydrophone positions
if (length(hydrophones(:,1))>1)
    %moving hydrophones (i.e. hydrophone are in different positions for each time delay measurement)
    gethydrophones = @(k) gethydrophonesgeo(k,hydrophones); %simple get hydrophones
else
    %static hydrophones
    gethydrophones = @(k) hydrophones; %simple get hydrophones
end

%Time delays
y = timedelaysobs;


if (length(timedelayserr(:,1))>1)
    %moving hydrophones (i.e. hydrophone are in different positions for each time delay measurement)
    gettderrors = @(k) getTDOAErr(k,timedelayserr); %simple get hydrophones
else
    %static hydrophones
    gettderrors = @(k) timedelayserr; %simple get hydrophones
end

%sim parametres
sigma_u = accelsigma; % standard deviation of acceleration for the animal model

%% Process equation x[k] = sys(k, x[k-1], u[k]);
nx = 6;  % a basic movement model for porpoises assuming a standard deviation
% of acceelration. 
sys = @(k, xkm1, uk) cetprocess3d(k, xkm1, uk, times, 'Bathymetry', bathymetry, 'MaxSpeed', maxspeed);

%% PDF of process noise and noise generator function
gen_sys_noise = @(u) normrnd(0, sigma_u, [3,1]);         % sample from p_sys_noise (returns column vector)

%% Transition prior PDF p(x[k] | x[k-1])
% (under the suposition of additive process noise)
% p_xk_given_xkm1 = @(k, xk, xkm1) p_sys_noise(xk - sys(k, xkm1, 0));

%% Observation likelihood PDF p(y[k] | x[k])
% (under the suposition of additive process noise)
p_yk_given_xk = @(k, yk, xk) cetweighttd(k, yk, xk, gettderrors, gethydrophones, c, delayfun, likelihood);

%% Number of time steps
T = length(timedelaysobs);
% T=15; %TEMP

%% The first measurement
xh0 = [startlocation, 0,0,0]; 

%% Initial PDF
% p_x0 = @(x) normpdf(x, 0,sqrt(10));             % initial pdf
gen_x0 = @(x) [normrnd(xh0(1:3), 10) ,0, 0, 0];               % sample from p_x0 (returns column vector)

%% Separate memory
xh = zeros(nx, T); 
xh(:,1) = xh0; % add to the first track

pf.k               = 1;                   % initial iteration number
pf.Ns              = particles;  %2000               % number of particles
pf.w               = zeros(pf.Ns, T);     % weights
pf.particles       = zeros(nx, pf.Ns, T); % particles
pf.gen_x0          = gen_x0;              % function for sampling from initial pdf p_x0
pf.p_yk_given_xk   = p_yk_given_xk;       % function of the observation likelihood PDF p(y[k] | x[k])
pf.gen_sys_noise   = gen_sys_noise;       % function for generating system noisev - the system noise 
%pf.p_x0 = p_x0;                          % initial prior PDF p(x[0])
%pf.p_xk_given_ xkm1 = p_xk_given_xkm1;   % transition prior PDF p(x[k] | x[k-1])

%% Estimate intial p values
chi2= -1*ones(1, T);
chi2(1) =  p_yk_given_xk(1, y(1,:), xh0);

%% Estimate state
for k = 2:T
   fprintf('Iteration = %d/%d\n',k,T);
   % state estimation
   
   pf.k = k; % the track is not evenly spaced in time.
   
   [xh(:,k), pf] = particle_filter(sys, y(k,:), pf, 'multinomial_resampling');
%    [xh(:,k), pf] = particle_filter(sys, y(k,:), pf, 'systematic_resampling');   
   chi2(k) =  p_yk_given_xk(k,  y(k,:), xh(:,k));
   
%    disp(['xh: ' num2str(xh(1,k))])

end


    function hydrophones = gethydrophonesgeo(k, hydrophonesgeo)
        % simple function just to get a hydrophone from cell array
        % hydrophone measurments. 
        hydrophones=hydrophonesgeo(k,:); 
    end

    function tdErrors = getTDOAErr(k, timedelayserr)
        %function to return the correct time delay errors from cell array
        tdErrors=timedelayserr(k,:); 
    end

end

