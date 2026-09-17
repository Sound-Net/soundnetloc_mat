%%import trigger data

folder = 'E:\Google Drive\SMRU_research\Gill nets 2016-20\SoundTrap_4c\20181002_Cornwall_AK580_H3\1678032921\Binary\'; 
filemask = 'Click_Detector_Click_Detector_Trigger_Background*'; 

clktrigger = loadPamguardBinaryFolder(folder, filemask, 4); 

clktriggerdat = zeros(length(clktrigger), 1);
for i=1:length(clktrigger)
    clktriggerdat(i,1) = clktrigger(i).date;
    clktriggerdat(i,2) = mean(clktrigger(i).rawLevels);
end
