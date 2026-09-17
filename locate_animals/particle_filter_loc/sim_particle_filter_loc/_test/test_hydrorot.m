% test the hydrophone rotation that is used in track2tdoainfo.m

devicesep = 40; 

hyderoangerr = -1; 

hydrophones1  = get_st_hydrophones();
hydrophones2  = get_st_hydrophones();

hydroorigin1 = [0,0 -15];
hydroorigin2 = [2,devicesep -15];

hydrophonestrue  = {hydrophones1+hydroorigin1, hydrophones2+hydroorigin2};
for k = 1:length(hydrophonestrue)
        % remeber that heading is the last angle. Because upside down roll
        % is 180
        [~, rotm] = geo_ref_vec([0,0], deg2rad([180 rand(1,1)*0, rand(1,1)*hyderoangerr]),...
            'xsens_pg_TD');
        
        hydrophones_rot{k}  = get_st_hydrophones();
        %Also rotate hydrophones
        for j=1:length(hydrophones_rot{k}(:,1))
            hydrophones_rot{k}(j,:)=(rotm*hydrophones_rot{k}(j,:)')';
        end
        
        hydroorigin = hydrophonestrue{k}- get_st_hydrophones(); 
        hydrophones{k} = hydrophones_rot{k} + hydroorigin; 
end

%% plot to see if things are working
clf
hold on
scatter(hydrophones{k}(:,1), hydrophones{k}(:,2), 'filled')
scatter(hydrophonestrue{k}(:,1), hydrophonestrue{k}(:,2), 'filled')
legend('Rotated', 'Original'); 
xlabel('x')
ylabel('y')
axis equal


