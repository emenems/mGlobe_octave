function check_out = mGlobe_view2D(plot_file,file_type,max_value,map_extend,save_option,print_file,plot_exclude)
%MGLOBE_VIEW2D Function for the 2D visualization
%   Function is used for the results visualization of 2D data, i.e. 
%   longitude, latitude + e.g. height
% 
% Input:
%   plot_file      ...  Full file names
%   file_type      ...  switch (1-6) for txt/txt/mat/ascii/grd6/netcdf
%                       input file
%   max_value      ...  maximal plotted value
%   map_extend     ...  map extend
%   save_option    ...  switch (1 to 3) for no/eps/tiff output file
%   print_file     ...  Full output file name
%   plot_exclude   ...  Exclusion/inclusion options (1 - nothing excluded,
%                       2 - Greenland excluded, 3 - Antarctica excluded, 
%                       4 -Greenland+Antarctica excluded, 5 - load 
%                       inclusion polygon)
% 
% Output:
%   check_out      ...  check number (1 - OK, 0 - not loaded)
% 
%                                         M.Mikolaj, mikolaj@gfz-potsdam.de
%                                                                18.06.2014
%                                                                      v1.0


set(findobj('Tag','text_status'),'String','Plot: loading data...'); drawnow % write status message
try
    switch file_type                                                        % switch between supported file types
        case 1                                                              % txt (Lon, Lat, data) file
            d = load(plot_file);                                            % open/read file
            x = unique(d(:,1));                                             % get unique x data
            y = unique(d(:,2));                                             % get unique y data
            z = d(:,3);                                                     % get all z data                                             

            [dem.lon,dem.lat] = meshgrid(x,y);                              % create meshgrid
            dem.height = dem.lon.*0;                                        % create height matrix
            for i = 1:length(y)                                             % find data for each unique y
                r = find(d(:,2) == y(i));
                dem.height(i,:) = z(r);
            end
        case 2                                                              % txt (Lat, Lon, data) file
            d = load(plot_file);                                               % open/read file
            x = unique(d(:,1));                                             % get unique x data
            y = unique(d(:,2));                                             % get unique y data
            z = d(:,3);                                                     % get all z data                                             

            [dem.lat,dem.lon] = meshgrid(x,y);                              % create meshgrid
            dem.height = dem.lon.*0;                                        % create height matrix
            for i = 1:length(y)                                             % find data for each unique y
                r = find(d(:,2) == y(i));
                dem.height(i,:) = z(r);
            end
        case 4                                                              % arc ascii file
            dem = o_ascii_xy2mat(plot_file);
            dem.lon = dem.x;dem.x = [];
            dem.lat = dem.y;dem.y = [];
        case 3                                                              % mat structure area file
            dem = importdata(plot_file);
            names = fieldnames(dem);
            for sel = 1:length(names);
                id_lon(sel) = strcmp(char(names(sel)),'lon');
                id_lat(sel) = strcmp(char(names(sel)),'lat');
                id_time(sel) = strcmp(char(names(sel)),'time');
            end;clear sel
            id_coor = id_lon+id_lat+id_time;
            out_names = names(id_coor ==0);
            [selection,confirm] = listdlg('ListString',out_names,'Name','Found layers','ListSize',[round(160*2),round(300*1.1)],"SelectionMode","Multiple");
            plot_out = 0;
            if confirm == 1
                for sel = selection
                    plot_out = plot_out + dem.(char(out_names(sel)));
                end
            else
                plot_out(size(dem.lon)) = NaN;
            end
            dem.height = plot_out;
        case 5                                                              % grd (Grapher 6) txt file
            fid = fopen(plot_file);
            dsaa = fscanf(fid,'%s', 1);
            dimen = fscanf(fid,'%d %d',2);
            xlim = fscanf(fid,'%f %f',2);
            step = abs(diff(xlim)/(dimen(1)-1));
            ylim = fscanf(fid,'%f %f',2);
            zlim = fscanf(fid,'%f %f',2);
            dem.height = fscanf(fid,'%f',dimen');
            x = xlim(1):step(1):xlim(2);
            if step ~= abs(diff(ylim)/(dimen(2)-1))
                   step(2) = abs(diff(ylim)/(dimen(2)-1));
                   y = ylim(1):step(2):ylim(2);
            else
                y = ylim(1):step:ylim(2);
            end
            dem.height = dem.height';
            if x(end) ~=xlim(2)
                x(end+1) = xlim(2);
            end
            if y(end) ~= ylim(2)
                y(end+1) = ylim(2);
            end
            [dem.lon,dem.lat] = meshgrid(x,y);
        case 6                                                              % NetCDF file
            ncid = netcdf_open(plot_file,'NC_NOWRITE');
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
            netcdf_close(ncid);
            
    end
    plot_out = dem.height;                                                  % prepare variable
    switch plot_exclude                                                     % switch between exclusion/inclusion areas
        case 2
            plot_out((dem.lon >-60 & dem.lon < -30) & (dem.lat >60 & dem.lat <85)) = NaN;
            plot_out((dem.lon >=-30 & dem.lon < -10) & (dem.lat >68 & dem.lat <85)) = NaN;
            plot_out((dem.lon >-73 & dem.lon < -60) & (dem.lat >75 & dem.lat <79.5)) = NaN;
            plot_out((dem.lon >-67 & dem.lon < -63.2) & (dem.lat >79.5 & dem.lat <81)) = NaN;
            plot_out((dem.lon >-63.5 & dem.lon < -60) & (dem.lat >79.5 & dem.lat <82)) = NaN;
        case 3 
            plot_out(dem.lat <-60) = NaN;
        case 4
            plot_out((dem.lon >-60 & dem.lon < -30) & (dem.lat >60 & dem.lat <85)) = NaN;
            plot_out((dem.lon >=-30 & dem.lon < -10) & (dem.lat >68 & dem.lat <85)) = NaN;
            plot_out((dem.lon >-73 & dem.lon < -60) & (dem.lat >75 & dem.lat <79.5)) = NaN;
            plot_out((dem.lon >-67 & dem.lon < -63.2) & (dem.lat >79.5 & dem.lat <81)) = NaN;
            plot_out((dem.lon >-63.5 & dem.lon < -60) & (dem.lat >79.5 & dem.lat <82)) = NaN;
            plot_out(dem.lat <-60) = NaN;
        case 5                                                              % load inclusion polygon
            [name,path] = uigetfile('*.txt','Select your inclusion polygon *.txt [Lon (deg) Lat (deg)]');
            if name ~=0
                try
                    inclusion = load([path,name]);
                    id_in = inpolygon(dem.lon,dem.lat,inclusion(:,1),inclusion(:,2));
                    plot_out(~id_in) = NaN;
                catch
                    fprintf('Plot: could not load inclusion polygon file\n');
                end
            end
    end   
    figid = figure;                                                         % new figure window
    %switch map_extend                                                       % set map projection
    %    case 1
    %        worldmap 'World'
    %    case 2
    %        worldmap 'Europe'
    %    case 3
    %        worldmap 'North America'
    %    case 4
    %        worldmap 'South America'
    %    case 5
    %        worldmap 'Africa'
    %    case 6
    %        worldmap 'Asia'
    %    case 7
    %        worldmap([min(min(dem.lat)),max(max(dem.lat))],...
    %                 [min(min(dem.lon)),max(max(dem.lon))]);
    %    otherwise
    %        worldmap
    %end  
    plot_out(plot_out>max_value) = max_value;                               % set max value
    if numel(dem.lon) > 1000*1000 && numel(dem.lon) <= 2000*2000                    % reduce the size of plotted matrix
      dem.lon = dem.lon(1:2:end,1:2:end);
      dem.lat = dem.lat(1:2:end,1:2:end);
      plot_out = plot_out(1:2:end,1:2:end);
    elseif numel(dem.lon) > 2000*2000
      dem.lon = dem.lon(1:4:end,1:4:end);
      dem.lat = dem.lat(1:4:end,1:4:end);
      plot_out = plot_out(1:4:end,1:4:end);
    end
    surf(dem.lon,dem.lat,plot_out,'EdgeColor','none'); 
    caxis([min(min(plot_out)),max(max(plot_out))]);
    % land = shaperead('landareas', 'UseGeoCoords', true);
    % plot3([land.Lat],[land.Lon],2,'Color','black');
    xlim([min(min(dem.lon)),max(max(dem.lon))]);ylim([min(min(dem.lat)),max(max(dem.lat))]);
    colorbar('location','southoutside');
    view(0,90);
catch exception
    set(findobj('Tag','text_status'),'String','Plot: Could not load input DEM file (check format)'); drawnow % warn user
    check_out = 1;
    return
end
%% Printing
set(gcf, 'PaperPositionMode', 'auto');        
switch save_option
    case 2
        print(figid,'-depsc','-r300',[print_file(1:end-3) 'eps']);
    case 3
        print(figid,'-dpng','-r300',[print_file(1:end-3) 'png']);
end
check_out = 1;
                        
