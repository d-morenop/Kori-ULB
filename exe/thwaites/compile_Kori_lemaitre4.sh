#!/bin/bash
# Bash file to compile Kori-ULB and copy it to CECI cluster.
# Execute it with: bash compile_Kori.sh
path_kori=/home/daniel/models/Kori-ULB
path_kori_subroutines=$path_kori/subroutines


# Define the remote server.
REMOTE_HOST=lemaitre4

# Experiment name (only for ensembles).
#exp=revert_t_m20_gammas
#exp=DIVA
#exp=sigma_oce400  
#exp=sigma_oce075
# dutrieux2009, dutrieux2012, mathiot_cold, naughten_cold, zhou.
exp=zhou


# LOCAL PATHS.
path_scr=$path_kori/calibration
#path_exe=$path_kori/exe/thwaites         # Thwaites.
#path_exe=$path_kori/exe/CalvingMIP       # CalvingMIP.
path_exe=$path_kori/exe/calibration       # Calibration.

# Deterministic.
#path_param=$path_exe/$REMOTE_HOST/deter/$exp     

# Stochastic.
#path_param=$path_exe/$REMOTE_HOST/stoch/tau_To_001/$exp     

# Initialization.
#path_param=$path_exe/$REMOTE_HOST/init/$exp  

# Calibration.
path_param=$path_exe/$REMOTE_HOST/$exp
init_file=/home/daniel/models/Kori-ULB/ice_data/ismip7/initialisation/Bedmachine8km_ISMIPgrid_v3_RACMO11km_Stal2021.mat


# CLUSTER PATHS.
path_parent=/globalscratch/ulb/glaciol/dmoreno/Kori-ULB/exe/ensembles

# Deterministic.
#path_cluster=$path_parent/thwaites/deter

# Stochastic.
#path_cluster=$path_parent/thwaites/stoch/tau_To_001

# Initialization.
#path_cluster=$path_parent/thwaites/init

# CalvingMIP. /home/daniel/models/Kori-ULB/exe/CalvingMIP
#path_cluster=$path_parent/calvingMIP/Exp3-4/dx_2km/OceanVisc_1e10/

# Calibration.
meltfunc=26
p="95"

case "$meltfunc" in
    23)
        meltname=quad_local_mean_slope
        ;;
    24)
        meltname=quad_local_local_slope
        ;;
    25)
        meltname=quad_semi_local_mean_slope
        ;;
    26)
        meltname=quad_semi_local_local_slope
        ;;
    *)
        echo "Usage: $0 23|24|25|26"
        exit 1
        ;;
esac


#path_cluster=$path_parent/calibration/quad_semi_local_local_slope/$exp
#path_cluster=$path_parent/calibration/dT/quad_semi_local_local_slope/$exp
path_cluster=$path_parent/calibration/dT/$meltname/percentile_$p/$exp

# Path to precompile executable.    
path_exe_cluster=$path_parent/thwaites/precompiled



# Enter path with matlab scripts to be compiled.
#cd $path_exe
cd $path_scr

# Compiling options: individual_file, ensemble.
option="individual_file"  

matlab_version="R2018b"


##################################################################################
# OPTION 1.
if [ "$option" = "individual_file" ]; then

echo "Compiling individual file..."

# Compilation for single files.
file_name=KoriCalibration_CECI.m            # CaMIP_Exp3_CECI.m
exe_name=KoriCalibration_CECI

echo "Compiling       : $file_name"
echo "Exe_name        : $exe_name"
echo "Matlab version  : $matlab_version"
echo "path_scr        : $path_scr"
echo "path_exe        : $path_exe"
echo "path_cluster    : $path_cluster"



case "$matlab_version" in
    R2018b)
        MATLAB_ROOT=/usr/local/MATLAB/R2018b
        ;;
    R2024b)
        MATLAB_ROOT=/usr/local/MATLAB/R2024b
        ;;
    R2025b)
        MATLAB_ROOT=/usr/local/MATLAB/R2025b
        ;;
    *)
        echo "Usage: $0 R2018b|R2024b|R2025b"
        exit 1
        ;;
esac

#mcc -m $file_name -a $path_kori/KoriModel.m -a $path_kori_subroutines -o $exe_name
#mcc -m $file_name -a $path_kori/KoriModel.m -a $path_kori_subroutines -o $exe_name

# ISMIP7 option: copy initialization in each folder as it is modified there.
#rsync -avz --progress "$init_file" "$REMOTE_HOST:$path_cluster/"

# Compile matlab file.
"$MATLAB_ROOT/bin/mcc" -m $file_name -a $path_kori/KoriModel.m -a $path_kori_subroutines -o $exe_name

mv $exe_name $path_exe
ssh $REMOTE_HOST "mkdir -p $path_cluster"
#rsync -avz --progress "$exe_name" "$REMOTE_HOST:$path_cluster"
rsync -avz --progress "$path_exe/$exe_name" "$REMOTE_HOST:$path_cluster"

##################################################################################




##################################################################################
# OPTION 2.
# Loop over each file in the directory.
elif [ "$option" = "ensemble" ]; then

echo "Compiling ensemble..."

file=RunASE_ceci.m
exe_name=RunASE_ceci

# Compile Kori only once.
echo "Path_par     : $path_param"
echo "Path_exe     : $path_exe"
echo "Path_cluster : $path_cluster"
echo "Compiling    : $file"

# RECOMPILE IN CASE OF CHANGES IN THE CODE!
mcc -m "$file" -a "$path_kori/KoriModel.m" -a "$path_kori_subroutines" -o "$exe_name"
rsync -avz --progress "$exe_name" "$REMOTE_HOST:$path_exe_cluster/"


# Copy folder with param files.
ssh $REMOTE_HOST "mkdir -p $path_cluster"
rsync -avz --progress "$path_param" "$REMOTE_HOST:$path_cluster/"


echo "Copying executable to all directories in a single SSH connection"
#ssh $REMOTE_HOST "mkdir -p $path_cluster"

# Copy via ssh only once and then copy within the cluster.
# File(s) to copy (you can use wildcards like *.sh)
# SSH command to copy files to all subdirectories
ssh $REMOTE_HOST << EOF
for dir in "$path_cluster/$exp"/*/; do
    if [ -d "\$dir" ]; then
        echo "Exp  : \$dir"
        cp "$path_exe_cluster/$exe_name" "\$dir"
    fi
done
EOF

echo "All files copied!"

##################################################################################

fi