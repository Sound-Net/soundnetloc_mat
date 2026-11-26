%An example of the particle filter to follow a 3D portpouise dive detected
%on two tiny aperture 4-channel hydrophone clusters. 

%% clear memory, screen, and close all figures
clear, clc, close all;

plotparticles=true; 

%% Observed data
type=2;%type of track to simulate 1- simple track 2- hard track with td's and points missing
ny = 3; % the 
[timedelaysobs, hydrophones, animaltrack] = simtrack(type); 
gethydrophones = @(k) hydrophones;  %simple get hydrophones 
y = timedelaysobs; 
tderr = @(k) 5/100/1500; 
times = animaltrack.times;
stda =0.5; %standard deivation in acceleration
c=1500; % sound speed. 

%% Process equation x[k] = sys(k, x[k-1], u[k]);
nx = 6;  % a basic movement model for porpoises assuming a standard deviation
% of acceelration. 
sys = @(k, xkm1, uk) cetprocess3d(k, xkm1, uk, times);

%% PDF of process noise and noise generator function
sigma_u = stda; % standard deviation of acceleration
gen_sys_noise = @(u) normrnd(0, sigma_u, [3,1]);         % sample from p_sys_noise (returns column vector)

%% Transition prior PDF p(x[k] | x[k-1])
% (under the suposition of additive process noise)
% p_xk_given_xkm1 = @(k, xk, xkm1) p_sys_noise(xk - sys(k, xkm1, 0));

%% Observation likelihood PDF p(y[k] | x[k])
% (under the suposition of additive process noise)
p_yk_given_xk = @(k, yk, xk) cetweighttd(k, yk, xk, tderr, gethydrophones, c);

%% Number of time steps
T = length(animaltrack.times);
% T=15; %TEMP

%% The first measurement
xh0 = [animaltrack.divetrack(1,:), 0,0,0]; 

%% Initial PDF
% p_x0 = @(x) normpdf(x, 0,sqrt(10));             % initial pdf
gen_x0 = @(x) [normrnd(xh0(1:3), 1) ,0, 0, 0];               % sample from p_x0 (returns column vector)

%% Separate memory
xh = zeros(nx, T); 
xh(:,1) = xh0; % add to the first track

pf.k               = 1;                   % initial iteration number
pf.Ns              = 1000;                 % number of particles
pf.w               = zeros(pf.Ns, T);     % weights
pf.particles       = zeros(nx, pf.Ns, T); % particles
pf.gen_x0          = gen_x0;              % function for sampling from initial pdf p_x0
pf.p_yk_given_xk   = p_yk_given_xk;       % function of the observation likelihood PDF p(y[k] | x[k])
pf.gen_sys_noise   = gen_sys_noise;       % function for generating system noisev - the system noise 
%pf.p_x0 = p_x0;                          % initial prior PDF p(x[0])
%pf.p_xk_given_ xkm1 = p_xk_given_xkm1;   % transition prior PDF p(x[k] | x[k-1])

%% Estimate state
for k = 2:T
   fprintf('Iteration = %d/%d\n',k,T);
   % state estimation
   
   pf.k = k; % the track is not evenly spaced in time.
   
   [xh(:,k), pf] = particle_filter(sys, y(k,:), pf, 'multinomial_resampling');
%    [xh(:,k), pf] = particle_filter(sys, y(k,:), pf, 'systematic_resampling');   

end


for i=1:T
    particles  = pf.particles(:,:,i); 
    xparticle(i,:)= particles(1,:);
    yparticle(i,:)= particles(2,:);
    zparticle(i,:)= particles(3,:);
end

hold on

if (plotparticles)
    %what is the maximum weight
    maxw = 0.9*max(max(pf.w));
    minw = 1.1*min(min(pf.w(:,2:end)));
    acmap = colormap('Jet');
    for i=1:length(xparticle(1,:))
        [colour, cindex] = tcolormap(pf.w(i,:), acmap, minw, maxw);
        f1=scatter3(xparticle(:,i), yparticle(:,i), zparticle(:,i), 15, colour(:,1:3), 'filled');
        % scatter3(xparticle(:,i), yparticle(:,i), zparticle(:,i), '.','MarkerEdgeColor', [0.6, 0.6, 0.6]);
        f1.MarkerFaceAlpha = 0.02;
    end
    
            f1.MarkerFaceAlpha = 0.2; % so can see on legend

%     c=colorbar;
%     c.Label.String = 'Particle Weight';
end

cols = getdefaultcols(); 
h2 = scatter3(xh(1,:), xh(2,:), xh(3,:), 'MarkerEdgeColor', cols(2,:),  'MarkerFaceColor', cols(2,:));

% plot sim track
colsim =cols(1,:); 
 plot3(animaltrack.divetrack(:,1), animaltrack.divetrack(:,2), animaltrack.divetrack(:,3),...
    'Color', colsim); 

index = zeros(length(timedelaysobs),1); %if there are missing time delay measurements. 
for i =1:length(timedelaysobs)
   for j=1:length(timedelaysobs(1,:))
      if (isempty(timedelaysobs{i,j}))
          index(i)=true; 
          break;
      end
   end
end

% plot the points with just one time delay measurement; 
h1 = scatter3(animaltrack.divetrack(index==1,1), animaltrack.divetrack(index==1,2), animaltrack.divetrack(index==1,3), ...
    'MarkerEdgeColor', colsim,  'MarkerFaceColor', 'none');
% plot the point wiht two time delay measurements 
h1 = scatter3(animaltrack.divetrack(~index,1), animaltrack.divetrack(~index,2), animaltrack.divetrack(~index,3), ...
    'filled', 'MarkerEdgeColor', colsim,  'MarkerFaceColor', colsim);

xlabel('x(m)', 'FontSize', 16)
ylabel('y(m)', 'FontSize', 16)
zlabel('depth(m)', 'FontSize', 16)

legend([h1, h2, f1], 'Porpoise track', 'Localised track', 'Particles')
view([50,40])
hold off


