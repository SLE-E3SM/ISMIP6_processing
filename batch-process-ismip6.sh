#!/bin/bash
#SBATCH --time=0:30:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --qos=debug
#SBATCH  --constraint=cpu

# a python env is needed.  may need/want to change this.
source /global/cfs/cdirs/fanssie/users/hoffman2/compass/main/load_dev_compass_1.4.0-alpha.7_pm-cpu_gnu_mpich_albany.sh

nprocs=128

IS=AIS
ISMIP6_ARCHIVE=/global/cfs/cdirs/fanssie/standard_datasets/ISMIP6_2100_archive


AIS_STD_EXP_LIST="exp05 exp06 exp07 exp08 exp09 exp10 exp12 exp13"
EXP_LIST=$AIS_STD_EXP_LIST

date
i=0
ii=0
((maxproc=nprocs-1))
echo $maxproc
for d1 in $ISMIP6_ARCHIVE/$IS/*/ ; do
    INST=`basename $d1`
    for d2 in $ISMIP6_ARCHIVE/$IS/$INST/*/; do
       ISM=`basename $d2`
       #for d3 in $ISMIP6_ARCHIVE/$IS/$INST/$ISM/*/; do
       #   EXP=`basename $d3`
       for EXP in $EXP_LIST; do
          if [ -d "$ISMIP6_ARCHIVE/$IS/$INST/$ISM/$EXP" ]; then
             echo Starting: $i $ii $IS $INST $ISM $EXP
             srun --exclusive -n 1 ./pre-process-ismip6-run.sh $IS $INST $ISM $EXP && echo "SUCCESS: $i $ii $IS $INST $ISM $EXP" || echo "FAILED: $i $ii $IS $INST $ISM $EXP" &
             ((ii+=1))
             if [[ "$i" == $maxproc ]]; then
                wait
                i=0
             else
                ((i+=1))
             fi
          else
             echo Skipping: $IS $INST $ISM $EXP
          fi
       done
    done
done
wait
date
