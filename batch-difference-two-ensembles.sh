#!/bin/bash
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1


date

IS=AIS
ENSEMBLE1_ROOT=/lustre/scratch5/mhoffman/SLM_Processing_2024-08-28/elastic-only
ENSEMBLE2_ROOT=/lustre/scratch5/mhoffman/SLM_Processing_2024-08-28/viscoelastic-standard-rheology

ENSEMBLE_DIFF_ROOT=/lustre/scratch5/mhoffman/SLM_Processing_2024-08-28/standard-minus-elastic

dest=$ENSEMBLE_DIFF_ROOT/Training_Data/$IS
mkdir -p $dest

SEARCHPATH1=${ENSEMBLE1_ROOT}/Training_Data/${IS}/
SEARCHPATH2=${ENSEMBLE2_ROOT}/Training_Data/${IS}/
for f2 in $SEARCHPATH2/*_tgrid.nc; do
    echo $f2
    fname=`basename $f2`
    ncdiff -O $SEARCHPATH2/$fname $SEARCHPATH1/$fname $dest/$fname
done
date

