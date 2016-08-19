function mGlobe_convert_GLDAS(start_calc,end_calc,model,time_resol,ghc_path,input_path,input_file)
%MGLOBE_CONVERT_GLDAS Download GLDAS/MERRA data
% Convert required hydrological GLDAS/MERRA data, i.e. soil moisture and snow.
% Water store in vegetation is not taken into account.
% 
% ASSUMTPION:      
%   NOAH           ... layer 0 == longitude vector
%                  ... layer 1 == latitude vector
%                  ... layer 4 == contains 4 soil moisture layers
%                  ... layer 5 == snow water equivalent
%   CLM            ... layer 0 == longitude vector
%                  ... layer 1 == latitude vector
%                  ... layer 4 == contains 10 soil moisture layers
%                  ... layer 5 == snow water equivalent
%   MOSAIC         ... layer 0 == longitude vector
%                  ... layer 1 == latitude vector
%                  ... layer 4 == contains 3 soil moisture layers
%                  ... layer 5 == snow water equivalent
%   VIC            ... layer 0 == longitude vector
%                  ... layer 1 == latitude vector
%                  ... layer 4 == contains 3 soil moisture layers
%                  ... layer 5 == snow water equivalent
%   MERRA          ... MAT1NXLND layers: TWLAND, XDim, YDim 
% 
% INPUT:
%   start_calc     ... starting time in matlab format (days)
%                      Example: datenum([2012,1,1,12,0,0]);
%   end_calc       ... finish time in matlab format (days)
%                      Example: datenum([2013,1,1,12,0,0]);
%   time_resol     ... time resolution switcher: 1 == 3 hours, 2 == 6 hours,
%                      3 == 12 hours, 4 == 24 hours, 5 == 48 hours, 6 == month.
%                      Example: 4
%   model          ... GLDAS model identification: 
%         1        ... CLM model (1.0 deg spatial resolution)
%         2        ... MOSAIC model (1.0 deg spatial resolution)
%         3        ... NOAH with 0.25 deg spatial resolution
%         4        ... NOAH with 1.0 deg spatial resolution
%         5        ... VIC model (1.0 deg spatial resolution)
%         6        ... MERRA model (0.667x0.5 deg spatial resolution)
%                      Example: 1
%   ghc_path 	     ... output path (string)
%                      Example: fullfile('GHM','CLM');
%   input_path     ... input file folder (string)
%                      Example: fullfile('E','models','CLM');
%   input_file     ... input file name (string)
%                      Example: 'GLDAS_CLM10SUBP_3H.A2013001.0000.001.2015184151845.pss.nc';
% 
% OUTPUT (saved automatically):
%   out_mat        ... structure array (several matrices) containing:
%   out_mat.lon    ... longitude (degrees)
%   out_mat.lat    ... latitude  (degrees)
%   out_mat.time   ... civil time (UTC)
%   out_mat.soilmX ... soil moisture for layer X (kg/m2)
%   out_mat.swe    ... snow water equivalent  (kg/m2)
%   out_mat.twland ... Total Land Water Storage (kg/m2)
%   out_mat.units  ... swe and soilmX units
% 
%                                         M.Mikolaj, mikolaj@gfz-potsdam.de
%                                                                05.07.2015
%                                                                      v1.0

%% Time setting
[year_s,month_s] = datevec(start_calc);                                     % transform matlab time to civil date
[year_e,month_e] = datevec(end_calc);
if time_resol == 6                                                          % create time for MONTHly data
    j = 1;
    for year = year_s:year_e
        if j == 1
            mz = month_s;
        else
            mz = 1;
        end
        if year == year_e
            mk = month_e;
        else
            mk = 12;
        end
        for m = mz:mk
            time(j,1) = year;
            time(j,2) = m;
            j = j + 1;
        end
    end
    time(:,3) = 1;
    time(:,7) = datenum(time(:,1),time(:,2),time(:,3));
else                                                                        % create time for other resolutions
    switch time_resol
        case 1
            time_resol_in_days = 3/24;
        case 2
            time_resol_in_days = 6/24;
        case 3 
            time_resol_in_days = 12/24;
        case 4
            time_resol_in_days = 1;
        case 5
            time_resol_in_days = 2;
    end
    days = start_calc:time_resol_in_days:end_calc;
    time = datevec(days);
    if model==6
        time(:,5) = 30;
    end
    time(:,7) = datenum(time(:,1:6));
    clear days
end
progres_perc = linspace(1,99,size(time,1));
for i = 1:size(time,1);
    check_out = 0;
try
switch model
        %% N O A H   0.25 deg
    case 3
        switch time_resol
            case 6 % monthly data
                cfile = fullfile(input_path,sprintf('%s%04d%02d*',input_file(1:17),time(i,1),time(i,2)));
                cfile = dir(cfile); % get exact file name without wildcard
                ncid = netcdf_open(fullfile(input_path,cfile.name),'NC_NOWRITE'); % use fullfile function as the dir command returns only file name, no path
                nazov = fullfile(ghc_path,sprintf('GLDAS_NOAH025_M_%4d%02d.mat',time(i,1),time(i,2))); 
            otherwise % hourly data
                cfile = fullfile(input_path,sprintf('%s%04d%03d.%02d*',input_file(1:22),time(i,1),floor(time(i,7)-datenum(time(i,1),1,1,0,0,0))+1,time(i,4)));
                cfile = dir(cfile); % get exact file name without wildcard
                ncid = netcdf_open(fullfile(input_path,cfile.name),'NC_NOWRITE'); % use fullfile function as the dir command returns only file name, no path
                nazov = fullfile(ghc_path,sprintf('GLDAS_NOAH025SUBP_3H_%4d%02d%02d_%02d.mat',time(i,1),time(i,2),time(i,3),time(i,4))); % Daily data
        end
            lat_vec = double(netcdf_getVar(ncid,1));
            lon_vec = double(netcdf_getVar(ncid,0));
            [out_mat.lon,out_mat.lat] = meshgrid(lon_vec,lat_vec);
            % Select data 
            temp = double(netcdf_getVar(ncid,4));
            out_mat.soilm1 = temp(:,:,4)';out_mat.soilm1(out_mat.soilm1>9.999e+19 | out_mat.soilm1<0) = 0;
            out_mat.soilm2 = temp(:,:,3)';out_mat.soilm2(out_mat.soilm2>9.999e+19 | out_mat.soilm2<0) = 0;
            out_mat.soilm3 = temp(:,:,2)';out_mat.soilm3(out_mat.soilm3>9.999e+19 | out_mat.soilm3<0) = 0;
            out_mat.soilm4 = temp(:,:,1)';out_mat.soilm4(out_mat.soilm4>9.999e+19 | out_mat.soilm4<0) = 0;
            out_mat.swe = double(netcdf_getVar(ncid,5));out_mat.swe = out_mat.swe';
            out_mat.swe(out_mat.swe>9.999e+19 | out_mat.swe<0) = 0;
            out_mat.time = time(i,7);
            out_mat.source = cfile;
            out_mat.units = 'mm';
            netcdf_close(ncid);
            save(nazov,'out_mat','-mat7-binary')
        %% N O A H   1 deg
    case 4
        switch time_resol
            case 6 % monthly data
                cfile = fullfile(input_path,sprintf('%s%04d%02d*',input_file(1:16),time(i,1),time(i,2))); % create file name with wildcard
                cfile = dir(cfile); % get exact file name without wildcard
                ncid = netcdf_open(fullfile(input_path,cfile.name),'NC_NOWRITE'); % use fullfile function as the dir command returns only file name, no path
                nazov = fullfile(ghc_path,sprintf('GLDAS_NOAH10_M_%4d%02d.mat',time(i,1),time(i,2))); 
            otherwise % hourly data
                cfile = fullfile(input_path,sprintf('%s%04d%03d.%02d*',input_file(1:21),time(i,1),floor(time(i,7)-datenum(time(i,1),1,1,0,0,0))+1,time(i,4))); % create file name with wildcard
                cfile = dir(cfile); % get exact file name without wildcard
                ncid = netcdf_open(fullfile(input_path,cfile.name),'NC_NOWRITE'); % use fullfile function as the dir command returns only file name, no path
                nazov = fullfile(ghc_path,sprintf('GLDAS_NOAH10SUBP_3H_%4d%02d%02d_%02d.mat',time(i,1),time(i,2),time(i,3),time(i,4))); % Daily data
        end
            lat_vec = double(netcdf_getVar(ncid,1));
            lon_vec = double(netcdf_getVar(ncid,0));
            [out_mat.lon,out_mat.lat] = meshgrid(lon_vec,lat_vec);
            % Select data 
            temp = double(netcdf_getVar(ncid,4));
            out_mat.soilm1 = temp(:,:,4)';out_mat.soilm1(out_mat.soilm1>9.999e+19 | out_mat.soilm1<0) = 0;
            out_mat.soilm2 = temp(:,:,3)';out_mat.soilm2(out_mat.soilm2>9.999e+19 | out_mat.soilm2<0) = 0;
            out_mat.soilm3 = temp(:,:,2)';out_mat.soilm3(out_mat.soilm3>9.999e+19 | out_mat.soilm3<0) = 0;
            out_mat.soilm4 = temp(:,:,1)';out_mat.soilm4(out_mat.soilm4>9.999e+19 | out_mat.soilm4<0) = 0;
            out_mat.swe = double(netcdf_getVar(ncid,5));out_mat.swe = out_mat.swe';
            out_mat.swe(out_mat.swe>9.999e+19 | out_mat.swe<0) = 0;
            out_mat.time = time(i,7);
            out_mat.source = cfile;
            out_mat.units = 'mm';
            netcdf_close(ncid);
            save(nazov,'out_mat','-mat7-binary')
        %% C L M
    case 1
        switch time_resol
            case 6 % monthly data
                cfile = fullfile(input_path,sprintf('%s%04d%02d*',input_file(1:15),time(i,1),time(i,2)));
                cfile = dir(cfile); % get exact file name without wildcard
                ncid = netcdf_open(fullfile(input_path,cfile.name),'NC_NOWRITE'); % use fullfile function as the dir command returns only file name, no path
                nazov = fullfile(ghc_path,sprintf('GLDAS_CLM10_M_%4d%02d.mat',time(i,1),time(i,2))); 
            otherwise % hourly data
                cfile = fullfile(input_path,sprintf('%s%04d%03d.%02d*',input_file(1:20),time(i,1),floor(time(i,7)-datenum(time(i,1),1,1,0,0,0))+1,time(i,4)));
                cfile = dir(cfile); % get exact file name without wildcard
                ncid = netcdf_open(fullfile(input_path,cfile.name),'NC_NOWRITE'); % use fullfile function as the dir command returns only file name, no path
                nazov = fullfile(ghc_path,sprintf('GLDAS_CLM10SUBP_3H_%4d%02d%02d_%02d.mat',time(i,1),time(i,2),time(i,3),time(i,4))); % Daily data
        end
            lat_vec = double(netcdf_getVar(ncid,1));
            lon_vec = double(netcdf_getVar(ncid,0));
            [out_mat.lon,out_mat.lat] = meshgrid(lon_vec,lat_vec);
            % Select data 
            temp = double(netcdf_getVar(ncid,4));
            out_mat.soilm1 = temp(:,:,10)';out_mat.soilm1(out_mat.soilm1>9.999e+19 | out_mat.soilm1<0) = 0;
            out_mat.soilm2 = temp(:,:,9)';out_mat.soilm2(out_mat.soilm2>9.999e+19 | out_mat.soilm2<0) = 0;
            out_mat.soilm3 = temp(:,:,8)';out_mat.soilm3(out_mat.soilm3>9.999e+19 | out_mat.soilm3<0) = 0;
            out_mat.soilm4 = temp(:,:,7)';out_mat.soilm4(out_mat.soilm4>9.999e+19 | out_mat.soilm4<0) = 0;
            out_mat.soilm5 = temp(:,:,6)';out_mat.soilm5(out_mat.soilm5>9.999e+19 | out_mat.soilm5<0) = 0;
            out_mat.soilm6 = temp(:,:,5)';out_mat.soilm6(out_mat.soilm6>9.999e+19 | out_mat.soilm6<0) = 0;
            out_mat.soilm7 = temp(:,:,4)';out_mat.soilm7(out_mat.soilm7>9.999e+19 | out_mat.soilm7<0) = 0;
            out_mat.soilm8 = temp(:,:,3)';out_mat.soilm8(out_mat.soilm8>9.999e+19 | out_mat.soilm8<0) = 0;
            out_mat.soilm9 = temp(:,:,2)';out_mat.soilm9(out_mat.soilm9>9.999e+19 | out_mat.soilm9<0) = 0;
            out_mat.soilm10 = temp(:,:,1)';out_mat.soilm10(out_mat.soilm10>9.999e+19 | out_mat.soilm10<0) = 0;
            out_mat.swe = double(netcdf_getVar(ncid,5));out_mat.swe = out_mat.swe';
            out_mat.swe(out_mat.swe>9.999e+19 | out_mat.swe<0) = 0;
            out_mat.time = time(i,7);
            out_mat.source = cfile;
            out_mat.units = 'mm';
            netcdf_close(ncid);
            save(nazov,'out_mat','-mat7-binary');
            clear out_mat nazov cfile
        %% M O S A I C
    case 2
        switch time_resol
            case 6 % monthly data
                cfile = fullfile(input_path,sprintf('%s%04d%02d*',input_file(1:15),time(i,1),time(i,2)));
                cfile = dir(cfile); % get exact file name without wildcard
                ncid = netcdf_open(fullfile(input_path,cfile.name),'NC_NOWRITE'); % use fullfile function as the dir command returns only file name, no path
                nazov = fullfile(ghc_path,sprintf('GLDAS_MOS10_M_%4d%02d.mat',time(i,1),time(i,2))); 
            otherwise % hourly data
                cfile = fullfile(input_path,sprintf('%s%04d%03d.%02d*',input_file(1:20),time(i,1),floor(time(i,7)-datenum(time(i,1),1,1,0,0,0))+1,time(i,4)));
                cfile = dir(cfile); % get exact file name without wildcard
                ncid = netcdf_open(fullfile(input_path,cfile.name),'NC_NOWRITE'); % use fullfile function as the dir command returns only file name, no path
                nazov = fullfile(ghc_path,sprintf('GLDAS_MOS10SUBP_3H_%4d%02d%02d_%02d.mat',time(i,1),time(i,2),time(i,3),time(i,4))); % Daily data
        end
            lat_vec = double(netcdf_getVar(ncid,1));
            lon_vec = double(netcdf_getVar(ncid,0));
            [out_mat.lon,out_mat.lat] = meshgrid(lon_vec,lat_vec);
            % Select data 
            temp = double(netcdf_getVar(ncid,4));
            out_mat.soilm1 = temp(:,:,3)';out_mat.soilm1(out_mat.soilm1>9.999e+19 | out_mat.soilm1<0) = 0;
            out_mat.soilm2 = temp(:,:,2)';out_mat.soilm2(out_mat.soilm2>9.999e+19 | out_mat.soilm2<0) = 0;
            out_mat.soilm3 = temp(:,:,1)';out_mat.soilm3(out_mat.soilm3>9.999e+19 | out_mat.soilm3<0) = 0;
            out_mat.swe = double(netcdf_getVar(ncid,5));out_mat.swe = out_mat.swe';
            out_mat.swe(out_mat.swe>9.999e+19 | out_mat.swe<0) = 0;
            out_mat.time = time(i,7);
            out_mat.source = cfile;
            out_mat.units = 'mm';
            netcdf_close(ncid);
            save(nazov,'out_mat','-mat7-binary')
        
        %% V I C
    case 5
        switch time_resol
            case 6 % monthly data
                cfile = fullfile(input_path,sprintf('%s%04d%02d*',input_file(1:15),time(i,1),time(i,2)));
                cfile = dir(cfile); % get exact file name without wildcard
                ncid = netcdf_open(fullfile(input_path,cfile.name),'NC_NOWRITE'); % use fullfile function as the dir command returns only file name, no path
                nazov = fullfile(ghc_path,sprintf('GLDAS_VIC10_M_%4d%02d.mat',time(i,1),time(i,2))); 
            otherwise % hourly data
                cfile = fullfile(input_path,sprintf('%s%04d%03d.%02d*',input_file(1:16),time(i,1),floor(time(i,7)-datenum(time(i,1),1,1,0,0,0))+1,time(i,4)));
                cfile = dir(cfile); % get exact file name without wildcard
                ncid = netcdf_open(fullfile(input_path,cfile.name),'NC_NOWRITE'); % use fullfile function as the dir command returns only file name, no path
                nazov = fullfile(ghc_path,sprintf('GLDAS_VIC10_3H_%4d%02d%02d_%02d.mat',time(i,1),time(i,2),time(i,3),time(i,4))); % Daily data
        end
            lat_vec = double(netcdf_getVar(ncid,1));
            lon_vec = double(netcdf_getVar(ncid,0));
            [out_mat.lon,out_mat.lat] = meshgrid(lon_vec,lat_vec);
            % Select data 
            temp = double(netcdf_getVar(ncid,4));
            out_mat.soilm1 = temp(:,:,3)';out_mat.soilm1(out_mat.soilm1>9.999e+19 | out_mat.soilm1<0) = 0;
            out_mat.soilm2 = temp(:,:,2)';out_mat.soilm2(out_mat.soilm2>9.999e+19 | out_mat.soilm2<0) = 0;
            out_mat.soilm3 = temp(:,:,1)';out_mat.soilm3(out_mat.soilm3>9.999e+19 | out_mat.soilm3<0) = 0;
            out_mat.swe = double(netcdf_getVar(ncid,5));out_mat.swe = out_mat.swe';
            out_mat.swe(out_mat.swe>9.999e+19 | out_mat.swe<0) = 0;
            out_mat.time = time(i,7);
            out_mat.source = cfile;
            out_mat.units = 'mm';
            netcdf_close(ncid);
            save(nazov,'out_mat','-mat7-binary')
    case 6                                                                        % MERRA model
        switch time_resol
            case 6 % monthly data
                cfile = fullfile(input_path,sprintf('%s%04d%02d*',input_file(1:36),time(i,1),time(i,2)));
                cfile = dir(cfile); % get exact file name without wildcard
                ncid = netcdf_open(fullfile(input_path,cfile.name),'NC_NOWRITE'); % use fullfile function as the dir command returns only file name, no path
                nazov = fullfile(ghc_path,sprintf('MERRA_M_%4d%02d.mat',time(i,1),time(i,2))); 
                [~,numvars] = netcdf_inq(ncid);                                   % get all variable names
                for j = 0:numvars-1                                                     % transform all layers (not only svwlX and sd)!!
                    name = netcdf_inqVar(ncid,j);                                       % get variable name
                    switch name
                        case 'XDim'
                          lon_vec = double(netcdf_getVar(ncid,j));
                        case 'YDim'
                          lat_vec = double(netcdf_getVar(ncid,j));
                        case 'TWLAND'
                          out_mat.twland = double(netcdf_getVar(ncid,j));
                          out_mat.twland = out_mat.twland';
                          out_mat.twland(out_mat.twland>9.999e+14 | out_mat.twland<0) = 0;
                        end
                end
                % Check if longitude vector exist (new Merra data format does not contain XDim variable)
                if ~exist('lon_vec','var')
                    lon_res = 360/size(out_mat.twland,2);
                    lon_vec = -180:lon_res:180-lon_res/2;
                end
                % Do the same for latitude
                if ~exist('lat_vec','var')
                    % Do not use linspace for longitude as -180 == 180 whereas -90 ~= 90 (data for pole)
                    lat_vec = linspace(-90,90,size(out_mat.twland,1));
                end
                % Create lon/lat matrix
                [out_mat.lon,out_mat.lat] = meshgrid(lon_vec,lat_vec);
                out_mat.time = time(i,7);
                out_mat.source = cfile;
                out_mat.units = 'mm';
                netcdf_close(ncid);
                save(nazov,'out_mat','-mat7-binary')
            otherwise % hourly data
                cfile = fullfile(input_path,sprintf('%s%04d%02d%02d*',input_file(1:36),time(i,1),time(i,2),time(i,3)));
                cfile = dir(cfile); % get exact file name without wildcard
                ncid = netcdf_open(fullfile(input_path,cfile.name),'NC_NOWRITE'); % use fullfile function as the dir command returns only file name, no path
                nazov = fullfile(ghc_path,sprintf('MERRA_1H_%4d%02d%02d_%02d.mat',time(i,1),time(i,2),time(i,3),time(i,4))); % 
                [numdims,numvars] = netcdf_inq(ncid);                                   % get all variable names
                for j = 0:numvars-1                                                     % transform all layers (not only svwlX and sd)!!
                    name = netcdf_inqVar(ncid,j);                                       % get variable name
                    switch name
                        case 'XDim'
                          lon_vec = double(netcdf_getVar(ncid,j));
                        case 'YDim'
                          lat_vec = double(netcdf_getVar(ncid,j));
                        case 'TWLAND'
                          temp = double(netcdf_getVar(ncid,j));
                          out_mat.twland = temp(:,:,time(i,4)+1);
                          out_mat.twland = out_mat.twland';
                          out_mat.twland(out_mat.twland>9.999e+14 | out_mat.twland<0) = 0;
                        end
                end
                % Check if longitude vector exist (new Merra data format does not contain XDim variable)
                if ~exist('lon_vec','var')
                    lon_res = 360/size(out_mat.twland,2);
                    lon_vec = -180:lon_res:180-lon_res/2;
                end
                % Do the same for latitude
                if ~exist('lat_vec','var')
                    % Do not use linspace for longitude as -180 == 180 whereas -90 ~= 90 (data for pole)
                    lat_vec = linspace(-90,90,size(out_mat.twland,1));
                end
                % Create lon/lat matrix
                [out_mat.lon,out_mat.lat] = meshgrid(lon_vec,lat_vec);
                out_mat.time = time(i,7);
                out_mat.source = cfile;
                out_mat.units = 'mm';
                netcdf_close(ncid);
                save(nazov,'out_mat','-mat7-binary')
        end
            
end
catch
    check_out = 1;
end
switch check_out
    case 0
        if size(time,1) > 2
            out_message = sprintf('Models: converting GLDAS/MERRA model ... (%3.0f%%)',progres_perc(i)); % create message
        else
            out_message = sprintf('Models: converting GLDAS/MERRA model ...'); % create message
        end
    case 1
        out_message= sprintf('Models: could not convert data for: %04d%02d%02d_%02d',time(i,1),time(i,2),time(i,3),time(i,4));
        fprintf('%s\n',out_message);
end
set(findobj('Tag','text_status'),'String',out_message); drawnow  
clear nazov
end

