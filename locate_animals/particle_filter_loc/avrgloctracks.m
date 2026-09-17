function [loctrack,loctrackerr] = avrgloctracks(loctrackmulti, method)
%AVRGLOCTRACKS Average localisation tracks from multiple runs of the pf loc
%algorithm
%   [LOCTRACK,LOCTRACKERR] = AVRGLOCTRACKS(LOCTRACKMULTI, METHOD) average
%   results from multipe runs of the particle filter localisation algorithm
%  

if nargin<2
method = 'average';
end

switch (method)

    case 'average'
        %calculate overall mean of track location and errors
    loctrack=loctrackmulti(1); % pre intitialise the structure

    for ii=1:length(loctrackmulti)

        disp(['Averaging track ' num2str(ii)  ' of ' num2str(length(loctrackmulti))])

        [pferr] = particle_filter_err(loctrackmulti(ii).xh,...
            loctrackmulti(ii).pf);

        errxyz = zeros(length(pferr),3);
        for k=1:length(pferr)
            errxyz(k,:) = pferr(k).xyzerr;
        end

        for j=1:3
            meanerr(j).mean(ii,:) = errxyz(:,j)';
        end

        for j=1:6
            meanxh(j).mean(ii,:) = loctrackmulti(ii).xh(j,:);
        end
        meanchi2(ii,:) = loctrackmulti(ii).chi2(1,:);
    end

    %average the results and error.
    for j=1:3
        loctrackerr(j,:) = mean(meanerr(j).mean);
    end

    for j=1:6
        loctrack.xh(j,:) = mean(meanxh(j).mean);
        loctrack.chi2 = mean(meanchi2);
    end

    case 'chi2'
        %choose the track with the lowest chi2 value
        medianchi2  =  nan(length(loctrackmulti),1);
        for ii=1:length(loctrackmulti)
            medianchi2(ii) = mean(loctrackmulti(ii).chi2(1,:));
        end

        [~, index]= min(medianchi2);

        loctrack = loctrackmulti(index); 

        [pferr] = particle_filter_err(loctrack.xh,...
            loctrack.pf);

         for k=1:length(pferr)
            loctrackerr(k,:) = pferr(k).xyzerr;
         end
         loctrackerr=loctrackerr'; 
end


