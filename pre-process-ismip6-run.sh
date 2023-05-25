# ---- STUFF TO CHANGE EACH RUN ----
IS=AIS
INST=DOE
ISM=MALI
EXP=exp13
# ----------------------------------

# ---- STUFF TO SET ONCE -----------
OUTPUT_DIR=/lustre/scratch5/mhoffman/SLM_Processing_MJH
ISMIP6_ARCHIVE=/lustre/scratch5/mhoffman/ISMIP6_2100_archive
AISMAPFILE=/usr/projects/climate/mhoffman/SLE-E3SM/ISMIP6_processing/mapfile_polarRank2_to_gaussRank2.nc
GISMAPFILE=/usr/projects/climate/mhoffman/SLE-E3SM/ISMIP6_processing/mapfile_ismip6_GrIS_Gauss.nc
STRIDE=5 # stride in years to subsample
# ----------------------------------


# CHANGE NOTHING BELOW HERE

set -e # exit on error

# Select mapping file
if [[ "$IS" == "AIS" ]]; then
   MAPFILE=$AISMAPFILE
elif [[ "$IS" == "GIS" ]]; then
   MAPFILE=$GISMAPFILE
else
   echo "Invalid ice sheet specified."
   exit
fi
echo Using mapfile: $MAPFILE

# set up some paths/variables
exp_in_path=$ISMIP6_ARCHIVE/$IS/$INST/$ISM/$EXP
exp_out_path=$OUTPUT_DIR/$IS/${INST}_$ISM/$EXP
name_base_string=${IS}_${INST}_${ISM}_${EXP}
mkdir -p $exp_out_path/subsampled
mkdir -p $exp_out_path/regridded
echo "$BASH_SOURCE"
echo exp_in_path=$exp_in_path
echo exp_out_path=$exp_out_path
echo name_base_string=$name_base_string

# ---------
echo -e "\n\n----- Subsampling data and subtracting control run -----\n"
# ---------
# find control run path - assumes only one file will be found
ctrl_lithk=`ls -1 $ISMIP6_ARCHIVE/$IS/$INST/$ISM/ctrl*/lithk*nc`

# get section of ctrl that matches time levels of projection.  assume it is the last 86 time levels
ctrl_20152100=$exp_out_path/subsampled/lithk_${IS}_${INST}_${ISM}_ctrl_2015-2100.nc
ncks -O -d time,-86, $ctrl_lithk $ctrl_20152100

# calculate anomaly from ctrl
lithk_anom=$exp_out_path/subsampled/lithk_${name_base_string}_subsampled_anomaly.nc
ncdiff -O -d time,0,,$STRIDE $exp_in_path/lithk_${name_base_string}.nc $ctrl_20152100 $lithk_anom

# get initial thickness
lithk_init=$exp_out_path/subsampled/lithk_${name_base_string}_init.nc
ncks -O -d time,0 $exp_in_path/lithk_${name_base_string}.nc $lithk_init
ncwa -O -a time $lithk_init ${lithk_init}_notime

# add anomaly to i.c.
lithk_anom_adj=$exp_out_path/subsampled/lithk_${name_base_string}_subsampled_anomaly_adjusted.nc
ncbo -O --op_typ=add $lithk_anom ${lithk_init}_notime $lithk_anom_adj

# subsample topg
topg_subsamp=$exp_out_path/subsampled/topg_${name_base_string}_subsampled.nc
ncks -O -d time,0,,$STRIDE $exp_in_path/topg_${name_base_string}.nc $topg_subsamp

# --------
echo -e "\n\n----- Performing remapping of lithk and topg -----\n"
# --------
lithk_gauss=$exp_out_path/regridded/lithk_${name_base_string}_GaussianGrid.nc
ncremap -m $MAPFILE -i $lithk_anom_adj -o $lithk_gauss

topg_gauss=$exp_out_path/regridded/topg_${name_base_string}_GaussianGrid.nc
ncremap -m $MAPFILE -i $topg_subsamp -o $topg_gauss

# --------
echo -e "\n\n----- Starting Reformat ------\n"
# --------
mkdir -p $exp_out_path/reformatted
python reformat_SL_inputdata.py $exp_out_path/regridded/ lithk_${name_base_string}_GaussianGrid.nc topg_${name_base_string}_GaussianGrid.nc

mkdir -p $exp_out_path/SLM_output
echo -e "\nComplete.\n"
