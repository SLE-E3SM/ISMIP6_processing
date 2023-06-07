#!/bin/bash

date

IS=AIS
ENSEMBLE_ROOT=/lustre/scratch5/mhoffman/SLM_Processing_MJH2
dest=$ENSEMBLE_ROOT/Training_Data/$IS
mkdir -p $dest


i=0
ii=0
((maxproc=nprocs-1))
echo $maxproc
for d1 in ${ENSEMBLE_ROOT}/${IS}/*/ ; do
    echo $d1
    ISM=`basename $d1`
    for d2 in ${ENSEMBLE_ROOT}/${IS}/${ISM}/*/; do
       echo $d2
       EXP=`basename $d2`
       for yr in {1..17}; do
          TARGETFILE=${dest}/${IS}_${ISM}_${EXP}_${yr}.nc
          # diff load
          ncdiff -O ${d2}/reformatted/grdice${yr}.nc ${d2}/reformatted/grdice0.nc ${TARGETFILE}
          ncdiff -A ${d2}/SLM_run/OUTPUT_SLM/tgrid0.nc ${d2}/SLM_run/OUTPUT_SLM/tgrid${yr}.nc ${TARGETFILE}
       done
    done
done
date
