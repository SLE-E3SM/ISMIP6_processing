#!/bin/bash

# a python env is needed.  may need/want to change this.
#source /usr/projects/climate/mhoffman/compass/main/load_dev_compass_1.2.0-alpha.5_chicoma-cpu_gnu_mpich_albany.sh

# This script can be invoked with 4 command-line arguments
# for ice sheet, institution, ice-sheet model, and experiments.
# If it is invoked with anything other than 4 arguments,
# the hard-coded values on the following lines will be used
# instead.

# ---- Set experiment
IS=AIS
INST=DOE
ISM=MALI
EXP=exp13
# --------------------

set -e # exit on error

# ---- STUFF TO SET ONCE -----------
OUTPUT_DIR=/lustre/scratch5/mhoffman/SLM_Processing_MJH2
ISMIP6_ARCHIVE=/lustre/scratch5/mhoffman/ISMIP6_2100_archive
AISMAPFILE=/usr/projects/climate/mhoffman/SLE-E3SM/ISMIP6_processing/mapfile_polarRank2_to_gaussRank2.nc
GISMAPFILE=/usr/projects/climate/mhoffman/SLE-E3SM/ISMIP6_processing/mapfile_ismip6_GrIS_Gauss.nc
STRIDE=5 # stride in years to subsample
# ----------------------------------


# CHANGE NOTHING BELOW HERE

if [ "$#" -eq 4 ]; then
   IS=$1
   INST=$2
   ISM=$3
   EXP=$4
   mkdir -p $OUTPUT_DIR/$IS/${INST}_$ISM/$EXP
   exec &> $OUTPUT_DIR/$IS/${INST}_$ISM/$EXP/log.out
fi



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
if [ -d "$ISMIP6_ARCHIVE/$IS/$INST/$ISM/ctrl_proj_std/" ]; then
   ctrl_lithk=`ls -1 $ISMIP6_ARCHIVE/$IS/$INST/$ISM/ctrl_proj_std/lithk*nc`
elif [ -d "$ISMIP6_ARCHIVE/$IS/$INST/$ISM/ctrl_proj/" ]; then
   ctrl_lithk=`ls -1 $ISMIP6_ARCHIVE/$IS/$INST/$ISM/ctrl_proj/lithk*nc`
else
   echo "Unable to find control run"
   exit 1
fi
echo "Found control run file $ctrl_lithk"

echo "get section of ctrl that matches time levels of projection.  assume it is the last 86 time levels"
ctrl_lithk_20152100=$exp_out_path/preprocessed/lithk_${IS}_${INST}_${ISM}_ctrl_2015-2100.nc
ncks -O -d time,-86, $ctrl_lithk $ctrl_lithk_20152100

echo "get initial ctrl thickness"
lithk_ctrl_init=$exp_out_path/preprocessed/lithk_${name_base_string}_ctrl_init.nc
ncks -O -d time,0 $ctrl_lithk_20152100 $lithk_ctrl_init
ncwa -O -a time $lithk_ctrl_init ${lithk_ctrl_init}_notime

echo "calculate ctrl anomaly over time"
lithk_ctrl_anom=$exp_out_path/preprocessed/lithk_${name_base_string}_ctrl_anomaly.nc
ncdiff -O $ctrl_lithk_20152100 ${lithk_ctrl_init}_notime $lithk_ctrl_anom

echo "get last 86 time levels of projection"
# some runs have 87 instead of 86
# some models used nonstandard filenames, so use wildcard to find the correct file
lithkfile=`ls -1 $exp_in_path/*lithk_*.nc`
lithk_20152100=$exp_out_path/preprocessed/lithk_${IS}_${INST}_${ISM}_2015-2100.nc
ncks -O -d time,-86, $lithkfile $lithk_20152100

echo "remove ctrl anomaly from projection"
lithk_anom_adj=$exp_out_path/preprocessed/lithk_${name_base_string}_anomaly_adjusted.nc
ncdiff -O $lithk_20152100 $lithk_ctrl_anom $lithk_anom_adj

echo "ensure no negative thickness!"
lithk_anom_adj_cln=$exp_out_path/preprocessed/lithk_${name_base_string}_anomaly_adjusted_cleaned.nc
ncap2 -O -s "where(lithk<0.0) lithk=0.0" $lithk_anom_adj $lithk_anom_adj_cln

echo "add bed topo so we can calculate grounded ice"
# some models used nonstandard filenames, so use wildcard to find the correct file
topgfile=`ls -1 $exp_in_path/*topg_*.nc`
ncks -A $topgfile $lithk_anom_adj_cln

echo "subsample anomaly adjusted file"
lithk_subsamp=$exp_out_path/preprocessed/lithk_${name_base_string}_preprocessed.nc
ncks -O -d time,0,,$STRIDE $lithk_anom_adj_cln $lithk_subsamp

echo "only keep grounded ice"
grdthk_subsamp=$exp_out_path/preprocessed/grdice_${name_base_string}_preprocessed.nc
ncap2 -O -s "where(lithk*910/1028+topg<0) lithk=0.0" $lithk_subsamp $grdthk_subsamp

echo "subsample topg - only need initial topg"
topg_subsamp=$exp_out_path/preprocessed/topg_${name_base_string}_preprocessed.nc
ncks -O -d time,0 $topgfile $topg_subsamp

echo "calc SLC for ctrl, projection, and anomaly-adjusted-cleaned proj"
python $SCRIPT_DIR/calc_SLR.py --lithk $ctrl_lithk_20152100 --topg $exp_in_path/topg_${name_base_string}.nc --out $exp_out_path/preprocessed/slc-ctrl.nc
python $SCRIPT_DIR/calc_SLR.py --lithk $exp_in_path/lithk_${name_base_string}.nc --topg $exp_in_path/topg_${name_base_string}.nc --out $exp_out_path/preprocessed/slc-proj.nc
python $SCRIPT_DIR/calc_SLR.py --lithk $lithk_anom_adj_cln --topg $exp_in_path/topg_${name_base_string}.nc --out $exp_out_path/preprocessed/slc-proj-adj.nc

# --------
echo -e "\n\n----- Performing remapping of lithk and topg -----\n"
# --------
grdthk_gauss=$exp_out_path/regridded/grdthk_${name_base_string}_GaussianGrid.nc
ncremap -m $MAPFILE -i $grdthk_subsamp -o $grdthk_gauss
echo "set fill value to 0 and remove attribute to leave 0 values where there is no ice"
ncatted -a _FillValue,,o,f,0.0 $grdthk_gauss
ncatted -a _FillValue,,d,, $grdthk_gauss

topg_gauss=$exp_out_path/regridded/topg_${name_base_string}_GaussianGrid.nc
ncremap -m $MAPFILE -i $topg_subsamp -o $topg_gauss --add_fll

# --------
echo -e "\n\n----- Starting Reformat ------\n"
# --------
mkdir -p $exp_out_path/reformatted
python $SCRIPT_DIR/reformat_SL_inputdata.py $exp_out_path/regridded/ $grdthk_gauss $topg_gauss

echo "set up run directory"
mkdir -p $exp_out_path/SLM_run/OUTPUT_SLM
cp namelist.sealevel $exp_out_path/SLM_run
cp runslm $exp_out_path/SLM_run
cp job_script.sh $exp_out_path/SLM_run

echo -e "\nComplete.\n"
