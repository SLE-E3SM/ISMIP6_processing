#!/bin/bash
#SBATCH --time=0:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=32
#SBATCH --cpus-per-task=1
#SBATCH --qos=debug
#SBATCH  --constraint=cpu


# Values to adjust ==============
nprocs=32
# adjust ntasks in header to match this value (not sure if required)
# can be 128 for nglv=512.  Needs to be smaller for nglv=2048 to avoid memory error.  32 works, but larger may be ok too - needs trial and error

startnum=0
# adjust this to restart an job that timed out.  Set this to the first value larger than the largest number of the last *set* of nprocs runs that completed

IS=AIS
#ENSEMBLE_ROOT=/global/cfs/cdirs/fanssie/users/hoffman2/RSL/Myungsoo-paper-analysis/SLM_Processing_2024-09-11/elastic-only-2048-noMarineCheck/
ENSEMBLE_ROOT=/global/cfs/cdirs/fanssie/users/hoffman2/RSL/Myungsoo-paper-analysis/SLM_Processing_2024-10-26/512-grdiceCalcOnGL-noMC-elastic-only
#ENSEMBLE_ROOT=/lustre/scratch5/mhoffman/SLM_Processing_2024-09-11/viscoelastic-wais-rheology
# ================================

date
i=0
ii=0
((maxproc=nprocs-1))
echo $maxproc
for d1 in ${ENSEMBLE_ROOT}/${IS}/*/ ; do
    #echo $d1
    ISM=`basename $d1`
    for d2 in ${ENSEMBLE_ROOT}/${IS}/${ISM}/*/; do
       #echo $d2
       EXP=`basename $d2`
       cd $d2/SLM_run
       if (( $ii >= $startnum )); then
          echo Starting: $i $ii $IS $ISM $EXP at `pwd`
          cp /global/cfs/cdirs/fanssie/users/hoffman2/RSL/Myungsoo-paper-analysis/ISMIP6_processing/runslm .
          cp /global/cfs/cdirs/fanssie/users/hoffman2/RSL/Myungsoo-paper-analysis/ISMIP6_processing/namelist.sealevel .
          chmod u+x runslm
          srun --exclusive --mem=16G -n 1 ./runslm &> slm.log && echo "SUCCESS: $i $ii $IS $ISM $EXP" || echo "FAILED: $i $ii $IS $ISM $EXP" &
       fi
       cd -
       ((ii+=1))
       if [[ "$i" == $maxproc ]]; then
          wait
          i=0
       else
          ((i+=1))
       fi
    done
done
wait
date
