%% Prepare ECCO data for mGlobe
% Use this script to convert ECCO1/2 (net)cdf files (no monthly
% data conversion). Downloading of ECCO data is currently not supported in 
% Octave due to FTP connection issues (only Matlab version is working right now
% github.com/emenems/mGlobe/blob/master/EXAMPLES/Scripts/download_convert_ecco_files.m)
clear
clc
pkg load netcdf
%% Settings
% Set time interval. Set carefully, this may overwrite existing files
time_start = [2016,1,1];
time_stop  = [2016,1,3];

% Set folder with downloaded ECCO1 & ECCO2 data
path_download1 = 'd:\GlobalModel\ECCO1\kfh_080\'; % ECCO1
path_download2 = 'd:\GlobalModel\ECCO2\PHIBOT\'; % ECCO1
% Set path with mGlobe OBPM (without 'ECCO1' & 'ECCO2' subfolder)
path_mglobe_obpm = 'f:\mikolaj\code\libraries\mGlobe_octave\OBPM\';
% Set path with mGlobe functions
path_mglobe = 'f:\mikolaj\code\libraries\mGlobe_octave';

% Set what should be done
convert_data = 2; % 0 = Off, 1 == ECCO1, 2 == ECCO2, 3 == ECCO1+ECCO2

% Close matlab/octave after downloading/conversion
close_after_comutation = 0; 

% ECCO subfolder/file naming
ecco1_subfolder = 'kf080h_'; % kalman filter, version dependent. tested for *80h only
ecco2_subfolder = 'PHIBOT.nc';

%% Convert data ECCO1
script_folder = pwd;
if convert_data == 1 || convert_data == 3
    try
        cd(path_download1);
        % First, get one file with ECCO1 (required for mGlobe_convert_ECCO)
        loc_dir = dir(fullfile(path_download1,...
                    sprintf('%s%04d',ecco1_subfolder,time_start(1)),'n10d*'));
        if length(loc_dir)>1
            % Look for one file
            for j = 1:length(loc_dir)
                loc_file = dir(fullfile(path_download1,...
                        sprintf('%s%04d',ecco1_subfolder,time_start(1)),...
                        loc_dir(j).name,'OBPano*'));
                if length(loc_file) >= 1
                    input_path = fullfile(path_download1,...
                        sprintf('%s%04d',ecco1_subfolder,time_start(1)),...
                        loc_dir(j).name);
                    break;
                end
            end
            if length(loc_file) >= 1
                cd(path_mglobe);
                mGlobe_convert_ECCO(datenum([time_start,6,0,0]),datenum([time_stop,18,0,0]),...
                    3,loc_file(1).name,fullfile(path_mglobe_obpm,'ECCO1'),...
                    input_path,1)
                cd(script_folder);
            else
                disp('Convert data ECCO1: set starting time to date with downloaded file');
            end
        else
            disp('Convert data ECCO1: set starting time to date with downloaded file');
        end
    catch exception
        cd(script_folder);
        fprintf('An error occurred during ECCO1 conversion:\n%s\n',exception.message);
    end
end

%% Convert data ECCO2
if convert_data == 2 || convert_data == 3
    try
        cd(path_download2);
        % First, get one file with ECCO2 (required for mGlobe_convert_ECCO)
        loc_dir = dir('PHIBOT.*.nc');
        if length(loc_dir)>1
            input_file = loc_dir(1).name;
            cd(path_mglobe);
            mGlobe_convert_ECCO(datenum(time_start),datenum(time_stop),...
                    4,input_file,fullfile(path_mglobe_obpm,'ECCO2'),...
                    path_download2,4)
        else
            disp('Convert data ECCO2: set starting time to date with downloaded file');
        end
    catch exception
        cd(script_folder);
        fprintf('An error occurred during ECCO2 conversion:\n%s\n',exception.message);
    end
end