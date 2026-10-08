function [superfolder] = getsuperfolder(type)
%GETSUPERFOLDER Get the current directory for the gill net data. this
%returens the location of the SMRU_research directory which contains all
%SMRU related research.

% type = 1: location gillnet analysis folder
% type = 2; location single channel processed data


if nargin<1
    type=1;
end

[~, name] = system('hostname');

name = strtrim(name);
switch (name)

    case  'DESKTOP-Q1JKK67'
        if (type==1)
            %Dropbox folder
            superfolder = 'D:\Dropbox\SMRU_research';
        end
        if (type==2)
            %archive on NAS drive
            superfolder = 'F:\SoundNet\1chan_analysis\pamguard';
        end

    case 'd41966'
        % MacBook pro 2019
        if (type==1)
            %Dropbox folder
            superfolder = '/Users/au671271/Library/CloudStorage/Dropbox/SMRU_research';
        end

    case {'MCL14W0H1XXK', 'MCH2XK59MQDK'}
        %Mac mini M2 work
        if (type==1)
             %Dropbox folder
            superfolder = '/Users/jdjm/Dropbox/SMRU_research/';
        end

        if (type==2)
             %Dropbox folder
            superfolder = '/Volumes/JameArchive_1/SoundNet/1chan_analysis/pamguard';
        end

    case {'jdjmlinux1'}

         if (type==1)
             %Dropbox folder
            superfolder = '/home/jdjm/Dropbox//SMRU_research/';
         end

         if (type==2)
            superfolder = '/Volumes/JameArchive_1/SoundNet/1chan_analysis/pamguard';
        end

end

end



