#!/bin/bash
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=debug
#SBATCH --reservation=debug
#SBATCH --mem-per-cpu=4G


date
nprocs=128

IS=AIS
ENSEMBLE_ROOT=/lustre/scratch5/mhoffman/SLM_Processing_MJH2


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
       cd $d2/SLM_run
       echo Starting: $i $ii $IS $ISM $EXP at `pwd`
       srun --exclusive -n 1 ./runslm &> slm.log && echo "SUCCESS: $i $ii $IS $ISM $EXP" || echo "FAILED: $i $ii $IS $ISM $EXP" &
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
