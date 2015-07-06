%%%%%%%%%%%%%%%%%%%%%%%%% ATMO CORRECTION FACTOR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear 														 % remove variable
close all													 % close all figures
clc 														 % clear command line
Input = [47.9283 15.8598 1044];								 % set computation point [latitude(deg),longitude(deg),height(m)]
dem_file = 'F:\mikolaj\Documents\DEM\Conrad\CO_lon14p8_16.8__lat47p4_48p4__res0p001.mat'; % digital elevation model (layers: *.lon, *.lat, *.height)
orography_file = 'F:\mikolaj\Downloads\netcdf-atls17-a562cefde8a29a7288fa0b8b7f9413f7-TfHNWT.nc'; % orography files (layers: see user's guide)
mGlobe_output = 'F:\mikolaj\Documents\MYpapers\mGlobe\Results\ATMO\mGlobE\CO\CO_MGLOBE_ATMO_ERA_012010_122013_6h_dem0.txt'; % mGlobe atmospheric effect txt output
local_pressure_tsf = 'F:\mikolaj\Documents\MYpapers\mGlobe\AuxData\CO\CO_resPress_mGlobe.tsf';  % tsf file containing pressure variation in hPa
local_pressure_channel = 2;																		% tsf channel with pressure
mGlobe_correctionFactor(Input,dem_file,orography_file,mGlobe_output,local_pressure_tsf,local_pressure_channel); % start the computation that will take some time...

