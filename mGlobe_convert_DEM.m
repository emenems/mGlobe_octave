function mGlobe_convert_DEM(DEM_input,DEM_output,DEM_type)
%MGLOBE_CONVERT_DEM Function serves for the conversion of DEMs
%   Function is used for the conversion of DEM. Input DEM can by transformed to 
%   matlab *.mat format used by the mGlobe. 
%   The mGlobe tool requires fix format:
%   dem.lon,dem.lat,dem.height.
% 
% Input:
%   DEM_input       ...     string with full path/name of the input DEM
%                           Example: 'VI_DEM_arc.ascii';
%   DEM_output      ...     string with full path/name of the output DEM
%                           Example: 'VI_DEM_arc.mat';
%   DEM_type        ...     number (1,3) for the identification of the
%                           input file format:  1 ... free (lon,lat,H)
%                                               2 ... free (lat,lon,H)
%                                               3 ... arc ASCII
%                                               4 ... grd 6 text
%                                               5 ... netCDF
%                           Example: 3
% Output:
%	dem.lon 	      ...		longitude (in input units)
%	dem.lat 	      ...		latitude (in input units)
%	dem.height 	    ...		longitude (in input units)
%	dem.input_file 	...		input file name
%	dem.units 	    ...		dem.height units
% 
%                                         M.Mikolaj, mikolaj@gfz-potsdam.de
%                                                                18.06.2014
%                                                                      v1.0

%% DEM conversion
set(findobj('Tag','text_status'),'String','Models: loading DEM ...');drawnow % status message
check_out = 0;                                                              % control value
try
    switch DEM_type
        case 1                                                              % Lon,Lat,Height txt format
            d = load(DEM_input);                                            % open/read file
            x = unique(d(:,1));                                             % get unique x data
            y = unique(d(:,2));                                             % get unique y data
            z = d(:,3);                                                     % get all z data                                             

            [dem.lon,dem.lat] = meshgrid(x,y);                              % create meshgrid
            dem.height = dem.lon.*0;                                        % create height matrix
            for i = 1:length(y)                                             % find data for each unique y
                r = find(d(:,2) == y(i));
                dem.height(i,:) = z(r);
            end
			      dem.units = 'm/see input model';
			      dem.input_file = DEM_input;
        case 2                                                              % Lon,Lat,Height txt format
            d = load(DEM_input);                                            % open/read file
            x = unique(d(:,1));                                             % get unique x data
            y = unique(d(:,2));                                             % get unique y data
            z = d(:,3);                                                     % get all z data                                             

            [dem.lat,dem.lon] = meshgrid(x,y);                              % create meshgrid
            dem.height = dem.lon.*0;                                        % create height matrix
            for i = 1:length(y)                                             % find data for each unique y
                r = find(d(:,2) == y(i));
                dem.height(i,:) = z(r);
            end
			      dem.units = 'm/see input model';
			      dem.input_file = DEM_input;
        case 3                                                              % arc ascii file format
            dem_o = o_ascii_xy2mat(DEM_input);
            dem.lon = dem_o.x;dem_o.x = [];
            dem.lat = dem_o.y;dem_o.y = [];
            dem.height = dem_o.height;clear dem_o;
			      dem.input_file = DEM_input;                                     % store input file name
			      dem.units = 'm/see input model';                                % store units
        case 5                                                              % NetCDF format
            ncid = netcdf_open(DEM_input,'NC_NOWRITE');
            [ndims,nvars] = netcdf_inq(ncid);
            for i = 1:nvars
                varname(i) = {netcdf_inqVar(ncid,i-1)};
            end
            % Longitude
            [selection,confirm] = listdlg('ListString',varname,'Name','Longitude (deg)',"SelectionMode","Multiple");
            if confirm == 1 && length(selection) == 1
                dem.lon = double(netcdf_getVar(ncid,selection-1));
                try
                    scale_factor = netcdf_getAtt(ncid,selection-1,'scale_factor');
                catch
                    scale_factor = 1;
                end
                try
                    add_offset = netcdf_getAtt(ncid,selection-1,'add_offset');
                catch
                    add_offset = 0;
                end
                dem.lon = dem.lon'*scale_factor + add_offset;
            end
            % Latitude
            [selection,confirm] = listdlg('ListString',varname,'Name','Latitude (deg)',"SelectionMode","Multiple");
            if confirm == 1 && length(selection) == 1
                dem.lat = double(netcdf_getVar(ncid,selection-1));
                try
                    scale_factor = netcdf_getAtt(ncid,selection-1,'scale_factor');
                catch
                    scale_factor = 1;
                end
                try
                    add_offset = netcdf_getAtt(ncid,selection-1,'add_offset');
                catch
                    add_offset = 0;
                end
                dem.lat = dem.lat'*scale_factor + add_offset;
                if size(dem.lon,1) == 1 || size(dem.lon,2) == 1
                    [dem.lon,dem.lat] = meshgrid(dem.lon,dem.lat);
                end
            end
            % Height
            [selection,confirm] = listdlg('ListString',varname,'Name','Data',"SelectionMode","Multiple");
            if confirm == 1 && length(selection) == 1
                dem.height = double(netcdf_getVar(ncid,selection-1));
                try
                    scale_factor = netcdf_getAtt(ncid,selection-1,'scale_factor');
                catch
                    scale_factor = 1;
                end
                try
                    add_offset = netcdf_getAtt(ncid,selection-1,'add_offset');
                catch
                    add_offset = 0;
                end
                dem.height = dem.height'*scale_factor + add_offset;
            else
                dem.height(size(dem.lon)) = NaN;
            end
            dem.input_file = DEM_input;
			      dem.units = 'm/see input model';
            netcdf_close(ncid);
            
        case 4                                                              % grd 6 txt (grapher) file format
            fid = fopen(DEM_input);                                         % open file
            dsaa = fscanf(fid,'%s', 1);                                     % read header id (not used)
            dimen = fscanf(fid,'%d %d',2);                                  % get dimensions
            xlim = fscanf(fid,'%f %f',2);                                   % get x limit
            step = abs(diff(xlim)/(dimen(1)-1));                            % set resolution
            ylim = fscanf(fid,'%f %f',2);                                   % get x limit
            zlim = fscanf(fid,'%f %f',2);                                   % get z limit (not used)
            dem.height = fscanf(fid,'%f',dimen');
            x = xlim(1):step(1):xlim(2);                                    % create longitude vector
            if step ~= abs(diff(ylim)/(dimen(2)-1))
                   step(2) = abs(diff(ylim)/(dimen(2)-1));
                   y = ylim(1):step(2):ylim(2);                             % create latitude vector
            else
                y = ylim(1):step:ylim(2);
            end
            dem.height = dem.height';                                       % transpose height matrix
            if x(end) ~=xlim(2)
                x(end+1) = xlim(2);
            end
            if y(end) ~= ylim(2)
                y(end+1) = ylim(2);
            end
            dem.input_file = DEM_input;                                     % store input file name
			      dem.units = 'm/see input model';                                % store units
            [dem.lon,dem.lat] = meshgrid(x,y);                              % create lon/lat matrices
    end
        set(findobj('Tag','text_status'),'String','Models: DEM converted...');drawnow % write status message
catch exception
    set(findobj('Tag','text_status'),'String','Models: Could not load the input DEM file (check format)'); drawnow
    check_out = 1;
    return
end

if check_out == 0;
    save(DEM_output,'dem','-mat7-binary');                                                 % save the transformed file
end 

end

function dem = o_ascii_xy2mat(fileID)
%O_ASCII_XY2MAT load arc ascii grid
% Examplte: dem = o_ascii_xy2mat('my_ascii_grid.asc');
% Input:
%   fileID        ... full file path
% 
% Output:
%   dem           ... matlab/octave structure file: dem.x,dem.y,dem.height
% 
%                                                   M.Mikolaj 01.07.2015


% open file
fid = fopen(fileID,'r');
% Get number of columns
temp = fgetl(fid);
if ischar(temp)
    if strcmp(temp(1:5),'ncols') | strcmp(temp(1:5),'NCOLS')
        col = str2double(temp(6:end));
    end
end
% Get number of rows
temp = fgetl(fid);
if ischar(temp)
    if strcmp(temp(1:5),'nrows') | strcmp(temp(1:5),'NROWS')
        row = str2double(temp(6:end));
    end
end
% Get x lower left corner
temp = fgetl(fid);
if ischar(temp)
    if strcmp(temp(1:5),'xllco') | strcmp(temp(1:5),'XLLCO')
        xll = str2double(temp(11:end));
    end
end
% Get y lower left corner
temp = fgetl(fid);
if ischar(temp)
    if strcmp(temp(1:5),'yllco') | strcmp(temp(1:5),'YLLCO')
        yll = str2double(temp(11:end));
    end
end
% Get cellsize
temp = fgetl(fid);
if ischar(temp)
    if strcmp(temp(1:5),'cells') | strcmp(temp(1:5),'CELLS')
        resol = str2double(temp(9:end));
    end
end
% Get nodata value
temp = fgetl(fid);
if ischar(temp)
    if strcmp(temp(1:5),'nodat') | strcmp(temp(1:5),'NODAT')
        ndata = str2double(temp(14:end));
    end
end
% close file after header reading
fclose(fid);

dem.height = dlmread(fileID,'',6,0);
dem.height = flipud(dem.height);
dem.x = xll:resol:xll+resol*(col-1);
dem.y = yll:resol:yll+resol*(row-1);
[dem.x,dem.y] = meshgrid(dem.x,dem.y);
dem.height(dem.height==ndata) = NaN;

end

