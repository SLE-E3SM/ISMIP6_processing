#!/bin/bash
#SBATCH --time=0:30:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=debug
#SBATCH  --constraint=cpu
#SBATCH -A m4274

date

IS=AIS
#ENSEMBLE_ROOT=/lustre/scratch5/mhoffman/SLM_Processing_2024-08-28/viscoelastic-wais-rheology
ENSEMBLE_ROOT=/global/cfs/cdirs/fanssie/users/hoffman2/RSL/Myungsoo-paper-analysis/SLM_Processing_2024-10-26/512-MC-elastic-only
dest=$ENSEMBLE_ROOT/Training_Data/$IS
mkdir -p $dest

ii=0
for d1 in ${ENSEMBLE_ROOT}/${IS}/*/ ; do
    echo $d1
    ISM=`basename $d1`
    ((ii+=1))

    if [[ "$ii" < '5' ]]
    then
        echo "Skipping $ii!"
        continue
    fi
    echo "Running $ii"
    
    for d2 in ${ENSEMBLE_ROOT}/${IS}/${ISM}/*/; do
       echo $d2
       EXP=`basename $d2`
       #ncrename -d .x,lat ${d2}/reformatted/grdice0.nc
       #ncrename -d .y,lon ${d2}/reformatted/grdice0.nc

       grdicefile=`ls -1 ${d2}/preprocessed/grdice_*_preprocessed.nc`
       #ncks -O -d time,0 $grdicefile ${d2}/preprocessed/grdice_PSG0.nc

       ncks -O -d time,0 $grdicefile ${d2}/preprocessed/tmp_thk_0.nc
       ncap2 -O -s "*hf = topg/910.0*1000.0; where(hf>0.0) hf=0.0; lithk += hf; where(lithk < 0.0) lithk = 0.0"  ${d2}/preprocessed/tmp_thk_0.nc ${d2}/preprocessed/grdice_PSG0.nc

       #for yr in {0..17}; do
       #   ncatted -a _FillValue,,o,f,0.0 ${d2}/reformatted/grdice${yr}.nc
       #   ncatted -a _FillValue,,d,, ${d2}/reformatted/grdice${yr}.nc
       #done
       for yr in {1..17}; do
          TARGETFILE=${dest}/${IS}_${ISM}_${EXP}_${yr}

          ## copy over latlon grdice
          #ncdiff -O ${d2}/reformatted/grdice${yr}.nc ${d2}/reformatted/grdice0.nc ${TARGETFILE}_grdice_latlon.nc

          # copy over polar stereographic grdice
          ncks -O -d time,${yr} $grdicefile ${d2}/preprocessed/tmp_thk_${yr}.nc
          ncap2 -O -s "*hf = topg/910.0*1000.0; where(hf>0.0) hf=0.0; lithk += hf; where(lithk < 0.0) lithk = 0.0"  ${d2}/preprocessed/tmp_thk_${yr}.nc ${d2}/preprocessed/grdice_PSG${yr}.nc

          #ncks -O -d time,${yr} $grdicefile ${d2}/preprocessed/grdice_PSG${yr}.nc

          ncdiff -O ${d2}/preprocessed/grdice_PSG${yr}.nc ${d2}/preprocessed/grdice_PSG0.nc ${TARGETFILE}_grdice_PSG.nc

          # copy over SLC
          ncdiff -O ${d2}/SLM_run/OUTPUT_SLM/tgrid0.nc ${d2}/SLM_run/OUTPUT_SLM/tgrid${yr}.nc ${TARGETFILE}_tgrid.nc
       done
    done
done
date
