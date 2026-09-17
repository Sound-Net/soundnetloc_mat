function [absclicksample, abseulersample] = match_samples_legacy(clicks, ...
    eulerangles, wavinfo, euleroffset, clockspeed)
%MATCH_SAMPLES Matches samples between detected clicks and  euler angles
%
%  [ABSSMPLSCLK, ABSSMPLSEUL] = MATCH_SAMPLES(CLICKS, EULERANGLES, WAVINFO)
%  calculates the absolute samples for a list of CLICKS and EULERANGLES
%  using infomration on each of the wav files in WAVINFO. This can be used
%  to accurately time align CLICKS and EULERANGLES. ABSSMPLSCLK is the
%  absolute sample and for convience the click heading in DEGREES and
%  ABSSMPLSEUL is the absolute sample of every euler angle and for
%  coneveience the heading in DEGREES.
%  
%
%  [ABSSMPLSCLK, ABSSMPLSEUL] = MATCH_SAMPLES(CLICKS, EULERANGLES, WAVINFO,
%  EULEROFFSET, CLOCKSPEED) adds a time offset EULEROFFSET to the
%  EULERANGLES in days and specifies the CLOCKSPEED compared to the sample
%  rate. e.g.4 means that the clock is running at 4 times the sample rate.
%  Usually this would be because a 4 channel system is being used. 

if nargin<3   
    euleroffset=0; 
end

if nargin<4    
    clockspeed=4; 
end

wavfiletimes=[wavinfo.datenumstart]; 

ULONGMAX= 4294967295; % the maximum value of an unsigned 16 bit long. 

%AIM to calculate the absolute samples for all clicks and euler angles,
%then use these sample to compare. 

%Now calculate the absolute sample for each click (total samples since start)
absclicksample = zeros(length(clicks),2);
for i=1:length(clicks)
    
    [~, index] = min(abs(wavfiletimes-clicks(i).date));
    
    if (clicks(i).date<wavinfo(index).datenumstart)
       index=index-1;  
    end
    
    %n is the index
    absclicksample(i, 1)=clicks(i).startSample + wavinfo(index).wavsampletotal;
    absclicksample(i, 2)=rad2deg(clicks(i).angles(1)); 
end


%Now calculate the values for the eular angles in much the same way as the
%clicks 
abseulersample=zeros(length(eulerangles), 2);
eulerangles(:,1)=eulerangles(:,1)+euleroffset; %add offset here so applied to everything else. 

for i=1:length(eulerangles)

    time = eulerangles(i,1);
    stsample = eulerangles(i,2);
    
    % find the correct wav file (roughly, will be a few lost ones here)
    [~, index] = min(abs(wavfiletimes-time));
    if (time<wavinfo(index).datenumstart)
       index=max([index-1, 1]);  
    end

    % if i==100
    %     pause
    % end
    
    ulongoffset=0;
    if (stsample<wavinfo(index).stsamplestart)
       % the  sample has reset within the wav file...
       ulongoffset = ULONGMAX;
    end
    
    %samples into wav file 
    samplesin = stsample-wavinfo(index).stsamplestart+ulongoffset; 
    abseulersample(i,1)=wavinfo(index).wavsampletotal + samplesin/clockspeed; 
%     abseulersample(i,2)=index;

    % disp(['ST SAMPLE: ' num2str(i) ' : ' num2str(stsample) ' INDEX ' num2str(index) ...
    %     ' abseuler: ' num2str(abseulersample(i,1)) '  ' num2str(samplesin)])

    abseulersample(i,2)=(eulerangles(i,5)); 
end

end

