%% test the angle horizontal angle distirbution of animal tracks
clear
close all

numtracks = 200;
maxstartrange = 400; 

horztrack = zeros(100000, 5); 

horzrand = rand(numtracks, 2);

n=1;
for i=1:numtracks

    disp(['Simulating track ' num2str(i) ' of ' num2str(numtracks)]);

    startlocation = [(rand(1,1)-0.5)*maxstartrange, (rand(1,1)-0.5)*maxstartrange, 0];
    %     startlocation = [-60,0,0]; %%TEMP

    %% test animal
    animal.starttime=0; %%nmatlab datenum
    animal.diveheight = randi([-30, -5]); % this is -depth

    %vertical angles
    animal.descentvertangle = randi([30 70]);
    animal.ascentvertangle = randi([30 70]);

    %horizontal angles
    animal.descenthorzangle = horzrand(i,1)*360;
    animal.ascenthorzangle = horzrand(i,2)*360;

    animal.descenthorzangle = randi([0 360]);
    animal.ascenthorzangle = randi([0 360]);

    %speed - need to add one here so we don't get very very slow animals!
    animal.descentspeed = rand(1,1)*2+1; %meters per second;
    animal.bottomspeed = rand(1,1)*2+1; %meters per second
    animal.ascentspeed = rand(1,1)*2+1; %meters per second;

    animal.bottomtime = rand(1,1)*120; %seonds

    animal.wobblesigma = 3; %degrees


    animal.startx = startlocation(1);
    animal.starty = startlocation(2);

    animals(i)=animal;

    %     load('animal.mat');

    % first % simulate a porpoise approaching the array% check if any of

    animaltracks(i) = sim_porp_dive_track(animal, startlocation);

    animaltrack = animaltracks(i);

    for j =1:length(animaltrack.times)
        % the horizontal and vertical angle of the animal
        if (j==1)
            startpt = animaltrack.divetrack(1,:);
            endpt = animaltrack.divetrack(2,:);
        else
            startpt = animaltrack.divetrack(j-1,:);
            endpt = animaltrack.divetrack(j,:);
        end

        horzang = atan2d((endpt(2)-startpt(2)), (endpt(1)-startpt(1)));
        vertang = asind((endpt(3)-startpt(3))/pdist([startpt; endpt],'euclidean'));

%         horzang =  animal.descenthorzangle; 

        horztrack(n,1:3) = animaltrack.divetrack(j,:);
        horztrack(n,4) = horzang;
        horztrack(n,5) = vertang;
        n=n+1;
    end

end

figure
index = 4; 
errorsurfhorz = makerrsurf(horztrack, index, 10); 

clf
[h, c] = ploterrsurf(errorsurfhorz, []);
c.Label.String = 'Angle (dB)';
c.FontSize=12;
set(gca, 'FontSize', 12); 
xlim([-200,200]);
ylim([-200,200]);
caxis([0,180])
% caxis([40,70])
print('-clipboard','-dbitmap')

figure
scatter(horztrack(:,2), horztrack(:,4), '.')
xlabel('x (m)')
ylabel('start angle (degrees)')
% hold on
% scatter([animals.startx], [animals.starty])
% scatter([   animals.startx], [animals.ascenthorzangle])
