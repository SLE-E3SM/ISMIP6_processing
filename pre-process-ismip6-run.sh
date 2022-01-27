# ---- STUFF TO CHANGE EACH RUN ----
IS=AIS
INST=DOE
ISM=MALI
EXP=exp13
# ----------------------------------

# ---- STUFF TO SET ONCE -----------
BASE_DIR=/lustre/scratch4/turquoise/mhoffman/SLM_Processing_MJH
ISMIP6_ARCHIVE=/lustre/scratch4/turquoise/hollyhan/ISMIP6-Projections_GCSv4/Full_Cleaned_Projection_Data
# ----------------------------------


# CHANGE NOTHING BELOW HERE
source /usr/projects/climate/SHARED_CLIMATE/anaconda_envs/load_latest_e3sm_unified_badger.sh

# Regrid data
exp_path=$BASE_DIR/$IS/${INST}_$ISM/$EXP
name_base_string=${IS}_${INST}_${ISM}_${EXP}
echo -e "Starting Regrid using exp_path=$exp_path and name_base_string=$name_base_string\n"
mkdir -p $exp_path/regridded
ncremap -m mapfile_polarRank2_to_gaussRank2.nc -i $ISMIP6_ARCHIVE/$IS/$INST/$ISM/$EXP/lithk_${name_base_string}.nc -o $exp_path/regridded/lithk_${name_base_string}_GaussianGrid.nc
ncremap -m mapfile_polarRank2_to_gaussRank2.nc -i $ISMIP6_ARCHIVE/$IS/$INST/$ISM/$EXP/topg_${name_base_string}.nc -o $exp_path/regridded/topg_${name_base_string}_GaussianGrid.nc

# reformat data
echo -e "\n\nStarting Reformat\n"
mkdir -p $exp_path/reformatted
python reformat_SL_inputdata.py $exp_path/regridded/ lithk_${name_base_string}_GaussianGrid.nc topg_${name_base_string}_GaussianGrid.nc

mkdir -p $exp_path/SLM_output
echo -e "\nComplete.\n"
