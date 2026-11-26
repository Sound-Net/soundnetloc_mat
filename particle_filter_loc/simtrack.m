function [timedelaysobs, hydrophones, animaltrack] = simtrack(type, startlocation)
%SIMTRACK Simulate example tracks to test with particle filter
%   [TIMEDELAYOBS, HYDROPHONES, ANIMALTRACK] = SIMTRACK(TYPE) simulateS an
%   ANIMALTRACK and correpsonding TIMEDELAYOBS measurements for each point
%   on the ANIMALTRACK assuming there is a hydrophones array positioned at
%   HYDROPHONES. TYPE indictates the type of simulated track to produce. 
%   TYPES are:
%%
%   * TYPE = 1: A simple simulated dive track. 
%   * TYPE = 2: Same 1 except some points on the track and time delay
%               measurements are removed. 


if nargin<1
    type = 1;
end

if nargin<2
    startlocation=[0,0,0];
end

c = 1500; 
hydrophones1  = get_st_hydrophones();
hydrophones2  = get_st_hydrophones();

hydroorigin1 = [0,0 -15]; 
hydroorigin2 = [0,30 -15]; 

hydrophones  = {hydrophones1+hydroorigin1, hydrophones2+hydroorigin2}; 

%generate the animal track
animaltrack=defaulttracks(1, startlocation);

% calculate the time delays for each point on the track
[timedelaysobs] = track_time_delays(animaltrack.divetrack, hydrophones, c); 

if type == 2
   [animaltrack,timedelaysobs] = sim_rmv_timedelays(animaltrack,timedelaysobs); 
end

% figure(1); 
% hold on
% plot3(animaltrack.divetrack(:,1), animaltrack.divetrack(:,2), animaltrack.divetrack(:,3));
% for i=1:length(hydrophones)
%     scatter3(hydrophones{i}(:,1), hydrophones{i}(:,2), hydrophones{i}(:,3), '.')
% end
% xlabel('x (m)');
% ylabel('y (m)');
% zlabel('z (m)');
% axis equal;
% legend('Track', 'Hydrophone Array 1', 'Hydrophone Array 2')
% hold off
% 
% figure(2)
% %plot the track time delays
% for j=1:length(timedelaysobs(1,:))
%     for i=1:length(timedelaysobs(:,1))
%         timedelaysmnat(i,:)=  timedelaysobs{i,j}'; 
%     end
%     subplot(1, length(timedelaysobs(1,:)), j); 
%     plot(timedelaysmnat); 
%     xlabel('n')
%     ylabel('Time delay (\mus)')
% end


end

