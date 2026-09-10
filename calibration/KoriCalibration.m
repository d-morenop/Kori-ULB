function KoriCalibration

    
clear;
close all;


% Paths.
addpath /home/daniel/models/Kori-ULB/subroutines/;
addpath /home/daniel/models/Kori-ULB/;

global_path = '/home/daniel/models/Kori-ULB/ice_data/ismip7/ismip7-antarctic-ocean-forcing';
init_path   = '/home/daniel/models/Kori-ULB/ice_data/ismip7/initialisation';

resolution = 8;
init_name  = ['Bedmachine',int2str(resolution),'km_ISMIPgrid_v3_RACMO11km_Stal2021']; % ALREADY CROPPED!!!

file_in = [init_path, '/', init_name];

ctr.runmode     = 3;
ctr.meltfunc    = 25; % melt scheme -- 3: PICO - 23: QUAD mean Ant slope (Burgard22) - 24: QUAD local slope (Burgard22)
ctr.C           = 1e6;
ctr.meltfac     = 1; 
ctr.gammaTplume = 0; % needs to be defined if meltfunc=5

% Control.
ctr.shelf      = 1;
ctr.SSA        = 2;
ctr.calving    = 2;
ctr.dt         = 1;
ctr.nsteps     = 1;
ctr.diagnostic = 1;

%Daniel Plume range:
%gamma = linspace(6e-5, 6e-3, n_gamma)
%Eo    = linspace(, n_gamma)


if resolution==16
    ctr.imax  = 351;
    ctr.jmax  = 351;
    ctr.delta = 16.e3;
elseif resolution==8
    ctr.imax  = 761; % 701
    ctr.jmax  = 761;
    ctr.delta = 8.e3;
end



DeltaT_correction = true;
n_dT = 61; % 31, 61
%dT   = linspace(-1.5, 1.5, n_dT)
dT   = -1.5:0.05:1.5; % Consistent with Ronja.

% Define range of parameters to be calibrated.
% pico.

if ctr.meltfunc == 3
    gammaT_0 = 1e-6;
    gammaT_f = 1e-4;
    n_gammaT = 10;     % 7

    C_0 = 1e5;
    C_f = 1e7;        % 7.5e6
    n_C = 10;

    values_1 = linspace(C_0, C_f, n_C);
    values_2 = linspace(gammaT_0, gammaT_f, n_gammaT);

% quad_local_mean_slope.
elseif ctr.meltfunc == 23

    % Extended range based on ISMIP7.
    gammaT_0 = 0.25e-5;
    gammaT_f = 3.6e-4; % Change to 3.0e-4
    n_gammaT = 100;

    values_1 = linspace(gammaT_0, gammaT_f, n_gammaT);

elseif ctr.meltfunc == 24

    % Extended range based on ISMIP7.
    gammaT_0 = 0.25e-5;
    gammaT_f = 3.6e-4;
    n_gammaT = 100;

    values_1 = linspace(gammaT_0, gammaT_f, n_gammaT);

elseif ctr.meltfunc == 25

    % Extended range based on ISMIP7.
    gammaT_0 = 0.25e-5;
    gammaT_f = 3.6e-4;
    n_gammaT = 100;

    values_1 = linspace(gammaT_0, gammaT_f, n_gammaT);

elseif ctr.meltfunc == 26

    % Extended range based on ISMIP7.
    gammaT_0 = 0.25e-5;
    gammaT_f = 3.6e-4;
    n_gammaT = 100;

    values_1 = linspace(gammaT_0, gammaT_f, n_gammaT);

end



% OCEAN CLIM.
%project = 'ISMIP7';
ocean   = 'Zhou';    % Dataset.
opt     = 'warm';            % cold/warm.



if isequal(ocean,'Zhou')
    
    path_to = [global_path,'/obs/ocean/climatology/zhou_annual_06_nov/thetao/v4/'];
    path_so = [global_path,'/obs/ocean/climatology/zhou_annual_06_nov/so/v4/'];

    file_to = 'thetao_AIS_obs_ocean_climatology_zhou_annual_06_nov_v4_1972-2024.nc';
    file_so = 'so_AIS_obs_ocean_climatology_zhou_annual_06_nov_v4_1972-2024.nc';

elseif isequal(ocean,'Dutrieux2009')

    path_to = [global_path,'/parameterisations/ocean/ocean_observations_data/'];
    path_so = [global_path,'/parameterisations/ocean/ocean_observations_data/'];

    file_to = ['Dutrieux_ismip8km_60m_thetao_2009.nc'];
    file_so = ['Dutrieux_ismip8km_60m_so_2009.nc'];

elseif isequal(ocean,'Dutrieux2012')

    path_to = [global_path,'/parameterisations/ocean/ocean_observations_data/'];
    path_so = [global_path,'/parameterisations/ocean/ocean_observations_data/'];

    file_to = ['Dutrieux_ismip8km_60m_thetao_2012.nc'];
    file_so = ['Dutrieux_ismip8km_60m_so_2012.nc'];

elseif isequal(ocean,'Mathiot')

    path_to = [global_path,'/parameterisations/ocean/ocean_modelling_data/'];
    path_so = [global_path,'/parameterisations/ocean/ocean_modelling_data/'];

    file_to = ['Mathiot_NEMO_',opt,'_v2_T.nc'];
    file_so = ['Mathiot_NEMO_',opt,'_v2_S.nc'];

elseif isequal(ocean,'Naughten')

    path_to = [global_path,'/parameterisations/ocean/ocean_modelling_data/'];
    path_so = [global_path,'/parameterisations/ocean/ocean_modelling_data/'];

    file_to = ['Naughten_FESOM_ACCESS_',opt,'_T.nc'];
    file_so = ['Naughten_FESOM_ACCESS_',opt,'_S.nc'];

elseif isequal(ocean,'Timmermann')

    path_to = [global_path,'/parameterisations/ocean/ocean_modelling_data/'];
    path_so = [global_path,'/parameterisations/ocean/ocean_modelling_data/'];

    file_to = ['Timmermann_FESOM_',opt,'_v2_T.nc'];
    file_so = ['Timmermann_FESOM_',opt,'_v2_S.nc'];

end


full_to = [path_to, file_to];
full_so = [path_so, file_so];


to = ncread(full_to, 'thetao');
so = ncread(full_so, 'so');
z  = ncread(full_so, 'z');

to0  = permute(ncread(full_to,'thetao'),[2 1 3]);  % base (uncorrected) temperature

size(to)

To = permute(to,[2 1 3]);
So = permute(so,[2 1 3]);

% Dimensions definition.
info = ncinfo(full_so,'so');
{info.Dimensions.Name}

%Melt = zeros(ctr.imax, ctr.jmax);

save(file_in,'To','So','-append')

% Depths of the 30 layers, it should be provided with the climatology.
% This is what tells Kori what depth is every layer for the 
% interpolation at the ice shelf draft.
fc.z = z;



% Options: pico, quad_local_mean_slope
if ctr.meltfunc == 3

    melt_param = 'pico';

elseif ctr.meltfunc == 23
    
    melt_param = 'quad_local_mean_slope';

elseif ctr.meltfunc == 24
    
    melt_param = 'quad_local_local_slope';

elseif ctr.meltfunc == 25
    
    melt_param = 'quad_semi_local_mean_slope';

elseif ctr.meltfunc == 26
    
    melt_param = 'quad_semi_local_local_slope';

end


% Define paths and names.
path     = '/home/daniel/models/Kori-ULB/output/calibration/dT/large_ensembles/';
path_out = [path, melt_param, '/']; 
file     = [path_out, 'MELT_', int2str(ctr.meltfunc), '_', int2str(resolution), 'km', '_', ocean, '_', opt, '_'];

mkdir(path_out)


% Loop over range of parameters for a given parametrization choice.
if DeltaT_correction == true 

    for i = 1:length(dT)

        % Optimal values for each param choice. 23: 1e-4, 24: 3.5e-5, 25: 1.325e-4, 26: 5.305e-5.
        ctr.gammaT = 1.325e-4;

        To = to0 + dT(i);
        save(file_in,'To','So','-append');   % perturbed ocean state read by KoriModel

        val_1 = 100*dT(i);

        if val_1 < 0
            num_1 = sprintf('m00%.0f', abs(val_1));

            if val_1 < -9
                num_1 = sprintf('m0%.0f', abs(val_1));

                if val_1 < -99
                num_1 = sprintf('m%.0f', abs(val_1));
                end

            end

        elseif val_1 >= 0
            num_1 = sprintf('p00%.0f', val_1);

            if val_1 > 9
                num_1 = sprintf('p0%.0f', abs(val_1));

                if val_1 > 99
                num_1 = sprintf('p%.0f', abs(val_1));
                end

            end
        end

        % Name of each permutation.
        name = ['gamma', num_1]

        % Run Kori diagnostic exp.
        KoriModel(file_in, [file,name], ctr, fc);
        
        % Load Melt from source file
        S = load([file,name,'_toto'], 'Melt');

        % Store under dynamic field name
        melt_all.(name) = S.Melt;

    end


else

    if ctr.meltfunc == 3

        for i = 1:length(values_1)
            for j = 1:length(values_2)

                ctr.C      = values_1(i);
                ctr.gammaT = values_2(j);

                val_1 = 1e-6*values_1(i);
                val_2 = 1e5*values_2(j);

                if val_1 < 10
                    num_1 = sprintf('0%.0f', val_1);
                else
                    num_1 = sprintf('%.0f', val_1);
                end

                if val_2 < 10
                    num_2 = sprintf('0%.0f', val_2);
                else
                    num_2 = sprintf('%.0f', val_2);
                end

                % Name of each permutation.
                name = ['C', num_1, '_', 'gamma', num_2]

                % Run Kori diagnostic exp.
                KoriModel(init_name, [file,name], ctr, fc);
                
                % Load Melt from source file
                S = load([file,name,'_toto'], 'Melt');

                % Extend grid to match ISMIP's.
                Melt(dn+1:end-dn,dn+1:end-dn,:) = S.Melt;

                % Store under dynamic field name
                melt_all.(name) = Melt;

            end
        end

    % quad_local_mean_slope.
    elseif ctr.meltfunc == 23 | ctr.meltfunc == 24 | ctr.meltfunc == 25 | ctr.meltfunc == 26

        for i = 1:length(values_1)
            
            ctr.gammaT = values_1(i);

            val_1 = 1e7*values_1(i);


            if val_1 < 10
                num_1 = sprintf('000%.0f', val_1);
            elseif val_1 < 100
                num_1 = sprintf('00%.0f', val_1);
            elseif val_1 < 1000
                num_1 = sprintf('0%.0f', val_1);
            else
                num_1 = sprintf('%.0f', val_1);
            end

            % Name of each permutation.
            name = ['gamma', num_1]

            % Run Kori diagnostic exp. file_in
            %KoriModel(init_name, [file,name], ctr, fc);
            KoriModel(file_in, [file,name], ctr, fc);
            
            % Load Melt from source file
            S = load([file,name,'_toto'], 'Melt');

            melt_all.(name) = S.Melt;

        
        end

    end

end


% Save all melt rates together.
save([file,'melt_all.mat'], 'melt_all');


end