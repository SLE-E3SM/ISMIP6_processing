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

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo $SCRIPT_DIR


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
mkdir -p $exp_out_path/preprocessed
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
ctrl_lithk_20152100=$exp_out_path/preprocessed/lithk_${IS}_${INST}_${ISM}_ctrl_2015-2100.nc
ncks -O -d time,-86, $ctrl_lithk $ctrl_lithk_20152100

# get initial ctrl thickness
lithk_ctrl_init=$exp_out_path/preprocessed/lithk_${name_base_string}_ctrl_init.nc
ncks -O -d time,0 $ctrl_lithk_20152100 $lithk_ctrl_init
ncwa -O -a time $lithk_ctrl_init ${lithk_ctrl_init}_notime

# calculate ctrl anomaly over time
lithk_ctrl_anom=$exp_out_path/preprocessed/lithk_${name_base_string}_ctrl_anomaly.nc
ncdiff -O $ctrl_lithk_20152100 ${lithk_ctrl_init}_notime $lithk_ctrl_anom

# remove ctrl anomaly from projection
lithk_anom_adj=$exp_out_path/preprocessed/lithk_${name_base_string}_anomaly_adjusted.nc
ncdiff -O $exp_in_path/lithk_${name_base_string}.nc $lithk_ctrl_anom $lithk_anom_adj

# ensure no negative thickness!
lithk_anom_adj_cln=$exp_out_path/preprocessed/lithk_${name_base_string}_anomaly_adjusted_cleaned.nc
ncap2 -O -s "where(lithk<0.0) lithk=0.0" $lithk_anom_adj $lithk_anom_adj_cln

# add bed topo so we can calculate grounded ice
ncks -A $exp_in_path/topg_${name_base_string}.nc $lithk_anom_adj_cln

# subsample anomaly adjusted file
lithk_subsamp=$exp_out_path/preprocessed/lithk_${name_base_string}_preprocessed.nc
ncks -O -d time,0,,$STRIDE $lithk_anom_adj_cln $lithk_subsamp

# only keep grounded ice
grdthk_subsamp=$exp_out_path/preprocessed/grdice_${name_base_string}_preprocessed.nc
ncap2 -O -s "where(lithk*910/1028+topg<0) lithk=0.0" $lithk_subsamp $grdthk_subsamp

# only need initial topg
topg_subsamp=$exp_out_path/preprocessed/topg_${name_base_string}_preprocessed.nc
ncks -O -d time,0 $exp_in_path/topg_${name_base_string}.nc $topg_subsamp

# calc SLC for ctrl, projection, and anomaly-adjusted-cleaned proj
python $SCRIPT_DIR/calc_SLR.py --lithk $ctrl_lithk_20152100 --topg $exp_in_path/topg_${name_base_string}.nc --out $exp_out_path/preprocessed/slc-ctrl.nc
python $SCRIPT_DIR/calc_SLR.py --lithk $exp_in_path/lithk_${name_base_string}.nc --topg $exp_in_path/topg_${name_base_string}.nc --out $exp_out_path/preprocessed/slc-proj.nc
python $SCRIPT_DIR/calc_SLR.py --lithk $lithk_anom_adj_cln --topg $exp_in_path/topg_${name_base_string}.nc --out $exp_out_path/preprocessed/slc-proj-adj.nc

# --------
echo -e "\n\n----- Performing remapping of lithk and topg -----\n"
# --------
grdthk_gauss=$exp_out_path/regridded/grdthk_${name_base_string}_GaussianGrid.nc
ncremap -m $MAPFILE -i $grdthk_subsamp -o $grdthk_gauss
# set fill value to 0 and remove attribute to leave 0 values where there is no ice
ncatted -a _FillValue,,o,f,0.0 $grdthk_gauss
ncatted -a _FillValue,,d,, $grdthk_gauss

topg_gauss=$exp_out_path/regridded/topg_${name_base_string}_GaussianGrid.nc
ncremap -m $MAPFILE -i $topg_subsamp -o $topg_gauss --add_fll

# --------
echo -e "\n\n----- Starting Reformat ------\n"
# --------
mkdir -p $exp_out_path/reformatted
python $SCRIPT_DIR/reformat_SL_inputdata.py $exp_out_path/regridded/ $grdthk_gauss $topg_gauss

mkdir -p $exp_out_path/SLM_run/OUTPUT_SLM
cp namelist.sealevel $exp_out_path/SLM_run
cp runslm $exp_out_path/SLM_run
cp job_script.sh $exp_out_path/SLM_run

echo -e "\nComplete.\n"
